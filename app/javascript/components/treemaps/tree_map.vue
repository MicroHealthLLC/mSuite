<template>
  <div>
    <nav class="navbar navbar-light navbar-background d-block">
      <a class="navbar-brand pointer"  @click="goHome">
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
        <button role="button" class="btn btn-secondary" @click.prevent="exportImage">
          <i class="fas fa-image"></i>
          Export Image
        </button>
      </div>
    </nav>
    <div class="row mt-3">
      <div class="col-12">
        <div id="treeMapGraph">
          <JqxTreeMap ref="myTreeMap" @bindingComplete="onBindingComplete($event)"
              :colorRange="50" :renderCallbacks="renderCallbacks"/>
        </div>
        <div v-if="colorSelected">
          <div class="card col-3 card-poisiton p-0 border-none">
            <div class="card-body p-0">
              <chrome-picker v-model="selectedNodeColor.line_color" @input="updateColorNode"/>
            </div>
            <div class="card-button d-flex">
              <button class="btn btn-success w-50 border-none" @click="saveNodeColor">Update</button>
              <button class="btn btn-info w-50 border-none" @click="closeModelPicker">Cancel</button>
            </div>
          </div>

        </div>
      </div>
    </div>

    <add-node ref="add-node" :treeMap="currentMindMap" :nodes="nodes" @saveNode="submitChildNode"></add-node>
    <confirm-save-key-modal ref="confirm-save-key-modal" :current-mind-map="currentMindMap"></confirm-save-key-modal>
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

    <sweet-modal ref="errorNodeModal" class="of_v" icon="error" title="Node Title Error">
      Nodes Title Cannot Be Empty
    </sweet-modal>

    <sweet-modal ref="deleteNodeConfirm" class="of_v" icon="warning" title="Delete node">
      Do you want to delete this node?
      <button slot="button" @click="deleteSelectedNode(child_node)" class="btn btn-warning mr-2">Delete</button>
      <button slot="button" @click="$refs['deleteNodeConfirm'].close()" class="btn btn-secondary">Cancel</button>
    </sweet-modal>
  </div>
</template>

<script>
  // Import the components that will be used
  import domtoimage from "dom-to-image-more"
  import http from '../../common/http'
  import JqxTreeMap from 'jqwidgets-scripts/jqwidgets-vue/vue_jqxtreemap.vue';
  import AddNode from './modals/add_node'
  import DeleteMapModal from '../../common/modals/delete_modal'
  import ConfirmSaveKeyModal from "../../common/modals/confirm_save_key_modal"
  import DeletePasswordModal from '../../common/modals/delete_password_modal'
  import MakePrivateModal from "../../common/modals/make_private_modal"

  export default {
    components: {
    // Adding imported widgets here
      JqxTreeMap,
      AddNode,
      MakePrivateModal,
      DeleteMapModal,
      DeletePasswordModal,
      ConfirmSaveKeyModal
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
        currentElementObj: null,
        oldEventElement: null,
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
                this.textEdit(event)
              }
              else if (event.target.tagName === 'DIV')
              {
                this.colorChange(value, elementObject)
              }
              else if (event.target.tagName === 'path')
              {
                this.deleteNode(value)
              }
            })
          }
        }
      }
    },
    mounted: async function () {
      this.$cable.subscribe({
        channel: "WebNotificationsChannel",
        room: this.currentMindMap.id,
      });
      this.getTreeMap()
    },
    channels: {
      WebNotificationsChannel: {
        connected() {},
        rejected() {},
        received(data) {
          if (data.message === "Mindmap Deleted" && this.currentMindMap.id === data.mindmap.id)
          {
            window.open('/','_self')
          } else {
            this.getTreeMap()
          }
        },
        disconnected() {}
      }
    },
    methods: {
      exportImage() {
        const _this = this
        let elm = document.getElementById("treeMapGraph")
        elm.style.transform = "scale(1)"
        let map_key = _this.currentMindMap.unique_key || "image"
        domtoimage.toPng(elm, {height: elm.scrollHeight, width: elm.scrollWidth})
        .then((url) => {
          let downloadLink = document.createElement("a")
          document.body.appendChild(downloadLink)
          downloadLink.href = url
          downloadLink.download = map_key + ".png"
          downloadLink.click()
          document.body.removeChild(downloadLink)
        })
        .catch((err) => {
          console.error('oops, something went wrong!', err)
        })
      },
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
        this.$refs['confirm-save-key-modal'].$refs['confirmSaveKeyModal'].open()
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
      },
      updateSelectedNode: async function(obj){
        await http.put(`/nodes/${obj.id}`, obj);
        this.child_node = null
        this.hiddenNode = false
      },
      deleteSelectedNode: async function(obj){
        await http.delete(`/nodes/${obj.id}.json`);
        this.$refs['deleteNodeConfirm'].close()
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
          // success modal display
        }).catch(err => {
          alert(err.message)
          // error modal display
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
        .patch(`/mindmaps/${this.currentMindMap.unique_key}.json`,{mindmap: {password: new_password, old_password: old_password}})
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
        .then(res => {
          window.open('/','_self')
        })
        .catch(error => {
          console.log(error)
        })
      },
      setNodeSelected(value){
        this.node.label = value.label
        if(this.node.label){
          this.child_node = this.nodes.find(n => n.title === this.node.label)
          this.parent_node = (this.node.label == this.currentMindMap.name) ? true : null
        }
      },
      textEdit(eventElement){
        var keyUpTimeOut
        let _this = this
        var oldTitle = _this.node.label
        eventElement.target.contentEditable = true
        eventElement.target.focus();
        _this.colorSelected = false
        _this.hiddenNode = true
        _this.oldEventElement = eventElement
        eventElement.target.addEventListener('keyup', function(){
          clearTimeout(keyUpTimeOut)
          var newTitle = event.target.innerText.split('\n').join('')
          if (event.keyCode === 13) {
            if (newTitle) {
              _this.node_title = newTitle
              _this.putData()
            }
            else {
              _this.$refs['errorNodeModal'].open()
              eventElement.target.innerText = oldTitle
            }
          }
          else if (newTitle && newTitle !== oldTitle) {
            keyUpTimeOut = setTimeout(() => {
              _this.node_title = newTitle
              _this.putData()
            }, 2000)
          }
        })
      },
      putData(){
        if(this.parent_node){
          this.currentMindMap.name = this.node_title
          this.updateTreeMaps(this.currentMindMap)
        } else {
          this.child_node.title = this.node_title
          this.updateSelectedNode(this.child_node)
        }
      },
      updateColorNode(){
        this.currentElementObj[0].style.backgroundColor = this.selectedNodeColor.line_color.hex
        this.selectedNodeColor.line_color = this.selectedNodeColor.line_color.hex
      },
      saveNodeColor(){
        if(this.parent_node){
          this.updateTreeMaps(this.selectedNodeColor)
        } else {
          this.updateSelectedNode(this.selectedNodeColor)
        }
        this.colorSelected = false
        this.selectedNodeColor = null
      },
      closeModelPicker(){
        this.currentElementObj[0].style.backgroundColor = this.oldElementColor
        this.colorSelected = false
      },
      colorChange(value, elementObject){
        if(this.hiddenNode){
          let _this = this
          let oldTitle = _this.node.label
          if (_this.oldEventElement.target.innerText) {
            _this.node_title = _this.oldEventElement.target.innerText
            _this.putData()
          }
          else {
            _this.$refs['errorNodeModal'].open()
            _this.oldEventElement.target.innerText = oldTitle
            _this.hiddenNode = false
          }
          return;
        }
        else if(this.colorSelected){
          this.currentElementObj[0].style.backgroundColor = this.oldElementColor
          return this.colorSelected = false
        }
        this.currentElementObj = elementObject
        this.setNodeSelected(value)
        this.colorSelected = true
        this.oldElementColor = JSON.parse(JSON.stringify(this.currentElementObj[0].style.backgroundColor))

        if(this.parent_node){
          let objKey = Object.assign({}, this.currentMindMap)
          this.selectedNodeColor = objKey
          this.nodeColor.hex = objKey.line_color
          this.selectedNodeColor.line_color = this.nodeColor
        } else {
          let objKey = Object.assign({}, this.child_node)
          this.selectedNodeColor = objKey
          this.nodeColor.hex = objKey.line_color
          this.selectedNodeColor.line_color = this.nodeColor
        }

      },
      deleteNode(value){
        this.setNodeSelected(value)
        if(this.parent_node){
          this.$refs['delete-map-modal'].$refs['deleteMapModal'].open()
        } else {
          this.$refs['deleteNodeConfirm'].open()
        }
      }
    }
  }
</script>

<style>
  @import "./tree_map.scss";
</style>
