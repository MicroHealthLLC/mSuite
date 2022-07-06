<template>
  <div>
    <navigation-bar
      @openPrivacy="openPrivacy"
      :current-mind-map="currentMindMap"
      @resetZoomScale="resetZoomScale"
      @deleteMindmap="deleteMSuite"
      @zoomInScale="zoomInScale"
      :scaleFactor="scaleFactor"
      :exportId="'treeChartObj'"
      :defaultDeleteDays="defaultDeleteDays"
      :expDays="expDays"
      :deleteAfter="deleteAfter"
      @resetMindmap="resetMindmap"
      @zoomOutScale="zoomOutScale">
    </navigation-bar>
    <!-- tree chart -->
    <section id="treeChartObj" class="main_body font-serif">
      <vue-tree
        style="width: 100%; height: 100%; min-height: 900px; min-width: 900px;"
        :dataset="treeChartObj"
        :config="treeConfig"
        linkStyle="straight"
        ref="refTree"
        class="parentTree"
      >
        <template v-slot:node="{ node }">
          <div class="rich-media-node mx-1 px-2 pt-2 w-100" :id="'treeChart' + node.id" :style="[node.color ? {'backgroundColor': node.color} : {'backgroundColor': currentMindMap.line_color}]" @drop="dragDrop(node.id)" ondragover="event.preventDefault();" draggable="true" @dragstart="dragStart(node.id)">
            <div>
              <span @click="deleteMap(node)">
                <i class="fas fa-times float-right icon-opacity text-danger" :title="currentMindMap.name == node.name ? 'Delete Map' : 'Delete Node'"></i>
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
        <div class="card card-position p-0 border-none z-index mt-5">
          <div class="card-body p-0">
            <sketch-picker v-model="treeNode.line_color" :preset-colors="uniqueColors" @input="updateColorNode()"/>
          </div>
          <div class="card-button d-flex">
            <button class="btn btn-success w-50 border-none" @click="saveNodeColor">Update</button>
            <button class="btn btn-info w-50 border-none" @click="closeModelPicker">Cancel</button>
          </div>
        </div>
      </div>
    </section>
    <!-- tree chart end -->

    <!-- import modals here -->
    <delete-map-modal ref="delete-map-modal" @delete-mindmap="confirmDeleteMindmap"></delete-map-modal>

    <make-private-modal ref="make-private-modal" @password-apply="passwordProtect"  @password_mismatched="$refs['passwordMismatched'].open()" :password="currentMindMap.password" :isSaveMSuite="isSaveMSuite"></make-private-modal>

    <sweet-modal ref="deleteNodeConfirm" class="of_v" icon="warning" title="Delete node">
      Do you want to delete this node?
      <button slot="button" @click="deleteSelectedNode(deleteNodeObj)" class="btn btn-warning mr-2">Delete</button>
      <button slot="button" @click="$refs['deleteNodeConfirm'].close()" class="btn btn-secondary">Cancel</button>
    </sweet-modal>

    <sweet-modal ref="passwordMismatched" class="of_v" icon="error" title="Password Mismatch">
      Your Password and Confirm Password are Mismatched, Please Try Again!
      <button slot="button" @click="passwordAgain" class="btn btn-warning mr-2">Try Again</button>
      <button slot="button" @click="$refs['passwordMismatched'].close()" class="btn btn-secondary">Cancel</button>
    </sweet-modal>

    <sweet-modal ref="errorNodeModal" class="of_v" icon="error" title="Node Title Error">
      Nodes Title Cannot Be Empty
    </sweet-modal>

    <sweet-modal ref="successModal" class="of_v" icon="success">
      Password updated successfully!
    </sweet-modal>

    <sweet-modal ref="errorModal" class="of_v" icon="error" title="Password Error">
      Incorrect Password, Please Try Again!
    </sweet-modal>

    <delete-password-modal ref="delete-password-modal" @deletePasswordCheck="deleteMindmapProtected">
    </delete-password-modal>

    <section v-if="exportLoading" class="export-loading-tab">
      <div class="loader-wrap">
        <sync-loader :loading="exportLoading" color="#FFF" size="15px"></sync-loader>
      </div>
    </section>
  </div>
</template>
<script type="text/javascript">
  // Import the components that will be used
  import Jimp from 'jimp'
  import { jsPDF } from "jspdf";
  import html2canvas from "html2canvas"
  import http from '../../common/http'
  import DeleteMapModal from '../../common/modals/delete_modal'
  import MakePrivateModal from "../../common/modals/make_private_modal"
  import DeletePasswordModal from '../../common/modals/delete_password_modal'
  import domtoimage from "dom-to-image-more"
  import Common from "../../mixins/common.js"

  Vue.config.warnHandler = function(msg, vm, info) {}
  export default {
    name: 'TreeChart',
    data(){
      return{
        dragElement: null,
        mapColors: [],
        uniqueColors: [],
        colorSelected: false,
        exportLoading: false,
        scaleFactor: 1,
        deleteNodeObj: null,
        collapsed: false,
        prevNode: null,
        selectedNode: {id: null},
        selectedNodeTitle: '',
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
          mindmap_id: this.currentMindMap.id,
          parent: null,
          parent_node: null,
          title: "Enter title here"
        },
        treeNode: null,
        treeConfig: { nodeWidth: 180, nodeHeight: 80, levelHeight: 200 },
        nodeChildTreeMaps: [],
        nodes: [],
        addNodeTree: false,
        isSaveMSuite: false
      }
    },
    mixins: [Common],
    props:['currentMindMap','defaultDeleteDays', 'deleteAfter','expDays'],
    mounted: async function(){
      this.$cable.subscribe({
        channel: "WebNotificationsChannel",
        room: this.currentMindMap.id,
      });
      this.mountMap()
      // this.fetchTreeChart()
    },
    components: {
      DeleteMapModal,
      MakePrivateModal,
      DeletePasswordModal
    },
    methods: {
      dragStart(nodeId){
        this.dragElement = this.nodes.find((node) => node.id == nodeId)
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
        if (this.scaleFactor < 1.50) {
          this.scaleFactor = this.scaleFactor + 0.05
        }
        this.$refs.refTree.zoomIn()
      },
      zoomOutScale(){
        if (this.scaleFactor > 0.50) {
          this.scaleFactor = this.scaleFactor - 0.05
        }
        this.$refs.refTree.zoomOut()
      },
      resetZoomScale(){
        this.scaleFactor = 1
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
        else element.style.backgroundColor = this.currentMindMap.line_color
        this.colorSelected = false
        this.getColorNode('.rich-media-node')
      },
      saveNodeColor(){
        this.node.mindmap_id = this.currentMindMap.id
        if(this.selectedNodeTitle == this.currentMindMap.name)
        {
          this.currentMindMap.line_color = this.treeNode.line_color
          this.updatedTreeChart(this.currentMindMap)
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
        this.node.mindmap_id = this.currentMindMap.id
        var objNode = {title: ''}
        objNode.title = this.selectedNode.name.split('\n').join('')
        if(this.currentMindMap.name == this.selectedNodeTitle)
        {
          this.currentMindMap.name = this.selectedNode.name.split('\n').join('')
          if(this.currentMindMap.name) {
            this.updatedTreeChart(this.currentMindMap)
          }else if(this.currentMindMap.name.replace(/\s/g, '') == '') {
            this.selectedNode.name = this.selectedNodeTitle
            this.$refs['errorNodeModal'].open()
            // this.updatedTreeChart(this.currentMindMap)
          }
        }
        else if(this.addNodeTree) {
          if(objNode.title) {
            objNode.parent_node = this.nodeTemp.parent_node
            objNode.mindmap_id = this.currentMindMap.id
            objNode.line_color = '#EBECF0'
            this.submitChildNode(objNode)
          }else if(objNode.title.replace(/\s/g, '') == '') {
            this.selectedNode.name = this.selectedNodeTitle
            this.$refs['errorNodeModal'].open()
          }
        } else {
          if(this.selectedNode && this.selectedNode.id === undefined){
            this.updatedTreeChart(this.currentMindMap)
          } else {
            objNode.id = this.selectedNode.id
            if(objNode.title) {
              this.updateTreeChartNode(objNode)
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
        if(nodeElement.name == this.currentMindMap.name) this.nodeTemp.parent_node = null
        else this.nodeTemp.parent_node = nodeElement.id
        this.nodes.push(this.nodeTemp)
        this.renderTreeChart()
        this.addNodeTree = true
      },
      mountMap(){
        this.selectedNode = {id: ''}
        this.treeChartObj.name = this.currentMindMap.name
        this.nodes = this.currentMindMap.nodes
        this.addNodeTree = false
        this.getColorNode('.rich-media-node')
        this.mapColors = []
        this.uniqueColors = []
        this.mapColors.push(this.currentMindMap.line_color);
        Object.values(this.nodes).forEach(node => {
          this.mapColors.push(node.line_color);
        });
        this.uniqueColors = this.getUniqueColors(this.mapColors);
        this.renderTreeChart()
      },
      async fetchTreeChart(){
        let mindmap_key = window.location.pathname.split('/')[2]
        let response = await http.get(`/msuite/${mindmap_key}.json`)
        this.selectedNode = {id: ''}
        this.expDays = response.data.expDays
        this.defaultDeleteDays = response.data.defaultDeleteDays
        this.deleteAfter= response.data.deleteAfter
        this.currentMindMap = response.data.mindmap
        this.treeChartObj.name = response.data.mindmap.name
        this.nodes = response.data.mindmap.nodes
        this.addNodeTree = false
        this.getColorNode('.rich-media-node')
        this.mapColors = []
        this.uniqueColors = []
        this.mapColors.push(this.currentMindMap.line_color);
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
              let obj = { name: node.title, id: node.id , color: node.line_color, children: []}
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
        let data = { node }
        http.post(`/nodes.json`, data).then((res) => {
          _this.addNodeTree = false
        }).catch(err => {
          alert(err.message)
        })
      },
      async updateTreeChartNode(obj){
        await http.put(`/nodes/${obj.id}`, obj);
      },
      async deleteSelectedNode(obj){
        await http.delete(`/nodes/${obj.id}.json`);
        this.$refs['deleteNodeConfirm'].close()
      },
      async updatedTreeChart(obj){
        await http.put(`/msuite/${obj.unique_key}`, obj);
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
            this.expDays = res.data.expDays
            this.defaultDeleteDays = res.data.defaultDeleteDays
            this.deleteAfter= res.data.deleteAfter
            this.currentMindMap.password = res.data.mindmap.password
            this.$refs['successModal'].open()
            if(!is_mSuite) window.open("/", "_self")
            else location.reload()
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
          this.deleteTreeChart()
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
      deleteMSuite(){
        this.$refs['delete-map-modal'].$refs['deleteMapModal'].open()
      },
      deleteMap(node){
        if(this.addNodeTree && node.name == "Enter title here"){
          this.nodes.pop()
          this.renderTreeChart()
          this.addNodeTree = false
        }else{
          if(this.currentMindMap.name == node.name) this.$refs['delete-map-modal'].$refs['deleteMapModal'].open()
          else
          {
            this.deleteNodeObj = node
            this.$refs['deleteNodeConfirm'].open()
          }
        }
        this.getColorNode('.rich-media-node')
        this.$refs.refTree.collapseEnabled = false
      },
      deleteTreeChart(){
        http
        .delete(`/msuite/${this.currentMindMap.unique_key}`)
        .then(res => {
          window.open("/", "_self")
        })
        .catch(error => {
          console.log(error)
        })
      },
      resetMindmap() {
        http
          .get(`/msuite/${this.currentMindMap.unique_key}/reset_mindmap.json`)
          .then((res) => {
            this.currentMindMap = res.data.mindmap
            this.selectedNode = { id: ''}
            this.currentMindMap.nodes = []     
          })
          .catch((err) => {
            console.log(err)
          })
      },
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
          else if(data.message === "Password Updated" && this.currentMindMap.id === data.mindmap.id)
          {
            setTimeout(()=>{
              location.reload()
            }, 1000)
          }
          else if (data.message === "Reset mindmap" && this.currentMindMap.id === data.mindmap.id) {
            this.currentMindMap = data.mindmap
            this.currentMindMap.nodes = []
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
  }
</script>
<style type="text/css" lang="scss">
  @import "./style/tree_chart.scss";
</style>
