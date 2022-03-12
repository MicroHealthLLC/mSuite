<template>
  <div>
    <navigation-bar
      v-if="isMounted"
      @mSuiteTitleUpdate="mSuiteTitleUpdate"
      @openPrivacy="openPrivacy"
      @deleteMindmap="deleteMap"
      :current-mind-map="currentMindMap"
      :defaultDeleteDays="defaultDeleteDays"
      :deleteAfter="deleteAfter"
      :exportId="'vue_canvas'"
      ref="whiteBoardNavigation">
    </navigation-bar>
    <div class="row">
      <div class="col-1 px-0 sidebar">
        <div class="rounded-0 pl-1 btn whiteboard-btns border pointer d-flex" :class="isDrawing ? 'active':''" @click="toggleDrawing">
          <span class="material-icons">
            edit
          </span>
          <span class="ml-1">Pencil</span>
        </div>
        <div class="rounded-0 pl-1 btn whiteboard-btns border pointer d-flex" @mouseover="increaseIcon = true" @mouseleave="increaseIcon = false" @click="increaseStroke">
          <span class="material-icons">
            line_weight
          </span>
          <span class="ml-1" v-show="!increaseIcon">Increase</span>
          <span class="ml-1" v-show="increaseIcon">{{line}}</span>
        </div>
        <div class="rounded-0 pl-1 btn whiteboard-btns border pointer d-flex" @click="decreaseStroke" @mouseover="decreaseIcon = true" @mouseleave="decreaseIcon = false" >
          <span class="material-icons rotate-180">
            line_weight
          </span>
          <span class="ml-1" v-show="!decreaseIcon">Decrease</span>
          <span class="ml-1" v-show="decreaseIcon">{{line}}</span>
        </div>
        <div @click="showColorPicker" class="rounded-0 pl-1 btn whiteboard-btns border pointer d-flex">
          <span class="material-icons">
            colorize
          </span>
          <span class="ml-1">Color</span>
        </div>
        <div @click="deleteModal" class="rounded-0 pl-1 btn whiteboard-btns border pointer d-flex" :class="eraser ? 'active':''">
          <span class="material-icons">
            delete
          </span>
          <span class="ml-1">Erase</span>
        </div>
        <div @click="addCircleToCanvas" class="rounded-0 pl-1 btn whiteboard-btns border pointer d-flex">
          <span class="material-icons">
            panorama_fish_eye
          </span>
          <span class="ml-1">Circle</span>
        </div>
        <div @click="addTriangleToCanvas" class="rounded-0 pl-1 btn whiteboard-btns border pointer d-flex">
          <span class="material-icons">
            change_history
          </span>
          <span class="ml-1">Triangle</span>
        </div>
        <div @click="addRectToCanvas" class="rounded-0 pl-1 btn whiteboard-btns border pointer d-flex">
          <span class="material-icons">
            crop_16_9
          </span>
          <span class="ml-1">Rectangle</span>
        </div>
        <div @click="addTextToCanvas" class="rounded-0 pl-1 btn whiteboard-btns border pointer d-flex">
          <span class="material-icons">
            rtt
          </span>
          <span class="ml-1">Text</span>
        </div>
        <div @click="redoCanvas" class="rounded-0 pl-1 btn whiteboard-btns border pointer d-flex">
          <span class="material-icons">
            redo
          </span>
          <span class="ml-1">Redo</span>
        </div>
        <div @click="undoCanvas" class="rounded-0 pl-1 btn whiteboard-btns border pointer d-flex">
          <span class="material-icons">
            undo
          </span>
          <span class="ml-1">Undo</span>
        </div>
        <div @click="resetModal" class="rounded-0 pl-1 btn btn-danger border pointer d-flex">
          <span class="material-icons">
            restart_alt
          </span>
          <span class="ml-1">Reset</span>
        </div>
      </div>
      <div id="vue_canvas" class="col-11 p-0 m-0 font-serif">
        <canvas id="canvas" class="border"></canvas>
      </div>
      <div v-if="colorSelected">
          <div class="card col-3 p-0 border-none color-picker-placement">
            <div class="card-body p-0">
              <chrome-picker @input="beforeUpdateColor" v-model="colorPicker"/>
            </div>
            <div class="card-button d-flex">
              <button class="btn btn-success w-50 border-none" @click="updateColor">Update</button>
              <button class="btn btn-info w-50 border-none" @click="cancelUpdateColor">Cancel</button>
            </div>
          </div>
      </div>
    </div>
    <make-private-modal ref="make-private-modal" @password-apply="passwordProtect" @password_mismatched="$refs['passwordMismatched'].open()" :password="currentMindMap.password" :isSaveMSuite="isSaveMSuite"></make-private-modal>
    <delete-map-modal ref="delete-map-modal" @delete-mindmap="confirmDeleteMindmap"></delete-map-modal>
    <delete-password-modal ref="delete-password-modal" @deletePasswordCheck="deleteMindmapProtected"></delete-password-modal>
    <confirm-save-key-modal ref="confirm-save-key-modal" :current-mind-map="currentMindMap"></confirm-save-key-modal>
    <sweet-modal ref="passwordMismatched" class="of_v" icon="error" title="Password Mismatch">
      Your Password and Confirm Password are Mismatched, Please Try Again!
      <button slot="button" @click="passwordAgain" class="btn btn-warning mr-2">Try Again</button>
      <button slot="button" @click="$refs['passwordMismatched'].close()" class="btn btn-secondary">Cancel</button>
    </sweet-modal>
    <sweet-modal ref="errorModal" class="of_v" icon="error" title="Password Error">
      Incorrect Password, Please Try Again!
    </sweet-modal>
    <sweet-modal ref="successModal" class="of_v" icon="success">
      Password updated successfully!
    </sweet-modal>
    <sweet-modal ref="resetModal" class="of_v" icon="warning">
      Are you sure, You want to reset your whiteboard?
        <button slot="button" @click="resetMap" class="btn btn-warning mr-2">Yes</button>
        <button slot="button" @click="$refs['resetModal'].close()" class="btn btn-secondary">Cancel</button>
    </sweet-modal>
  </div>
</template>
<script>
  import http from "../../common/http"
  import { jsPDF } from "jspdf";
  import html2canvas from "html2canvas"
  import domtoimage from "dom-to-image-more"
  import DeleteMapModal from '../../common/modals/delete_modal';
  import MakePrivateModal from "../../common/modals/make_private_modal"
  import DeletePasswordModal from '../../common/modals/delete_password_modal';
  import { fabric } from 'fabric';
  import 'fabric-history';

  export default {
    props: ['whiteboardImage'],
    data() {
      return {
        isMounted: false,
        line: 5,
        color: "#AADDCC",
        image: "",
        defaultDeleteDays: '',
        colorPicker: "#000000",
        colorSelected: false,
        increaseIcon: false,
        decreaseIcon: false,
        mousePressed: false,
        isDrawing: false,
        currentMindMap: {},
        initialImage: [],
        eraser: false,
        keyUpTimeOut: null,
        deleteAfter: '',
        saveData: true,
        isRest: false,
        isSaveMSuite: false
      }
    },
    components: {
      fabric,
      DeleteMapModal,
      DeletePasswordModal,
      MakePrivateModal
    },
    channels: {
      WebNotificationsChannel: {
        received(data) {
          if (data.message === "Mindmap Deleted" && this.currentMindMap.id === data.mindmap.id)
          {
            window.open('/','_self')
          } else if (data.message === "Password Updated" && this.currentMindMap.id === data.mindmap.id) {
            setTimeout(() => {
              location.reload()
            }, 500)
          } else {
            this.initialImage = JSON.parse(data.mindmap.image)
            this.canvas.loadFromJSON(this.initialImage);
            this.canvas.renderAll();
          }
        }
      }
    },
    methods: {
      getMindmap(id) {
        http
        .get(`/msuite/${id}.json`)
        .then((res) => {
          this.defaultDeleteDays = res.data.defaultDeleteDays
          this.deleteAfter = res.data.deleteAfter
          this.currentMindMap = res.data.mindmap
          this.isMounted = true
          this.$cable.subscribe({ channel:"WebNotificationsChannel", room: this.currentMindMap.id })
        })
      },
      openPrivacy(val) {
        this.isSaveMSuite = val
        this.$refs['make-private-modal'].$refs['makePrivateModal'].open()
      },
      deleteMap() {
        this.$refs['delete-map-modal'].$refs['deleteMapModal'].open()
      },
      confirmDeleteMindmap() {
        if (this.currentMindMap.password){
          this.$refs['delete-password-modal'].$refs['DeletePasswordModal'].open()
        } else {
          this.deleteMindmap()
        }
      },
      deleteMindmapProtected(password) {
        http
        .delete(`/msuite/${this.currentMindMap.unique_key}.json?password_check=${password}`)
        .then(res=>{
          if (!res.data.success && this.currentMindMap.password)
            this.$refs['errorModal'].open()
        })
        .catch(error => {
          console.log(error)
        })
      },
      deleteMindmap() {
        http
        .delete(`/msuite/${this.currentMindMap.unique_key}.json`)
        .then(res => {
          window.open("/", "_self")
        })
        .catch(error => {
          console.log(error)
        })
      },
      passwordProtect(new_password, old_password, is_mSuite) {
        http
        .patch(`/msuite/${this.currentMindMap.unique_key}.json`,{mindmap:{password: new_password, old_password: old_password}})
        .then(res => {
          if (res.data.mindmap) {
            this.currentMindMap.password = res.data.mindmap.password
            if(!is_mSuite) window.open("/", "_self")
            else location.reload()
            this.$refs['successModal'].open()
          } else {
            if (res.data.error) this.$refs['errorModal'].open()
          }
        })
      },
      passwordAgain() {
        this.$refs['passwordMismatched'].close()
        this.openPrivacy()
      },
      addRectToCanvas() {
        this.toggleResetDraw();
        this.rect = new fabric.Rect({
          left: 70,
          top: 70,
          fill:  "#ffffff",
          stroke: this.color,
          width: 125,
          height: 75,
          strokeWidth: this.line,
          opacity: .8
        });
        this.canvas.add(this.rect);
        this.canvas.setActiveObject(this.rect)
      },
      addCircleToCanvas() {
        this.toggleResetDraw();
        this.circle = new fabric.Circle({
          left: 70,
          top: 70,
          radius: 50,
          fill: "#ffffff",
          stroke: this.color,
          width: 100,
          height: 100,
          strokeWidth: this.line,
          opacity: .8
        });
        this.canvas.add(this.circle);
        this.canvas.setActiveObject(this.circle)
      },
      addTextToCanvas() {
        this.toggleResetDraw();
        this.text = new fabric.IText('Tap and Type', {
          left: 70,
          top: 70,
          fontFamily: 'sans-serif',
          fill: this.color
        })
        this.canvas.add(this.text);
        this.canvas.setActiveObject(this.text)
      },
      addTriangleToCanvas() {
        this.toggleResetDraw();
        this.triangle = new fabric.Triangle({
          left: 90,
          top: 70,
          fill:  "#ffffff",
          stroke: this.color,
          width: 100,
          height: 100,
          strokeWidth: this.line,
          opacity: .8,
        })
        this.canvas.add(this.triangle);
        this.canvas.setActiveObject(this.triangle)
      },
      beforeUpdateColor(){
        this.toggleResetDraw();
        if(this.activeObject.type == 'i-text') this.activeObject.set("fill", this.colorPicker.hex8);
        else this.activeObject.set("stroke", this.colorPicker.hex8);
        this.saveData = false
        this.canvas.renderAll();
      },
      updateColor() {
        this.toggleResetDraw();
        this.color = this.colorPicker.hex8
        this.saveData = true
        this.colorSelected = false
      },
      cancelUpdateColor(){
        this.colorSelected = false
        http
        .get(`/msuite/${this.$route.params.key}.json`)
        .then((res) => {
          this.initialImage = JSON.parse(res.data.mindmap.image)
          this.canvas.loadFromJSON(this.initialImage);
          this.canvas.renderAll();
        })
      },
      undoCanvas() {
        this.toggleResetDraw();
        this.canvas.undo();
      },
      redoCanvas() {
        this.toggleResetDraw();
        this.canvas.redo();
      },
      deleteModal() {
        if (this.eraser) {
          this.eraser = false;
          this.isDrawing = false;
          this.canvas.isDrawingMode = false;
        } else {
          this.eraser = true;
          this.isDrawing= false;
          this.canvas.isDrawingMode = false;
          this.canvas.hoverCursor = 'grab';
        }
      },
      resetModal() {
        this.$refs['resetModal'].open();
      },
      resetMap() {
        this.isRest = true
        let mindmap = { mindmap: { image: '{"version":"4.6.0","objects":[]}' } }
        let id = this.currentMindMap.unique_key
        http.patch(`/msuite/${id}.json`,mindmap)
        this.$refs['resetModal'].close()
      },
      increaseStroke() {
        clearTimeout(this.keyUpTimeOut)
        this.line < 25 ? ++this.line : ''
        this.canvas.freeDrawingBrush.width = this.line;
        if(this.activeObject){
          this.activeObject.set("strokeWidth", this.line)
          this.canvas.renderAll()
          this.keyUpTimeOut = setTimeout(() => {
            this.updateWhiteBoard(JSON.stringify(this.canvas.toJSON()));
          }, 2000)
        }
      },
      decreaseStroke() {
        clearTimeout(this.keyUpTimeOut)
        this.line > 1 ? --this.line : ''
        this.canvas.freeDrawingBrush.width = this.line;
        if(this.activeObject){
          this.activeObject.set("strokeWidth", this.line)
          this.canvas.renderAll()
          this.keyUpTimeOut = setTimeout(() => {
            this.updateWhiteBoard(JSON.stringify(this.canvas.toJSON()));
          }, 2000)
        }
      },
      toggleResetDraw() {
        this.canvas.isDrawingMode = false;
        this.isDrawing = false;
        this.eraser = false;
        this.canvas.hoverCursor = 'auto';
      },
      toggleDrawing() {
        if (this.isDrawing) {
          this.isDrawing = false;
          this.canvas.isDrawingMode = false;
          this.eraser = false;
          this.canvas.renderAll();
        } else {
          this.isDrawing = true;
          this.canvas.freeDrawingBrush.color = this.color;
          this.canvas.freeDrawingBrush.width = this.line;
          this.canvas.isDrawingMode = true;
          this.eraser = false;
          this.canvas.renderAll();
        }
      },
      showColorPicker() {
        if(this.activeObject.type == 'i-text') this.colorPicker = this.activeObject.fill
        this.colorSelected = !this.colorSelected
      },
      mouseEvents() {
        let _this = this
        this.canvas.on('mouse:down:before', (event) => {
          _this.mousePressed = true;
        })
        this.canvas.on('mouse:down', (event) => {
          if(_this.colorSelected) this.cancelUpdateColor()
          if (_this.eraser) {
            var activeObject = this.canvas.getActiveObject();
            if (activeObject) {
              _this.canvas.remove(activeObject);
            }
          }
        })
        this.canvas.on('mouse:up', (event) => {
          this.canvas.setActiveObject(event.currentTarget)
          _this.mousePressed = false
        })
        this.canvas.on('selection:created', (event) => {
          this.activeObject = this.canvas.getActiveObject();
          this.line = this.activeObject.strokeWidth
          this.colorPicker = this.activeObject.stroke
          this.canvas.renderAll();
        })
        this.canvas.on('selection:cleared', (event) => {
          if(this.saveData) this.updateWhiteBoard(JSON.stringify(this.canvas.toJSON()));
        })
        this.canvas.on('selection:updated', (event) => {
          if(this.saveData) this.updateWhiteBoard(JSON.stringify(this.canvas.toJSON()));
        })
      },
      updateWhiteBoard(obj) {
        let mindmap = { mindmap: { image: obj } }
        let id = this.currentMindMap.unique_key
        if(!this.isRest) http.patch(`/msuite/${id}.json`,mindmap)
        else this.isRest = false
      }
    },
    mounted() {
      if (this.$route.params.key) {
        this.getMindmap(this.$route.params.key)
        var canvas2 = document.getElementsByTagName('canvas')[0];
        canvas2.width = $(document).width() - 140;
        canvas2.height = $(document).height() - 75;
      }
      this.canvas = new fabric.Canvas('canvas',{
        selection: false
      });
      this.mouseEvents();
      this.canvas.renderAll();
      this.initialImage = JSON.parse(this.whiteboardImage)
      if (this.initialImage) {
        this.canvas.loadFromJSON(this.initialImage);
        this.canvas.renderAll();
      }
    }
  }
</script>

<style>
  #canvas {
    background-color: white;
  }
  .rotate-180 {
    transform: rotate(180deg);
  }
  .sidebar {
    height: 80vh;
  }
  .whiteboard-btns:hover{
    background-color: #091e4214;
    color: #172b4d;
  }
</style>
