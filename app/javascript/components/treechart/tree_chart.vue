<template>
  <div>
    <!-- tree chart -->
    <div id="treeChartObj" class="main_body font-serif w-100" :class="mm_type == 'flowmap' ? 'd-flex align-items-center' : ''">
      <vue-tree
        style="width: 100%; height: 100%; min-height: 900px; min-width: 900px;"
        :dataset="treeChartObj"
        :config="treeConfig"
        :direction="isTreeChart"
        linkStyle="straight"
        ref="refTree"
        class="flowmap-center-vertical overflow-hidden"
      >
        <template v-slot:node="{ node }">
          <div class="rich-media-node mx-1 px-2 pt-2 w-100" :id="'treeChart' + node.id" :style="[node.color ? {'backgroundColor': node.color} : {'backgroundColor': $store.getters.getMsuite.line_color}]" @drop="dragDrop(node.id)" ondragover="event.preventDefault();" draggable="true" @dragstart="dragStart(node.id)">
            <div>
              <span @click="deleteMap(node)">
                <i class="fas ml-2 fa-times float-right icon-opacity text-danger" :title="$store.getters.getMsuite.name == node.name ? 'Delete Map' : 'Delete Node'"></i>
              </span>
              <span @click="node.name != 'Enter title here' ? addNode(node) : ''">
                <i class="fas fa-plus float-right icon-opacity add-icon" title="Add Child Node"></i>
              </span>
              <span @click="node.name != 'Enter title here' ? showColorPicker(node) : ''">
                <i class="fas fa-eye-dropper color-picker float-right icon-opacity text-dark" title="Color Picker"></i>
              </span>
              <div  v-if="node.id !== undefined">
                <i class="fas fa-arrows-alt position-relative icon-opacity text-dark float-left" title="Drag Node"></i>
              </div>
            </div>
            <span class="my-2 text-left text-break" v-if="selectedNode.id != node.id" @click="showInputField(node)">
              {{ node.name }}
            </span>
            <span v-else-if="selectedNode.id == node.id">
              <textarea-autosize type="text" v-model="selectedNode.name"  v-debounce:3000ms="blurEvent" @blur.native="saveNodeTreeChart" :rows="1" class="w-100 rounded my-2" placeholder="Enter title here" :id="'textArea' + node.id"/>
            </span>
            <span class="w-100 position-arrow text-center" @click="collapseNode(node)" :id="'collapsed'+node.id">
              <i class="fas fa-caret-square-down"></i>
            </span>
          </div>
        </template>
      </vue-tree>
      <div v-if="colorSelected">
        <div class="card-position p-0 border-none z-index mt-5">
          <color-palette
            :selected-node="treeNode"
            :nodes="nodes"
            :customPallete="customPallete"
            :uniqueColors="uniqueColors"
            @updateColorNode="updateColorNode"
            @saveNodeColor="saveNodeColor"
            @closeModelPicker="closeModelPicker"
            @updateTreeChartNode="updateTreeChartNode"
          ></color-palette>
        </div>
      </div>
    </div>
    <!-- tree chart end -->

    <!-- import modals here -->
    <section v-if="exportLoading" class="export-loading-tab">
      <div class="loader-wrap">
        <sync-loader :loading="exportLoading" color="#FFF" size="15px"></sync-loader>
      </div>
    </section>
  </div>
</template>
<script type="text/javascript">
  // Import the components that will be used
  import http from '../../common/http'
  import ColorPalette from '../../common/modals/color_palette_modal'
  import Common from "../../mixins/common.js"
  import TemporaryUser from "../../mixins/temporary_user.js"
  import History from "../../mixins/history.js"

  Vue.config.warnHandler = function(msg, vm, info) {}
  export default {
    name: 'TreeChart',
    props: {
      undoMap: Function,
      redoMap: Function,
      zmInScale: Function,
      zmOutScale: Function,
      resetZmScale: Function
    },
    data(){
      return{
        mm_type: this.$store.getters.getmmType,
        dragElement: null,
        mapColors: [],
        uniqueColors: [],
        colorSelected: false,
        exportLoading: false,
        scaleFactor: this.$store.getters.getScaleFactor,
        deleteNodeObj: null,
        collapsed: false,
        prevNode: null,
        selectedNode: {id: null},
        selectedNodeTitle: '',
        customPallete: [],
        nodeColor: { hex: '' },
        treeChartObj: {
          name: '',
          children: []
        },
        node: {
          title: 'Enter title here',
          parent_node: '',
          mindmap_id: '',
          line_color: '#EBECF0'
        },
        nodeTemp: {
          id: 0,
          line_color: "##EBECF0",
          mindmap_id: this.$store.getters.getMindmapId,
          parent: null,
          parent_node: null,
          title: "Enter title here"
        },
        treeNode: null,
        treeConfig: { nodeWidth: 180, nodeHeight: 80, levelHeight: 200 },
        nodeChildTreeMaps: [],
        nodes: [],
        undoNodes: [],
        redoNodes: [],
        addNodeTree: false,
        isSaveMSuite: false,
        palleteUpdate: false,
        nodeNumber: 0,
        undoDone: false,
        temporaryUser: '',
      }
    },
    mixins: [Common, TemporaryUser, History],
    mounted: async function(){
      this.subscribeCable(this.$store.getters.getMsuite.id)
      this.$store.dispatch('setExportId', 'treeChartObj')
      this.sendLocals(false)
      this.mountMap()
      this.getUserOnMount()
      this.undoMap(this.undoObj)
      this.redoMap(this.redoObj)
      this.zmInScale(this.zoomInScale)
      this.zmOutScale(this.zoomOutScale)
      this.resetZmScale(this.resetZoomScale)
      window.addEventListener('wheel', this.transformScale)
    },
    components: {
      ColorPalette
    },
    methods: {
      dragStart(nodeId){
        this.dragElement = this.nodes.find((node) => node.id == nodeId)
        this.sendLocals(true)
      },
      dragDrop(nodeId){
        let dropElement = this.nodes.find((node) => node.id == nodeId)
        if(nodeId && nodeId != this.dragElement.id && this.dragElement.id != dropElement.parent_node)
        { 
          this.dragElement.parent_node = nodeId
          this.updateTreeChartNode(this.dragElement)
        }
        else if(nodeId === undefined)
        {
          this.dragElement.parent_node = null
          this.updateTreeChartNode(this.dragElement)
        }
      },
      zoomInScale(){
        if (this.$store.getters.getScaleFactor < 1.50) {
          this.$store.dispatch('setScaleFactor', this.$store.getters.getScaleFactor + 0.05)
        }
        this.$refs.refTree.zoomIn()
      },
      zoomOutScale(){
        if (this.$store.getters.getScaleFactor > 0.50) {
          this.$store.dispatch('setScaleFactor', this.$store.getters.getScaleFactor - 0.05)
        }
        this.$refs.refTree.zoomOut()
      },
      transformScale(event) {
        if (event.deltaY < 0) {
          this.zoomInScale()
        }
        else if (event.deltaY > 0) {
          this.zoomOutScale()
        }
      },
      resetZoomScale() {
        this.$refs.refTree.restoreScale()
      },
      showColorPicker(nodeObj){
        this.addNodeTree = false
        this.selectedNodeTitle = JSON.parse(JSON.stringify(nodeObj.name))
        this.treeNode = Object.assign({}, nodeObj)
        this.$refs.refTree.collapseEnabled = false
        this.nodeColor.hex = nodeObj.color
        this.treeNode.line_color = this.nodeColor
        this.colorSelected = true
        setTimeout(()=>{
          $('.vc-sketch-presets')[0].style.maxHeight = '10vh'
        },10)
      },
      updateColorNode(){
        let element = document.getElementById('treeChart'+this.treeNode.id)
        element.style.backgroundColor = this.treeNode.line_color.hex
        this.treeNode.line_color = this.treeNode.line_color.hex
        this.getColorNode('.rich-media-node')
      },
      closeModelPicker(){
        let element = document.getElementById('treeChart'+this.treeNode.id)
        if(this.nodeColor.hex) element.style.backgroundColor = this.nodeColor.hex
        else element.style.backgroundColor = this.$store.getters.getMsuite.line_color
        this.colorSelected = false
        this.getColorNode('.rich-media-node')
      },
      saveNodeColor(){
        this.node.mindmap_id = this.$store.getters.getMsuite.id
          if(this.selectedNodeTitle == this.$store.getters.getMsuite.name)
          {
            this.$store.getters.getMsuite.line_color = this.treeNode.line_color
            this.updatedTreeChart(this.$store.getters.getMsuite)
          }
          else
          {
            var objNode = {id: '', line_color: ''}
            objNode.id = this.treeNode.id
            objNode.line_color = this.treeNode.line_color
            this.updateTreeChartNode(objNode)
          }
        this.colorSelected = false
      },
      blurEvent(val, e){
        if (e.target) e.target.blur()
      },
      saveNodeTreeChart(){
        this.$refs.refTree.collapseEnabled = false
        this.node.mindmap_id = this.$store.getters.getMsuite.id
        var objNode = {title: ''}
        objNode.title = this.selectedNode.name.split('\n').join('')
        if(this.$store.getters.getMsuite.name == this.selectedNodeTitle){
          this.$store.getters.getMsuite.name = this.selectedNode.name.split('\n').join('')
          if(this.$store.getters.getMsuite.name) {
            if(this.$store.getters.getMsuite.name != this.selectedNodeTitle){
              this.updatedTreeChart(this.$store.getters.getMsuite)
            }
            else{
              this.fetchTreeChart()
            }
          }else if(this.$store.getters.getMsuite.name.replace(/\s/g, '') == '') {
            this.selectedNode.name = this.selectedNodeTitle
            this.$refs['errorNodeModal'].open()
          }
        }
        else if(this.addNodeTree) {
          if(objNode.title) {
            let paleteColor = ['#bcd4de','#b1d0d8','#a5ccd1','#c6dde0','#e7edee','#d4dcde','#c0cbce','#98a8ae','#abb5ba','#bec1c5']
            objNode.parent_node = this.nodeTemp.parent_node
            objNode.mindmap_id = this.$store.getters.getMsuite.id
            objNode.line_color = paleteColor[this.nodes.length]
            this.undoDone = false
            this.submitChildNode(objNode)
          }else if(objNode.title.replace(/\s/g, '') == '') {
            this.selectedNode.name = this.selectedNodeTitle
            this.$refs['errorNodeModal'].open()
          }
        } else {
          if(this.selectedNode && this.selectedNode.id === undefined){
            this.updatedTreeChart(this.$store.getters.getMsuite)
          } else {
            objNode.id = this.selectedNode.id
            if(objNode.title) {
              if (this.selectedNode.name != this.selectedNodeTitle){
                this.updateTreeChartNode(objNode)
              }
              else{
                this.fetchTreeChart()
              } 
            }else if(objNode.title.replace(/\s/g, '') == '') {
              this.selectedNode.name = this.selectedNodeTitle
              this.$refs['errorNodeModal'].open()
          }}
        }
      },
      showInputField(node){
        let _this = this
        this.addNodeTree = false
        this.$refs.refTree.collapseEnabled = false
        this.selectedNode = node
        this.selectedNodeTitle = JSON.parse(JSON.stringify(node.name))
        setTimeout(() => {
          document.getElementById('textArea'+ _this.selectedNode.id).focus()
        }, 300)
      },
      collapseNode(node){
        this.getColorNode('.rich-media-node')
        this.collapsed = !this.collapsed
        if(this.collapsed) this.insertNodeElement('fas fa-caret-square-up', node.id)
        else this.insertNodeElement('fas fa-caret-square-down', node.id)
        this.$refs.refTree.collapseEnabled = true
      },
      insertNodeElement(class_list, nodeId) {
        var nodeElement = document.createElement("i");
        var textnodeElement = document.createTextNode("")
        nodeElement.appendChild(textnodeElement);
        nodeElement.setAttribute('class', class_list)
        var element = document.getElementById('collapsed'+nodeId)
        element.replaceChild(nodeElement, element.childNodes[0]);
      },
      addNode(nodeElement){
        this.$refs.refTree.collapseEnabled = false
        this.selectedNodeTitle = ''
        if(!this.addNodeTree) this.reRenderTree(nodeElement)
        this.getColorNode('.rich-media-node')
      },
      reRenderTree(nodeElement){
        this.nodeTemp.parent = nodeElement.name
        if(nodeElement.name == this.$store.getters.getMsuite.name) this.nodeTemp.parent_node = null
        else this.nodeTemp.parent_node = nodeElement.id
        this.nodes.push(this.nodeTemp)
        this.addNodeTree = true
        this.$store.dispatch('setMindMapId', this.$store.getters.getMsuite.id)

        if(this.nodes.length > 1 && this.$store.state.nodeNumber != 'NaN'){
          this.$store.dispatch('setNodeNumber', parseInt(this.$store.state.nodeNumber) + 1)
        } else {
          this.$store.dispatch('setNodeNumber', this.nodeNumber + 1)
        }
        this.selectedNode.name = 'Enter Node Title for node ' + this.$store.state.nodeNumber
        this.sendLocals(false)
        this.saveNodeTreeChart()
        this.renderTreeChart()
      },
      mountMap(){
        this.selectedNode = {id: ''}
        this.treeChartObj.name = this.$store.getters.getMsuite.name
        this.nodes = this.$store.getters.getMsuite.nodes
        this.setUserOnMount()
        this.addNodeTree = false
        this.getColorNode('.rich-media-node')
        this.mapColors = []
        this.uniqueColors = []
        this.mapColors.push(this.$store.getters.getMsuite.line_color);
        Object.values(this.nodes).forEach(node => {
          this.mapColors.push(node.line_color);
        });
        this.uniqueColors = this.getUniqueColors(this.mapColors);
        this.renderTreeChart()
      },
      async fetchTreeChart(){
        let res = await this.$store.dispatch('getMSuite')
        let response = this.$store.getters.getMsuite
        this.$store.dispatch('setMindMapId', response.id)

        this.selectedNode = {id: ''}
        // this.$store.commit('SET_MSUITE', response.data.mindmap)
        this.treeChartObj.name = response.name
        this.nodes = response.nodes
        this.addNodeTree = false
        this.getColorNode('.rich-media-node')
        this.mapColors = []
        this.uniqueColors = []
        this.mapColors.push(response.line_color);
        Object.values(this.nodes).forEach(node => {
          this.mapColors.push(node.line_color);
        });
        let object = {};
        this.mapColors.forEach(item => {
          if(!object[item])
            object[item] = 0;
            object[item] += 1;
        })
        for (let prop in object) {
          if(object[prop] != undefined) {
            this.uniqueColors.push(prop);
          }
        }
        this.renderTreeChart()
      },
      renderTreeChart(){
        let array_nodes = this.nodes.map((node, index) => {
          return {
            name: node.title,
            id: node.id,
            color: node.line_color
          };
        })
        let parent_nodes = []
        this.nodes.forEach((node) => {
          if(node.parent_node == null){
            parent_nodes.push(node)
          }
        })

        parent_nodes = parent_nodes.map((node, index) => {
          return {
            name: node.title,
            id: node.id,
            color: node.line_color,
            children: []
          }
        })
        this.getChildNode(parent_nodes)
        this.selectedNode = { id: ''}
      },
      getChildNode(parent_nodes){
        let childNodes = []
        this.nodes.forEach((node) => {
          parent_nodes.forEach((p, index)=> {
            if(p.id == node.parent_node){
              let obj = { name: node.title, id: node.id , color: node.line_color, children: [], parent_node: node.parent_node}
              parent_nodes[index].children.push(obj)
              childNodes = childNodes.concat(parent_nodes[index].children)
            }
          })
        })
        if(childNodes.length > 0){
          this.getChildNode(_.uniq(childNodes))
        }
        this.treeChartObj.children = parent_nodes
      },
      async submitChildNode(node){
        let _this = this
        let data = {}
        if(_this.undoDone){
          data = { node:{
            line_color: node.color,
            mindmap_id: node.mindmap_id,
            parent_node: node.parent_node,
            title: node.name
          }}
        } else {
          data = { node }
        }
        this.updatedTreeChart()
        http.post(`/nodes.json`, data).then((res) => {
          if (!this.undoDone) {
            let receivedData = res.data.node
            _this.undoNodes.push({'req': 'addNode', 'node':receivedData})
          }
          _this.addNodeTree = false
          if(res.data.node.id == null){
            node.title = node.title + '0'
            this.submitChildNode(node)
          }
        }).catch(err => {
          alert(err.message)
        })
      },
      async updateTreeChartNode(obj){
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
        this.updatedTreeChart()
        await http.put(`/nodes/${obj.id}`, obj);
        this.sendLocals(false)
      },
      async deleteSelectedNode(obj){
        this.updatedTreeChart()
        await http.delete(`/nodes/${obj.id}.json`).then((res) => {
          let receivedNodes = res.data.node
          if(receivedNodes && receivedNodes.length > 0){
            this.undoNodes.push({'req': 'deleteNode', 'node' : receivedNodes})
          }
          if (!this.undoDone) {
            let myNode = {
              id: obj.id,
              title: obj.name,
              line_color: obj.color,
              mindmap_id: obj.mindmap_id,
              parent_node: obj.parent_node
            }
            this.undoNodes.push({'req': 'deleteNode', node: myNode})
          }
        });
        this.sendLocals(false)
      },
      async updatedTreeChart(obj){
        this.colorSelected = false
        if(obj == undefined){
          obj = {
            canvas: this.$store.state.userEdit
          }
        } else obj.canvas = this.$store.state.userEdit

        this.$store.dispatch('updateMSuite', obj)
        this.sendLocals(false)
      },
      deleteMap(node){
        if(this.addNodeTree && node.name == "Enter title here"){
          this.nodes.pop()
          this.renderTreeChart()
          this.addNodeTree = false
        }else{
          if (this.$store.getters.getMsuite.name == node.name) this.$emit("deleteMindMap")
          else
          {
            node.mindmap_id = this.$store.getters.getMsuite.id
            this.undoDone = false
            this.deleteSelectedNode(node)
          }
        }
        this.getColorNode('.rich-media-node')
        this.$refs.refTree.collapseEnabled = false
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
    },
    channels: {
      WebNotificationsChannel: {
        connected() {},
        rejected() {},
        received(data) {
          if (data.message === "Mindmap Deleted" && this.$store.getters.getMsuite.id === data.mindmap.id)
          {
            window.open('/','_self')
          }
          else if(data.message === "Password Updated" && this.$store.getters.getMsuite.id === data.mindmap.id)
          {
            setTimeout(()=>{
              location.reload()
            }, 1000)
          }
          else if(data.message === "storage updated" && this.$store.getters.getMsuite.id == data.content.mindmap_id)
          {
            this.$store.dispatch('setUserEdit'     , data.content.userEdit)
            this.$store.dispatch('setNodeNumber' , data.content.nodeNumber)
            this.$store.dispatch('setTemporaryUser', data.content.userEdit)
            this.$store.dispatch('setUserList'     , data.content.userEdit)
          }
          else if (data.message === "Reset mindmap" && this.$store.getters.getMsuite.id === data.mindmap.id) {
            this.selectedNode = { id: ''}
            this.undoNodes = []
            this.redoNodes = []
            this.fetchTreeChart()
          }
          else
          {
            this.fetchTreeChart()
          }
        },
        disconnected() {}
      }
    },
    computed: {
      isTreeChart(){
        if(this.mm_type == 'flowmap') return 'horizontal'
      }
    }
  }
</script>
<style type="text/css" lang="scss">
  @import "./style/tree_chart.scss";
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
