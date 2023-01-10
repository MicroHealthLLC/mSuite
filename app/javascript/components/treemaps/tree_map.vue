<template>
  <div>
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
            :selected-node="selectedNodeColor"
            :nodes="nodes"
            :customPallete="customPallete"
            :uniqueColors="uniqueColors"
            @updateColorNode="updateColorNode"
            @saveNodeColor="saveNodeColor"
            @closeModelPicker="closeModelPicker"
            @updateTreeChartNode="updateSelectedNode"
          ></color-palette>
        </div>
      </div>
    </div>

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
  import http from '../../common/http'
  import JqxTreeMap from 'jqwidgets-scripts/jqwidgets-vue/vue_jqxtreemap.vue';
  import ColorPalette from '../../common/modals/color_palette_modal'
  import Common from "../../mixins/common.js"
  import TemporaryUser from "../../mixins/temporary_user.js"
  import History from "../../mixins/history.js"

  export default {
    components: {
    // Adding imported widgets here
      JqxTreeMap,
      ColorPalette,
    },
    props: {
      undoMap: Function,
      redoMap: Function
    },
    mixins: [Common, TemporaryUser, History],
    data: function () {
      // Define properties which will use in the widget
      return {
        currentMindMap: this.$store.getters.getMsuite,
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
              else if(event.target.tagName === 'DIV')
              {
                if(this.oldEventElement) this.oldEventElement.target.style.backgroundColor = ""
              }
            })
          }
        }
      }
    },
    mounted: async function () {
      this.subscribeCable(this.currentMindMap.id)
      this.$store.dispatch('setExportId', 'treeMapGraph')
      this.sendLocals(false)
      this.mountMap()
      this.getUserOnMount()
      this.undoMap(this.undoObj)
      this.redoMap(this.redoObj)
    },
    channels: {
      WebNotificationsChannel: {
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
          else if (data.message === "Mindmap Updated" && this.currentMindMap.id === data.mindmap.id) {
            
          }
          else if(data.message === "storage updated" && this.currentMindMap.id == data.content.mindmap_id)
          {
            this.$store.dispatch('setUserEdit'     , data.content.userEdit)
            this.$store.dispatch('setNodeNumber' , data.content.nodeNumber)
            this.$store.dispatch('setTemporaryUser', data.content.userEdit)
            this.$store.dispatch('setUserList'     , data.content.userEdit)
          }
          else if (data.message === "Reset mindmap" && this.currentMindMap.id === data.mindmap.id) {
            this.$store.commit('setMSuite', data.mindmap)
            this.currentMindMap = data.mindmap
            this.undoNodes = []
            this.redoNodes = []
            this.getTreeMap()
          } 
          else if (data.message === "Node is deleted" && this.currentMindMap.id === data.node.mindmap_id) {
            this.spliceNodes(data.node.id)
            this.buildMap()
          }
          else {
            this.getTreeMap()
          }

        },
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
        event.addEventListener('dragstart' , this.dragStart)
        event.addEventListener('drop'      , this.dropNode )
        event.addEventListener('dragover'  , this.allowdrop)
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
        nodeElement.appendChild(textnodeElement)
        nodeElement.setAttribute('class', class_list)
        nodeElement.title = title
        return nodeElement
      },
      updateTreeMaps: async function (obj) {
        let data = {}

        if (obj == undefined){
          data = {
            canvas: this.$store.state.userEdit
          }
        } else {
          data = {
            name: obj.name,
            mm_type: 'tree_map',
            line_color: obj.line_color,
            canvas: this.$store.state.userEdit
          }
        }

        await this.$store.dispatch('updateMSuite', data)
        // await http.put(`/msuite/${this.currentMindMap.unique_key}`, data);
        this.parent_node = null
        this.hiddenNode = false
        this.addChildTreeMap = false
        this.colorSelected = false
      },
      updateSelectedNode: async function(obj){
        if(this.undoNodes.length > 0) {
          this.undoNodes.forEach((element, index) => {
            if(element['node'].id === obj.id) {
              this.undoNodes[index]['node'].title = obj.title
              this.undoNodes[index]['node'].line_color = obj.line_color
            }
          });
        } else {
          this.undoNodes.push({'req': 'addNode', node: obj})
        }
        this.updateTreeMaps()
        await http.put(`/nodes/${obj.id}`, obj).then((res) => {
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
            this.undoNodes.push({'req': 'deleteNode', 'node' : receivedNodes})
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
        this.updateTreeMaps()
      },
      submitChildNode: async function (obj) {

        let _this = this
        if(this.nodes.length > 0 && this.$store.state.nodeNumber != 'NaN'){
          this.$store.dispatch('setNodeNumber', parseInt(this.$store.state.nodeNumber) + 1)
        } else {
          this.$store.dispatch('setNodeNumber', this.nodeNumber + 1)
        }
        let parent = (obj.parent_label != '') ? obj.parent_label : 0
        this.sendLocals(false)
        let data = {
          node: {
            title: obj.label + ' ' + _this.$store.state.nodeNumber,
            line_color: obj.color,
            node_width: 50,//obj.node_width,
            parent_node: parent,
            mindmap_id: _this.currentMindMap.id,
          }
        }
        await http.post(`/nodes.json`, data).then((res) => {
          _this.submitChild = false
          _this.addChildTreeMap = false
          _this.hiddenNode = false
          _this.child_node = null
          _this.nodeSample.parent_label = ''
          if( res.data.node.id == null ){
            obj.label = obj.label + ' 0'
            obj.parent_label = parent
            this.submitChildNode(obj)
          }
          if (!this.undoDone) {
            let receivedData = res.data.node
            _this.undoNodes.push({'req': 'addNode', 'node': receivedData})
          }
          // success modal display
        }).catch(err => {
          _this.err = err.message
          _this.$refs['errorAddNode'].open()
          // error modal display
        })
        this.updateTreeMaps()

      },
      mountMap: async function() {
        this.parent_nodes.label = this.currentMindMap.name
        this.parent_nodes.color = this.currentMindMap.line_color
        this.nodes = this.currentMindMap.nodes
        this.sendLocals(false)
        this.setUserOnMount()
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
        let res = await this.$store.dispatch('getMSuite')
        let response = await this.$store.getters.getMsuite
        this.$store.dispatch('setMindMapId', response.id)
        this.parent_nodes.label = response.name
        this.currentMindMap.id = response.id
        this.currentMindMap.name = response.name
        this.currentMindMap.title = response.title
        this.defaultDeleteDays = response.defaultDeleteDays
        this.deleteAfter = response.deleteAfter
        this.expDays = response.expDays
        this.currentMindMap.line_color = response.line_color
        this.parent_nodes.color = this.currentMindMap.line_color
        this.nodes = response.nodes
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
        if(this.oldEventElement) this.oldEventElement.target.style.backgroundColor = ""
        let _this = this
        _this.hiddenNode = true
        if(value.label == 'Enter Node Title Here') return this.saveNodeElement(eventElement,value);
        var keyUpTimeOut
        var oldTitle = _this.node.label
        eventElement.target.contentEditable = true
        eventElement.target.focus();
        eventElement.target.style.backgroundColor = "white"
        eventElement.target.style.color = "black"
        _this.colorSelected = false
        _this.oldEventElement = eventElement
        eventElement.target.addEventListener('blur', function(){
          if(_this.oldEventElement) _this.oldEventElement.target.style.backgroundColor = ""
        })
        eventElement.target.addEventListener('keyup', function(){
          clearTimeout(keyUpTimeOut)
          var newTitle = event.target.innerText.split('\n').join('')
          if (event.keyCode === 13) {
            if (newTitle) {
              _this.node_title = newTitle
              _this.sendLocals(true)
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
              _this.sendLocals(true)
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
        this.sendLocals(true)
      },
      closeModelPicker(){
        this.currentElementObj[0].style.backgroundColor = this.oldElementColor
        this.colorSelected = false
        this.getColorNode('.jqx-treemap-rectangle')
      },
      colorChange(value, elementObject){
        if(this.addChildTreeMap) return
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
        if(this.addChildTreeMap){
          this.treemap_data.splice(-1, 1)
          this.addChildTreeMap = false
          return this.$refs.myTreeMap.source = this.treemap_data
        }
        this.setNodeSelected(value)
        if (this.parent_node) this.$emit("deleteMindMap")
        else {
          this.child_node.mindmap_id = this.currentMindMap.id
          this.undoDone = false
          this.deleteSelectedNode(this.child_node)
        }
      },
      spliceNodes(id){
        const index = this.nodes.indexOf(this.nodes.find(x => x.id === id))
        if (index > -1) { 
          this.nodes.splice(index, 1); 
        }
      },
      addNodeToTreeMap(value, event){
        if(this.addChildTreeMap) return
        this.setNodeSelected(value)
        if(this.child_node) this.nodeSample.parent_label = this.child_node.id
        this.undoDone = false
        let paleteColor = ['#bcd4de','#b1d0d8','#a5ccd1','#c6dde0','#e7edee','#d4dcde','#c0cbce','#98a8ae','#abb5ba','#bec1c5']
        this.nodeSample.color = paleteColor[this.nodes.length]
        this.submitChildNode(this.nodeSample)
        this.addChildTreeMap = true
      },
      async undoObj(){
        this.undoDone = true
        let undoObj = await this.undoNode(this.undoNodes)
        if(undoObj){
          this.undoNodes.pop()
          this.redoNodes.push({req: undoObj.req, node: undoObj.node})
        }
      },
      async redoObj(){
        let redoObj = await this.redoNode(this.redoNodes)
        if(redoObj){
          this.redoNodes.pop()
          this.undoNodes.push({req: redoObj.req, node: redoObj.node})
        }
      },
    }
  }
</script>

<style  lang="scss">
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
