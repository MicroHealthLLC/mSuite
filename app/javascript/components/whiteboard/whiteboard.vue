<template>
  <div>
    <navigation-bar
      v-if="isMounted"
      @mSuiteTitleUpdate="mSuiteTitleUpdate"
      @openPrivacy="openPrivacy"
      @deleteMindmap="deleteMap"
      @updateWhiteBoard="updateWhiteBoard"
      :current-mind-map="currentMindMap"
      :defaultDeleteDays="defaultDeleteDays"
      :expDays="expDays"
      :deleteAfter="deleteAfter"
      @resetMindmap="resetMindmap"
      :exportId="'vue_canvas'"
      ref="whiteBoardNavigation">
    </navigation-bar>
    <div class="row">
      <div class="col-1 px-0 sidebar">
        <div class="rounded-0 pl-1 btn whiteboard-btns border pointer d-flex" :class="isDrawing && !eraser ? 'active':''" @click="toggleDrawing">
          <span class="material-icons">
            edit
          </span>
          <span class="ml-1">Pencil</span>
        </div>
        <div class="rounded-0 pl-1 btn whiteboard-btns border pointer d-flex" :class="drawLine ? 'active':''" @click="toggleDrawLine">
          <span class="material-icons">horizontal_rule</span>
          <span class="ml-1">Line</span>
        </div>
        <div class="rounded-0 pl-1 btn whiteboard-btns border pointer d-flex" :class="createSelection ? 'active':''" @click="toggleCreateSelection">
          <span class="material-icons">pan_tool</span>
          <span class="ml-1">Select</span>
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
        <div @click="bringForward" class="rounded-0 pl-1 btn whiteboard-btns border pointer d-flex">
          <span class="material-icons">
            arrow_outward
          </span>
          <span class="ml-1">Forward</span>
        </div>
        <div @click="sendBackward" class="rounded-0 pl-1 btn whiteboard-btns border pointer d-flex">
          <span class="material-icons rotate-180">
            arrow_outward
          </span>
          <span class="ml-1">Backward</span>
        </div>
      </div>
      <div id="vue_canvas" class="col-11 p-0 m-0 font-serif">
        <canvas id="canvas" class="border"></canvas>
      </div>
      <div v-if="colorSelected">
          <div class="card p-0 border-none color-picker-placement">
            <div class="card-body p-0">
              <sketch-picker @input="beforeUpdateColor" :preset-colors="uniqueColors" v-model="colorPicker"/>
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
  import Common from "../../mixins/common.js"

  import { fabric } from './fabric.js'
  import 'fabric-history';

  export default {
    props: ['whiteboardImage'],
    mixins: [Common],
    data() {
      return {
        isMounted: false,
        line: 5,
        color: "#AADDCC",
        mapColors: [],
        image: "",
        expDays: '',
        defaultDeleteDays: '',
        colorPicker: "#000000",
        colorSelected: false,
        points: [],
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
        isSaveMSuite: false,
        isPencil: false,
        addObj: false,
        newObj: false,
        drawLine: false,
        createSelection: false,
        oldColor: '',
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
          } else if(data.message === "Mindmap Updated" && this.currentMindMap.id === data.mindmap.id){
            this.currentMindMap = data.mindmap
            this.initialImage = data.mindmap.canvas
            this.mapColors = []
            this.color = "#AADDCC"
            JSON.parse(this.initialImage).objects.forEach((x, i) => {
              this.mapColors.push(x.stroke)
            })
            this.colorSelected = false
            this.canvas.loadFromJSON(this.initialImage);
            this.canvas.renderAll();
            this.createSelection = false
          }
        }
      }
    },
    computed: {
      uniqueColors(){
        return this.getUniqueColors(this.mapColors);
      }
    },
    methods: {
      getMindmap(id) {
        http
        .get(`/msuite/${id}.json`)
        .then((res) => {
          this.expDays = res.data.expDays
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
        this.createSelection = true;
        this.addObj = true;
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
        this.newObj = true
        this.rect.set('erasable',true)
        this.canvas.add(this.rect);
        this.canvas.setActiveObject(this.rect)
      },
      addCircleToCanvas() {
        this.toggleResetDraw();
        this.createSelection = true;
        this.addObj = true;
        this.newObj = true
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
        this.createSelection = true;
        this.text = new fabric.IText('Tap and Type', {
          left: 70,
          top: 70,
          fontFamily: 'sans-serif',
          fill: this.color
        })
        this.newObj = true
        this.canvas.add(this.text);
        this.canvas.setActiveObject(this.text)
      },
      addTriangleToCanvas() {
        this.newObj = true
        this.toggleResetDraw();
        this.createSelection = true;
        this.addObj = true;
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
      straightLine(){
        const myPoints = Object.values(this.points);
        this.stLine = new fabric.Line(myPoints, {
            strokeWidth: this.line,
            fill: this.color,
            stroke: this.color,
            originX: 'center',
            originY: 'center'
        });
        this.canvas.add(this.stLine);
      },
      beforeUpdateColor(){
        this.toggleResetDraw();
        if(this.activeObject.type == 'i-text') this.activeObject.set("fill", this.colorPicker.hex8);
        else this.activeObject.set("stroke", this.colorPicker.hex8);
        this.saveData = false
        this.canvas.renderAll();
      },
      updateColor() {
        this.color = this.colorPicker.hex8
        this.saveData = true
        this.colorSelected = false
        this.mapColors.push(this.color)
      },
      cancelUpdateColor(){
        this.colorSelected = false
        this.activeObject.set("stroke", this.oldColor);
        this.color = this.oldColor
        this.canvas.renderAll();
      },
      undoCanvas() {
        this.toggleResetDraw();
        this.canvas.undo();
      },
      bringForward(){
        this.canvas.bringForward(this.canvas.getActiveObject())
        this.updateWhiteBoard(JSON.stringify(this.canvas.toJSON()));
      },
      sendBackward(){
        this.canvas.sendBackwards(this.canvas.getActiveObject())
        this.updateWhiteBoard(JSON.stringify(this.canvas.toJSON()));
      },
      redoCanvas() {
        this.toggleResetDraw();
        this.canvas.redo();
      },
      deleteModal() {
        if(this.eraser) {
          this.eraser = false;
          $('.upper-canvas').removeClass('eraserCursor')
          this.updateWhiteBoard(JSON.stringify(this.canvas.toJSON()));
        }
        else this.eraser = true;
        let activeObject = this.canvas.getActiveObject();
        if (activeObject) {
          this.canvas.remove(activeObject);
          this.eraser = false;
          this.isDrawing = false;
          this.canvas.isDrawingMode = false;
        } else {
          this.toggleDrawing()
          this.canvas.hoverCursor = 'grab';
        }
      },
      resetModal() {
        this.$refs['resetModal'].open();
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
        this.drawLine = false;
        this.canvas.hoverCursor = 'auto';
        $('.upper-canvas').removeClass('eraserCursor')

      },
      toggleDrawLine() {
        this.createSelection = false;
        this.isDrawing = false;
        this.eraser = false;
        this.canvas.isDrawingMode = false;
        if(this.drawLine) this.drawLine = false
        else this.drawLine = true
        $('.upper-canvas').removeClass('eraserCursor')
      },
      toggleDrawing() {
        this.createSelection = false;
        this.drawLine = false
        if (this.isDrawing) {
          this.isDrawing = false;
          this.canvas.isDrawingMode = false;
          this.canvas.renderAll();
        } else {
          this.isDrawing = true;
          if(this.eraser) {
            this.createSelection = false
            this.canvas.freeDrawingBrush = new fabric.EraserBrush(this.canvas);
            this.canvas.isDrawingMode = true;
            $('.upper-canvas').addClass('eraserCursor')
          } else if(this.isDrawing && !this.drawLine) {
            this.canvas.freeDrawingBrush = new fabric.PencilBrush(this.canvas);
            this.canvas.freeDrawingBrush.color = this.color;
            this.isPencil = true
          }
          this.canvas.freeDrawingBrush.width = this.line;
          this.canvas.isDrawingMode = true;
          this.canvas.renderAll();
        }
      },
      toggleCreateSelection(){
        if(this.createSelection){
          this.createSelection = false
          this.updateWhiteBoard(JSON.stringify(this.canvas.toJSON()))
        } else {
          this.createSelection = true
          this.eraser = false
          this.isDrawing = false
          this.drawLine = false
          this.canvas.isDrawingMode = false
          $('.upper-canvas').removeClass('eraserCursor')
        }
      },
      showColorPicker() {
        if(this.activeObject.type == 'i-text') this.colorPicker = this.activeObject.fill
        if(this.canvas.getActiveObject()) this.colorSelected = true
      },
      mouseEvents() {
        let _this = this
        this.canvas.on('mouse:down:before', (event) => {
          _this.mousePressed = true;
          _this.addObj = false;
        })
        this.canvas.on('mouse:move', (event) => {
          if(!_this.createSelection && _this.canvas.getActiveObject()) _this.canvas.discardActiveObject()
          if(!this.drawLine) return

          this.pointer = this.canvas.getPointer(event.e);
          this.stLine.set({ x2: this.pointer.x, y2: this.pointer.y });
          this.canvas.renderAll();
        })
        this.canvas.on('mouse:down', (event) => {
          if(_this.colorSelected) this.cancelUpdateColor()
          if (_this.eraser) {
            var activeObject = this.canvas.getActiveObject();
            if (activeObject) {
              this.canvas.setActiveObject(activeObject)
            }
          }
          if (this.drawLine) {
            const mousePos = canvas.getBoundingClientRect();

            const x1 = Math.round(event.e.clientX - mousePos.left);
            const y1 = Math.round(event.e.clientY - mousePos.top);

            this.points = [ x1, y1, x1, y1 ]
            this.straightLine()
          }
        })
        this.canvas.on('mouse:up', (event) => {
          if(this.isDrawing) {
            this.newObj = true
            this.canvas.setActiveObject(event.currentTarget)
          }
          if(this.drawLine) {
            this.newObj = true
            this.canvas.setActiveObject(this.stLine)
          }
          this.isStraightLine = false;
          this.mousePressed = false
          if(this.eraser){
            this.updateWhiteBoard(JSON.stringify(this.canvas.toJSON()))
          }
          if(this.drawLine) {
            this.updateWhiteBoard(JSON.stringify(this.canvas.toJSON()))
          }
        })
        this.canvas.on('selection:created', (event) => {
          this.drawLine = false
          if(!this.eraser) this.createSelection = true
          if(this.isDrawing && !this.eraser) this.canvas.isDrawingMode = false
          this.isDrawing = false;
          this.activeObject = this.canvas.getActiveObject();
          this.oldColor = this.activeObject.stroke
          if(this.activeObject) {
            this.line = this.activeObject.strokeWidth
            this.colorPicker = this.activeObject.stroke}
          this.canvas.renderAll();
        })
        this.canvas.on('selection:cleared', (event) => {
          if(this.saveData && !_this.addObj) this.updateWhiteBoard(JSON.stringify(this.canvas.toJSON()));
          else if(!this.colorSelected) this.updateWhiteBoard(JSON.stringify(this.canvas.toJSON()));
        })
        this.canvas.on('selection:updated', (event) => {

          this.drawLine = false
          if(!this.eraser) this.createSelection = true
          if(this.isDrawing && !this.eraser) this.canvas.isDrawingMode = false
          this.isDrawing = false;
          this.activeObject = this.canvas.getActiveObject();
          if(this.activeObject) {
            this.line = this.activeObject.strokeWidth
            this.colorPicker = this.activeObject.stroke}
          this.canvas.renderAll();
          if(this.saveData && !_this.addObj) this.updateWhiteBoard(JSON.stringify(this.canvas.toJSON()));
          else if(!this.colorSelected) this.updateWhiteBoard(JSON.stringify(this.canvas.toJSON()));
        })
      },
      updateWhiteBoard(obj) {
        if(obj == undefined){
          obj = JSON.stringify(this.canvas.toJSON())
        }
        let mindmap = { mindmap: { canvas: obj } }
        let id = this.currentMindMap.unique_key
        if(!this.isRest){
          http.patch(`/msuite/${id}.json`,mindmap)
          this.newObj = false
        }
        else this.isRest = false
      },
      resetMindmap() {
        this.isRest = true
        this.createSelection = false
        this.isDrawing = false
        this.eraser = false
        this.canvas.isDrawingMode = false
        this.drawLine = false
        let mindmap = { mindmap: {
            canvas: '{"version":"4.6.0","objects":[]}',
            title: 'Title'
          }
        }
        let id = this.currentMindMap.unique_key
        http.patch(`/msuite/${id}.json`,mindmap)
      },
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
      this.initialImage = this.whiteboardImage
      if(JSON.parse(this.initialImage)){
        JSON.parse(this.initialImage).objects.forEach((x, i) => {
          this.mapColors.push(x.stroke)
        })
      }
      if (this.initialImage) {
        this.canvas.loadFromJSON(this.initialImage);
        this.canvas.renderAll();
      }
    },
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
  .sidebar > .active{
    background-color: #866EFB;
  }
  .whiteboard-btns:hover{
    background-color: #091e4214;
    color: #172b4d;
  }
  .eraserCursor{
    cursor: url('eraser.png') 5 5, auto !important;
  }
</style>
