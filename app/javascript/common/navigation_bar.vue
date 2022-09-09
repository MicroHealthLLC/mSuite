<template>
  <div class="buttons_area">
    <div class="buttons_container px-2 pt-2 row pb-0">
      <span class="navbar_icon flex ml-5 col-lg-2 col-md-2 col-sm-2 pr-0">
        <a
          href="javascript:;"
          role="button"
          class="navbar-brand p-0"
          @click.stop="goHome"
        >
          <img src="/assets/msuite.png"/>
        </a>
      </span>
      <span class="col-lg-3 col-md-3 col-sm-3 d-flex justify-content-center px-0">
        <span v-show="!editable" @click="makeEditable" class="my-1 py-1 pointer text-sapphire text-wrapper" data-toggle="tooltip" :title="mSuiteTitle">{{ mSuiteTitle | truncate(30) }}</span>
        <input
          v-show="editable"
          :rows="1"
          id="mSuiteTitle"
          @keydown.enter.prevent="mSuiteTitleUpdate"
          type="text"
          v-debounce:3000ms="blurEvent"
          v-model="mSuiteName"
          class="my-1 py-1 mindmap-title border-0 text-sapphire font-weight-bold align-items-center w-100 text-center"
          @blur="mSuiteTitleUpdate"
          placeholder="Enter mSuite Map Title"
        >
        </input>
      </span>
      <span class="navbar_buttons col-lg-6 col-md-12 col-sm-12 d-flex flex-row-reverse">
        <span class="navbar_button d-flex flex-row-reverse">
          <a
            v-if="currentMindMap.mm_type != 'pollvote'"
            href="javascript:;"
            role="button"
            v-b-tooltip.hover title="Delete"
            class="navbar_button d-flex text-info pointer edit_delete_btn mr-3 center_flex"
            @click.prevent="deleteMap"
          >
            <i class="fas fa-trash-alt icons d-flex center_flex"></i>
          </a>
          <a
            href="javascript:;"
            role="button"
            v-b-tooltip.hover title="User"
            class="navbar_button d-flex text-info pointer edit_delete_btn mr-3 center_flex"
            @click.prevent="openUserModal"
          >
            <i class="fas fa-user-edit icons d-flex center_flex"></i>
          </a>
          <a
            v-if="currentMindMap.mm_type != 'pollvote'"
            href="javascript:;"
            role="button"
            class="navbar_button d-flex text-info pointer edit_delete_btn mr-3 center_flex"
            v-b-tooltip.hover title="Comments"
            @click.prevent="openCommentModal"
          >
            <i id="comment" class="fa fa-comment d-flex center_flex"></i>
          </a>
          <a
            v-if="currentMindMap.mm_type != 'pollvote'"
            href="javascript:;"
            role="button"
            class="navbar_button d-flex text-info edit_delete_btn mr-3 center_flex"
            v-b-tooltip.hover title="Reset"
            @click.stop="resetMap"
          >
            <i class="material-icons restore_icon icons d-flex center_flex"></i>
          </a>
        </span>
        <span v-if="checkMSuiteTypes" class = "d-flex flex-row-reverse">
            <a
              href="javascript:;"
              role="button"
              v-b-tooltip.hover title="Redo"
              class="d-flex text-info pointer edit_delete_btn mr-3 center_flex"
              @click.stop="redoMindmap"
            >
              <i class="fas fa-redo-alt"></i>
            </a>
            <a
              href="javascript:;"
              role="button"
              v-b-tooltip.hover title="Undo"
              class="d-flex text-info pointer edit_delete_btn mr-3 center_flex"
              @click.stop="undoMindmap"
            >
              <i class="fas fa-undo-alt"></i>
            </a>
        </span>
        <span class="d-flex">  
          <a
            v-if="currentMindMap.mm_type==='simple'"
            ref="exportWordBtn"
            role="button"
            v-b-tooltip.hover title="Export Word"
            class="navbar_button d-flex text-info pointer edit_delete_btn mr-3 center_flex"
            @click.stop="exportToWord"
          >
            <i class="fas fa-file-word icons d-flex center_flex"></i>
          </a>
          <a
            v-if="currentMindMap.mm_type == 'pollvote'"
            role="button"
            href="javascript:;"
            class="text-dark mt-2 mr-4 font-weight-bold"
            v-b-tooltip.hover title="Poll Expires"
          >
            <span class="">
              Poll Expires: {{pollExpDate}}
            </span>
          </a>
          <a
            ref="exportBtn"
            role="button"
            href="javascript:;"
            v-b-tooltip.hover title="Export"
            class="navbar_button d-flex text-info pointer edit_delete_btn mr-3 center_flex"
            @click.prevent.stop="$refs['exportOption'].open()"
          >
            <i class="material-icons export_icon icons d-flex center_flex"></i>
          </a>
          <a
            v-if="currentMindMap.mm_type==='spreadsheet' || currentMindMap.mm_type==='poll' "
            ref="exportBtn"
            role="button"
            href="javascript:;"
            class="navbar_button zoom_btn text-info edit_delete_btn center_flex mr-3"
            v-b-tooltip.hover title="Export"
            @click.prevent.stop="$refs['exportOptionCsv'].open()"
          >
            <i class="fas fa-file-excel icons d-flex center_flex"></i>
          </a>
          <a
            v-if="currentMindMap.mm_type != 'pollvote'"
            role="button"
            href="javascript:;"
            class="navbar_button d-flex text-info pointer edit_delete_btn mr-3 center_flex"
            @click.prevent.stop="saveMSuite"
            v-b-tooltip.hover :title="'Expires '+ expireDateTime"
          >
            <i class="material-icons save_btn icons d-flex center_flex"></i>
          </a>
        </span>
        <span v-if="currentMindMap.mm_type === 'simple' || currentMindMap.mm_type === 'tree_chart' || currentMindMap.mm_type === 'flowmap'" class="d-flex">
            <a
              v-if="scaleFactor != 1"
              href="javascript:;"
              role="button"
              v-b-tooltip.hover title="100%"
              class="zoom_btn text-info edit_delete_btn center_flex mr-3"
              @click.prevent="resetZoomScale"
            >
              <i class="fas fa-history icons d-flex center_flex"></i>
            </a>
            <a
              href="javascript:;"
              role="button"
              v-b-tooltip.hover title="Zoom +"
              class="navbar_button zoom_btn text-info edit_delete_btn center_flex mr-3"
              @click.prevent="zoomInScale"
            >
              <i class="material-icons zoom_in_icon icons d-flex center_flex"></i>
            </a>
            <a
              href="javascript:;"
              role="button"
              v-b-tooltip.hover title="Zoom -"
              class="navbar_button zoom_btn text-info edit_delete_btn mr-3 center_flex"
              @click.prevent="zoomOutScale"
            >
              <i class="material-icons zoom_out_icon icons d-flex center_flex"></i>
            </a>
        </span>  
        <span v-if="currentMindMap.editable && currentMindMap.mm_type === 'simple'" class="d-flex flex-row-reverse">
          <span v-b-tooltip.hover title="Delete">
            <a
              href="javascript:;"
              role="button"
              :disabled="!selectedNode"
              :class="{button_disabled: !selectedNode}"
              class="navbar_button d-flex text-info edit_delete_btn mr-3 center_flex"
              @click.stop="deleteSelectedNode"
            >
              <i class="material-icons delete_icon icons d-flex center_flex"></i>
            </a>
          </span>
            <span v-b-tooltip.hover title="Paste">
              <a
                href="javascript:;"
                role="button"
                :disabled="!selectedNode"
                :class="{button_disabled: !copiedNode}"
                class="navbar_button d-flex text-info edit_delete_btn mr-3 center_flex"
                @click.stop="pasteCopiedNode"
              >
                <i class="fa fa-paste paste_icon icons d-flex center_flex"></i>
              </a>
            </span>
          <span v-b-tooltip.hover title="Cut">  
            <a
              href="javascript:;"
              role="button"
              :disabled="!selectedNode"
              :class="{button_disabled: !selectedNode}"
              class="navbar_button d-flex text-info edit_delete_btn mr-3 center_flex"
              @click.stop="cutSelectedNode"
            >
              <i class="fa fa-cut cut_icon icons d-flex center_flex"></i>
            </a>
          </span>
          <span v-b-tooltip.hover title="Copy" class="">  
            <a
              href="javascript:;"
              role="button"
              :disabled="!selectedNode"
              :class="{button_disabled: !selectedNode}"
              class="navbar_button d-flex text-info edit_delete_btn mr-3 center_flex"
              @click.stop="copySelectedNode"
            >
              <i class="material-icons copy_icon icons d-flex center_flex"></i>
            </a>
          </span>
        </span>
      </span>
      <span class="col-12 d-flex justify-content-end pt-2" style="height: 2rem;">
        <a
          href="javascript:;"
          role="button"
          class="navbar_button d-flex text-info pointer mr-3 center_flex"
          v-b-tooltip.hover title="Status"
        >
          <div v-if="renderUserList && renderUserList.length > 0">
            Editing by:
            <span v-for="user in renderUserList">
              {{user}},
            </span>
          </div>
        </a>
        <a
          href="javascript:;"
          role="button"
          class="navbar_button d-flex text-info pointer mr-3 center_flex"
          v-b-tooltip.hover title="Status"
          v-if="temporaryUser"
        >
            <span> Last Edited By {{temporaryUser}}</span>
        </a>
      </span>
    </div>
    <sweet-modal>
    </sweet-modal>
    <comment-map-modal :mind-map='currentMindMap' ref="comment-box-modal"></comment-map-modal>
    <confirm-save-key-modal
      @openPrivacy="openPrivacy"
      @updateInActiveDate="updateMsuite"
      @deleteMap="deleteMap"
      @isSave="isSave"
      @changeIsMsuitSaved="handleChangeIsMsuiteSaved"
      ref="confirm-save-key-modal"
      :current-mind-map="currentMindMap"
      :isSaveMSuite="isSaveMSuite"
      :isSaveMap="isSaveMap"
      :defaultDeleteDays="defaultDeleteDays"
      :deleteAfter="deleteAfter"
      :expDays="expDays">
    </confirm-save-key-modal>
    <user-map-modal :mind-map='currentMindMap' ref="user-box-modal"></user-map-modal>
    <sweet-modal ref="exportOption" class="of_v" icon="info" title="Export Format">
      Kindly Choose the Format of Export
      <button slot="button" v-if="currentMindMap.mm_type === 'Notepad'" @click="exportImage(1)" class="btn btn-warning float-left mr-2">Export to Document</button>
      <button slot="button" v-else @click="exportImage(1)" class="btn btn-warning float-left mr-2">Export to Image</button>

      <button slot="button" v-if="currentMindMap.mm_type === 'Notepad'" @click="exportImage(2)" class="btn btn-info float-left">Export to rtf</button>
      <button slot="button" v-else @click="exportImage(2)" class="btn btn-info float-left">Export to Pdf</button>
      <button slot="button" @click="$refs['exportOption'].close()" class="btn btn-secondary">Cancel</button>
    </sweet-modal>
    <sweet-modal ref="exportOptionCsv" class="of_v" icon="info" title="Export Format">
      Kindly Choose the Format of Export
      <button slot="button" @click="exportXLS(1)" class="btn btn-warning float-left mr-2">Export to Excel</button>

      <button slot="button" @click="exportXLS(2)" class="btn btn-info float-left">Export to csv</button>
      <button slot="button" @click="$refs['exportOptionCsv'].close()" class="btn btn-secondary">Cancel</button>
    </sweet-modal>
    <reset-map-modal
      ref="reset-map-modal"
      @reset-mindmap="resetMindmap"
    ></reset-map-modal>
    <make-private-modal
      ref="make-private-modal"
      @password-apply="passwordProtect"
      @password_mismatched="$refs['passwordMismatched'].open()"
      :password="password"
      :isSaveMSuite="isSaveMSuite"
    ></make-private-modal>
    <sweet-modal ref="errorModal" class="of_v" icon="error" title="Password Error">
      Incorrect Password, Please Try Again!
    </sweet-modal>

    <sweet-modal ref="passwordMismatched" class="of_v" icon="error" title="Password Mismatch">
      Your Password and Confirm Password are Mismatched, Please Try Again!
      <button slot="button" @click="passwordAgain" class="btn btn-warning mr-2">Try Again</button>
      <button slot="button" @click="$refs['passwordMismatched'].close()" class="btn btn-secondary">Cancel</button>
    </sweet-modal>

    <sweet-modal ref="successModal" class="of_v" icon="success">
      Password updated successfully!
    </sweet-modal>
    <delete-map-modal ref="delete-map-modal" @delete-mindmap="confirmDeleteMindmap"></delete-map-modal>
    <delete-password-modal ref="delete-password-modal" @deletePasswordCheck="deleteMindmapProtected">
    </delete-password-modal>
  </div>
</template>

<script>
  import ConfirmSaveKeyModal from "./modals/confirm_save_key_modal"
  import { jsPDF } from "jspdf";
  import html2canvas from "html2canvas"
  import domtoimage from "dom-to-image-more"
  import http from "./http"
  import ResetMapModal from '../components/mindmaps/modals/reset_map_modal'
  import UserMapModal from "./modals/user_map_modal"
  import CommentMapModal from "./modals/comment_map_modal"
  import MakePrivateModal from "./modals/make_private_modal"
  import DeleteMapModal from './modals/delete_modal'
  import DeletePasswordModal from './modals/delete_password_modal'
  export default{
    name:"NavigationBar",
    props:["scaleFactor", "currentMindMap", "selectedNode", "copiedNode", "exportId", "defaultDeleteDays","deleteAfter","isEditing","saveElement", "expDays","temporaryUser","userList","pollPin","pollEdit","pollExpDate"],
    data() {
      return{
        mSuiteName: this.currentMindMap.title,
        editable: false,
        isSaveMSuite: true,
        isMsuiteSaved: true,
        poll_pin: null,
        password: JSON.parse(JSON.stringify(this.currentMindMap.password)),
        isSaveMap: JSON.parse(JSON.stringify(this.currentMindMap.is_save)),
        pollEditing: false,
        dateFormate: { month: 'long', weekday: 'long', year: 'numeric', day: 'numeric' }
      }
    },
    created(){
      window.addEventListener('beforeunload', this.isMsuiteEmpty)
    },
    components:{
      DeletePasswordModal,
      DeleteMapModal,
      ConfirmSaveKeyModal,
      ResetMapModal,
      CommentMapModal,
      UserMapModal,
      MakePrivateModal
    },
    computed: {
      renderUserList () {
        if(this.userList) return this.userList.filter((v, i, a) => a.indexOf(v) === i)
      },
      mSuiteTitle () {
        return this.mSuiteName
      },
      expireDateTime () {
        let x = new Date(this.currentMindMap.will_delete_at)
        return x.toDateString();
      },
      checkMSuiteTypes () {
        return this.currentMindMap.mm_type==='kanban' || this.currentMindMap.mm_type==='tree_chart' || this.currentMindMap.mm_type==='flowmap' || this.currentMindMap.mm_type==='todo' || this.currentMindMap.mm_type==='tree_map'
      }
    },
    filters: {
      truncate: function(data,num){
        if(data === undefined) return
        let reqdString = data.split("").slice(0, num).join("");
        if (reqdString.length < data.length) {
          reqdString = reqdString.concat('.....')
        }
        return reqdString;
      }
    },
    methods:{
      isSave () {
        http.post(`/msuite/${this.currentMindMap.unique_key}/reset_password`)
        .then((res) => {
          this.currentMindMap = res.data.mindmap
          this.password = JSON.parse(JSON.stringify(this.currentMindMap.password))
          this.isSaveMap = JSON.parse(JSON.stringify(this.currentMindMap.is_save))
        })
      },
      deleteMap(){
        this.$refs['delete-map-modal'].$refs['deleteMapModal'].open()
      },
      openPrivacy(val) {
        this.isSaveMSuite = val
        this.$refs['make-private-modal'].$refs['makePrivateModal'].open()
      },
      passwordProtect(new_password, old_password){
        http
        .patch(`/msuite/${this.currentMindMap.unique_key}.json`,{mindmap:{password: new_password, old_password: old_password}})
        .then(res=>{
          if (res.data.mindmap) {
            this.currentMindMap.password = res.data.mindmap.password
            if(!this.isSaveMSuite) window.open("/", "_self")
            else location.reload()
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
      confirmDeleteMindmap(){
        if (this.password){
          this.$refs['delete-password-modal'].$refs['DeletePasswordModal'].open()
        }
        else {
          this.deleteMindmap()
        }
      },
      deleteMindmapProtected(password){
        http
        .delete(`/msuite/${this.currentMindMap.unique_key}.json?password_check=${password}`)
        .then(res=>{
          if(res.data.success) window.open("/", "_self")
          if (!res.data.success && this.currentMindMap.password)
            this.$refs['errorModal'].open()
        })
        .catch(error=>{
          console.log(error)
        })
      },
      deleteMindmap(){
        http
        .delete(`/msuite/${this.currentMindMap.unique_key}`)
        .then(res=>{
          window.open("/", "_self")
        })
        .catch(error=>{
          console.log(error)
        })
      },
      isMsuiteEmpty () {
        if (this.isMsuiteSaved){
          let data = new FormData()
          let token = document.querySelector('meta[name="csrf-token"]').attributes['content'].value;
          data.append('unique_key', this.currentMindMap.unique_key);
          data.append("authenticity_token", token);
          navigator.sendBeacon('is_msuite_empty', data)
        }
      },
      handleChangeIsMsuiteSaved(){
        this.isMsuiteSaved = false
      },
      updateMsuite(obj) {
        let _this = this
        http.put(`/msuite/${this.currentMindMap.unique_key}.json`, obj)
        .then((res) => {
          _this.currentMindMap = res.data.mindmap
        })
      },
      putMSuite (value) {
        let _this = this
        http.patch(`/msuite/${ this.currentMindMap.unique_key }.json`,{ mindmap: { title: value }})
        .then((res) => {
          _this.currentMindMap = res.data.mindmap
          _this.mSuiteName = res.data.mindmap.title
          _this.defaultDeleteDays = res.data.defaultDeleteDays
          _this.expDays = res.data.expDays
          _this.deleteAfter = res.data.deleteAfter
        })
      },
      openUserModal () {
        this.$refs['user-box-modal'].$refs['UserBoxModal'].open()
      },
      openCommentModal () {
        this.$refs['comment-box-modal'].$refs['commentBoxModal'].open()
      },
      saveMSuite () {
        this.isSaveMSuite = true
        this.$refs['confirm-save-key-modal'].$refs['confirmSaveKeyModal'].open()
      },
      goHome () {
        if(this.currentMindMap.mm_type != 'pollvote'){
          this.isSaveMSuite = false
          this.$refs['confirm-save-key-modal'].$refs['confirmSaveKeyModal'].open()
        }
      },
      resetMindmap () {
        this.pollEditing = false
        this.$emit("resetMindmap")
      },
      exportToWord () {
        this.$emit("exportToWord")
      },
      exportXLS (option) {
        this.$emit("exportXLS",option)
      },
      resetZoomScale () {
        this.$emit("resetZoomScale")
      },
      zoomInScale () {
        this.$emit("zoomInScale")
      },
      zoomOutScale () {
        this.$emit("zoomOutScale")
      },
      copySelectedNode () {
        this.$emit("copySelectedNode")
      },
      deleteSelectedNode () {
        this.$emit("deleteSelectedNode")
      },
      pasteCopiedNode () {
        this.$emit("pasteCopiedNode")
      },
      cutSelectedNode () {
        this.$emit("cutSelectedNode")
      },
      resetMap () {
        this.$emit("beforeReset")
        this.$refs['reset-map-modal'].$refs['resetMapModal'].open()
      },
      redoMindmap() {
        this.$emit("redoMindmap")
      },
      undoMindmap() {
        this.$emit("undoMindmap")
      },
      makeEditable () {
        if(this.currentMindMap.mm_type != 'pollvote'){
          this.editable = true
          setTimeout(() => {
            document.getElementById('mSuiteTitle').focus()
          }, 300)
          this.$emit('updateWhiteBoard')
          this.$emit('sendLocals', true)
        }
      },
      mSuiteTitleUpdate () {
        this.editable = false
        this.$emit('sendLocals', false)
        this.mSuiteName = this.mSuiteName.trim()
        if(this.mSuiteName) this.putMSuite(this.mSuiteName)
        else this.mSuiteName = this.currentMindMap.title
      },
      blurEvent (val, e) {
        if (e.target) {
          e.target.blur()
        };
      },
      exportImage(option) {
        if (this.currentMindMap.mm_type === 'simple')
        {
          this.$emit('exportToImage',option)
        } else if (this.currentMindMap.mm_type === 'Notepad') {
          this.$emit('exportToDocument',option)
        } else {
          const _this = this
          let elm = document.getElementById(this.exportId)
          if (this.currentMindMap.mm_type === 'kanban')
          {
            let inner_list = document.getElementsByClassName('drag-inner-list')
            inner_list.forEach(i=>i.classList.add('mh-100'))
          }
          if (this.currentMindMap.mm_type === 'spreadsheet'){
            elm = document.getElementsByClassName('jexcel_content')[0]
          }
          elm.style.transform = "scale(1)"
          let map_key = _this.currentMindMap.unique_key || "image"
          domtoimage.toPng(elm, {height: elm.scrollHeight, width: elm.scrollWidth})
          .then((url) => {
            if (option === 1){
              let downloadLink = document.createElement("a")
              document.body.appendChild(downloadLink)
              downloadLink.href = url
              downloadLink.download = map_key + ".png"
              downloadLink.click()
              document.body.removeChild(downloadLink)
            }
            else {
              var pdf = new jsPDF('l', 'px',[elm.scrollWidth,elm.scrollHeight],true);
              var width = pdf.internal.pageSize.getWidth();
              var height = pdf.internal.pageSize.getHeight();
              html2canvas(elm).then(canvas => {
                pdf.addImage(url, 'JPEG', 0, 0, width, height);
                pdf.save(map_key + '.pdf');
              });
            }
            _this.currentMindMap.mm_type === 'kanban' ? document.getElementsByClassName('drag-inner-list').forEach(i => i.classList.remove('mh-100')) : false
            _this.$refs['exportOption'].close()
          })
          .catch((err) => {
            console.error('oops, something went wrong!', err)
          })
        }
      },
    },
    watch: {
      currentMindMap: {
        handler(value) {
          this.mSuiteName = value.title
        }, deep: true
      },
    }
  }
</script>

<style>
  @import "../components/mindmaps/styles/mindmap_new.scss";

  .dot {
    width: 3px;
    height: 3px;
    background: #0F6674;
    display: inline-block;
    border-radius: 50%;
    right: 0px;
    bottom: 0px;
    margin: 0px 0.2px;
    position: relative;
    animation: jump 1s infinite;
  }
  .dots-cont:hover > .dot {
    animation: none;
  }
  .dots-cont .dot-1 {
    -webkit-animation-delay: 100ms;
    animation-delay: 100ms;
  }
  .dots-cont .dot-2 {
    -webkit-animation-delay: 200ms;
    animation-delay: 200ms;
  }
  .dots-cont .dot-3 {
    -webkit-animation-delay: 300ms;
    animation-delay: 300ms;
  }
  @keyframes jump {
    0%   {bottom: 0px;}
    20%  {bottom: 5px;}
    40%  {bottom: 0px;}
  }
  .mindmap-title{
    resize:none
  }
  @media (min-width: 1000px) and (max-width: 1280px) {
    .navbar_buttons{
      padding-right: 0px !important;
    }
    .navbar_button{
      margin-right: 0.5rem !important;
    }
    .navbar_icon{
      margin-left: 0rem !important;
    }
  }
  input:focus {
  outline: none;
  }
</style>
