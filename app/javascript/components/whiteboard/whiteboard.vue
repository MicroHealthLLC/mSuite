<template>
  <div>
    <navigation-bar v-if="isMounted" @goHome="goHome" @mSuiteTitleUpdate="mSuiteTitleUpdate" @openPrivacy="openPrivacy" @exportToImage="exportImage" @deleteMindmap="deleteMap" :current-mind-map="currentMindMap"></navigation-bar>
    <div class="row mt-whiteboard">
      <div class="ml-2 border-1 border border-right-0 mb-0 tool-column">
        <div class="tools btn btn-info border pointer icon-height" @click="drawingMode('dash')">
          <span class="material-icons mr-1">
            edit
          </span>
          <span>Pencil</span>
        </div>
        <div class="tools btn btn-info border pointer icon-height" @mouseover="increaseIcon = true" @mouseleave="increaseIcon = false" @click="line < 25 ? ++line : ''">
          <span class="material-icons mr-2">
            line_weight
          </span>
          <span v-show="!increaseIcon">Increase</span>
          <span v-show="increaseIcon">{{line}}</span>
        </div>
        <div class="tools btn btn-info border pointer icon-height" @click="line > 1 ? --line : ''" @mouseover="decreaseIcon = true" @mouseleave="decreaseIcon = false" >
          <span class="material-icons mr-2 mt-4 rotate-180">
            line_weight
          </span>
          <span v-show="!decreaseIcon">Decrease</span>
          <span v-show="decreaseIcon">{{line}}</span>
        </div>
        <div @click="colorSelected=!colorSelected" class="tools btn btn-info border pointer icon-height">
          <span class="material-icons mr-2">
            colorize
          </span>
          <span>Color</span>
        </div>
        <div @click="eraser=true" class="tools btn btn-info border pointer icon-height">
          <span class="material-icons mr-2">
            delete
          </span>
          <span>Eraser</span>
        </div>
        <div @click="drawingMode('circle')" class="tools btn btn-info border pointer icon-height">
          <span class="material-icons mr-2">
            panorama_fish_eye
          </span>
          <span>Circle</span>
        </div>
        <div @click="drawingMode('triangle')" class="tools btn btn-info border pointer icon-height">
          <span class="material-icons mr-2">
            change_history
          </span>
          <span>Triangle</span>
        </div>
        <div @click="drawingMode('square')" class="tools btn btn-info border pointer icon-height">
          <span class="material-icons mr-2">
            crop_16_9
          </span>
          <span>Rectangle</span>
        </div>
        <div @click="redoUndoMap(0)" class="tools btn btn-info border pointer icon-height">
          <span class="material-icons mr-2">
            redo
          </span>
          <span>Redo</span>
        </div>
        <div @click="redoUndoMap(1)" class="tools btn btn-info border pointer icon-height">
          <span class="material-icons mr-2">
            undo
          </span>
          <span>Undo</span>
        </div>
        <div @click="resetMap" class="tools btn btn-danger border pointer icon-height">
          <span class="material-icons mr-2">
            restart_alt
          </span>
          <span>Reset</span>
        </div>
      </div>
      <div id="vue_canvas" class="col-9 p-0 m-0">
          <vue-drawing-canvas
            ref="VueCanvasDrawing"
            :eraser="eraser"
            :width="1275"
            :height="550"
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
  import NavigationBar from "../../common/navigation_bar";
  import domtoimage from "dom-to-image-more"
  import VueDrawingCanvas from 'vue-drawing-canvas';
  import DeleteMapModal from '../../common/modals/delete_modal';
  import MakePrivateModal from "../../common/modals/make_private_modal"
  import ConfirmSaveKeyModal from "../../common/modals/confirm_save_key_modal"
  import DeletePasswordModal from '../../common/modals/delete_password_modal';
  export default {
    props:['whiteboardImage'],
    mounted(){
      if (this.$route.params.key) {
        this.getMindmap(this.$route.params.key)
      }
      this.initialImage = JSON.parse(this.whiteboardImage)
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
      NavigationBar,
      DeleteMapModal,
      DeletePasswordModal,
      MakePrivateModal,
      ConfirmSaveKeyModal,
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
          else {
            this.initialImage = JSON.parse(data.mindmap.image)
          }
        }
      }
    },
    methods:{
      getMindmap(id){
        http
        .get(`/mindmaps/${id}.json`)
        .then((res) => {
          this.currentMindMap = res.data.mindmap
          this.isMounted = true
          this.$cable.subscribe({ channel:"WebNotificationsChannel", room: this.currentMindMap.id })
        })

      },
      mSuiteTitleUpdate(mSuite_name){
        http.patch(`/mindmaps/${ this.currentMindMap.unique_key }.json`,{ mindmap: { name: mSuite_name }})
      },
      goHome(){
       this.$refs['confirm-save-key-modal'].$refs['confirmSaveKeyModal'].open()
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
        .delete(`/mindmaps/${this.currentMindMap.unique_key}.json?password_check=${password}`)
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
        .delete(`/mindmaps/${this.currentMindMap.unique_key}.json`)
        .then(res=>{
        })
        .catch(error=>{
          console.log(error)
        })
      },
      passwordProtect(new_password, old_password){
        http
        .patch(`/mindmaps/${this.currentMindMap.unique_key}.json`,{mindmap:{password: new_password, old_password: old_password}})
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
        .patch(`/mindmaps/${id}.json`,mindmap)
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
      exportImage() {
        const _this = this
        let elm = document.getElementById("vue_canvas")
        let map_key = _this.currentMindMap.unique_key || "image"
        domtoimage.toPng(elm, {height: elm.scrollHeight, width: elm.scrollWidth})
          .then((url) => {
            let downloadLink = document.createElement("a")
            document.body.appendChild(downloadLink)
            downloadLink.href = url
            downloadLink.download = map_key + ".png"
            downloadLink.click()
            document.body.removeChild(downloadLink)
          })
          .catch((err) => {
            console.error('oops, something went wrong!', err)
          })
      },
      getCoordinates(e){
        let coord = this.$refs.VueCanvasDrawing.getCoordinates(e)
        this.exampleContent = ""
        this.x = coord.x
        this.y = coord.y
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
