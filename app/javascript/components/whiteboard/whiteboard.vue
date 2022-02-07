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
    <div class="row mt-5">
      <div class="col-1 px-0 mt-3 sidebar">
        <div class="rounded-0 pl-1 btn btn-info border pointer d-flex" @click="drawingMode('dash')">
          <span class="material-icons">
            edit
          </span>
          <span class="ml-1">Pencil</span>
        </div>
        <div class="rounded-0 pl-1 btn btn-info border pointer d-flex" @mouseover="increaseIcon = true" @mouseleave="increaseIcon = false" @click="line < 25 ? ++line : ''">
          <span class="material-icons">
            line_weight
          </span>
          <span class="ml-1" v-show="!increaseIcon">Increase</span>
          <span class="ml-1" v-show="increaseIcon">{{line}}</span>
        </div>
        <div class="rounded-0 pl-1 btn btn-info border pointer d-flex" @click="line > 1 ? --line : ''" @mouseover="decreaseIcon = true" @mouseleave="decreaseIcon = false" >
          <span class="material-icons rotate-180">
            line_weight
          </span>
          <span class="ml-1" v-show="!decreaseIcon">Decrease</span>
          <span class="ml-1" v-show="decreaseIcon">{{line}}</span>
        </div>
        <div @click="colorSelected=!colorSelected" class="rounded-0 pl-1 btn btn-info border pointer d-flex">
          <span class="material-icons">
            colorize
          </span>
          <span class="ml-1">Color</span>
        </div>
        <div @click="eraser=true" class="rounded-0 pl-1 btn btn-info border pointer d-flex">
          <span class="material-icons">
            delete
          </span>
          <span class="ml-1">Eraser</span>
        </div>
        <div @click="drawingMode('circle')" class="rounded-0 pl-1 btn btn-info border pointer d-flex">
          <span class="material-icons">
            panorama_fish_eye
          </span>
          <span class="ml-1">Circle</span>
        </div>
        <div @click="drawingMode('triangle')" class="rounded-0 pl-1 btn btn-info border pointer d-flex">
          <span class="material-icons">
            change_history
          </span>
          <span class="ml-1">Triangle</span>
        </div>
        <div @click="drawingMode('square')" class="rounded-0 pl-1 btn btn-info border pointer d-flex">
          <span class="material-icons">
            crop_16_9
          </span>
          <span class="ml-1">Rectangle</span>
        </div>
        <div @click="redoUndoMap(0)" class="rounded-0 pl-1 btn btn-info border pointer d-flex">
          <span class="material-icons">
            redo
          </span>
          <span class="ml-1">Redo</span>
        </div>
        <div @click="redoUndoMap(1)" class="rounded-0 pl-1 btn btn-info border pointer d-flex">
          <span class="material-icons">
            undo
          </span>
          <span class="ml-1">Undo</span>
        </div>
        <div @click="resetMap" class="rounded-0 pl-1 btn btn-danger border pointer d-flex">
          <span class="material-icons">
            restart_alt
          </span>
          <span class="ml-1">Reset</span>
        </div>
      </div>
      <div id="vue_canvas" class="col-11 p-0 m-0 font-serif mt-3">
          <vue-drawing-canvas
            ref="VueCanvasDrawing"
            :eraser="eraser"
            :lineWidth="Number(line)"
            :color="color"
            :stroke-type="strokeType"
            :classes="['border']"
            :image.sync="image"
            :save-as="'jpeg'"
            :initial-image.sync="initialImage"
            @mouseup.native="saveImage"
          />
      </div>
      <div v-if="colorSelected">
          <div class="card col-3 p-0 border-none color-picker-placement">
            <div class="card-body p-0">
              <chrome-picker @input="updateColor" v-model="colorPicker"/>
            </div>
            <div class="card-button d-flex">
              <button class="btn btn-success w-100 border-none" @click="colorSelected=false">Close</button>
            </div>
          </div>
      </div>
    </div>
    <make-private-modal ref="make-private-modal" @password-apply="passwordProtect" @password_mismatched="$refs['passwordMismatched'].open()" :password="currentMindMap.password"></make-private-modal>
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
  import VueDrawingCanvas from 'vue-drawing-canvas';
  import DeleteMapModal from '../../common/modals/delete_modal';
  import MakePrivateModal from "../../common/modals/make_private_modal"
  import DeletePasswordModal from '../../common/modals/delete_password_modal';
  export default {
    props:['whiteboardImage'],
    mounted(){
      let _this = this
      if (this.$route.params.key) {
        this.getMindmap(this.$route.params.key)
        this.$refs.VueCanvasDrawing.width = window.innerWidth - 120
        this.$refs.VueCanvasDrawing.height = window.innerHeight - 70 
      }
      this.initialImage = JSON.parse(this.whiteboardImage)
      $(window).resize(function() {
        _this.$refs.VueCanvasDrawing.width = window.innerWidth - 120
        _this.$refs.VueCanvasDrawing.height = window.innerHeight - 70
          _this.$refs.VueCanvasDrawing.images = []
        if (_this.$refs.VueCanvasDrawing.initialImage !== null)
          _this.$refs.VueCanvasDrawing.drawInitialImage()
      });
    },
    watch: {
     initialImage: function (newVal) {
      if(newVal !== null && newVal.length < 1){
         this.$refs.VueCanvasDrawing.trash.length < 1 ? this.$refs.VueCanvasDrawing.reset() : ''
      }
      else{
        setTimeout(() => {
          this.$refs.VueCanvasDrawing.images = []
          if (this.$refs.VueCanvasDrawing.initialImage !== null)
            this.$refs.VueCanvasDrawing.drawInitialImage()
        }, 200)
      }
     }
    },
    components: {
      VueDrawingCanvas,
      DeleteMapModal,
      DeletePasswordModal,
      MakePrivateModal
    },
    data(){
      return{
        eraser: false,
        isMounted: false,
        line: 5,
        strokeType: "dash",
        color: "#000000",
        backgroundColor: "#ffffff",
        currentMindMap: {},
        defaultDeleteDays: '',
        deleteAfter: '',
        initialImage: [],
        image: "",
        colorPicker: "#000000",
        x: 0,
        y: 0,
        colorSelected: false,
        increaseIcon: false,
        decreaseIcon: false
      }
    },
    channels: {
      WebNotificationsChannel: {
        received(data) {
          if (data.message === "Mindmap Deleted" && this.currentMindMap.id === data.mindmap.id)
          {
            window.open('/','_self')
          }
          else if(data.message === "Password Updated" && this.currentMindMap.id === data.mindmap.id)
          {
            setTimeout(() => {
              location.reload()
            }, 500)
          }
          else
          {
            this.initialImage = JSON.parse(data.mindmap.image)
          }
        }
      }
    },
    methods:{
      getMindmap(id){
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
      openPrivacy() {
        this.$refs['make-private-modal'].$refs['makePrivateModal'].open()
      },
      deleteMap(){
        this.$refs['delete-map-modal'].$refs['deleteMapModal'].open()
      },
      confirmDeleteMindmap(){
        if (this.currentMindMap.password){
          this.$refs['delete-password-modal'].$refs['DeletePasswordModal'].open()
        }
        else{
          this.deleteMindmap()
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
      deleteMindmap(){
        http
        .delete(`/msuite/${this.currentMindMap.unique_key}.json`)
        .then(res=>{
        })
        .catch(error=>{
          console.log(error)
        })
      },
      passwordProtect(new_password, old_password){
        http
        .patch(`/msuite/${this.currentMindMap.unique_key}.json`,{mindmap:{password: new_password, old_password: old_password}})
        .then(res => {
          if (res.data.mindmap) {
            this.currentMindMap.password = res.data.mindmap.password
            this.$refs['successModal'].open()
          }
          else {
            if (res.data.error) this.$refs['errorModal'].open()
          }
        })
      },
      passwordAgain(){
        this.$refs['passwordMismatched'].close()
        this.openPrivacy()
      },
      saveImage(){
        let mindmap = {mindmap:{image:JSON.stringify(this.$refs.VueCanvasDrawing.getAllStrokes())}}
        let id = this.currentMindMap.unique_key
        http
        .patch(`/msuite/${id}.json`,mindmap)
        .then(res=>{
        })
        .catch(err=>{
          console.log(err)
        })
      },
      resetMap(){
        this.$refs['VueCanvasDrawing'].reset()
        this.saveImage()
      },
      redoUndoMap(process){
        process === 0 ? this.$refs.VueCanvasDrawing.redo() : this.$refs.VueCanvasDrawing.undo()
        this.saveImage()
      },
      drawingMode(shape){
        this.strokeType = shape
        this.eraser = false
      },
      updateColor(){
        this.color = this.colorPicker.hex
      }
    }
  }
</script>
<style>
  @import "./whiteboard.scss";
</style>
