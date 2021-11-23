<template>
  <div>
    <nav class="navbar navbar-light navbar-background d-block">
      <a class="navbar-brand" href="#" @click="goHome">
        <img src="/assets/microhealthllc.png"/>
      </a>
      <button role="button" class="btn btn-info" @click.prevent="openPrivacy">
          <i class="fas fa-shield-alt"></i>
          Make Private
      </button>
      <div class="float-right pt-2 pr-2">
        <button role="button" class="btn btn-info" @click.prevent="addedTreeMap">
          <i class="fas fa-plus"></i>
          Update TreeMap
        </button>
        <button role="button" class="btn btn-primary" @click.prevent="updateNodeToMap">
          <i class="fas fa-plus"></i>
          Update Node
        </button>
        <button role="button" class="btn btn-secondary" @click.prevent="AddNodeToMap">
          <i class="fas fa-plus"></i>
          Add Node
        </button>
        <button role="button" class="btn btn-danger" @click.prevent="$refs['delete-map-modal'].$refs['deleteMapModal'].open">
          <i class="fas fa-trash"></i>
          Delete Map
        </button>
      </div>
    </nav>
    <div class="row mt-3">
      <div class="col-12">
        <JqxTreeMap ref="myTreeMap" @bindingComplete="onBindingComplete($event)"
            :colorRange="50"/>
      </div>
    </div>
    <add-node ref="add-node" :treeMap="currentMindMap" :nodes="nodes" @saveNode="submitChildNode"></add-node>
    <update-tree-map ref="update-tree-map" :treeMaps="currentMindMap" @updateTreeMap="updateTreeMaps"></update-tree-map>
    <update-node ref="update-node" :nodes="nodes" @updatedNode="updateSelectedNode" @deleteNode="deleteSelectedNode"></update-node>
    <make-private-modal ref="make-private-modal" @password-apply="passwordProtect"  @password_mismatched="$refs['passwordMismatched'].open()" :password="currentMindMap.password"></make-private-modal>

    <sweet-modal ref="errorModal" class="of_v" icon="error" title="Password Error">
      Incorrect Password, Please Try Again!
    </sweet-modal>
    <sweet-modal ref="passwordMismatched" class="of_v" icon="error" title="Password Mismatch">
      Your Password and Confirm Password are Mismatched, Please Try Again!
      <button slot="button" @click="passwordAgain" class="btn btn-warning mr-2">Try Again</button>
      <button slot="button" @click="$refs['passwordMismatched'].close()" class="btn btn-secondary">Cancel</button>
    </sweet-modal>

    <sweet-modal ref="successModal" class="of_v" icon="success">
      Password updated successfully!
    </sweet-modal>
    <delete-map-modal ref="delete-map-modal" @delete-mindmap="confirmDeleteMindmap"></delete-map-modal>

    <delete-password-modal ref="delete-password-modal" @deletePasswordCheck="passwordCheck">
    </delete-password-modal>
  </div>
</template>

<script>
  // Import the components that will be used
  import http from '../../common/http'
  import JqxTreeMap from 'jqwidgets-scripts/jqwidgets-vue/vue_jqxtreemap.vue';
  import AddNode from './modals/add_node'
  import UpdateNode from './modals/update_node'
  import UpdateTreeMap from './modals/update_tree_map'
  import DeleteMapModal from '../../common/modals/delete_modal'
  import DeletePasswordModal from '../../common/modals/delete_password_modal'
  import MakePrivateModal from "../../common/modals/make_private_modal"
  export default {
    components: {
    // Adding imported widgets here
      JqxTreeMap,
      AddNode,
      UpdateNode,
      UpdateTreeMap,
      MakePrivateModal,
      DeleteMapModal,
      DeletePasswordModal
    },
    props:['currentMindMap'], //Props to be used in the widget
    data: function () {
      // Define properties which will use in the widget
      return {
        color: null,
        nodes: [],
        currentMindMap: {
          mindmap_key: null,
          name: null,
          id: null
        },
        width: 850,
        height: 600,
        colorRange: 50,
        treemap_data: [],
        parent_nodes: {
          label: 'centralized',
          value: 100,
          color: '#B3FAFF'
        },
        renderCallbacks: {
          '*': (elementObject, value) => {
            if (value.data === undefined) {
              let element = elementObject[0];
              element.style.backgroundColor = '#fff';
              element.style.border = '1px solid #555';
            }
            else {
              elementObject.jqxTooltip({
                content: '<div><div style="font-weight: bold; max-width: 200px; font-family: verdana; font-size: 13px;">' + value.data.title + '</div><div style="width: 200px; font-family: verdana; font-size: 12px;">' + value.data.description + '</div></div>',
                position: 'mouse',
                autoHideDelay: 6000
              });
            }
          }
        }
      }
    },
    mounted: async function () {
      this.getTreeMap()
    },
    methods: {
      AddNodeToMap: function () {
        this.$refs['add-node'].$refs['addNodeToTreeMap'].open()
      },
      updateNodeToMap: function () {
        this.$refs['update-node'].$refs['updateNodeToTreeMap'].open()
      },
      addedTreeMap: function () {
        this.$refs['update-tree-map'].$refs['updateTreeMapRef'].open()
      },
      onBindingComplete: function (event) {
      },
      goHome(){
        window.open('/',"_self")
      },
      updateTreeMaps: async function (obj) {
        let data = {
          name: obj.name,
          mm_type: 'tree_map'
        }
        await http.put(`/mindmaps/${this.currentMindMap.mindmap_key}`, data);
        this.getTreeMap()
      },
      updateSelectedNode: async function(obj){
        await http.put(`/nodes/${obj.id}`, obj);
        this.getTreeMap()
      },
      deleteSelectedNode: async function(obj){
        await http.delete(`/nodes/${obj.id}.json`);
        this.getTreeMap()
      },
      submitChildNode: async function (obj) {
        let _this = this
        let data = {
          node: {
            title: obj.label,
            line_color: obj.color,
            node_width: 50,//obj.node_width,
            parent_node: ((obj.parent_label != null) ? obj.parent_label : 0),
            mindmap_id: this.currentMindMap.id,
          }
        }
        http.post(`/nodes.json`, data).then((res) => {
          _this.getTreeMap()
        }).catch(err => {
          alert(err.message)
        })
      },
      getTreeMap: async function(){
        this.currentMindMap.mindmap_key = this.$route.fullPath.replace('/','');
        let _this = this
        let array_nodes = null
        let response = await http.get(`/mindmaps/${this.currentMindMap.mindmap_key}.json`);
        this.parent_nodes.label = response.data.mindmap.name
        this.currentMindMap.id = response.data.mindmap.id
        this.currentMindMap.name = response.data.mindmap.name
        this.nodes = response.data.mindmap.nodes
        array_nodes = this.nodes.map((node, index) => {
          return {
            label: node.title,
            parent: node.parent,
            color: node.line_color,
            value: 50 //node.node_width
          };
        })
        array_nodes.unshift(this.parent_nodes)
        this.treemap_data = []
        this.treemap_data = array_nodes
        this.$refs.myTreeMap.source = this.treemap_data
      },
      openPrivacy() {
        this.$refs['make-private-modal'].$refs['makePrivateModal'].open()
      },
      passwordAgain(){
        this.$refs['passwordMismatched'].close()
        this.openPrivacy()
      },
      passwordProtect(new_password, old_password){
        http
        .patch(`/mindmaps/${this.currentMindMap.unique_key}.json`,{mindmap:{password: new_password, old_password: old_password}})
        .then(res=>{
          if (res.data.mindmap) {
            this.currentMindMap.password = res.data.mindmap.password
            this.$refs['successModal'].open()
          }
          else {
            this.$refs['errorModal'].open()
          }
        })
      },
      confirmDeleteMindmap(){
        if (this.currentMindMap.password){
          this.$refs['delete-password-modal'].$refs['DeletePasswordModal'].open()
        }
        else{
          this.deleteMindmap()
        }
      },
      passwordCheck(password){
        http.get(`/mindmaps/${this.currentMindMap.unique_key}.json?password_check=${password}`)
        .then(res=>{
          if (res.data.is_verified){
            this.deleteMindmap()
          }
          else{
            this.$refs['errorModal'].open()
          }
        })
      },
      deleteMindmap(){
        http
        .delete(`/mindmaps/${this.currentMindMap.unique_key}`)
        .then(res=>{
          window.open('/','_self')
        })
        .catch(error=>{
          console.log(error)
        })
      }
    }
  }
</script>

<style>
  @import "./tree_map.scss";
</style>
