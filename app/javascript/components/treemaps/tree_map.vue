<template>
  <div>
    <navigation-bar
      @openPrivacy="openPrivacy"
      :current-mind-map="currentMindMap"
      :defaultDeleteDays="defaultDeleteDays"
      :deleteAfter="deleteAfter"
      :expDays="expDays"
      :temporaryUser="temporaryUser"
      :saveElement="saveElement"
      @deleteMindmap="deleteMap"
      @resetMindmap="resetMindmap"
      @undoMindmap="undoObj"
      @redoMindmap="redoObj"
      @sendLocals="sendLocals"
      :isEditing="isEditing"
      :userList="userList"
      :exportId="'treeMapGraph'">
    </navigation-bar>
    <div class="row mt-1 main_body">
      <div class="col-12 mt-4 font-serif" id="treeMapGraph">
        <JqxTreeMap
          ref="myTreeMap"
          @bindingComplete="onBindingComplete($event)"
          :colorRange="50"
          :renderCallbacks="renderCallbacks"/>
      </div>
      <div v-if="colorSelected">
        <div class="card card-position p-0 border-none mt-5">
          <color-palette
            :treeNode="selectedNodeColor"
            :nodes="nodes"
            :currentMindMap="currentMindMap"
            :customPallete="customPallete"
            :uniqueColors="uniqueColors"
            @updateColorNode="updateColorNode"
            @saveNodeColor="saveNodeColor"
            @closeModelPicker="closeModelPicker"
            @updatedTreeChart="updateTreeMaps"
            @updateTreeChartNode="updateSelectedNode"
          ></color-palette>
        </div>
      </div>
    </div>

    <make-private-modal ref="make-private-modal" @password-apply="passwordProtect"  @password_mismatched="$refs['passwordMismatched'].open()" :password="currentMindMap.password" :isSaveMSuite="isSaveMSuite"></make-private-modal>

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

    <delete-password-modal ref="delete-password-modal" @deletePasswordCheck="deleteMindmapProtected">
    </delete-password-modal>

    <sweet-modal ref="errorNodeModal" class="of_v" icon="error" title="Node Title Error">
      Nodes Title Cannot Be Empty
    </sweet-modal>
    <sweet-modal ref="errorAddNode" class="of_v" icon="error" title="Node Error">
      {{ err }}
    </sweet-modal>
  </div>
</template>

<script>
  // Import the components that will be used
  import domtoimage from "dom-to-image-more"
  import { jsPDF } from "jspdf";
  import html2canvas from "html2canvas"
  import http from '../../common/http'
  import JqxTreeMap from 'jqwidgets-scripts/jqwidgets-vue/vue_jqxtreemap.vue';
  import DeleteMapModal from '../../common/modals/delete_modal'
  import DeletePasswordModal from '../../common/modals/delete_password_modal'
  import ColorPalette from '../../common/modals/color_palette_modal'
  import MakePrivateModal from "../../common/modals/make_private_modal"
  import Common from "../../mixins/common.js"
  import TemporaryUser from "../../mixins/temporary_user.js"

  export default {
    components: {
    // Adding imported widgets here
      JqxTreeMap,
      MakePrivateModal,
      DeleteMapModal,
      DeletePasswordModal,
      ColorPalette
    },
    mixins: [Common, TemporaryUser],
    props:['currentMindMap','defaultDeleteDays','deleteAfter','expDays'], //Props to be used in the widget
    data: function () {
      // Define properties which will use in the widget
      return {
        nodeColor: { hex: '#194d33' },
        mapColors: [],
        uniqueColors: [],
        colorSelected: false,
        selectedNodeColor: null,
        nodes: [],
        width: 850,
        userList: [],
        parent_node: null,
        child_node: null,
        addChildTreeMap: false,
        node:{},
        dragedNode: null,
        node_title:'',
        newNodeValue: '',
        currentElementObj: null,
        oldEventElement: null,
        hiddenNode: false,
        treemap_data: [],
        submitChild: false,
        isSaveMSuite: false,
        isEditing: false,
        nodeSample: {label: 'Enter node title for node',parent_label: '',color: '#CCBBBB'},
        customPallete: [],
        nodeNumber: 0,
        undoNodes: [],
        redoNodes: [],
        undoDone: false,
        nodeSample: {label: 'Enter new node',parent_label: '',color: '#CCBBBB'},
        temporaryUser: '',
        saveElement: false,
        parent_nodes: {
          label: 'centralized',
          value: 100,
          color: '#eeeeee'
        },
        err: '',
        renderCallbacks: {
          '*': (elementObject, value) => {
            elementObject.click(() => {
              if (event.target.tagName === 'SPAN')
              {
                this.setNodeSelected(value)
                this.textEdit(event, value)
              }
              else if (event.target.tagName === 'I')
              {
                if(event.target.classList.contains('fa-plus')){
                  this.addNodeToTreeMap(value, event)
                }else if(event.target.classList.contains('fa-eye-dropper')){
                  this.colorChange(value, elementObject)
                }
                else if(event.target.classList.contains('fa-times')){
                  this.deleteNode(value)
                }
              }
            })
          }
        }
      }
    },
    mounted: async function () {
      this.subscribeCable(this.currentMindMap.id)
      this.mountMap()
      if(localStorage.mindmap_id == this.currentMindMap.id){
        this.userList = JSON.parse(localStorage.userList)
        this.temporaryUser = localStorage.userEdit
      }
    },
    channels: {
      WebNotificationsChannel: {
        connected() {},
        rejected() {},
        received(data) {
          if (data.message === "Mindmap Deleted" && this.currentMindMap.id === data.mindmap.id)
          {
            window.open('/','_self')
          }
          else if (data.message === "Password Updated" && this.currentMindMap.id === data.mindmap.id) {
            setTimeout(() => {
              location.reload()
            }, 1000)
          }
          else if(data.message === "storage updated" && this.currentMindMap.id == data.content.mindmap_id)
          {
            localStorage.nodeNumber = data.content.nodeNumber
            localStorage.userNumber = data.content.userNumber
            this.temporaryUser = data.content.userEdit
            this.userList.push(data.content.userEdit)
            localStorage.userList = JSON.stringify(this.userList);
            this.isEditing = data.isEditing
            if (!this.isEditing) {
              this.saveElement = true
              setTimeout(()=>{
                this.saveElement = false
              },1200)
            }
          }
          else if (data.message === "Reset mindmap" && this.currentMindMap.id === data.mindmap.id) {
            this.currentMindMap = data.mindmap
            this.getTreeMap()
          } 
          else {
            this.getTreeMap()
          }

        },
        disconnected() {}
      }
    },
    methods: {
      onBindingComplete: function (event) {
        let nodestreeMaps = []
        var nodeElement = this.insertNodeElement('fas ml-2 fa-times text-danger cancel-btn mt-1 icon-opacity', 'Delete Map')
        var nodeElementSecond = this.insertNodeElement('fas fa-plus add-icon cancel-btn mt-1 icon-opacity', 'Add Child Node')
        var nodeElementThird = this.insertNodeElement('fas fa-eye-dropper text-dark cancel-btn mt-1 icon-opacity', 'Color Picker')
        event.target.children[0].addEventListener('drop', this.dropNode)
        event.target.children[0].addEventListener('dragover', this.allowdrop)
        event.target.children[0].append(nodeElement, nodeElementSecond, nodeElementThird)
        this.appendElementTreeMap(event.target.children[0].children)
      },
      appendElementTreeMap(objArray){
        let jqxParentArray = new Array()
        objArray.forEach((e)=>{
          var nodeElement = this.insertNodeElement('fas ml-2 fa-times text-danger cancel-btn mt-1 icon-opacity', 'Delete Node')
          var nodeElementSecond = this.insertNodeElement('fas fa-plus add-icon cancel-btn mt-1 icon-opacity', 'Add Child Node')
          var nodeElementThird = this.insertNodeElement('fas fa-eye-dropper text-dark cancel-btn mt-1 icon-opacity', 'Color Picker')
          if(e.className == 'jqx-treemap-rectangle jqx-treemap-rectangle-parent')
          {
            e.style.marginTop = '13px'
            e.style.width = e.style.width.split('px')[0] - 5 + 'px'
            e.style.height = e.style.height.split('px')[0] - 16 + 'px'
            this.bindDragAndDrop(e)
            e.append(nodeElement, nodeElementSecond, nodeElementThird)
            jqxParentArray = [].concat.apply(jqxParentArray, e.children)
          }

          if(e.className == 'jqx-treemap-rectangle'){
            e.style.marginTop = '13px'
            e.style.width = e.style.width.split('px')[0] - 10 + 'px'
            e.style.height = e.style.height.split('px')[0] - 21 + 'px'
            this.bindDragAndDrop(e)
            e.append(nodeElement, nodeElementSecond, nodeElementThird)
          }
        })
        if(jqxParentArray.length > 0) this.appendElementTreeMap(jqxParentArray)
      },
      bindDragAndDrop(event){
        event.setAttribute("draggable", true)
        event.addEventListener('dragstart', this.dragStart)
        event.addEventListener('drop', this.dropNode)
        event.addEventListener('dragover', this.allowdrop)
      },
      allowdrop(ev){
        ev.preventDefault()
      },
      dropNode(e){
        var dropNode = { label: '' }
        if (event.target.tagName === 'SPAN') dropNode.label = e.target.innerText
        if (event.target.tagName === 'DIV') dropNode.label = e.target.children[0].innerText
        this.setNodeSelected(dropNode)
        if(dropNode.label != this.dragedNode.title)
        {
          if(this.child_node) this.dragedNode.parent_node = this.child_node.id
          else if(this.parent_node) this.dragedNode.parent_node = null
          this.updateSelectedNode(this.dragedNode)
        }
      },
      dragStart(e){
        var dragNode = { label: '' }
        if (event.target.tagName === 'SPAN') dragNode.label = e.target.innerText
        if (event.target.tagName === 'DIV') dragNode.label = e.target.children[0].innerText
        this.setNodeSelected(dragNode)
        this.dragedNode = this.child_node
      },
      insertNodeElement(class_list, title) {
        var nodeElement = document.createElement("i");
        var textnodeElement = document.createTextNode("")
        nodeElement.appendChild(textnodeElement);
        nodeElement.setAttribute('class', class_list)
        nodeElement.title = title
        return nodeElement
      },
      updateTreeMaps: async function (obj) {
        let data = {
          name: obj.name,
          mm_type: 'tree_map',
          line_color: obj.line_color
        }
        await http.put(`/msuite/${this.currentMindMap.unique_key}`, data);
        this.parent_node = null
        this.hiddenNode = false
        this.addChildTreeMap = false
        this.colorSelected = false
        this.sendLocals(false)
      },
      updateSelectedNode: async function(obj){
        if(this.undoNodes.length > 0) {
          this.undoNodes.forEach((element, index) => {
            if(element['receivedData']){
              if(element['receivedData'].id === obj.id) {
                this.undoNodes[index]['receivedData'].title = obj.title
                this.undoNodes[index]['receivedData'].line_color = obj.line_color
              } else if(element['node']) {
                if(element['node'].id === obj.id) {
                  this.undoNodes[index]['node'].title = obj.title
                  this.undoNodes[index]['node'].line_color = obj.line_color
                }
              }
            }
          });
        } else {
          this.undoNodes.push({'req': 'addNode', node: obj})
        }
        await http.put(`/nodes/${obj.id}`, obj).then((res) => {
          this.sendLocals(false)
        }).catch(err => {
          this.err = err.message
          this.$refs['errorAddNode'].open()
        });
        this.child_node = null
        this.parent_node = null
        this.hiddenNode = false
        this.addChildTreeMap = false
      },
      deleteSelectedNode: async function(obj){
        await http.delete(`/nodes/${obj.id}.json`).then((res) => {
          let receivedNodes = res.data.node
          if(receivedNodes && receivedNodes.length > 0){
            this.undoNodes.push({'req': 'deleteNode', receivedNodes})
          }
          if (!this.undoDone) {
            let myNode = {
              id: obj.id,
              title: obj.title,
              line_color: obj.line_color,
              mindmap_id: obj.mindmap_id,
              parent_node: obj.parent_node
            }
            this.undoNodes.push({'req': 'deleteNode', node: myNode})
          }
        });
        this.sendLocals(false)
      },
      submitChildNode: async function (obj) {

        let _this = this

        localStorage.mindmap_id = _this.currentMindMap.id
        if(_this.nodes.length > 0 && localStorage.nodeNumber != 'NaN'){
          localStorage.nodeNumber = parseInt(localStorage.nodeNumber) + 1
        } else {
          localStorage.nodeNumber = this.nodeNumber + 1
        }
        this.sendLocals(false)
        let data = {
          node: {
            title: obj.label + ' ' + localStorage.nodeNumber,
            line_color: obj.color,
            node_width: 50,//obj.node_width,
            parent_node: ((obj.parent_label != null) ? obj.parent_label : 0),
            mindmap_id: this.currentMindMap.id,
          }
        }
        http.post(`/nodes.json`, data).then((res) => {
          _this.submitChild = false
          _this.addChildTreeMap = false
          _this.hiddenNode = false
          _this.child_node = null
          _this.nodeSample.parent_label = ''
          if( res.data.node.id == null ){
            obj.label = obj.label + ' 0'
            this.submitChildNode(obj)
          }
          if (!this.undoDone) {
            let receivedData = res.data.node
            _this.undoNodes.push({'req': 'addNode', receivedData})
          }
          // success modal display
        }).catch(err => {
          _this.err = err.message
          _this.$refs['errorAddNode'].open()
          // error modal display
        })
      },
      mountMap: async function() {
        this.parent_nodes.label = this.currentMindMap.name
        this.currentMindMap.id = this.currentMindMap.id
        this.currentMindMap.name = this.currentMindMap.name
        this.currentMindMap.line_color = this.currentMindMap.line_color
        this.parent_nodes.color = this.currentMindMap.line_color
        this.nodes = this.currentMindMap.nodes
        this.getColorNode('.jqx-treemap-rectangle')
        this.mapColors = []
        this.uniqueColors = []
        this.mapColors.push(this.currentMindMap.line_color);
        Object.values(this.nodes).forEach(node => {
          this.mapColors.push(node.line_color);
        });
        this.uniqueColors = this.getUniqueColors(this.mapColors);
        this.buildMap()
      },
      getTreeMap: async function(){
        this.currentMindMap.unique_key = this.$route.fullPath.replace('/','');
        let response = await http.get(`/msuite/${this.currentMindMap.unique_key}.json`);
        this.parent_nodes.label = response.data.mindmap.name
        this.currentMindMap.id = response.data.mindmap.id
        this.currentMindMap.name = response.data.mindmap.name
        this.currentMindMap.title = response.data.mindmap.title
        this.defaultDeleteDays = response.data.defaultDeleteDays
        this.deleteAfter = response.data.deleteAfter
        this.expDays = response.data.expDays
        this.currentMindMap.line_color = response.data.mindmap.line_color
        this.parent_nodes.color = this.currentMindMap.line_color
        this.nodes = response.data.mindmap.nodes
        this.getColorNode('.jqx-treemap-rectangle')
        this.mapColors = []
        this.uniqueColors = []
        this.mapColors.push(this.currentMindMap.line_color);
        Object.values(this.nodes).forEach(node => {
          this.mapColors.push(node.line_color);
        });
        this.uniqueColors = this.getUniqueColors(this.mapColors);
        this.buildMap()
      },
      buildMap() {
        let array_nodes = null
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
      openPrivacy(val) {
        this.isSaveMSuite = val
        this.$refs['make-private-modal'].$refs['makePrivateModal'].open()
      },
      passwordAgain(){
        this.$refs['passwordMismatched'].close()
        this.openPrivacy()
      },
      passwordProtect(new_password, old_password, is_mSuite){
        http
        .patch(`/msuite/${this.currentMindMap.unique_key}.json`,{mindmap: {password: new_password, old_password: old_password}})
        .then(res=>{
          if (res.data.mindmap) {
            this.currentMindMap.password = res.data.mindmap.password
            if(!is_mSuite) window.open("/", "_self")
            else location.reload()
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
      deleteMindmapProtected(password){
        http
        .delete(`/msuite/${this.currentMindMap.unique_key}.json?password_check=${password}`)
        .then(res=>{
          if (!res.data.success && this.currentMindMap.password)
            this.$refs['errorModal'].open()
        })
        .catch(error=>{
          console.log(error)
        })
      },
      deleteMindmap(){
        http
        .delete(`/msuite/${this.currentMindMap.unique_key}`)
        .then(res => {
          window.open("/", "_self")
        })
        .catch(error => {
          console.log(error)
        })
      },
      setNodeSelected(value){
        this.node.label = value.label
        if(this.node.label && value.label != "Enter Node Title Here"){
          this.child_node = this.nodes.find(n => n.title === this.node.label)
          this.parent_node = (this.node.label == this.currentMindMap.name) ? true : null
        }else if(value.parent.label && value.label == "Enter Node Title Here"){
          this.child_node = this.nodes.find(n => n.title === value.parent.label)
          this.parent_node = (value.parent.label == this.currentMindMap.name) ? true : null
          this.submitChild = true
        }
      },
      textEdit(eventElement, value){
        let _this = this
        _this.sendLocals(true)
        _this.hiddenNode = true
        if(value.label == 'Enter Node Title Here') return this.saveNodeElement(eventElement,value);
        var keyUpTimeOut
        var oldTitle = _this.node.label
        eventElement.target.contentEditable = true
        eventElement.target.focus();
        eventElement.target.style.backgroundColor = "white"
        eventElement.target.style.color = "black"
        _this.colorSelected = false
        _this.sendLocals(false)
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
              eventElement.target.style.backgroundColor = ""
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
      saveNodeElement(eventElement, value){
        let _this = this
        var keyUpTimeOut
        var oldTitle = _this.node.label
        var input = document.createElement("input");
        input.type = "text";
        input.setAttribute("id", "nodeField")
        input.setAttribute("class", "input-field px-2")
        eventElement.target.innerText = ''
        eventElement.target.appendChild(input)
        document.getElementById('nodeField').focus()
        eventElement.target.addEventListener('keyup', (() => {
          clearTimeout(keyUpTimeOut)
          _this.newNodeValue = document.getElementById('nodeField').value
          if (event.keyCode === 13) {
            if(_this.newNodeValue && _this.newNodeValue != oldTitle) _this.postDataNode(_this.newNodeValue)
            else {
              _this.$refs['errorNodeModal'].open(); eventElement.target.innerText = oldTitle
            }
          }else if (_this.newNodeValue && _this.newNodeValue !== oldTitle)
          {
            keyUpTimeOut = setTimeout(() => {
              _this.postDataNode(_this.newNodeValue)
            }, 2000)
          }
          }), false)
      },
      postDataNode(){
        let node = {
          label: this.newNodeValue,
          parent_label: null,
          node_width: '50',
          color: '#CCBBBB'
        }
        if(this.child_node) node.parent_label = this.child_node.id
        this.undoDone = false
        this.submitChildNode(node)
      },
      putData(){
        if(!this.submitChild && this.parent_node){
          this.currentMindMap.name = this.node_title
          this.updateTreeMaps(this.currentMindMap)
        }else if(this.child_node && !this.submitChild){
          this.child_node.title = this.node_title
          this.updateSelectedNode(this.child_node)
        }
        this.sendLocals(false)
      },
      updateColorNode(){
        this.currentElementObj[0].style.backgroundColor = this.selectedNodeColor.line_color.hex
        if(this.wc_hex_is_light(this.selectedNodeColor.line_color.hex)){
          this.currentElementObj[0].style.color = '#000'
        } else {
          this.currentElementObj[0].style.color = '#fff'
        }
        this.selectedNodeColor.line_color = this.selectedNodeColor.line_color.hex
        this.getColorNode('.jqx-treemap-rectangle')
      },
      saveNodeColor(){
        if(this.parent_node){
          this.updateTreeMaps(this.selectedNodeColor)
        } else {
          this.updateSelectedNode(this.selectedNodeColor)
        }
      this.colorSelected = false
      this.selectedNodeColor = null
      this.sendLocals(false)
      },
      closeModelPicker(){
        this.currentElementObj[0].style.backgroundColor = this.oldElementColor
        this.colorSelected = false
        this.getColorNode('.jqx-treemap-rectangle')
        this.sendLocals(false)
      },
      colorChange(value, elementObject){
        if(this.addChildTreeMap) return
        this.currentElementObj = elementObject
        this.setNodeSelected(value)
        this.colorSelected = true
        this.sendLocals(true)
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
        if(this.addChildTreeMap){
          this.treemap_data.splice(-1, 1)
          this.addChildTreeMap = false
          return this.$refs.myTreeMap.source = this.treemap_data
        }
        this.setNodeSelected(value)
        if(this.parent_node){
          this.$refs['delete-map-modal'].$refs['deleteMapModal'].open()
        } else {
          this.child_node.mindmap_id = this.currentMindMap.id
          this.undoDone = false
          this.deleteSelectedNode(this.child_node)
        }
      },
      deleteMap(){
        this.$refs['delete-map-modal'].$refs['deleteMapModal'].open()
      },
      addNodeToTreeMap(value, event){
        if(this.addChildTreeMap) return
        this.setNodeSelected(value)
        if(this.child_node) this.nodeSample.parent_label = this.child_node.id
        this.undoDone = false
        this.submitChildNode(this.nodeSample)
        this.addChildTreeMap = true

      },
      resetMindmap() {
        http
          .get(`/msuite/${this.currentMindMap.unique_key}/reset_mindmap.json`)
          .then((res) => {
            this.currentMindMap.nodes = []
            this.undoNodes = []
            this.redoNodes = []
          })
          .catch((err) => {
            console.log(err)
          })
      },
      undoObj(){
        this.undoDone = true
        http
          .post(`/msuite/${this.currentMindMap.unique_key}/undo_mindmap.json`, { undoNode: this.undoNodes })
          .then((res) => {
            this.undoNodes.pop()
            let req = res.data.node.req
            let node = res.data.node.node
            this.redoNodes.push({req, node})
          })
          .catch((err) => {
            console.log(err)
          })
      },
      redoObj(){
        this.redoDone = true
        http
          .put(`/msuite/${this.currentMindMap.unique_key}/redo_mindmap.json`, { redoNode: this.redoNodes })
          .then((res) => {
            this.redoNodes.pop()
            let req = res.data.node.req
            let receivedData = res.data.node.node
            this.undoNodes.push({req, receivedData})
          })
          .catch((err) => {
            console.log(err)
          })
      }
    }
  }
</script>

<style>
  @import "./tree_map.scss";
</style>
<style scoped>
  .pallete{
    max-height: 15vh;
    background: linear-gradient(135deg, #eee, white);
    overflow: auto;
  }
  .color-pallete {
    text-align : center;
    padding : 0.6em;
    border : 0.01em solid black;
    width  : 1em;
    height : 1em;
    border-radius: 100%;
  }
</style>
