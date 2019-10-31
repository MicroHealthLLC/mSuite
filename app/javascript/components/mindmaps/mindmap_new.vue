<template>
  <div class="map-container">
    <div class="buttons_area">
      <div class="buttons_container">
        <span class="flex">
          <a 
            href="javascript:;"
            role="button" 
            class="d-flex text-info edit_delete_btn delete ml-2 mr-3 center_flex"
            @click.stop="goHome" 
          >
            <i class="material-icons home_icon icons d-flex center_flex"></i>
          </a> 
        </span>
        <span class="ml_10">
          <a 
            href="javascript:;"
            role="button" 
            :disabled="!selectedNode" 
            :class="{button_disabled: !selectedNode}" 
            class="d-flex text-info edit_delete_btn delete mr-3 center_flex"
            @click.stop="deleteSelectedNode" 
          >
            <i class="material-icons delete_icon icons d-flex center_flex"></i>
          </a> 
          <a 
            href="javascript:;"
            role="button" 
            :disabled="!selectedNode" 
            :class="{button_disabled: !copiedNode}" 
            class="d-flex text-info edit_delete_btn delete mr-3 center_flex"
            @click.stop="pasteCopiedNode" 
          >
            <i class="fa fa-paste paste_icon icons d-flex center_flex"></i>
          </a> 
          <a 
            href="javascript:;"
            role="button" 
            :disabled="!selectedNode" 
            :class="{button_disabled: !selectedNode}" 
            class="d-flex text-info edit_delete_btn delete mr-3 center_flex"
            @click.stop="cutSelectedNode" 
          >
            <i class="fa fa-cut cut_icon icons d-flex center_flex"></i>
          </a> 
          <a 
            href="javascript:;"
            role="button" 
            :disabled="!selectedNode" 
            :class="{button_disabled: !selectedNode}" 
            class="d-flex text-info edit_delete_btn delete mr-3 center_flex"
            @click.stop="copySelectedNode" 
          >
            <i class="material-icons copy_icon icons d-flex center_flex"></i>
          </a> 
        </span>
        <span>
          <a 
            href="javascript:;"
            role="button" 
            class="d-flex text-info edit_delete_btn delete mr-3 center_flex"
            @click.stop="$refs.resetMapModal.open" 
          >
            <i class="material-icons restore_icon icons d-flex center_flex"></i>
          </a> 
          <a 
            href="javascript:;"
            role="button" 
            class="d-flex text-info edit_delete_btn delete mr-3 center_flex"
            @click.stop="$refs.openMapModal.open" 
          >
            <i class="fa fa-folder-open open_icon icons d-flex center_flex"></i>
          </a> 
          <a 
            href="javascript:;"
            role="button" 
            class="d-flex text-info edit_delete_btn delete mr-3 center_flex"
            @click.stop="$refs.newMapModal.open" 
          >
            <i class="material-icons new_icon icons d-flex center_flex"></i>
          </a> 
          <a 
            ref="exportBtn"
            role="button" 
            class="d-flex text-info pointer edit_delete_btn delete mr-3 center_flex"
            @click.stop="exportToImage" 
            download="image.png" 
          >
            <i class="material-icons export_icon icons d-flex center_flex"></i>
          </a>
        </span>
      </div>
    </div>
    <div class="scaling_area">
      <span class="flex">
          <a
                  v-if="this.scaleFactor != 1"
                  href="javascript:;"
                  role="button"
                  class="d-flex zoom_btn text-info edit_delete_btn delete center_flex"
                  @click.stop="resetZoomScale"
          >
          <i class="material-icons icons d-flex center_flex">youtube_searched_for</i>
        </a>

        <a 
          href="javascript:;"
          role="button" 
          class="d-flex zoom_btn text-info edit_delete_btn delete ml-2 center_flex"
          @click.stop="zoomInScale" 
        >
          <i class="material-icons icons d-flex center_flex">zoom_in</i>
        </a> 

        <a
          href="javascript:;"
          role="button" 
          class="d-flex zoom_btn text-info edit_delete_btn delete ml-2 center_flex"
          @click.stop="zoomOutScale" 
        >
          <i class="material-icons icons d-flex center_flex">zoom_out</i>
        </a>

      </span>
    </div>
    <div ref="slideSection" id="slideSection" @mousedown.stop="slideInit" @mousemove.prevent="slideTheCanvas" @mouseleave="isSlideDown = false" @mouseup="isSlideDown = false">
      <section v-if="!loading" id="map-container" @mousemove.prevent="doDrag" :style="C_scaleFactor">
        <div class="center" @click.stop.prevent="nullifySlider" :style="C_centeralNodePosition">
          <span @mousedown.prevent.stop="startDrag" class="start_dot"></span>
          <textarea type="text" ref="central_idea" @input="updateCentralIdea" v-model="centralIdea" class="shadow-lg central_idea pt-2" :style="C_centralIdeaStyle"/>
        </div>
        <input-field 
          v-for="node in currentMindMap.nodes" 
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
          @start-drag="startDrag($event, node)" 
          @mousedown-event="startDragNode($event, node)" 
          @node-updated="nodeUpdated(node)"
          @switch-expand-children="switchExpandChildren($event, node)"
          @edit-node="editNode($event, node)"
          @open-attachment="openAttachments"
          class="pos_abs input_field">
          </input-field>
        <canvas id="map-canvas" class="has_bg" :width="windowWidth" :height="windowHeight" @click.stop="nullifyFlags"></canvas>
      </section>
    </div>
    <sweet-modal ref="newMapModal" class="of_v">
      <div class="sweet_model_icon_div">
        <div class="radius_circle bg-warning center_flex mlr_a">
          <i class="material-icons text-white">error_outline</i>
        </div>
      </div>
      <h3 class="f_smooth_auto">Are you Sure?</h3>
      <p class="text-muted fs_18">You may want to open in new Tab!</p>
      <div class="center_flex mt_2">
        <a 
          href="javascript:;" 
          class="btn_2 bg-danger text-white mr_1"
          @click.stop="openNewMap" 
        >
          <i class="material-icons mr-1">done</i>
          Continue Here
        </a>
        <a 
          href="javascript:;" 
          class="btn_2 bg-warning text-white mr_1"
          @click.stop="openNewMapNewWindow" 
        >
          <i class="material-icons mr-1">open_in_new</i>
          Open new Tab!
        </a>
        <a 
          href="javascript:;" 
          class="btn_2 bg-primary text-white mr_1"
          @click.stop="$refs.newMapModal.close" 
        >
          <i class="material-icons mr-1">cancel</i>
          Cancel
        </a>
      </div>
    </sweet-modal>
    <sweet-modal ref="openMapModal" class="of_v">
      <div class="sweet_model_icon_div">
        <div class="radius_circle bg-success center_flex mlr_a">
          <i class="material-icons text-white">folder_open</i>
        </div>
      </div>
      <p class="text-muted fs_18">Enter the map key you want to open here!</p>
      <div class="form-horizontal">   
        <div class="row form-group mt-2">
          <label class="control-label col-4" for="mindmap_name">Mindmap Name:</label>
          <input type="text" placeholder="Enter map key" v-model="openMindMapKey" class="form-control col-6 ">
        </div>
      </div>
      <div class="center_flex mt_2">
        <a 
          href="javascript:;" 
          class="btn_2 bg-success text-white mr_1"
          @click.stop.prevent="openPreviousMap" 
        >
          <i class="material-icons mr-1">done</i>
          Open
        </a>
        <a 
          href="javascript:;" 
          class="btn_2 bg-primary text-white mr_1"
          @click.stop.prevent="$refs.openMapModal.close" 
        >
          <i class="material-icons mr-1">cancel</i>
          Cancel
        </a>
      </div>
    </sweet-modal>
    <sweet-modal ref="resetMapModal" class="of_v">
      <div class="sweet_model_icon_div">
        <div class="radius_circle bg-warning center_flex mlr_a">
          <i class="material-icons text-white">restore</i>
        </div>
      </div>
      <h3 class="f_smooth_auto">Are you Sure you want to reset this Map?</h3>
      <p class="text-muted fs_18">Your current changes will be discarded, you won't be able to revert this!</p>
      <div class="center_flex mt_2">
        <a 
          href="javascript:;" 
          class="btn_2 bg-danger text-white mr_1"
          @click.stop="resetMindmap" 
        >
          <i class="material-icons mr-1">done</i>
          Continue
        </a>
        <a 
          href="javascript:;" 
          class="btn_2 bg-primary text-white mr_1"
          @click.stop="$refs.resetMapModal.close" 
        >
          <i class="material-icons mr-1">cancel</i>
          Cancel
        </a>
      </div>
    </sweet-modal>

    <sweet-modal ref="attachmentModal" id="attachment-modal" class="of_v">
      <div class="sweet_model_icon_div">
        <div class="radius_circle bg-success center_flex mlr_a">
          <i class="material-icons text-white">post_add</i>
        </div>
      </div>
      <sweet-modal-tab title="Description" id="description-tab">
        <template v-if="selectedNode">
          <section v-if="descEditMode">
            <quill-editor
              v-model="selectedNode.description"
              ref="contentEditor"
              :options="editorOption"
            >
            </quill-editor>

            <div class="right_flex mt_2">
              <a 
                href="javascript:;" 
                class="btn_1 btn-sm bg-danger text-white mr_1"
                @click.stop="updateNodeDescription(selectedNode)" 
              >
                <i class="material-icons mr-1">done</i>
                Save
              </a>
            </div>
          </section>
          <section v-else>
            <section v-if="selectedNode.description"
              class="node-description-tab"
              v-html="selectedNode.description"
            ></section>
            <section v-else class="node-description-tab text-center text-secondary">
              <i>No description present..</i>
            </section>
            <span class="edit-icon shadow" @click.stop="descEditMode = true">
              <i class="material-icons">edit</i>
            </span>
          </section>
        </template>
      </sweet-modal-tab>
      <sweet-modal-tab title="Files" id="files-tab">
        <section class="row node-files-tab">
          <div class="col-md-6">
            <attachment-input 
              :show-label="true" 
              @input="addFile"
            >
            </attachment-input>
          </div>
          <div class="col-md-6 node-files-list">
            <div v-if="attachFiles.length > 0">
              <div class="files-list p-2" v-for="file in attachFiles">
                <span class="files-name text-left mr-1 p-1"> 
                  {{ file.uri.split("/").pop().replace(/%20/g, ' ') }}
                </span>
                <span class="files-action d-flex align-items-center">
                  <a :href="fileLink(file)" target="_blank" class="download-btn mr-2">
                    <i class="material-icons p-2">get_app</i>
                  </a>
                  <a href="javascript:;" :data-file-id="file.id" class="remove-btn" @click.prevent="removeFile(file)">
                    <i class="material-icons p-2">close</i>
                  </a>
                </span>
              </div>
            </div>
            <div v-else class="empty-file-list text-secondary">
              No files attached...
            </div>
          </div>
        </section>
      </sweet-modal-tab>
    </sweet-modal>
  </div>
</template>

<script>
  import InputField                 from "./idea_input_field"
  import http                       from "../../common/http"
  import {SweetModal,SweetModalTab} from "sweet-modal-vue"
  import _                          from "lodash"
  import domtoimage                 from "dom-to-image-more"
  import fileDownload               from "js-file-download"
  import {quillEditor}              from "vue-quill-editor"
  import AttachmentInput            from '../shared/attachment_input'
  import "quill/dist/quill.core.css"
  import "quill/dist/quill.snow.css"
  import "quill/dist/quill.bubble.css"

  export default 
  {
    components: {
      InputField, 
      SweetModal,
      SweetModalTab,
      quillEditor,
      AttachmentInput
    },
    
    data() {
      return {
        selectedNode      : null,
        nodeParent        : null,
        nodeColor         : null,
        centralIdea       : '',
        currentMindMap    : {},
        loading           : true,
        dragging          : false,
        draggingNode      : false,
        currentPositionX  : 0,
        currentPositionY  : 0,
        nodeOffsetX       : 0,
        nodeOffsetY       : 0,
        parent_x          : 0,
        parent_y          : 0,
        
        // hardcoded fixed window size
        window_innerWidth : 1900,
        window_innerHeight: 900,
        windowWidth       : 1900 * 3,
        windowHeight      : 900 * 3,
        stopWatch         : false,
        openMindMapKey    : '',
        nodeUpdatedFlag   : false,
        copiedNode        : null,
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
        attachmentModal   : false,
        uploadFiles       : [],
        attachFiles       : [],
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
              // [{ 'script': 'sub' }, { 'script': 'super' }],
              // [{ 'indent': '-1' }, { 'indent': '+1' }],
              // [{ 'font': [] }],
              [{ 'color': [] }, { 'background': [] }]
            ],
            syntax : {
              highlight: text => hljs.highlightAuto(text).value
            }
          }
        }
      }
    },
    
    channels: {
      WebNotificationsChannel: {
        received(data) {
          this.getMindmap(this.currentMindMap.unique_key)
        }
      }
    },
    
    computed: {
      C_centeralNodePosition() {
        return {
          left: (Math.floor(this.windowWidth/2) - 120) +'px', 
          top : (Math.floor(this.windowHeight/2) - 40) +'px'
        }
      },
      C_selectedNodeId() {
        return this.selectedNode ? this.selectedNode.id : 0
      },
      C_editNodeId() {
        return this.editingNode ? this.editingNode.id : 0
      },
      C_scaleFactor() {
        return {
          transform : "scale(" + this.scaleFactor + ")",
          minWidth  : this.windowWidth+ "px",
          minHeight : this.windowHeight+ "px"
        }
      },
      C_centralIdeaStyle() {
        return {
          width : this.centralIdeaWidth,
          height: this.centralIdeaHeight
        }
      }
    },
    
    methods: {
      // =============== GETTING MAP =====================
      getMindmap(id) {
        http
          .get(`/mindmaps/${id}.json`)
          .then((res) => {
            this.stopWatch      = true
            this.currentMindMap = res.data.mindmap
            
            setTimeout(this.drawLines, 100)
            this.closeOpenMapModal()
            this.updateQuery()
            this.loading = false
          }).catch((error) => {
            alert(`Mind map with id ${id} not found`)
            console.log(error)
            window.open('/', '_self')
          })
      },
      getNewMindmap() {
        http
          .get('/mindmaps/new.json')
          .then((res) => {
            this.loading        = false
            this.currentMindMap = res.data.mindmap
            let query           = {}
            this.$router.push({query: query})
          }).catch((error) => {
            console.log(error)
            this.loading = false
          })
      },
      nullifySlider() {
        this.isSlideDown  = false
        this.selectedNode = null
      },
      editNode(event, node) {
        this.editingNode  = node
        this.selectedNode = null
        this.dragging     = false
        this.draggingNode = false
      },
      // =============== GETTING MAP =====================

      // =============== MODALS OPEN/CLOSE/OPERATIONS =====================
      closeOpenMapModal() {
        this.openMindMapKey = ''
        this.$refs.openMapModal.close()
      },
      openPreviousMap() {
        this.getMindmap(this.openMindMapKey)
      },
      openNewMapNewWindow() {
        window.open(window.location.origin+'/mindmaps/new')
      },
      openNewMap() {
        this.removeLines()
        this.getNewMindmap()
        this.$refs.newMapModal.close()
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
        if(p_node) {
          if (this.nodeQuadrant(p_node) == 'UL' || this.nodeQuadrant(p_node) == 'LL') {
            this.parent_x = p_node.position_x - 100 ;
            this.parent_y = p_node.position_y + 25;
          } else {
            this.parent_x = p_node.position_x + 100
            this.parent_y = p_node.position_y + 25;
          }
        } else {
          this.parent_x = event.clientX + this.$refs.slideSection.scrollLeft - 15;
          this.parent_y = event.clientY + this.$refs.slideSection.scrollTop - 15;
        }

        let canvas_id = this.parent_x + ""
        if (!document.getElementById(canvas_id)) {
          var c = document.createElement('CANVAS')
          c.id  = this.parent_x + ""
          
          document.getElementById('map-container').appendChild(c)
          c.style.position = "absolute"
          c.style.top      = 0
          c.style.left     = 0
          c.width          = this.windowWidth
          c.height         = this.windowHeight
        }
        this.currentPositionX = this.currentPositionY = 0
      },
      startDragNode(event, node) {
        this.selectedNode = node
        this.nodeOffsetX  = event.clientX - node.position_x
        this.nodeOffsetY  = event.clientY - node.position_y
        this.draggingNode = true
        this.currentPositionX = this.currentPositionY = 0
      },
      doDrag(event) {
        if (this.dragging) {
          document.body.style.setProperty("cursor", "grabbing", "important");
          this.currentPositionX = event.clientX + this.$refs.slideSection.scrollLeft - (1 - this.scaleFactor) * (this.windowWidth / 2 - event.clientX - this.$refs.slideSection.scrollLeft) - (1 - this.scaleFactor) * 100 ;
          this.currentPositionY = event.clientY + this.$refs.slideSection.scrollTop - (1 - this.scaleFactor) * (this.windowHeight / 2 - event.clientY - this.$refs.slideSection.scrollTop) - (1 - this.scaleFactor) * 100 ;
          var c = document.getElementById(this.parent_x + "")
          var ctx = c.getContext("2d");

          ctx.clearRect(0, 0, c.width, c.height)
          ctx.beginPath()

          ctx.lineWidth = "8";
          ctx.lineCap = "round";
          ctx.strokeStyle = this.nodeColor;
          ctx.moveTo(this.parent_x, this.parent_y);
          ctx.quadraticCurveTo(this.parent_x, (this.parent_y + this.currentPositionY)/2, this.currentPositionX, this.currentPositionY);
          ctx.stroke();
        } else if (this.draggingNode) {
          this.nodeUpdatedFlag = true
          let node = this.currentMindMap.nodes.findIndex((nod) => nod.id == this.selectedNode.id)
          this.currentMindMap.nodes[node].position_x = event.clientX - this.nodeOffsetX
          this.currentMindMap.nodes[node].position_y = event.clientY - this.nodeOffsetY
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
          this.selectedNode = null
          this.createNode(node)
          
          // this.currentMindMap.nodes.push(node);
          this.currentPositionX = this.currentPositionY = 0
          this.nodeParent       = null
          this.drawLines()
        } 
        if (this.draggingNode) {
          this.dragging     = false
          this.draggingNode = false
          this.saveNode(this.selectedNode)
          this.removeLines()
          this.drawLines()
        }
      },
      // =============== DRAGGING OPERATIONS =====================

      // =============== STYLING OPERATIONS =====================
      getNodeStyle(node) {
        let p_node = this.currentMindMap.nodes.filter((n) => n.id == node.parent_node)[0]

        if (this.nodeQuadrant(node) == "LL") 
        {
          if (p_node && p_node.position_x < node.position_x) {
            return {left: (node.position_x) + 'px', top: (node.position_y - 20) + 'px'}
          } else {
            return {left: (node.position_x - 100) + 'px', top: (node.position_y - 20) + 'px'}
          }
        } 
        else if (this.nodeQuadrant(node) == "UL") 
        {
          if (p_node && p_node.position_x < node.position_x) {
            return {left: (node.position_x) + 'px', top: (node.position_y - 20) + 'px'}
          } else {
            return {left: (node.position_x - 100) + 'px', top: (node.position_y - 20) + 'px'}
          }
        } 
        else 
        {
          return {left: node.position_x +'px', top: (node.position_y - 20) + 'px'}
        }
      },
      drawLines(retry_count=0) {
        if (document.getElementById("map-canvas") != null) 
        {
          this.removeLines()
          var c = document.getElementById("map-canvas")
          if (!c) { return; }
          
          var ctx = c.getContext("2d")
          ctx.clearRect(0, 0, c.width, c.height)
          
          var CI = this
          this.currentMindMap.nodes.forEach((nod) => {
            if (nod.is_disabled || nod.hide_self) { return; }
            if(nod.line_color) {
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
              var p_node = CI.currentMindMap.nodes.filter((n) => n.id == nod.parent_node)[0]
              if (p_node) {
                if (this.nodeQuadrant(p_node) == "UL" || this.nodeQuadrant(p_node) == "LL") 
                {
                  if (p_node.position_x > nod.position_x) {
                    ctx.moveTo(p_node.position_x - 95, p_node.position_y + 20);
                    position_x = p_node.position_x - 95
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

            if (this.nodeQuadrant(nod) == "LL") {
              if (p_node && p_node.position_x < nod.position_x) {
                ctx.lineTo(nod.position_x + 100, nod.position_y + 20)
              } else {
                ctx.lineTo(nod.position_x - 100, nod.position_y + 20)
              }
            } 
            else if (this.nodeQuadrant(nod) == "UL") 
            {
              if (p_node && p_node.position_x < nod.position_x) {
                ctx.lineTo(nod.position_x + 100, nod.position_y + 20)
              } else {
                ctx.lineTo(nod.position_x - 100, nod.position_y + 20)
              }
            } 
            else {
              ctx.lineTo(nod.position_x + 100, nod.position_y + 20)
            }
            ctx.stroke()
            ctx.closePath()
          })
        } 
        else if (retry_count < 5) {
          setTimeout(this.drawLines(retry_count++), 100); 
        }
      },
      removeLines() {
        document.querySelectorAll("CANVAS").forEach((canvas) => {
          if(canvas.id != "map-canvas") {
            canvas.parentNode.removeChild(canvas)
          }
        })
        
        var c = document.getElementById("map-canvas")
        if (!c) { return; }
        var ctx = c.getContext("2d");
        ctx.clearRect(0, 0, c.width, c.height)
      },
      drawNewLine(node) {
        var c = document.getElementById("map-canvas")
        if (!c) { return; }
        var ctx = c.getContext("2d")
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
      },
      nullifyFlags() {
        this.selectedNode = null
        this.dragging     = false
        this.draggingNode = false
        this.copiedNode   = null
        this.editingNode  = null
      },
      // =============== STYLING OPERATIONS =====================


      // =============== Node CRUD OPERATIONS =====================
      cutSelectedNode() {
        if (!this.selectedNode) { return; }
        this.copiedNode             = this.selectedNode
        this.copiedNode.is_disabled = true
        this.cutFlag                = true
        
        http.put(`/nodes/${this.copiedNode.id}.json`, {node: this.copiedNode}).then((res) => {
          this.selectedNode = null
        }).catch((error) => {
          console.log(error)
        })
      },
      copySelectedNode() {
        if (!this.selectedNode) { return; }
        this.copiedNode   = this.selectedNode
        this.selectedNode = null
      },
      pasteCopiedNode() {
        if (!this.copiedNode) { return; }
        let new_parent = 0
        if (this.selectedNode) {
          new_parent = this.selectedNode.id
        }

        // clone copied node
        const dupNode = {}
        Object.assign(dupNode, this.copiedNode)

        let location        = this.getNewPosition(new_parent)
        dupNode.parent_node = new_parent
        dupNode.position_x  = location[0]
        dupNode.position_y  = location[1]
        dupNode.is_disabled = false

        this.drawNewLine(dupNode)
        this.copiedNode = null

        if (this.cutFlag) {
          http.put(`/nodes/${dupNode.id}.json`, {node: dupNode}).then((res) => {
            this.getMindmap(this.currentMindMap.unique_key)
            this.cutFlag      = false
            this.selectedNode = res.data.node
          }).catch((error) => {
            console.log(error)
          })
        }
        else {
          http.post('/nodes.json', {node: dupNode, duplicate_child_nodes: dupNode.id}).then((res) => {
            this.getMindmap(this.currentMindMap.unique_key)
            this.selectedNode = null
          }).catch((error) => {
            console.log(error)
          })
        }
      },
      saveNode(node, files=null) {
        if (this.nodeUpdatedFlag == false) { return; }
        if (!node || !node.id) { console.log("Unable to update node"); return; }

        this.nodeUpdatedFlag = false
        let index = this.currentMindMap.nodes.findIndex((nod) => nod.id == node.id)
        if (index != -1) {
          node = this.currentMindMap.nodes[index]
          var formData = files ? new FormData() : {node: node}
          if (files) {
            files.forEach((file) => {
              formData.append("node[node_files][]", file)
            })
          }
          http.put(`/nodes/${node.id}.json`, formData).then((res) => {
            this.currentMindMap.nodes.splice(index, 1, res.data.node)
            // for node attachment
            this.attachFiles = res.data.node.attach_files
          }).catch((error) => {
            console.log(error)
          })
        }
      },
      createNode(node) {
        this.drawNewLine(node)
        node['mindmap_id'] = this.currentMindMap.id
        http.post('/nodes.json', {node: node}).then((res) => {
          this.getMindmap(this.currentMindMap.unique_key)
          this.selectedNode = res.data.node
        }).catch((error) => {
          console.log(error)
        })
      },
      nodeUpdated(node) {
        this.nodeUpdatedFlag = true
        this.saveNode(node)
      },
      deleteSelectedNode(is_cut=false) {
        if (!this.selectedNode || !this.selectedNode.id) { return; }

        http.delete(`/nodes/${this.selectedNode.id}.json`).then((res) => {
          if (res.data.success) {
            this.selectedNode = null
            this.getMindmap(this.currentMindMap.unique_key)
          } else {
            console.log("Unable to delete node")
          }
        }).catch((error) => {
          console.log(error)
        })
      },
      deletAllNodes(nodes) {
        http.put('/mindmaps/destroy_nodes.json', {nodes: nodes})
      },
      // =============== Node CRUD OPERATIONS =====================

      // =============== Map CRUD OPERATIONS =====================
      saveCurrentMap() {
        if (this.currentMindMap.id) {
          http.put(`/mindmaps/${this.currentMindMap.unique_key}.json`, {mindmap: this.currentMindMap}).then((res) => {
            this.stopWatch      = true
            this.currentMindMap = res.data.mindmap
            this.selectedNode   = null
            this.updateQuery()
          }).catch((error) => {
            console.log(error)
          })
        } else {
          http.post(`/mindmaps.json`, {mindmap: this.currentMindMap}).then((res) => {
            this.stopWatch      = true
            this.currentMindMap = res.data.mindmap
            this.selectedNode   = null
            this.updateQuery()
          }).catch((error) => {
            console.log(error)
          })
        }
      },
      resetMindmap() {
        this.deletAllNodes(this.currentMindMap.nodes)
        this.selectedNode        = null
        this.stopWatch           = true
        this.currentMindMap.name = "Central Idea"
        this.removeLines()
        this.scrollToCenter()
        setTimeout(this.saveCurrentMap, 500)
        this.$refs.resetMapModal.close()
      },
      // =============== Map CRUD OPERATIONS =====================

      // =============== OTHERS =====================
      updateQuery() {
        let query = {}
        query['key'] = this.currentMindMap.unique_key
        this.$router.push({query: query})
      },
      updateCentralIdea: _.debounce(
        function(input) {
          this.currentMindMap.name = this.$refs.central_idea.value
        },
        500
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
      goHome() {
        window.open("/","_self")
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
        http.get(`/nodes/hide_children.json?id=${node.id}&flag=${flag}`).then((red) => {

        }).catch((error) => {
          alert("There was an error while collapsing/expanding child nodes.")
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
        if(this.attachmentModal) { return; }
        if (event.deltaY < 0) {
          if (this.scaleFactor < 1.50) {
            this.scaleFactor = this.scaleFactor + 0.01
          }
        }
        else if (event.deltaY > 0) {
          if (this.scaleFactor > 0.50) {
            this.scaleFactor = this.scaleFactor - 0.01
          }
        }

        this.drawLines()
      },
      exportToImage(event) {
        let expBtn          = this.$refs.exportBtn
        let elm             = document.getElementById("map-container")
        elm.style.transform = "scale(1)"
        let map_key         = this.currentMindMap.unique_key

        domtoimage.toPng(elm)
          .then(function (dataUrl) {
            var data = dataUrl.replace(/^data:image\/\w+;base64,/, "")
            var buf  = new Buffer(data, 'base64')
            
            fileDownload(buf, map_key+".png")
          })
          .catch(function (error) {
            console.error('oops, something went wrong!', error)
        })
          
        elm.style.transform = "scale(" + this.scaleFactor +")"
        expBtn.blur()
      }, 
      zoomInScale() {
        if (this.scaleFactor < 1.50) {
          this.scaleFactor = this.scaleFactor + 0.05
        }
      },
      zoomOutScale() {
        if (this.scaleFactor > 0.50) {
          this.scaleFactor = this.scaleFactor - 0.05
        }
      },
      resetZoomScale() {
        this.scaleFactor = 1

      },

      //========== Slide ============
      scrollToCenter() {
        setTimeout(() => {
          let cal_height = this.windowHeight/2 - window.innerHeight/2
          document.getElementById("slideSection").scrollTop = cal_height
          
          let cal_width = this.windowWidth/2 - window.innerWidth/2
          document.getElementById("slideSection").scrollLeft = cal_width + (1 - this.scaleFactor) * cal_width/2
        }, 200)
      },
      slideInit(e) {
        let slider           = this.$refs.slideSection
        this.isSlideDown     = true
        this.slideStartX     = e.pageX - slider.offsetLeft
        this.slideStartY     = e.pageY - slider.offsetTop
        this.slideScrollLeft = slider.scrollLeft
        this.slideScrollTop  = slider.scrollTop
      },
      slideTheCanvas(e) {
        let slider = this.$refs.slideSection
        if (!this.isSlideDown) { return; }
        
        let x     = e.pageX - slider.offsetLeft
        let walkX = x - this.slideStartX
        walkX     = this.slideScrollLeft - walkX
        
        if (walkX > (this.windowWidth * (1-this.scaleFactor)/2)) { 
          slider.scrollLeft = walkX
        }

        let y     = e.pageY - slider.offsetTop
        let walkY = y - this.slideStartY
        walkY     = this.slideScrollTop - walkY
        
        if (walkY > (this.windowHeight * (1-this.scaleFactor)/2)) { 
          slider.scrollTop = walkY
        }
      },

      // attchment
      openAttachments() {
        if(!this.selectedNode) { return; }
        this.attachFiles = this.selectedNode.attach_files
        this.$refs.attachmentModal.open()
      },
      updateNodeDescription(node) {
        this.nodeUpdatedFlag = true
        this.saveNode(node)
        this.descEditMode = false
      },
      addFile(params) {
        this.uploadFiles.push(params.data)
        if (params.length == this.uploadFiles.length) {
          this.nodeUpdatedFlag = true
          this.saveNode(this.selectedNode, this.uploadFiles)
          this.uploadFiles = []
        }
      },
      removeFile(file) {
        http
          .put(`/nodes/${this.selectedNode.id}/destroy_file`, {file: file})
          .then((res) => {
            _.remove(this.attachFiles, (f) => f.id === file.id)
            this.$forceUpdate()
          }).catch((error) => {
            console.log(error)
            console.log("Unable to remove the file..")
          })
      },
      fileLink(file) {
        return window.location.origin + file.uri
      }
    },
    mounted() {
      if (this.$route.query.key) {
        this.getMindmap(this.$route.query.key)
      } else {
        this.getNewMindmap()
      }
      window.addEventListener('mouseup', this.stopDrag)
      window.addEventListener('wheel', this.transformScale)
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
          this.saveCurrentMap()
        },
        deep: true
      },
      centralIdea(value) {
        let dheight            = Math.ceil(value.length / 15)
        dheight                = dheight > 1 ? dheight * 2 : 3
        this.centralIdeaHeight = dheight > 8 ? "8em" : dheight + "em" 
      }
    }
  }
</script>

<style scoped lang="scss">
  .central_idea {
    text-align   : center;
    border       : none;
    position     : relative;
    z-index      : 99;
    border       : 5px solid red;
    border-radius: 20px;
    font-weight  : 800;
  }
  .pos_abs {
    position: absolute !important;
  }
  .input_field {
    cursor   : pointer;
    min-width: 100px;
  }
  .options_button {
    cursor          : pointer;
    background-color: #6acfff;
    padding         : 1vh;
    font-size       : 20px;
    border-radius   : 20%;
  }
  .button_disabled {
    color : #a0a0a0 !important;
    cursor: not-allowed !important;
  }
  .buttons_area {
    position  : fixed;
    overflow  : hidden;
    top       : 0;
    width     : 98%;
    background: lightcyan;
    padding   : 1vh;
    z-index   : 100;
  }
  .center {
    position   : absolute;
    top        : 300px;
    left       : 650px;
    align-items: center;
  }
  .start_dot {
    cursor          : -webkit-grab;
    height          : 15px;
    width           : 15px;
    background-color: #f00;
    border-radius   : 50%;
    display         : none;
    position        : absolute;
    left            : 4.55em;
    top             : 1.7em;
    z-index         : 100;
  }
  .center:hover .start_dot {
    display: inline-block;
  }
  .start_dot:hover {
    border: 3px solid cornflowerblue;
  }
  .buttons_container {
    display        : flex;
    justify-content: space-between;
  }
  .header_logo {
    font-family    : fantasy;
    text-decoration: underline;
  }
  .scaling_area {
    position: fixed;
    top     : 4.4em;
    right   : 2em;
    z-index : 100;
  }
  .rich_text_area {
    position: fixed;
    top     : 4.4em;
    left    : 2em;
    z-index : 100;
  }
  #slideSection {
    overflow: hidden;
    height  : 100vh;
  }
  #attachment-modal /deep/ .sweet-modal {
    min-width: 800px;
    .sweet-content {
      padding-top   : 1.5em;
      padding-bottom: 2.5em;
    }
  }
  #attachment-modal /deep/ .ql-container {
    height    : 40vh;
    max-height: 40vh;
  }
  .node-description-tab {
    text-align : left;
    font-size  : 80%;
    border     : 1px solid #edeeef;
    padding    : 1em;
    line-height: 1.5;
    height     : 40vh;
    max-height : 40vh;
    overflow   : auto;
    p {
      margin-bottom: 0;
    }
  }
  .node-files-tab {
    height    : 40vh;
    max-height: 40vh;
    font-size : 80%;
  }
  .edit-icon {
    position        : absolute;
    top             : 88px;
    border-radius   : 50%;
    left            : 14px;
    font-size       : 0px;
    padding         : 10px;
    background-color: #edeeef;
    color           : #17a2b8;
    cursor          : pointer;
    i {
      font-size: 20px;
    }
  }
  .edit-icon:hover {
    i {
      font-size: 22px;
    }
  }
  .node-files-list {
    height  : 100%;
    border  : 1px solid #ccc;
    overflow: auto;
    
    .files-list {
      display        : flex;
      justify-content: space-between;
      width          : 100%;
      word-break     : break-word;
      &:hover {
        cursor    : pointer;
        font-size : 105%;
        box-shadow: 0 0.1em 0.2em rgba(0, 0, 0, 0.12);
      }
    }
    
    a {
      color: inherit;
      i {
        font-size: 18px;
      }
      &:hover {
        border-radius: 50%;
        color        : white;
      }
    }
    
    .files-name {
      display      : flow-root;
      white-space  : nowrap;
      width        : 24em;
      text-overflow: ellipsis;
      overflow     : hidden;
    }
    .remove-btn:hover {
      background-color: red;
    }
    .download-btn:hover {
      background-color: #17a2b8;
    }
    .empty-file-list {
      font-size : 15px;
      font-style: italic;
      padding   : 1em;
    }
  }
</style>
