<template>
  <div class="row">
    <div class="col-1 px-0 sidebar">
      <div @click="addCircleToCanvas" class="rounded-0 pl-1 btn whiteboard-btns border pointer d-flex">
        <span class="material-icons">
          panorama_fish_eye
        </span>
        <span class="ml-1">Venn</span>
      </div>
       <div @click="addTextToCanvas" class="rounded-0 pl-1 btn whiteboard-btns border pointer d-flex">
        <span class="material-icons">
          rtt
        </span>
        <span class="ml-1">Text</span>
      </div>
      <div @click="showColorPicker" class="rounded-0 pl-1 btn whiteboard-btns border pointer d-flex">
        <span class="material-icons">
          colorize
        </span>
        <span class="ml-1">Color</span>
      </div>
      <div @click="deleteModal" class="rounded-0 pl-1 btn whiteboard-btns border pointer d-flex">
        <span class="material-icons">
          delete
        </span>
        <span class="ml-1">Delete</span>
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
</template>
<script>
  import http from "../../common/http"
  import TemporaryUser from "../../mixins/temporary_user.js"
  import Common from "../../mixins/common.js"
  import { fabric } from 'fabric'
  import 'fabric-history';

  export default {
    props: {
      resetBefore: Function,
      saveBefore: Function,
      undoMap: Function,
      redoMap: Function,
    },
    data() {
      return {
        currentMindMap: this.$store.getters.getMsuite,
        line: 1,
        color: "#AADDCC",
        fillColor: "#AADDCC99",
        mapColors: [],
        colorPicker: "#AADDCC",
        colorSelected: false,
        points: [],
        mousePressed: false,
        isDrawing: false,
        initialImage: [],
        eraser: false,
        saveData: true,
        isRest: false,
        addObj: false,
        newObj: false,
        drawLine: false,
        createSelection: false,
        oldColor: '',
        oldFillColor: '',
        saveElement: false,
      }
    },
    mixins: [Common, TemporaryUser],
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
    mounted(){
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
      this.sendLocals()
      this.setUserOnMountC()
      this.getUserOnMount()
      this.resetBefore(this.beforeReset)
      this.saveBefore(this.beforeSave)
      this.undoMap(this.undoCanvas)
      this.redoMap(this.redoCanvas)
    },
    methods: {
      addValue(){
        this.addBar = true
      },
      addNewValue(dataSet){
        let dataArray  = dataSet.sets.split(",").map(String);
        let dataValue  = parseFloat(dataSet.value)
        let createData = {
          sets : dataArray,
          value: dataValue
        }
        if (dataSet.name != '') createData.name = dataSet.name
        this.addBar = false
        this.addNewSet(createData, dataSet)
      },
      addNewSet(createData, dataSet) {
        let nodeName = ''
        if (createData.name) nodeName = createData.name
        let data = {
          node: {
            title: nodeName,
            description: dataSet.sets,
            mindmap_id: this.currentMindMap.id,
            position: createData.value,
            line_color: "#B3FAFF"
          }
        }
        http.post(`/nodes.json`, data).then((res) => {
          if(res.data.node.id){
            this.updateVennUser()
            this.sendLocals()
            this.undoNodes.push({req: 'addNode', 'node': res.data.node})
          } else {
            this.$refs["dataErrorModal"].open()
          }
        }).catch((err) => {
          console.log(err);
        });
      },
      async updateSet(){
        let mySet = {
          title: this.selectedSet.name,
          position: this.selectedSet.value,
          description: this.selectedSet.sets.toString(),
          line_color: this.selectedSet.color
        }
        if(this.undoNodes.length > 0) {
          this.undoNodes.forEach((element, index) => {
            if(element['node'].id === this.selectedSet.nodeId) {
              this.undoNodes[index]['node'].title = mySet.title
              this.undoNodes[index]['node'].position = mySet.position
              this.undoNodes[index]['node'].description = mySet.description
              this.undoNodes[index]['node'].line_color = mySet.line_color
            }
          });
        } else {
          this.undoNodes.push({'req': 'addNode', node: mySet})
        }
        this.openEditBox = false
        var _this = this
        await http.put(`/nodes/${this.selectedSet.nodeId}`, mySet).then( async (res) => {
          this.updateVennUser()
          this.sendLocals()
        }).catch( err => {
          console.log(err);
        })
      },
      async updateVennUser(){
        await this.$store.dispatch('updateMSuite',  {
          canvas: this.$store.getters.getUser
        })
      },
      pointClick(event) {
        this.selectedSet = event.point
        let getNode = this.savedSets.find( n => {
          let title = n.description
          if (title === this.selectedSet.sets.join(",")) return n
        })
        this.selectedSet.nodeId = getNode.id
        this.openEditBox = true
        setTimeout(()=>{
          let element = document.getElementById('edit')
          element.style.top  = this.selectedSet.plotY + 'px'
          element.style.left = this.selectedSet.plotX + 'px'
        },10)
      },
      forceRerender() {
        this.componentKey += 1
      },
      closeEditBox(){
        this.openEditBox = false
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
          this.undoNodes.push({req: redoObj.req, 'node': redoObj.node})
        }
      },
      addCircleToCanvas() {
        this.createSelection = true;
        this.addObj = true;
        this.newObj = true
        let circle = new fabric.Circle({
          left        : 70,
          top         : 70,
          radius      : 50,
          fill        : this.fillColor,
          stroke      : this.color,
          width       : 100,
          height      : 100,
          strokeWidth : this.line,
          opacity     : .8
        });
        this.canvas.add(circle);
        this.canvas.setActiveObject(circle)
        this.$store.dispatch('setCanvas' , JSON.stringify(this.canvas.toJSON()))
      },
      addTextToCanvas() {
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
      beforeUpdateColor(){
        if(this.activeObject.type == 'i-text') this.activeObject.set("fill", this.colorPicker.hex8);
        else {
          this.activeObject.set("stroke", this.colorPicker.hex8);
          this.activeObject.set("fill"  , this.colorPicker.hex + "99");
        }
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
        this.activeObject.set("fill", this.oldFillColor);
        this.color = this.oldColor
        this.canvas.renderAll();
      },
      undoCanvas() {
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
        this.canvas.redo();
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
          this.oldFillColor = this.activeObject.fill
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
      },
      deleteModal() {
        this.canvas.remove(this.canvas.getActiveObject());
      },
    }
  };
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
</style>
