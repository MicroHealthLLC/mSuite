<template>
  <div class="map-container">
    <div ref="slideSection" id="slideSection" @mousedown.stop="slideInit"  @touchstart.stop="slideInit" @touchmove.prevent="slideTheCanvas" @mousemove.prevent="slideTheCanvas" @mouseleave="isSlideDown = false" @mouseup="isSlideDown = false" @touchend="isSlideDown = false">
      <section v-if="!loading" id="map-container" class="font-serif" @mousemove.prevent="doDrag" @touchmove.prevent="doDrag" :style="C_scaleFactor">
        <div class="center" @click.stop.prevent="nullifySlider" :style="C_centeralNodePosition">
          <div class="row central_node_attachment text-secondary">
            <div class="col-12 px-0">
              <span class="central_notes_bar float-right">
                <span style="font-size: 14px;" @click.stop="openCentralAttachModal" data-tab="central-description-tab" class="mr-2" :class="C_hasDescription ? 'text-info' : ''"><i class="fa fa-comment"></i></span>
              </span>
            </div>
          </div>
          <span v-if="currentMindMap.editable" @mousedown.prevent.stop="startDrag" @touchstart.prevent.stop="startDrag" class="start_dot"></span>
          <textarea type="text" ref="central_idea" @input="updateCentralIdea" v-on:keyup.enter="saveCurrentMap" @blur="saveCurrentMap" v-model="centralIdea" class="shadow-lg central_idea" :style="C_centralIdeaStyle" :readOnly="!currentMindMap.editable" />
        </div>
        <input-field
          v-for="node in currentNodes"
          v-if="!node.is_disabled && !node.hide_self"
          v-model="node.title"
          :key="`${node.id}`"
          :style="getNodeStyle(node)"
          :is-selected="C_selectedNodeId === node.id"
          :is-edited="C_editNodeId === node.id"
          :quadrant="nodeQuadrant(node)"
          :has-child="hasChilNodes(node)"
          :hide-children="node.hide_children"
          :node-attr="node"
          :editable="currentMindMap.editable"
          :isEditing="isEditing"
          @sendLocals="sendLocals"
          @start-drag="startDrag($event, node)"
          @mousedown-event="startDragNode($event, node)"
          @node-updated="nodeUpdated(node)"
          @switch-expand-children="switchExpandChildren($event, node)"
          @edit-node="editNode($event, node)"
          @open-attachment="openAttachments($event)"
          class="pos_abs input_field">
        </input-field>
        <canvas id="map-canvas" class="has_bg" :width="windowWidth" :height="windowHeight" @click.stop="nullifyFlags"></canvas>
      </section>
    </div>

    <new-map-modal
      @open-new-map="openNewMap"
    ></new-map-modal>

    <open-map-modal
      @open-previous-map="openPreviousMap"
    ></open-map-modal>

    <attachment-modal
      ref="attachment-modal"
      :editor-option="editorOption"
      :editable="currentMindMap.editable"
      @nullify-attachment-modals="nullifyAttachmentModal"
      @update-node-description="updateNodeDescription"
    ></attachment-modal>

    <central-attachment-modal
      ref="central-attachment-modal"
      :editor-option="editorOption"
      :current-mind-map="currentMindMap"
      @nullify-attachment-modals="nullifyAttachmentModal"
      @update-map-notes="updateMapNotes"
    ></central-attachment-modal>

    <export-to-word-modal
      ref="export-to-word-modal"
      :current-mind-map="currentMindMap"
      :open-v-modal="openVModal"
      @nullify-attachment-modals="nullifyAttachmentModal"
    ></export-to-word-modal>



    <section v-if="exportLoading" class="export-loading-tab">
      <div class="loader-wrap">
        <sync-loader :loading="exportLoading" color="#FFF" size="15px"></sync-loader>
      </div>
    </section>
  </div>
</template>

<script>
  import _ from "lodash"
  import { jsPDF } from "jspdf";
  import html2canvas from "html2canvas"
  import Jimp from 'jimp'
  import domtoimage from "dom-to-image-more"
  import InputField from "./idea_input_field"
  import NewMapModal from "./modals/new_map_modal"
  import OpenMapModal from "./modals/open_map_modal"
  import AttachmentModal from "./modals/attachment_modal"
  import CentralAttachmentModal from "./modals/central_attachment_modal"
  import ExportToWordModal from "./modals/export_to_word_modal"
  import http from "../../common/http"
  import TemporaryUser from "../../mixins/temporary_user.js"

  export default {
    components: {
      InputField,
      NewMapModal,
      OpenMapModal,
      AttachmentModal,
      CentralAttachmentModal,
      ExportToWordModal,
    },

    mixins: [TemporaryUser],
    props: {
      zmInScale: Function,
      zmOutScale: Function,
      resetZmScale: Function,
      exportImg: Function,
      exportWord: Function,
      delSelectedNode: Function,
      cutSelNode: Function,
      copySelNode: Function,
      pasteNode: Function,
    },

    data() {
      return {
        currentMindMap    : this.$store.getters.getMsuite,
        userList          : [],
        currentNodes      : [],
        nodeParent        : null,
        nodeColor         : null,
        centralIdea       : '',
        loading           : true,
        dragging          : false,
        draggingNode      : false,
        currentPositionX  : 0,
        currentPositionY  : 0,
        nodeOffsetX       : 0,
        nodeOffsetY       : 0,
        parent_x          : 0,
        parent_y          : 0,
        mousePos          : null,

        // hardcoded fixed window size
        window_innerWidth : 1900,
        window_innerHeight: 900,
        windowWidth       : 1900 * 3,
        windowHeight      : 900 * 3,
        stopWatch         : false,
        nodeUpdatedFlag   : false,
        cutFlag           : false,
        scaleFactor       : 1,
        centralIdeaWidth  : '10em',
        centralIdeaHeight : '3em',
        isSlideDown       : false,
        slideStartX       : 0,
        slideScrollLeft   : 0,
        slideStartY       : 0,
        slideScrollTop    : 0,
        editingNode       : null,

        // attachment
        openVModal        : false,
        centralNotes      : "",
        descEditMode      : false,
        editorOption      : {
          modules : {
            toolbar : [
              ['bold', 'italic', 'underline', 'strike'],
              [{ 'size': ['small', false, 'large', 'huge'] }],
              ['blockquote', 'code-block'],
              ['link'],
              [{ 'header': 1 }, { 'header': 2 }],
              [{ 'list': 'ordered' }, { 'list': 'bullet' }],
              [{ 'color': [] }, { 'background': [] }]
            ],
            syntax : {
              highlight: text => hljs.highlightAuto(text).value
            }
          }
        },
        exportLoading: false
      }
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
            }, 500)
          }
          else if ( data.message === "storage updated" && this.currentMindMap.id == data.content.mindmap_id) {
            this.$store.dispatch('setUserEdit'     , data.content.userEdit)
            this.$store.dispatch('setTemporaryUser', data.content.userEdit)
            this.$store.dispatch('setUserList'     , data.content.userEdit)
          }
          else {
            this.getMindmap(this.currentMindMap.unique_key)
            if (data.node) this.$store.commit('setSelectedNode' , data.node)
          }
        }
      }
    },

    computed: {
      C_centeralNodePosition() {
        return {
          left: (Math.floor(this.windowWidth/2) - 120) +'px',
          top : (Math.floor(this.windowHeight/2) - 60) +'px'
        }
      },
      C_selectedNodeId() {
        return this.$store.getters.getSelectedNode ? this.$store.getters.getSelectedNode.id : 0
      },
      C_editNodeId() {
        return this.editingNode ? this.editingNode.id : 0
      },
      C_scaleFactor() {
        return {
          transform : "scale(" + this.$store.getters.getScaleFactor + ")",
          minWidth  : this.windowWidth+ "px",
          minHeight : this.windowHeight+ "px"
        }
      },
      C_centralIdeaStyle() {
        return {
          width    : this.centralIdeaWidth,
          height   : this.centralIdeaHeight,
          minHeight: "3em"
        }
      },
      C_hasDescription() {
        return !!this.currentMindMap.description
      }
    },

    methods: {
      mountMap() {
        this.stopWatch        = true
        this.centralIdea      = this.currentMindMap.name
        this.currentNodes     = this.currentMindMap.nodes
        this.setUserOnMount()
        setTimeout(() => { this.drawLines() }, 1000)
        this.loading = false
      },
      // =============== GETTING MAP =====================
      getMindmap: async function(id) {
        await this.$store.dispatch('getMSuite')
        let res = await this.$store.getters.getDataMsuite

        this.stopWatch      = true
        this.expDays = res.expDays
        this.defaultDeleteDays = res.defaultDeleteDays
        this.deleteAfter = res.deleteAfter

        this.currentMindMap = res.mindmap
        this.currentNodes   = res.mindmap.nodes

        setTimeout(this.drawLines, 100)
        this.updateQuery()
        this.loading = false
      },
      getNewMindmap() {
        http
          .post('/msuite.json', { mindmap: { name: "Central Idea" } })
          .then((res) => {
            this.expDays = this.expDays
            this.loading        = false
            this.$store.commit('setMSuite', res.data.mindmap)
            this.defaultDeleteDays = res.data.defaultDeleteDays
            this.deleteAfter = res.data.deleteAfter
            this.currentNodes   = res.data.mindmap.nodes
            this.updateQuery()
          }).catch((error) => {
            console.log(error)
            this.loading = false
          })
      },
      nullifySlider() {
        this.isSlideDown  = false
        this.$store.commit('setSelectedNode' , { id: ''})
      },
      editNode(event, node) {
        this.editingNode  = node
        this.$store.commit('setSelectedNode' , { id: ''})
        this.dragging     = false
        this.draggingNode = false
        this.sendLocals(true)
      },
      // =============== GETTING MAP =====================

      // =============== MODALS OPEN/CLOSE/OPERATIONS =====================
      openPreviousMap(key) {
        this.getMindmap(key)
      },
      openNewMap() {
        this.removeLines()
        this.getNewMindmap()
      },
      // =============== MODALS OPEN/CLOSE/OPERATIONS =====================

      // =============== DRAGGING OPERATIONS =====================
      startDrag(event, p_node=null) {
        this.isSlideDown = false
        this.dragging    = true
        if (p_node) {
          this.nodeParent = p_node
          this.nodeColor  = p_node.line_color
        }
        else {
          this.nodeColor = this.getRandomColor()
        }
        if (p_node) {
          this.mousePos = $("#map-canvas")[0].getBoundingClientRect();
          if (this.nodeQuadrant(p_node) == 'UL' || this.nodeQuadrant(p_node) == 'LL') {
            this.parent_x = p_node.position_x - 100;
            this.parent_y = p_node.position_y + 25;
          } else {
            this.parent_x = p_node.position_x + 100;
            this.parent_y = p_node.position_y + 25;
          }
        } else {
          this.mousePos = $("#map-canvas")[0].getBoundingClientRect();
          if (event.touches){
            this.parent_x = (event.touches[0].clientX - this.mousePos.left) / (this.mousePos.right - this.mousePos.left) * $("#map-canvas")[0].width,
            this.parent_y = (event.touches[0].clientY - this.mousePos.top) / (this.mousePos.bottom - this.mousePos.top) * $("#map-canvas")[0].height
          
          }
          else{
            this.parent_x = (event.clientX - this.mousePos.left) / (this.mousePos.right - this.mousePos.left) * $("#map-canvas")[0].width,
            this.parent_y = (event.clientY - this.mousePos.top) / (this.mousePos.bottom - this.mousePos.top) * $("#map-canvas")[0].height
          }
        }
        let canvas_id = this.parent_x + ""
        if (!document.getElementById(canvas_id)) {
          let c = document.createElement('CANVAS')
          c.id  = this.parent_x + ""

          document.getElementById('map-container').appendChild(c)
          c.style.position = "absolute"
          c.style.top      = 0
          c.style.left     = 0
          c.width          = this.windowWidth
          c.height         = this.windowHeight
        }
        this.currentPositionX = this.currentPositionY = 0

        this.sendLocals(true)
      },
      startDragNode(event, node) {
        this.$store.commit('setSelectedNode' , node)
        if (!this.currentMindMap.editable) return false
        if (event.touches){
          this.nodeOffsetX  = event.touches[0].clientX - node.position_x
          this.nodeOffsetY  = event.touches[0].clientY - node.position_y
        }
        else{
          this.nodeOffsetX  = event.clientX - node.position_x
          this.nodeOffsetY  = event.clientY - node.position_y

        }
        this.draggingNode = true
        this.currentPositionX = this.currentPositionY = 0
      },
      doDrag(event) {
        if (this.dragging) {
          document.body.style.setProperty("cursor", "grabbing", "important");
          if(!this.mousePos) this.mousePos = $("#map-canvas")[0].getBoundingClientRect();
          if (event.touches){
            this.currentPositionX = (event.touches[0].clientX - this.mousePos.left) / (this.mousePos.right - this.mousePos.left) * $("#map-canvas")[0].width
            this.currentPositionY = (event.touches[0].clientY - this.mousePos.top) / (this.mousePos.bottom - this.mousePos.top) * $("#map-canvas")[0].height
          }
          else{
            this.currentPositionX = (event.clientX - this.mousePos.left) / (this.mousePos.right - this.mousePos.left) * $("#map-canvas")[0].width
            this.currentPositionY = (event.clientY - this.mousePos.top) / (this.mousePos.bottom - this.mousePos.top) * $("#map-canvas")[0].height
          }
          let c = document.getElementById(this.parent_x + "")
          let ctx = null
          if (c) {
            ctx = c.getContext("2d");

            ctx.clearRect(0, 0, c.width, c.height)
            ctx.beginPath()

            ctx.lineWidth = "8";
            ctx.lineCap = "round";
            ctx.strokeStyle = this.nodeColor;
            ctx.moveTo(this.parent_x, this.parent_y);
            ctx.quadraticCurveTo(this.parent_x, (this.parent_y + this.currentPositionY)/2, this.currentPositionX, this.currentPositionY);
            ctx.stroke();
          }
        } else if (this.draggingNode) {
          this.nodeUpdatedFlag = true
          let node = this.currentMindMap.nodes.findIndex((nod) => nod.id == this.$store.getters.getSelectedNode.id)
          if (event.touches){
            this.currentMindMap.nodes[node].position_x = event.touches[0].clientX - this.nodeOffsetX
            this.currentMindMap.nodes[node].position_y = event.touches[0].clientY - this.nodeOffsetY
          }
          else{
            this.currentMindMap.nodes[node].position_x = event.clientX - this.nodeOffsetX
            this.currentMindMap.nodes[node].position_y = event.clientY - this.nodeOffsetY
            
          }
        }
      },
      stopDrag(event) {
        document.body.style.cursor = "unset"
        if (this.dragging) {
          this.dragging     = false
          this.draggingNode = false

          // To prevent adding new input box if user clicks on red circle.
          this.removeLines()
          if (this.currentPositionX == 0 && this.currentPositionY == 0) {
            this.drawLines()
            return;
          }

          if ((this.windowWidth - this.currentPositionX) < 100) {
            this.currentPositionX -= 150
          } else if (this.currentPositionX < 100) {
            this.currentPositionX += 100
          }
          if ((this.windowHeight - this.currentPositionY) < 50) {
            this.currentPositionY -= 50
          } else if (this.currentPositionY < 50) {
            this.currentPositionY += 5
          }
          let node = {
            title      : "New Idea",
            position_x : this.currentPositionX,
            position_y : this.currentPositionY,
            line_color : this.nodeColor,
            parent_node: this.nodeParent ? this.nodeParent.id : 0
          }
          this.$store.commit('setSelectedNode' , { id: ''})
          this.createNode(node)
          this.sendLocals(false)
          // this.currentMindMap.nodes.push(node);
          this.currentPositionX = this.currentPositionY = 0
          this.nodeParent       = null
          this.drawLines()
        }
        if (this.draggingNode) {
          this.dragging     = false
          this.draggingNode = false
          this.saveNode(this.$store.getters.getSelectedNode)
          this.removeLines()
          this.drawLines()
          this.sendLocals(false)
        }

      },
      // =============== DRAGGING OPERATIONS =====================

      // =============== STYLING OPERATIONS =====================
      getNodeStyle(node) {
        let p_node = this.currentMindMap.nodes.filter((n) => n.id == node.parent_node)[0]

        if (this.nodeQuadrant(node) == "LL")
        {
          if (p_node && p_node.position_x < node.position_x) {
            return {left: (node.position_x - 120) + 'px', top: (node.position_y - 20) + 'px'}
          } else {
            return {left: (node.position_x - 120) + 'px', top: (node.position_y - 20) + 'px'}
          }
        }
        else if (this.nodeQuadrant(node) == "UL")
        {
          if (p_node && p_node.position_x < node.position_x) {
            return {left: (node.position_x - 120) + 'px', top: (node.position_y - 20) + 'px'}
          } else {
            return {left: (node.position_x - 120) + 'px', top: (node.position_y - 20) + 'px'}
          }
        }
        else
        {
          return {left: (node.position_x - 20) +'px', top: (node.position_y - 20) + 'px'}
        }
      },
      drawLines(retry_count=0) {
        if (document.getElementById("map-canvas") != null)
        {
          this.removeLines()
          let c = document.getElementById("map-canvas")
          if (!c) { return; }

          let ctx = c.getContext("2d")
          ctx.clearRect(0, 0, c.width, c.height)

          let CI = this
          if(this.currentMindMap.nodes) {
            this.currentMindMap.nodes.forEach((nod) => {
            if (nod.is_disabled || nod.hide_self) { return; }
            if (nod.line_color) {
              ctx.strokeStyle = nod.line_color
            }
            else {
              ctx.strokeStyle = CI.nodeColor
            }
            ctx.lineWidth = "5";
            ctx.lineCap = "round";
            ctx.beginPath();
            let position_x = 0;
            let position_y = 0;
            if (nod.parent_node == 0) {
              ctx.moveTo(Math.floor(CI.windowWidth/2) - 50, Math.floor(CI.windowHeight/2) - 15);
              position_x = Math.floor(CI.windowWidth/2) - 50;
              position_y =  Math.floor(CI.windowHeight/2) - 15;
            } else {
              let p_node = CI.currentMindMap.nodes.filter((n) => n.id == nod.parent_node)[0]
              if (p_node) {
                if (this.nodeQuadrant(p_node) == "UL" || this.nodeQuadrant(p_node) == "LL")
                {
                  if (p_node.position_x > nod.position_x) {
                    ctx.moveTo(p_node.position_x - 100, p_node.position_y + 20);
                    position_x = p_node.position_x - 100
                    position_y =  p_node.position_y + 20
                  } else {
                    ctx.moveTo(p_node.position_x + 5, p_node.position_y + 20);
                    position_x = p_node.position_x + 5
                    position_y =  p_node.position_y + 20
                  }
                }
                else
                {
                  if (p_node.position_x < nod.position_x) {
                    ctx.moveTo(p_node.position_x + 100, p_node.position_y + 20);
                    position_x = p_node.position_x +100
                    position_y =  p_node.position_y + 20
                  } else {
                    ctx.moveTo(p_node.position_x + 5, p_node.position_y + 20);
                    position_x = p_node.position_x +5
                    position_y =  p_node.position_y + 20
                  }
                }
              }
            }
            ctx.quadraticCurveTo(position_x, (position_y + nod.position_y)/2 ,nod.position_x + 5, nod.position_y + 20);

            if (
              this.nodeQuadrant(nod) == "LL" ||
              this.nodeQuadrant(nod) == "UL"
            ) {
              ctx.lineTo(nod.position_x - 100, nod.position_y + 20)
            }
            else {
              ctx.lineTo(nod.position_x + 100, nod.position_y + 20)
            }
            ctx.stroke()
            ctx.closePath()
            })
          }
        }
        else if (retry_count < 5) {
          setTimeout(this.drawLines(retry_count++), 100);
        }
      },
      removeLines() {
        document.querySelectorAll("CANVAS").forEach((canvas) => {
          if (canvas.id != "map-canvas") {
            canvas.parentNode.removeChild(canvas)
          }
        })

        let c = document.getElementById("map-canvas")
        if (!c) { return; }
        let ctx = c.getContext("2d");
        ctx.clearRect(0, 0, c.width, c.height)
      },
      drawNewLine(node) {
        let c = document.getElementById("map-canvas")
        if (!c) { return; }
        let ctx = c.getContext("2d")
        ctx.clearRect(0, 0, c.width, c.height)

        ctx.lineWidth   = "3"
        ctx.lineCap     = "round"
        ctx.strokeStyle = node.line_color

        ctx.beginPath()
        if (node.parent_node == 0) {
          ctx.moveTo(Math.floor(this.windowWidth/2) - 50, Math.floor(this.windowHeight/2) - 15)
        } else {
          let p_nodes = this.currentMindMap.nodes.filter((n) => n.id == node.parent_node)

          // Getting only first parent here as We have single parent in phase 1.
          // only drawing of we find parent node.
          if (p_nodes[0]) {
            ctx.moveTo(p_nodes[0].position_x + 80, p_nodes[0].position_y + 17)
          }
        }
        ctx.lineTo(node.position_x + 80, node.position_y + 17)
        ctx.stroke()
        ctx.closePath()

        this.isEditing = true
        this.sendLocals(true)
      },
      nullifyFlags() {
        this.$store.commit('setSelectedNode' , { id: ''})
        this.dragging     = false
        this.draggingNode = false
        this.$store.commit('setCopiedNode' , null)
        this.editingNode  = null
      },
      // =============== STYLING OPERATIONS =====================

      // =============== Node CRUD OPERATIONS =====================
      cutSelectedNode() {
        if (!this.$store.getters.getSelectedNode) { return; }
        this.$store.commit('setCopiedNode' , this.$store.getters.getSelectedNode)
        this.$store.commit('setCopiedNodeDisabled' , true)
        this.cutFlag                = true
        this.saveCurrentMap()
        http.put(`/nodes/${this.$store.getters.getCopiedNode.id}.json`, {node: this.$store.getters.getCopiedNode}).then((res) => {
          this.$store.commit('setSelectedNode' , { id: ''})
        }).catch((error) => {
          console.log(error)
        })
      },
      copySelectedNode() {
        if (!this.$store.getters.getSelectedNode) { return; }
        this.$store.commit('setCopiedNode' , this.$store.getters.getSelectedNode)
        this.$store.commit('setSelectedNode' , { id: ''})
      },
      pasteCopiedNode() {
        if (!this.$store.getters.getCopiedNode) { return; }
        let new_parent = 0

        if (this.$store.getters.getSelectedNode) {
          new_parent = this.$store.getters.getSelectedNode.id
        }

        // clone copied node
        const dupNode = {}
        Object.assign(dupNode, this.$store.getters.getCopiedNode)

        if (dupNode.parent_node != 0 || !this.cutFlag) {
          dupNode.line_color = this.getRandomColor()
        }

        let location        = this.getNewPosition(new_parent)
        dupNode.parent_node = new_parent
        dupNode.position_x  = location[0]
        dupNode.position_y  = location[1]
        if (!!new_parent) dupNode.line_color = this.$store.getters.getSelectedNode.line_color

        this.drawNewLine(dupNode)
        this.$store.commit('setCopiedNode' , null)
        this.saveCurrentMap()

        if (this.cutFlag) {
          dupNode.is_disabled = false

          http
            .put(`/nodes/${dupNode.id}.json`, {node: dupNode})
            .then((res) => {
              this.getMindmap(this.currentMindMap.unique_key)
              this.cutFlag      = false
              this.$store.commit('setSelectedNode' , res.data.node)
            }).catch((error) => {
              console.log(error)
            })
        }
        else {
          http
            .post('/nodes.json', {node: dupNode, duplicate_child_nodes: dupNode.id})
            .then((res) => {
              this.getMindmap(this.currentMindMap.unique_key)
              this.$store.commit('setSelectedNode' , { id: ''})
            }).catch((error) => {
              console.log(error)
            })
        }
      },
      saveNode(node) {
        if (this.nodeUpdatedFlag == false) { return; }
        if (!node || !node.id) { console.log("Unable to update node"); return; }

        this.nodeUpdatedFlag = false
        let index = this.currentMindMap.nodes.findIndex((nod) => nod.id == node.id)
        if (index != -1) {
          this.saveCurrentMap()
          let formData = { node: node }
          http.put(`/nodes/${node.id}.json`, formData).then((res) => {
            this.currentMindMap.nodes.splice(index, 1, res.data.node)
          }).catch((error) => {
            console.log(error)
          })
        }
      },
      createNode(node) {
        this.drawNewLine(node)
        node['mindmap_id'] = this.currentMindMap.id
        this.saveCurrentMap()
        http.post('/nodes.json', {node: node}).then((res) => {
          this.getMindmap(this.currentMindMap.unique_key)
          this.$store.commit('setSelectedNode' , res.data.node)
        }).catch((error) => {
          console.log(error)
        })

        this.sendLocals(true)
      },
      nodeUpdated: _.debounce(
        function(node) {
          this.nodeUpdatedFlag = true
          this.saveNode(node)
        },
        2000
      ),
      deleteSelectedNode(is_cut=false) {
        if (!this.$store.getters.getSelectedNode || !this.$store.getters.getSelectedNode.id) { return; }
        let node_id = this.$store.getters.getSelectedNode.id
        this.saveCurrentMap()
        http.delete(`/nodes/${node_id}.json`).then((res) => {
          if (res.data.success) {
            this.$store.commit('setSelectedNode' , { id: ''})
            this.getMindmap(this.currentMindMap.unique_key)
          } else {
            console.log("Unable to delete node")
          }
        }).catch((error) => {
          console.log(error)
        })

        this.sendLocals(false)
      },
      deletAllNodes(nodes) {
        http.put('/msuite/destroy_nodes.json', {nodes: nodes})
      },
      // =============== Node CRUD OPERATIONS =====================

      // =============== Map CRUD OPERATIONS =====================
      saveCurrentMap() {
        this.currentMindMap.name = this.centralIdea
        this.currentMindMap.canvas = this.$store.getters.getUser
        if (this.currentMindMap.id) {
          let formData = { mindmap: this.currentMindMap }
          this.$store.dispatch('updateMSuite', formData)
          this.stopWatch      = true
          this.currentMindMap = this.$store.getters.getMsuite
          this.$store.commit('setSelectedNode' , null)
          this.updateQuery()
        } else {
          http.post(`/msuite.json`, { mindmap: this.currentMindMap }).then((res) => {
            this.stopWatch      = true
            this.$store.commit('setMSuite', res.data.mindmap)

            this.currentMindMap = this.$store.getters.getMsuite
            this.$store.commit('setSelectedNode' , null)
            this.updateQuery()
          }).catch((error) => {
            console.log(error)
          })
        }
        this.sendLocals(true)
      },
      // =============== Map CRUD OPERATIONS =====================

      // =============== OTHERS =====================
      updateQuery() {
        this.$router.push({ name: 'maproot', params: { key: this.currentMindMap.unique_key } })
      },
      updateCentralIdea: _.debounce(
        function(input) {
          this.currentMindMap.name = this.$refs.central_idea.value
        },
        1000
      ),
      hasChilNodes(node) {
        return this.currentMindMap.nodes.filter((nod) => nod.parent_node == node.id).length > 0;
      },
      getNewPosition(new_parent) {
        let new_location = [0, 0]

        if (new_parent) {
          let new_p    = this.currentMindMap.nodes.filter((nod) => nod.id == new_parent)[0]
          new_location = [new_p.position_x, new_p.position_y - 100]

          for (;;) {
            if (new_location[1] < 50) {
              new_location[1] += 50
            } else {
              break
            }
          }
        } else {
          new_location[0] = Math.floor(this.windowWidth/2)
          new_location[1] = Math.floor(this.windowHeight/2) - 100
        }

        return new_location
      },

      nodeQuadrant(node) {
        let center_x = Math.floor(this.windowWidth/2)
        let center_y = Math.floor(this.windowHeight/2)

        if (node.position_x < center_x &&
            node.position_y < center_y) {
          return "UL"; // Uper Left
        }
        if (node.position_x < center_x &&
            node.position_y > center_y) {
          return "LL"; // Lower Left
        }
        if (node.position_x > center_x &&
            node.position_y < center_y) {
          return "UR"; // Upper right
        }
        if (node.position_x > center_x &&
            node.position_y > center_y) {
          return "LR"; // Lower right
        }
      },
      switchExpandChildren(flag, node) {
        http.get(`/nodes/hide_children.json?id=${node.id}&flag=${flag}`)
          .then((res) => {})
          .catch((error) => {
            let err_msg = error.response.status === 401 ? "Unauthorized request!" : "There was an error while collapsing/expanding child nodes."
            alert(err_msg)
            console.log(error)
          })
      },
      // =============== OTHERS =====================
      getRandomColor() {
        let letters = '0123456789ABCDEF'
        let color   = '#'
        for (let i=0; i<6; i++) {
          color += letters[Math.floor(Math.random() * 16)]
        }
        return color
      },
      // =============== SCALING ====================
      transformScale(event) {
        if (this.openVModal) { return; }
        if (event.deltaY < 0) {
          if (this.$store.getters.getScaleFactor < 1.50) {
            this.$store.dispatch('setScaleFactor', this.$store.getters.getScaleFactor + 0.03)
          }
        }
        else if (event.deltaY > 0) {
          if (this.$store.getters.getScaleFactor > 0.50) {
            this.$store.dispatch('setScaleFactor', this.$store.getters.getScaleFactor - 0.03)
          }
        }

        this.drawLines()
      },
      exportImage(option) {
        const _this = this
        let elm = document.getElementById("map-container")
        elm.style.transform = "scale(1)"
        let map_key = _this.currentMindMap.unique_key || "image"
        _this.exportLoading = true

        domtoimage.toPng(elm)
          .then((url) => {
            Jimp.read(url).then((image) => {
              let size = _this.getExportCanvasSize()
              image.crop(size.x, size.y, size.w, size.h)
              image.getBase64(Jimp.MIME_PNG,
                ((err, baseUrl) => {
                  if (option === 1){
                    let downloadLink = document.createElement("a")
                    document.body.appendChild(downloadLink)
                    downloadLink.href = baseUrl
                    downloadLink.download = map_key + ".png"
                    downloadLink.click()
                    document.body.removeChild(downloadLink)
                    _this.exportLoading = false
                  }
                  else {
                    var pdf = new jsPDF('l', 'px',[size.w,size.h],true);
                    var width = pdf.internal.pageSize.getWidth();
                    var height = pdf.internal.pageSize.getHeight();
                    html2canvas(elm).then(canvas => {
                      pdf.addImage(baseUrl, 'JPEG', 0, 0, size.w, size.h);
                      pdf.save(this.currentMindMap.unique_key + '.pdf');
                    });
                    _this.exportLoading = false
                  }
                })
              );
            }).catch((err) => {
              _this.exportLoading = false
              console.error('oops, something went wrong!', err)
            })
          })
          .catch((err) => {
            _this.exportLoading = false
            console.error('oops, something went wrong!', err)
          })

        elm.style.transform = "scale(" + this.$store.getters.getScaleFactor +")"
      },
      zoomInScale() {
        if (this.$store.getters.getScaleFactor < 1.50) {
          this.$store.dispatch('setScaleFactor', this.$store.getters.getScaleFactor + 0.03)
        }
      },
      zoomOutScale() {
        if (this.$store.getters.getScaleFactor > 0.50) {
          this.$store.dispatch('setScaleFactor', this.$store.getters.getScaleFactor - 0.03)
        }
      },
      resetZoomScale() {
        this.$store.dispatch('setScaleFactor', 1)
        this.$forceUpdate()
      },

      //========== Slide ============
      scrollToCenter() {
        setTimeout(() => {
          let cal_height = this.windowHeight/2 - window.innerHeight/2
          document.getElementById("slideSection").scrollTop = cal_height

          let cal_width = this.windowWidth/2 - window.innerWidth/2
          document.getElementById("slideSection").scrollLeft = cal_width + (1 - this.$store.getters.getScaleFactor) * cal_width/2
        }, 200)
      },
      slideInit(e) {
        let slider           = this.$refs.slideSection
        this.isSlideDown     = true
        if (e.touches){
          this.slideStartX     = e.touches[0].pageX - slider.offsetLeft
          this.slideStartY     = e.touches[0].pageY - slider.offsetTop
        }
        else{
          this.slideStartX     = e.pageX - slider.offsetLeft
          this.slideStartY     = e.pageY - slider.offsetTop
        }
        this.slideScrollLeft = slider.scrollLeft
        this.slideScrollTop  = slider.scrollTop
      },
      slideTheCanvas(e) {
        let slider = this.$refs.slideSection
        if (!this.isSlideDown) { return; }
        let x , y
        if (e.touches){
          x     = e.touches[0].pageX - slider.offsetLeft
          y     = e.touches[0].pageY - slider.offsetTop
        }
        else{
          x     = e.pageX - slider.offsetLeft
          y     = e.pageY - slider.offsetTop
        }
        let walkX = x - this.slideStartX
        walkX     = this.slideScrollLeft - walkX

        if (walkX > (this.windowWidth * (1-this.$store.getters.getScaleFactor)/2)) {
          slider.scrollLeft = walkX
        }

        let walkY = y - this.slideStartY
        walkY     = this.slideScrollTop - walkY

        if (walkY > (this.windowHeight * (1-this.$store.getters.getScaleFactor)/2)) {
          slider.scrollTop = walkY
        }
      },

      // attchment
      nullifyAttachmentModal() {
        this.centralNotes = ""
        this.openVModal = false
        this.descEditMode = false
      },
      openAttachments(tab="description-tab") {
        if (!this.$store.getters.getSelectedNode) { return; }
        this.openVModal = true
        this.$refs['attachment-modal'].$refs.attachmentModal.open(tab)
      },
      updateNodeDescription(notes) {
        if (!this.$store.getters.getSelectedNode) { return; }
        this.nodeUpdatedFlag = true
        this.$store.getters.getSelectedNode.description = notes
        this.$forceUpdate()
        this.saveNode(this.$store.getters.getSelectedNode)
        this.descEditMode = false

        this.sendLocals(true)
      },
      // central Idea Attachments
      openCentralAttachModal(e) {
        this.openVModal = true
        this.centralNotes = this.currentMindMap.description
        this.$refs["central-attachment-modal"].$refs.centralAttachmentModal.open(e.target.dataset.tab)
      },
      updateMapNotes(notes) {
        this.currentMindMap.description = notes
        this.saveCurrentMap()
        this.descEditMode = false
        this.sendLocals(true)
      },
      // export word functions
      exportToWord() {
        this.openVModal = true
        this.$refs['export-to-word-modal'].$refs.exportToWordModal.open()
      },
      getExportCanvasSize() {
        const nodes = this.currentNodes
        let ASPECT_MARGIN = 150
        let size = { x:1900, y:900, w:1900, h:900 }

        if (nodes.length <= 0) return;

        let min_x = Math.min.apply(Math, nodes.map((n) => {return n.position_x}))
        let max_x = Math.max.apply(Math, nodes.map((n) => {return n.position_x}))
        let min_y = Math.min.apply(Math, nodes.map((n) => {return n.position_y}))
        let max_y = Math.max.apply(Math, nodes.map((n) => {return n.position_y}))

        size.x = min_x < size.x ? min_x : size.x
        size.y = min_y < size.y ? min_y : size.y
        size.w = max_x - size.x < size.w ? size.w : max_x - size.x
        size.h = max_y - size.y < size.h ? size.h : max_y - size.y

        if (size.x > 0) size.x = size.x - ASPECT_MARGIN
        if (size.y > 0) size.y = size.y - ASPECT_MARGIN
        size.w = size.w + (ASPECT_MARGIN * 2)
        size.h = size.h + (ASPECT_MARGIN * 2)

        return size
      },
    },

    mounted() {
      this.subscribeCable(this.currentMindMap.id)
      this.mountMap()

      window.addEventListener('mouseup', this.stopDrag)
      window.addEventListener('touchend', this.stopDrag)
      window.addEventListener('wheel', this.transformScale)

      this.getUserOnMount()
      this.zmInScale(this.zoomInScale)
      this.zmOutScale(this.zoomOutScale)
      this.resetZmScale(this.resetZoomScale)
      this.exportImg(this.exportImage)
      this.exportWord(this.exportToWord)
      this.delSelectedNode(this.deleteSelectedNode)
      this.cutSelNode(this.cutSelectedNode)
      this.copySelNode(this.copySelectedNode)
      this.pasteNode(this.pasteCopiedNode)
    },

    created(){
      this.$nextTick(() => {
        this.scrollToCenter()
      })
    },

    watch: {
      "currentMindMap.id"() {
        if (this.currentMindMap.id) {
          this.$cable.subscribe({ channel: 'WebNotificationsChannel', room: this.currentMindMap.id})
        }
      },
      "currentMindMap.name": {
        handler: function(new_map) {
          this.centralIdea = this.currentMindMap.name
          if (this.stopWatch) {
            this.stopWatch = false
            return
          }
          if(this.currentMindMap.name != '') this.saveCurrentMap()
          },
        deep: true
      },
      "currentMindMap.description": {
        handler: function() {
          this.centralNotes = this.currentMindMap.description
        },
        deep: true
      },
      "currentMindMap.nodes": {
        handler: function() {
          this.currentNodes = this.currentMindMap.nodes
        },
        deep: true
      },
      centralIdea(value) {
        let dheight            = Math.ceil(value.length / 15)
        dheight                = dheight > 1 ? dheight * 2 : 3
        this.centralIdeaHeight = dheight > 8 ? "8em" : dheight + "em"
      },
      descEditMode(value) {
        document.getElementsByClassName("ql-toolbar")[0].style.display = value ? "block" : "none"
        document.getElementsByClassName("ql-container")[0].style.borderTop = value ? "0px" : "1px solid #ccc"
      }
    }
  }
</script>

<style scoped lang="scss">
  @import "./styles/mindmap_new.scss";
</style>
