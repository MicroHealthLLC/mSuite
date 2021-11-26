<template>
  <div>
    <nav class="navbar navbar-light navbar-background d-block">
      <a class="navbar-brand" href="#" @click="goHome">
        <img src="/assets/microhealthllc.png"/>
      </a>
      <div class="float-right pt-2 pr-2">
        <button role="button" class="btn btn-info" @click.prevent="openPrivacy">
            <i class="fas fa-shield-alt"></i>
            Make Private
        </button>
        <button role="button" class="btn btn-primary" @click.prevent="AddNodeToMap">
          <i class="fas fa-plus"></i>
          Add Node
        </button>
      </div>
    </nav>
    <div class="row mt-3">
      <div class="col-12">
        <JqxTreeMap ref="myTreeMap" @bindingComplete="onBindingComplete($event)"
            :colorRange="50" :renderCallbacks="renderCallbacks"/>
        <div v-if="colorSelected">
          <chrome-picker v-model="selectedNodeColor.line_color" @input="updateColorNode"/>
        </div>
      </div>
    </div>

    <add-node ref="add-node" :treeMap="currentMindMap" :nodes="nodes" @saveNode="submitChildNode"></add-node>
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

    <sweet-modal ref="deleteNodeConfirm" class="of_v" icon="warning" title="Delete node">
      Do you want to delete this node?
      <button slot="button" @click="deleteSelectedNode(child_node)" class="btn btn-warning mr-2">Delete</button>
      <button slot="button" @click="$refs['deleteNodeConfirm'].close()" class="btn btn-secondary">Cancel</button>
    </sweet-modal>
  </div>
</template>

<script>
  // Import the components that will be used
  import http from '../../common/http'
  import JqxTreeMap from 'jqwidgets-scripts/jqwidgets-vue/vue_jqxtreemap.vue';
  import AddNode from './modals/add_node'
  import DeleteMapModal from '../../common/modals/delete_modal'
  import DeletePasswordModal from '../../common/modals/delete_password_modal'
  import MakePrivateModal from "../../common/modals/make_private_modal"

  export default {
    components: {
    // Adding imported widgets here
      JqxTreeMap,
      AddNode,
      MakePrivateModal,
      DeleteMapModal,
      DeletePasswordModal
    },
    props:['currentMindMap'], //Props to be used in the widget
    data: function () {
      // Define properties which will use in the widget
      return {
        nodeColor: { hex: '#194d33' },
        colorSelected: false,
        selectedNodeColor: null,
        nodes: [],
        width: 850,
        parent_node: null,
        child_node: null,
        height: 600,
        colorRange: 50,
        node:{},
        node_title:'',
        oldEvenetElement: null,
        hiddenNode: false,
        treemap_data: [],
        parent_nodes: {
          label: 'centralized',
          value: 100,
          color: '#B3FAFF'
        },
        renderCallbacks: {
          '*': (elementObject, value) => {
            elementObject.click(() => {
              if (event.target.tagName === 'SPAN')
              {
                this.setNodeSelected(value)
                this.textEdit(event,value,elementObject)
              }
              else if (event.target.tagName === 'DIV')
              {
                this.colorChange(event,value)
              }
              else if (event.target.tagName === 'path')
              {
                this.deleteNode(event, value)
              }
            })
            elementObject.hover(() => {
            })
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
      onBindingComplete: function (event) {
        let nodestreeMaps = []
        var node = document.createElement("i");
        var textnode = document.createTextNode("")
        node.appendChild(textnode);
        node.setAttribute('class','fas fa-times cancel-btn mr-1 mt-1')
        event.target.children[0].append(node)
        this.appendElementTreeMap(event.target.children[0].children)
      },
      appendElementTreeMap(objArray){
        let jqxParentArray = new Array()
        objArray.forEach((e)=>{
          var nodeElement = document.createElement("i");
          var textnodeElement = document.createTextNode("")
          nodeElement.appendChild(textnodeElement);
          nodeElement.setAttribute('class','fas fa-times cancel-btn mr-1 mt-1 pointer')

          if(e.className == 'jqx-treemap-rectangle jqx-treemap-rectangle-parent')
          {
            e.append(nodeElement)
            jqxParentArray = [].concat.apply(jqxParentArray, e.children)
          }

          if(e.className == 'jqx-treemap-rectangle') e.append(nodeElement)
        })
        if(jqxParentArray.length > 0) this.appendElementTreeMap(jqxParentArray)
      },
      goHome(){
        window.open('/',"_self")
      },
      updateTreeMaps: async function (obj) {
        let data = {
          name: obj.name,
          mm_type: 'tree_map',
          line_color: obj.line_color
        }
        await http.put(`/mindmaps/${this.currentMindMap.unique_key}`, data);
        this.parent_node = null
        this.hiddenNode = false
        this.getTreeMap()
      },
      updateSelectedNode: async function(obj){
        await http.put(`/nodes/${obj.id}`, obj);
        this.child_node = null
        this.hiddenNode = false
        this.getTreeMap()
      },
      deleteSelectedNode: async function(obj){
        await http.delete(`/nodes/${obj.id}.json`);
        this.$refs['deleteNodeConfirm'].close()
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
        this.currentMindMap.unique_key = this.$route.fullPath.replace('/','');
        let _this = this
        let array_nodes = null
        let response = await http.get(`/mindmaps/${this.currentMindMap.unique_key}.json`);
        this.parent_nodes.label = response.data.mindmap.name
        this.currentMindMap.id = response.data.mindmap.id
        this.currentMindMap.name = response.data.mindmap.name
        this.currentMindMap.line_color = response.data.mindmap.line_color
        this.parent_nodes.color = this.currentMindMap.line_color
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
            if (res.data.error) this.$refs['errorModal'].open()
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
      },
      setNodeSelected(v){
        this.node.label = v.label
        if(this.node.label){
          this.child_node = this.nodes.find(n=>n.title === this.node.label)
          this.parent_node = (this.node.label == this.currentMindMap.name) ? true : null
        }
      },
      textEdit(e,v,el){
        let _this = this
        e.target.contentEditable = true
        e.target.focus();
        _this.colorSelected = false
        _this.hiddenNode = true
        _this.node_title = e.target.innerText
        _this.oldEvenetElement = e
        e.target.addEventListener('keyup',function(){
          if (event.keyCode === 13) {
            _this.node_title = e.target.innerText.split('\n').join('')
            _this.putData()
          }
        })
      },
      putData(){
        if(this.parent_node){
          this.currentMindMap.name = this.node_title
          this.updateTreeMaps(this.currentMindMap)
        }else{
          this.child_node.title = this.node_title
          this.updateSelectedNode(this.child_node)
        }
      },
      updateColorNode(){
        this.selectedNodeColor.line_color = this.selectedNodeColor.line_color.hex
        if(this.parent_node){
          this.updateTreeMaps(this.selectedNodeColor)
        }else{
          this.updateSelectedNode(this.selectedNodeColor)
        }
        this.colorSelected = false
        this.selectedNodeColor = null
      },
      colorChange(e,v){
        if(this.hiddenNode){
          this.node_title = this.oldEvenetElement.target.innerText
          this.putData()
          return;
        }
        if(this.colorSelected){
          return this.colorSelected = false
        }
        this.setNodeSelected(v)
        this.colorSelected = true
        if(this.parent_node){
          this.selectedNodeColor = this.currentMindMap
          this.nodeColor.hex = this.currentMindMap.line_color
        }else{
          let objKey = Object.assign({}, this.child_node);
          this.selectedNodeColor = objKey
          this.nodeColor.hex = objKey.line_color
        }
        this.selectedNodeColor.line_color = this.nodeColor
      },
      deleteNode(e,v){
        this.setNodeSelected(v)
        if(this.parent_node){
          this.$refs['delete-map-modal'].$refs['deleteMapModal'].open()
        }else{
          this.$refs['deleteNodeConfirm'].open()
        }
      }
    }
  }
</script>

<style>
  @import "./tree_map.scss";
</style>
