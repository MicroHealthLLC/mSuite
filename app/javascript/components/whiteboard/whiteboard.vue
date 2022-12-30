<template>
  <div>
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
  </div>
</template>
<script>
  import http from "../../common/http"
  import { jsPDF } from "jspdf";
  import html2canvas from "html2canvas"
  import domtoimage from "dom-to-image-more"
  import Common from "../../mixins/common.js"
  import TemporaryUser from "../../mixins/temporary_user.js"

  import { fabric } from 'fabric'
  import 'fabric-history';

  export default {
    mixins: [Common, TemporaryUser],
    props: {
      resetBefore: Function,
      saveBefore: Function,
      undoMap: Function,
      redoMap: Function,
    },
    data() {
      return {
        currentMindMap: this.$store.getters.getMsuite,
        line: 5,
        color: "#AADDCC",
        mapColors: [],
        image: "",
        expDays: '',
        defaultDeleteDays: '',
        colorPicker: "#AADDCC",
        colorSelected: false,
        points: [],
        increaseIcon: false,
        decreaseIcon: false,
        mousePressed: false,
        isDrawing: false,
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
        saveElement: false,
      }
    },
    components: {
      fabric,
    },
    channels: {
      WebNotificationsChannel: {
        received(data) {
          if (
            data.message === "Mindmap Deleted"      &&
            this.currentMindMap.id === data.mindmap.id
          ) {
            window.open('/','_self')
          } else if (
            data.message === "Password Updated"     &&
            this.currentMindMap.id === data.mindmap.id
          ) {
            setTimeout(() => {
              location.reload()
            }, 500)
          } else if (
            data.message          === "storage updated"    &&
            this.currentMindMap.id == data.content.mindmap_id
          ) {
            this.$store.dispatch('setUserEdit'     , data.content.userEdit)
            this.$store.dispatch('setTemporaryUser', data.content.userEdit)
            this.$store.dispatch('setUserList'     , data.content.userEdit)
          }
          else if( data.message  === "Reset mindmap" && this.currentMindMap.id ===    data.mindmap.id){
            this.$store.commit('setMSuite', data.mindmap)
            this.currentMindMap = this.$store.getters.getMsuite
            this.initialImage = data.mindmap.canvas
            this.mapColors = []
            this.color = "#AADDCC"
            this.colorSelected = false
            if (this.initialImage && this.initialImage != '{"version":"4.6.0","columns":[], "data":[], "style":{}, "width": []}') this.canvas.loadFromJSON(JSON.parse(JSON.parse(this.initialImage).whiteboardImage));
            else this.canvas.loadFromJSON('{"version":"4.6.0","objects":[]}')
            this.canvas.renderAll();
            this.createSelection = false
          } else if( data.message  === "Mindmap Updated" &&
            this.currentMindMap.id ===      data.mindmap.id
          ) {
            this.$store.commit('setMSuite', data.mindmap)
            this.initialImage = data.mindmap.canvas
            this.mapColors = []
            this.color = "#AADDCC"
            if (this.initialImage && this.initialImage != '{"version":"4.6.0","columns":[], "data":[], "style":{}, "width": []}') JSON.parse(JSON.parse(this.initialImage).whiteboardImage).objects.forEach((x, i) => {
              if(x.stroke == null) this.mapColors.push(x.fill)
              else this.mapColors.push(x.stroke)
            })
            this.colorSelected = false
            if (this.initialImage && this.initialImage != '{"version":"4.6.0","columns":[], "data":[], "style":{}, "width": []}') this.canvas.loadFromJSON(JSON.parse(JSON.parse(this.initialImage).whiteboardImage));
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
        this.$store.dispatch('setCanvas' , JSON.stringify(this.canvas.toJSON()))
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
        this.$store.dispatch('setCanvas' , JSON.stringify(this.canvas.toJSON()))
      },
      addTextToCanvas() {
        this.toggleResetDraw();
        this.createSelection = true;
        this.text = new fabric.IText('Tap and Type', {
          left: 70,
          top: 70,
          fontFamily: 'sans-serif',
          fill: this.color,
          strokeWidth: this.line,
        })
        this.newObj = true
        this.canvas.add(this.text);
        this.canvas.setActiveObject(this.text)
        this.$store.dispatch('setCanvas' , JSON.stringify(this.canvas.toJSON()))
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
        this.$store.dispatch('setCanvas' , JSON.stringify(this.canvas.toJSON()))
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
        this.isRest = false
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

        this.saveElement = false
        this.$store.dispatch('setCanvas' , JSON.stringify(this.canvas.toJSON()))
        this.sendLocals(true)
      },
      mouseEvents() {
        let _this = this
        this.canvas.on('mouse:down:before', (event) => {
          _this.mousePressed = true;
          _this.addObj = false;
        })
        this.canvas.on('mouse:move', (event) => {
          if(!_this.createSelection && _this.canvas.getActiveObject() != undefined) _this.canvas.discardActiveObject()
          if(!this.drawLine) return

          this.pointer = this.canvas.getPointer(event.e);
          if(this.stLine) this.stLine.set({ x2: this.pointer.x, y2: this.pointer.y });
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
          this.$store.dispatch('setCanvas' , JSON.stringify(this.canvas.toJSON()))
          if (this.drawLine) {
            const mousePos = canvas.getBoundingClientRect();
            let x1 , y1
            if(event.e.touches){
              const touches = event.e.touches
              x1 = Math.round(touches[0].clientX - mousePos.left);
              y1 = Math.round(touches[0].clientY - mousePos.top);
            }
            else{
              const elment = event.e
              x1 = Math.round(elment.clientX - mousePos.left);
              y1 = Math.round(elment.clientY - mousePos.top);
            }
            this.points = [ x1, y1, x1, y1 ]
            this.straightLine()
            this.$store.dispatch('setCanvas' , JSON.stringify(this.canvas.toJSON()))
            this.sendLocals(true)
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
          this.$store.dispatch('setCanvas' , JSON.stringify(this.canvas.toJSON()))
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
          this.$store.dispatch('setCanvas' , JSON.stringify(this.canvas.toJSON()))
          this.sendLocals(true)
        })
        this.canvas.on('selection:cleared', (event) => {
          if(this.saveData && !_this.addObj) this.updateWhiteBoard(JSON.stringify(this.canvas.toJSON()));
          else if(!this.colorSelected) this.updateWhiteBoard(JSON.stringify(this.canvas.toJSON()));
          this.$store.dispatch('setCanvas' , JSON.stringify(this.canvas.toJSON()))
          this.sendLocals(false)
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
          this.$store.dispatch('setCanvas' , JSON.stringify(this.canvas.toJSON()))
          this.sendLocals(true)
        })
      },
      updateWhiteBoard(obj) {
        if(obj == undefined){
          obj = JSON.stringify(this.canvas.toJSON())
        }
        let mycanvas = {
          whiteboardImage : obj,
          user            : this.$store.getters.getUser
        }
        mycanvas = JSON.stringify(mycanvas)
        let mindmap = { mindmap: { canvas: mycanvas } }
        let id = this.currentMindMap.unique_key
        if(!this.isRest){
          this.$store.dispatch('updateMSuite', mindmap)
          this.newObj = false
          this.$store.dispatch('setCanvas' , JSON.stringify(this.canvas.toJSON()))
        }
        else this.isRest = false
      },
      beforeReset(){
        let mindmap = { mindmap: {
            canvas: '{"version":"4.6.0","objects":[]}',
            title: 'Title'
          }
        }
        this.beforeSave()
        this.$store.dispatch('setCanvas' , mindmap.mindmap.canvas)
      },
      beforeSave(){
        this.updateWhiteBoard(JSON.stringify(this.canvas.toJSON()))
      }
    },
    mounted() {
      this.subscribeCable(this.currentMindMap.id)
      this.$store.dispatch('setExportId', 'vue_canvas')
      var canvas2 = document.getElementsByTagName('canvas')[0];
      canvas2.width = $(document).width() - 140;
      canvas2.height = $(document).height() - 75;
      this.canvas = new fabric.Canvas('canvas',{
        selection: false
      });
      this.mouseEvents();
      this.canvas.renderAll();
      this.initialImage = this.currentMindMap.canvas
      if(this.initialImage &&
          JSON.parse(this.initialImage) &&
          JSON.parse(this.initialImage).whiteboardImage
        ){
        JSON.parse(JSON.parse(this.initialImage).whiteboardImage).objects.forEach((x, i) => {
          if(x.stroke == null) this.mapColors.push(x.fill)
          else this.mapColors.push(x.stroke)
        })
        this.canvas.loadFromJSON(JSON.parse(this.initialImage).whiteboardImage);
        this.canvas.renderAll();
      }
      this.sendLocals(false)
      this.setUserOnMountC()
      this.getUserOnMount()
      this.resetBefore(this.beforeReset)
      this.saveBefore(this.beforeSave)
      this.undoMap(this.undoCanvas)
      this.redoMap(this.redoCanvas)
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
