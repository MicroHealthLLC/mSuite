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
          href="javascript:;"
          role="button" 
          class="d-flex zoom_btn text-info edit_delete_btn delete center_flex"
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
    <section v-if="!loading" id="map-container" @mousemove.prevent="doDrag" :style="C_scaleFactor">
      <div class="center" @click.stop="selectedNode=null" :style="C_centeralNodePosition">
        <span @mousedown="startDrag" class="start_dot"></span>
        <textarea type="text" ref="central_idea" @input="updateCentralIdea" v-model="centralIdea" class="central_idea pt-2" :style="centralIdeaStyle"/>
      </div>
      <input-field 
        v-for="node in currentMindMap.nodes" 
        v-if="!node.is_disabled && !node.hide_self"
        v-model="node.title" 
        :key="`${node.id}`" 
        :style="getNodeStyle(node)" 
        :is-selected="C_selectedNodeId === node.id"
        :quadrant="nodeQuadrant(node)"
        :has-child="hasChilNodes(node)"
        :hide-children="node.hide_children"
        @start-drag="startDrag($event, node)" 
        @mousedown-event="startDragNode($event, node)" 
        @node-updated="nodeUpdated(node)"
        @switch-expand-children="switchExpandChildren($event, node)"
        class="pos_abs input_field">
        </input-field>
      <canvas id="map-canvas" :width="windowWidth" :height="windowHeight"></canvas>
    </section>
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
          @click.stop="resetMindmapap" 
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
  </div>
</template>

<script>
  import InputField from './idea_input_field'
  import http from '../../common/http'
  import {SweetModal }from 'sweet-modal-vue'
  import _ from 'lodash'
  import html2canvas from 'html2canvas'

  export default {
    components: {InputField, SweetModal},
    data() {
      return {
        selectedNode: null,
        nodeParent: null,
        nodeColor: null,
        centralIdea: '',
        currentMindMap: {},
        loading: true,
        dragging: false,
        draggingNode: false,
        currentPositionX: 0,
        currentPositionY: 0,
        nodeOffsetX: 0,
        nodeOffsetY: 0,
        parent_x: 0,
        parent_y: 0,
        windowWidth: window.innerWidth,
        windowHeight: window.innerHeight,
        stopWatch: false,
        openMindMapKey: '',
        nodeUpdatedFlag: false,
        copiedNode: null,
        cutFlag: false,
        scaleFactor: 1,
        centralIdeaWidth: '10em',
        centralIdeaHeight: '3em'
      }
    },
    channels: {
      WebNotificationsChannel: {
        received(data) {
          this.getMindmap(this.currentMindMap.unique_key);
        },
      }
    },
    computed: {
      C_centeralNodePosition() {
        return {
          left: (Math.floor(this.windowWidth/2) - 120) +'px', 
          top: (Math.floor(this.windowHeight/2) - 40) +'px'
        }
      },
      C_selectedNodeId() {
        return this.selectedNode ? this.selectedNode.id : 0;
      },
      C_scaleFactor() {
        return {
          transform: "scale(" + this.scaleFactor + ")"
        }
      },
      centralIdeaStyle() {
        return {
          width: this.centralIdeaWidth,
          height: this.centralIdeaHeight
        }
      }
    },
    methods: {
      // =============== GETTING MAP =====================
      getMindmap(id) {
        http.get(`/mindmaps/${id}.json`).then((res) => {
          this.stopWatch = true;
          this.currentMindMap = res.data.mindmap;
          setTimeout(this.drawLines, 100);
          this.closeOpenMapModal();
          this.updateQuery();
          this.loading = false;
        }).catch((error) => {
          alert(`Mind map with id ${id} not found`);
          console.log(error);
        })
      },
      getNewMindmap() {
        http.get('/mindmaps/new.json').then((res) => {
          this.currentMindMap = res.data.mindmap;
          let query = {};
          this.$router.push({query: query});
          this.loading = false;
        }).catch((error) => {
          console.log(error);
          this.loading = false;
        })
      },
      // =============== GETTING MAP =====================

      // =============== MODALS OPEN/CLOSE/OPERATIONS =====================
      closeOpenMapModal() {
        this.openMindMapKey = '';
        this.$refs.openMapModal.close();
      },
      openPreviousMap() {
        this.getMindmap(this.openMindMapKey);
      },
      openNewMapNewWindow() {
        window.open(window.location.origin+'/mindmaps/new')
      },
      openNewMap() {
        this.removeLines();
        this.getNewMindmap();
        this.$refs.newMapModal.close()
      },
      // =============== MODALS OPEN/CLOSE/OPERATIONS =====================

      // =============== DRAGGING OPERATIONS =====================
      startDrag(event, p_node=null) {
        if (p_node) {
          this.nodeParent = p_node;
          this.nodeColor = p_node.line_color;
        } 
        else {
          this.nodeColor = this.getRandomColor();
        }
        this.dragging = true;
        this.parent_x = event.clientX;
        this.parent_y = event.clientY;
        let canvas_id = this.parent_x + "";
        if (!document.getElementById(canvas_id)) {
          var c = document.createElement('CANVAS');
          c.id = this.parent_x + "";
          document.getElementById('map-container').appendChild(c);
          c.style.position="absolute";
          c.style.top = 0;
          c.style.left = 0;
          c.width = this.windowWidth;
          c.height = this.windowHeight;
        }
        this.currentPositionX = this.currentPositionY = 0;
      },
      startDragNode(event, node) {
        this.selectedNode = node;
        this.nodeOffsetX = event.clientX - node.position_x;
        this.nodeOffsetY = event.clientY - node.position_y;
        this.draggingNode = true;
        this.currentPositionX = this.currentPositionY = 0;
      },
      doDrag(event) {
        if (this.dragging) {
          this.currentPositionX = event.clientX ;
          this.currentPositionY = event.clientY ;

          var c = document.getElementById(this.parent_x + "")
          var ctx = c.getContext("2d");
          ctx.clearRect(0, 0, c.width, c.height)
          ctx.beginPath();

          ctx.lineWidth = "8";
          ctx.lineCap = "round";
          ctx.strokeStyle = this.nodeColor;
          ctx.moveTo(this.parent_x, this.parent_y);
          ctx.lineTo(this.currentPositionX, this.currentPositionY);
          ctx.stroke();
        } else if (this.draggingNode) {
          this.nodeUpdatedFlag = true;
          let node = this.currentMindMap.nodes.findIndex((nod) => nod.id == this.selectedNode.id);
          this.currentMindMap.nodes[node].position_x = event.clientX - this.nodeOffsetX;
          this.currentMindMap.nodes[node].position_y = event.clientY - this.nodeOffsetY;
        }
      },
      stopDrag(event) {
        if (this.dragging) {
          this.dragging = false;
          this.draggingNode = false;

          // To prevent adding new input box if user clicks on red circle.
          this.removeLines();
          if (this.currentPositionX == 0 && this.currentPositionY == 0) {
            this.drawLines()
            return;
          }

          if ((this.windowWidth - this.currentPositionX) < 100) {
            this.currentPositionX -= 150;
          } else if (this.currentPositionX < 100) {
            this.currentPositionX += 100;
          }
          if ((this.windowHeight - this.currentPositionY) < 50) {
            this.currentPositionY -= 50;
          } else if (this.currentPositionY < 50) {
            this.currentPositionY += 50;
          }
          let node = {
            title: "New Idea",
            position_x: this.currentPositionX,
            position_y: this.currentPositionY,
            line_color: this.nodeColor,
            parent_node: this.nodeParent ? this.nodeParent.id : 0
          }
          this.selectedNode = null;
          this.createNode(node);
          // this.currentMindMap.nodes.push(node);
          this.currentPositionX = this.currentPositionY = 0;
          this.nodeParent = null;
          this.drawLines()
        } 
        if (this.draggingNode) {
          this.dragging = false;
          this.draggingNode = false;
          this.saveNode(this.selectedNode);
          this.removeLines();
          this.drawLines()
        }
      },
      // =============== DRAGGING OPERATIONS =====================

      // =============== STYLING OPERATIONS =====================
      getNodeStyle(node) {
        let p_node = this.currentMindMap.nodes.filter((n) => n.id == node.parent_node)[0];

        if (this.nodeQuadrant(node) == "LL") {
          if (p_node && p_node.position_x < node.position_x) {
            return {left: (node.position_x) + 'px', top: (node.position_y - 20) + 'px'}
          } else {
            return {left: (node.position_x - 100) + 'px', top: (node.position_y - 20) + 'px'}
          }
        } else if (this.nodeQuadrant(node) == "UL") {
          if (p_node && p_node.position_x < node.position_x) {
            return {left: (node.position_x) + 'px', top: (node.position_y - 20) + 'px'}
          } else {
            return {left: (node.position_x - 100) + 'px', top: (node.position_y - 20) + 'px'}
          }
        } else {
          return {left: node.position_x +'px', top: (node.position_y - 20) + 'px'}
        }
      },
      drawLines(retry_count=0) {
        if (document.getElementById("map-canvas") != null) {
          this.removeLines();
          var c = document.getElementById("map-canvas")
          if (!c) { return; }
          var ctx = c.getContext("2d");
          ctx.clearRect(0, 0, c.width, c.height)
          
          var CI = this;
          this.currentMindMap.nodes.forEach((nod) => {
            if (nod.is_disabled || nod.hide_self) { return }
            if(nod.line_color) {
              ctx.strokeStyle = nod.line_color;
            }
            else {
              ctx.strokeStyle = CI.nodeColor;
            }
            ctx.lineWidth = "5";
            ctx.lineCap = "round";
            ctx.beginPath();
            if (nod.parent_node == 0) {
              ctx.moveTo(Math.floor(CI.windowWidth/2) - 50, Math.floor(CI.windowHeight/2) - 15);
            } else {
              var p_node = CI.currentMindMap.nodes.filter((n) => n.id == nod.parent_node)[0];
              if (p_node) {
                if (this.nodeQuadrant(p_node) == "UL" || this.nodeQuadrant(p_node) == "LL") {
                  if (p_node.position_x > nod.position_x) {
                    ctx.moveTo(p_node.position_x - 95, p_node.position_y + 20);
                  } else {
                    ctx.moveTo(p_node.position_x + 5, p_node.position_y + 20);
                  }
                } else {
                  if (p_node.position_x < nod.position_x) {
                    ctx.moveTo(p_node.position_x + 100, p_node.position_y + 20);
                  } else {
                    ctx.moveTo(p_node.position_x + 5, p_node.position_y + 20);
                  }
                }
              }
            }
            ctx.lineTo(nod.position_x + 5, nod.position_y + 20);
            
            if (this.nodeQuadrant(nod) == "LL") {
              if (p_node && p_node.position_x < nod.position_x) {
                ctx.lineTo(nod.position_x + 100, nod.position_y + 20);
              } else {
                ctx.lineTo(nod.position_x - 100, nod.position_y + 20);
              }
            } else if (this.nodeQuadrant(nod) == "UL") {
              if (p_node && p_node.position_x < nod.position_x) {
                ctx.lineTo(nod.position_x + 100, nod.position_y + 20);
              } else {
                ctx.lineTo(nod.position_x - 100, nod.position_y + 20);
              }
            } else {
              ctx.lineTo(nod.position_x + 100, nod.position_y + 20);
            }
            ctx.stroke();
            ctx.closePath();
          })
        } else if (retry_count < 5) {
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
          var ctx = c.getContext("2d");
          ctx.clearRect(0, 0, c.width, c.height)

          ctx.lineWidth = "5";
          ctx.lineCap = "round";
          ctx.strokeStyle = "red";

          ctx.beginPath();
          if (node.parent_node == 0) {
            ctx.moveTo(Math.floor(this.windowWidth/2) - 50, Math.floor(this.windowHeight/2) - 15);
          } else {
            let p_nodes = this.currentMindMap.nodes.filter((n) => n.id == node.parent_node);

            // Getting only first parent here as We have single parent in phase 1.
            // only drawing of we find parent node.
            if (p_nodes[0]) {
              ctx.moveTo(p_nodes[0].position_x + 80, p_nodes[0].position_y + 17);
            }
          }
          ctx.lineTo(node.position_x + 80, node.position_y + 17);
          ctx.stroke();
          ctx.closePath();
      },
      // =============== STYLING OPERATIONS =====================


      // =============== Node CRUD OPERATIONS =====================
      cutSelectedNode() {
        if (!this.selectedNode) {return;}
        // if (this.hasChilNodes(this.selectedNode)) {
        //   alert("You cannot cut a node having child nodes for now, this functionality will be available soon.");
        //   return;
        // }
        this.copiedNode = this.selectedNode;
        this.copiedNode.is_disabled = true;
        this.cutFlag = true;
        http.put(`/nodes/${this.copiedNode.id}.json`, {node: this.copiedNode}).then((res) => {
          this.selectedNode = null;
        }).catch((error) => {
          console.log(error);
        })
      },
      copySelectedNode() {
        if (!this.selectedNode) {return;}
        // if (this.hasChilNodes(this.selectedNode)) {
        //   alert("You cannot copy a node having child nodes for now, this functionality will be available soon.");
        //   return;
        // }

        this.copiedNode = this.selectedNode;
      },
      pasteCopiedNode() {
        if (!this.copiedNode) {return;}
        let new_parent = 0;
        if (this.selectedNode) {
          new_parent = this.selectedNode.id;
        }
        
        let location = this.getNewPosition(new_parent);
        this.copiedNode.parent_node = new_parent;
        this.copiedNode.position_x = location[0];
        this.copiedNode.position_y = location[1];
        this.copiedNode.is_disabled = false;

        this.drawNewLine(this.copiedNode);

        if (this.cutFlag) {
          http.put(`/nodes/${this.copiedNode.id}.json`, {node: this.copiedNode}).then((res) => {
            this.getMindmap(this.currentMindMap.unique_key);
            this.cutFlag = false;
            this.copiedNode = null;
            this.selectedNode = res.data.node
          }).catch((error) => {
            console.log(error);
          })
        }
        else {
          http.post('/nodes.json', {node: this.copiedNode, duplicate_child_nodes: this.copiedNode.id}).then((res) => {
            this.getMindmap(this.currentMindMap.unique_key);
            this.copiedNode = null;
            this.selectedNode = null;
          }).catch((error) => {
            console.log(error);
          })
        }
      },
      saveNode(node) {
        if (this.nodeUpdatedFlag == false) { return; }
        if (!node || !node.id) { console.log("Unable to update node"); return; }

        this.nodeUpdatedFlag = false;
        let index = this.currentMindMap.nodes.findIndex((nod) => nod.id == node.id);
        if (index != -1) {
          node = this.currentMindMap.nodes[index]
          http.put(`/nodes/${node.id}.json`, {node: node}).then((res) => {
              this.currentMindMap.nodes.splice(index, 1, res.data.node);
          }).catch((error) => {
            console.log(error);
          })
        }
      },
      createNode(node) {
        this.drawNewLine(node);
        node['mindmap_id'] = this.currentMindMap.id;
        http.post('/nodes.json', {node: node}).then((res) => {
          this.getMindmap(this.currentMindMap.unique_key);
          this.selectedNode = res.data.node;
        }).catch((error) => {
          console.log(error);
        })
      },
      nodeUpdated(node) {
        this.nodeUpdatedFlag = true;
        this.saveNode(node);
      },
      deleteSelectedNode(is_cut=false) {
        if (!this.selectedNode || !this.selectedNode.id) { return; }

        http.delete(`/nodes/${this.selectedNode.id}.json`).then((res) => {
          if (res.data.success) {
            this.selectedNode = null;
            this.getMindmap(this.currentMindMap.unique_key);
          } else {
            console.log("Unable to delete node");
          }
        }).catch((error) => {
          console.log(error);
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
            this.stopWatch = true;
            this.currentMindMap = res.data.mindmap;
            this.selectedNode = null;
            this.updateQuery();
          }).catch((error) => {
            console.log(error)
          })
        } else {
          http.post(`/mindmaps.json`, {mindmap: this.currentMindMap}).then((res) => {
            this.stopWatch = true;
            this.currentMindMap = res.data.mindmap;
            this.selectedNode = null;
            this.updateQuery();
          }).catch((error) => {
            console.log(error)
          })
        }
      },
      resetMindmapap() {
        this.selectedNode = null;
        this.deletAllNodes(this.currentMindMap.nodes);
        this.stopWatch = true;
        this.currentMindMap.name = "Central Idea";
        this.removeLines();
        setTimeout(this.saveCurrentMap, 500)
        this.$refs.resetMapModal.close();
      },
      // =============== Map CRUD OPERATIONS =====================

      // =============== OTHERS =====================
      updateQuery() {
        let query = {};
        query['key'] = this.currentMindMap.unique_key;
        this.$router.push({query: query});
      },
      updateCentralIdea: _.debounce(
        function(input) {
          this.currentMindMap.name = this.$refs.central_idea.value;
        },
        500
      ),
      hasChilNodes(node) {
        return this.currentMindMap.nodes.filter((nod) => nod.parent_node == node.id).length > 0;
      },
      getNewPosition(new_parent) {
        let new_location = [0, 0];

        if (new_parent) {
          let new_p = this.currentMindMap.nodes.filter((nod) => nod.id == new_parent)[0];
          new_location = [new_p.position_x, new_p.position_y - 100];

          for (;;) {
            if (new_location[1] < 50) {
              new_location[1] += 50;
            } else {
              break;
            }
          }
        } else {
          new_location[0] = Math.floor(this.windowWidth/2);
          new_location[1] = Math.floor(this.windowHeight/2) - 100;
        }

        return new_location;
      },
      goHome() {
        window.open("/","_self");
      },
      nodeQuadrant(node) {
        let center_x = Math.floor(this.windowWidth/2);
        let center_y = Math.floor(this.windowHeight/2);

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
          alert("There was an error while collapsing/expanding child nodes.");
          console.log(error);
        })
      },
      // =============== OTHERS =====================
      getRandomColor() {
        let letters = '0123456789ABCDEF'
        let color = '#'
        for (let i=0; i<6; i++) {
          color += letters[Math.floor(Math.random() * 16)]
        }
        return color
      },
      // =============== SCALING ====================
      transformScale(event) {
        if (event.deltaY < 0) {
          if (this.scaleFactor < 2) {
            this.scaleFactor = this.scaleFactor + 0.1
          } 
        }
        else if (event.deltaY > 0) {
          if (this.scaleFactor > 0.4) {
            this.scaleFactor = this.scaleFactor - 0.1
          }
        }
      },
      exportToImage(event) {
        let expBtn = this.$refs.exportBtn
        let elm = document.getElementById("map-container")
        elm.style.transform = "scale(1)"
        html2canvas(elm).then((canvas) => {
          expBtn.download = this.currentMindMap.unique_key + ".png"
          expBtn.href = canvas.toDataURL("image/png").replace(/^data:image\/[^;]/, 'data:application/octet-stream')
        })
        elm.style.transform = "scale(" + this.scaleFactor +")"
        expBtn.blur()
      }, 
      zoomInScale() {
        if (this.scaleFactor < 2) {
          this.scaleFactor = this.scaleFactor + 0.1
        }
      },
      zoomOutScale() {
        if (this.scaleFactor > 0.4) {
          this.scaleFactor = this.scaleFactor - 0.1
        }
      }
    },
    mounted() {
      if (this.$route.query.key) {
        this.getMindmap(this.$route.query.key)
      } else {
        this.getNewMindmap();
      }
      window.addEventListener('mouseup', this.stopDrag);
      window.addEventListener('wheel', this.transformScale);
    },
    watch: {
      "currentMindMap.id"() {
        if (this.currentMindMap.id) {
          this.$cable.subscribe({ channel: 'WebNotificationsChannel', room: this.currentMindMap.id});
        }
      },
      "currentMindMap.name": {
        handler: function(new_map) {
          this.centralIdea = this.currentMindMap.name;
          if (this.stopWatch) { 
            this.stopWatch = false;
            return; 
          }
          this.saveCurrentMap();
        },
        deep: true
      },
      centralIdea(value) {
        let dheight = Math.ceil(value.length / 15)
        dheight = dheight > 1 ? dheight*2 : 3
        this.centralIdeaHeight = dheight > 8 ? "8em" : dheight + "em" 
      }
    }
  }
</script>

<style scoped lang="scss">
  #map-container {
    transform: scale(0.6);
  }
  .central_idea {
    text-align: center;
    border: none;
    border: 5px solid red;
    border-radius: 20px;
    font-weight: 800;
  }
  .pos_abs {
    position: absolute !important;
  }
  .input_field {
    cursor: pointer;
    min-width: 100px;
  }
  .options_button {
    cursor: pointer;
    background-color: #6acfff;
    padding: 1vh;
    font-size: 20px;
    border-radius: 20%;
  }
  .button_disabled {
    color: #a0a0a0 !important;
    cursor: not-allowed !important;
  }
  .buttons_area {
    position: fixed;
    overflow: hidden;
    top: 0;
    width: 98%;
    background: lightcyan;
    padding: 1vh;
    z-index: 100;
  }
  .center {
    position: absolute;
    top: 300px;
    left: 650px;
    align-items: center;
    z-index: 100;
  }
  .start_dot {
    cursor: -webkit-grab;
    height: 15px;
    width: 15px;
    background-color: #f00;
    border-radius: 50%;
    display: inline-block;
    position: absolute;
    left: 4.55em;
    top: 0.7em;
  }
  .start_dot:hover {
    border: 10px solid cornflowerblue;
  }
  .buttons_container {
    display: flex;
    justify-content: space-between;
  }
  .header_logo {
    font-family: fantasy;
    text-decoration: underline;
  }
  .scaling_area {
    position: fixed;
    top: 4.4em;
    right: 2em;
    z-index: 100;
  }
</style>
