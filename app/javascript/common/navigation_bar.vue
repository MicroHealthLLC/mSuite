<template>
  <div class="buttons_area" id="nav">
    <div class="buttons_container px-2 pt-2 row pb-0">
      <span :class="!$parent.is_verified ? 'mb-5 mt-1 ml-5' : 'navbar_icon flex ml-5 col-lg-2 col-md-2 col-sm-2 pr-0'">
        <a v-if="$parent.is_verified && mm_type != 'fileshare'" href="javascript:;" role="button" class="navbar-brand p-0" @click.stop="goHome">
          <img src="/assets/msuite.png" />
        </a>
        <a v-else href="javascript:;" role="button" class="navbar-brand p-0" @click.stop="routeHome">
          <img src="/assets/msuite.png" />
        </a>
      </span>
      <!-- <span v-if="$parent.is_verified"> -->
        <span class="col-lg-3 col-md-3 col-sm-3 d-flex justify-content-center px-0">
          <span v-show="!editable && mm_type != 'fileshare'" @click="makeEditable" class="my-1 py-1 pointer text-sapphire text-wrapper"
            data-toggle="tooltip" :title="mSuiteTitle">{{ mSuiteTitle | truncate(30) }}</span>
          <input v-show="editable" :rows="1" id="mSuiteTitle" @keydown.enter.prevent="mSuiteTitleUpdate" type="text"
            v-debounce:3000ms="blurEvent" v-model="mSuiteName"
            class="my-1 py-1 mindmap-title border-0 text-sapphire font-weight-bold align-items-center w-100 text-center"
            @blur="mSuiteTitleUpdate" placeholder="Enter mSuite Map Title" />
        </span>
        <span v-if="$parent.is_verified" class="navbar_buttons col-lg-6 col-md-12 col-sm-12 d-flex flex-row-reverse">
          <span class="navbar_button d-flex flex-row-reverse">
            <a v-if="duplicateMap && mm_type != 'fileshare'" href="javascript:;" role="button" v-b-tooltip.hover title="Duplicate"
              class="navbar_button d-flex text-info pointer edit_delete_btn mr-3 center_flex"
              @click.prevent="beforeClone">
              <i class="fas fa-clone icons d-flex center_flex"></i>
            </a>
            <a v-if="mm_type != 'pollvote' && mm_type != 'fileshare'" href="javascript:;" role="button" v-b-tooltip.hover title="Delete"
              class="navbar_button d-flex text-info pointer edit_delete_btn mr-3 center_flex"
              @click.prevent="deleteMap">
              <i class="fas fa-trash-alt icons d-flex center_flex"></i>
            </a>
            <a v-if="mm_type == 'fileshare'" href="javascript:;" role="button" v-b-tooltip.hover title="key"
              class="navbar_button d-flex text-info pointer edit_delete_btn mr-3 center_flex"
              @click.prevent="openKeyModal">
              <i class="fas fa-key icons d-flex center_flex"></i>
            </a>
            <a href="javascript:;" role="button" v-b-tooltip.hover title="User"
              class="navbar_button d-flex text-info pointer edit_delete_btn mr-3 center_flex"
              @click.prevent="openUserModal">
              <i class="fas fa-user-edit icons d-flex center_flex"></i>
            </a>
            <a v-if="mm_type != 'pollvote'" href="javascript:;" role="button"
              class="navbar_button d-flex text-info pointer edit_delete_btn mr-3 center_flex" v-b-tooltip.hover
              title="Comments" @click.prevent="openCommentModal">
              <i id="comment" class="fa fa-comment d-flex center_flex"></i>
            </a>
            <a v-if="mm_type != 'pollvote' && mm_type != 'fileshare'" href="javascript:;" role="button"
              class="navbar_button d-flex text-info edit_delete_btn mr-3 center_flex" v-b-tooltip.hover title="Reset"
              @click.stop="resetMap">
              <i class="material-icons restore_icon icons d-flex center_flex"></i>
            </a>
          </span>
          <span v-if="checkMSuiteTypes && mm_type != 'fileshare'" class="d-flex flex-row-reverse">
            <a href="javascript:;" role="button" v-b-tooltip.hover title="Redo"
              class="d-flex text-info pointer edit_delete_btn mr-3 center_flex" @click.stop="redoMindmap">
              <i class="fas fa-redo-alt"></i>
            </a>
            <a v-if="mm_type != 'fileshare'" href="javascript:;" role="button" v-b-tooltip.hover title="Undo"
              class="d-flex text-info pointer edit_delete_btn mr-3 center_flex" @click.stop="undoMindmap">
              <i class="fas fa-undo-alt"></i>
            </a>
          </span>
          <span class="d-flex">
            <a v-if="mm_type === 'simple'" ref="exportWordBtn" role="button" v-b-tooltip.hover title="Export Word"
              class="navbar_button d-flex text-info pointer edit_delete_btn mr-3 center_flex"
              @click.stop="exportToWord">
              <i class="fas fa-file-word icons d-flex center_flex"></i>
            </a>
            <a
              v-if="mm_type == 'todo' || mm_type =='calendar'"
              :disabled="disableToggle"
              :class="{ button_disabled: disableToggle }"
              ref="changeView"
              role="button"
              href="javascript:;"
              v-b-tooltip.hover :title="mm_type == 'todo' ? 'Switch to Calendar':'Switch to Todo'"
              class="navbar_button d-flex text-info edit_delete_btn mr-3 center_flex"
              @click.prevent.stop="changeView"
            >
              <i
                class="icons d-flex center_flex"
                :class="mm_type == 'todo' ? 'fad fa-calendar-alt' : 'fas fa-tasks'">
              </i>
            </a>
            <a v-if="mm_type == 'pollvote'" role="button" href="javascript:;"
              class="text-dark mt-2 mr-4 font-weight-bold" v-b-tooltip.hover title="Poll Expires">
              <span class="">
                Poll Expires: {{ pollExpDate }}
              </span>
            </a>
            <a v-if="mm_type != 'fileshare'" ref="exportBtn" role="button" href="javascript:;" v-b-tooltip.hover title="Export"
              class="navbar_button d-flex text-info pointer edit_delete_btn mr-3 center_flex"
              @click.prevent.stop="$refs['exportOption'].open()">
              <i class="material-icons export_icon icons d-flex center_flex"></i>
            </a>
            <a v-if="mm_type === 'spreadsheet' || mm_type === 'poll'" ref="exportBtn" role="button" href="javascript:;"
              class="navbar_button zoom_btn text-info edit_delete_btn center_flex mr-3" v-b-tooltip.hover title="Export"
              @click.prevent.stop="$refs['exportOptionCsv'].open()">
              <i class="fas fa-file-excel icons d-flex center_flex"></i>
            </a>
            <a v-if="mm_type != 'pollvote' && mm_type != 'fileshare'" role="button" href="javascript:;"
              class="navbar_button d-flex text-info pointer edit_delete_btn mr-3 center_flex"
              @click.prevent.stop="saveMSuite" v-b-tooltip.hover :title="'Expires ' + expireDateTime">
              <i class="material-icons save_btn icons d-flex center_flex"></i>
            </a>
          </span>
          <span v-if="mm_type === 'simple' || mm_type === 'tree_chart' || mm_type === 'flowmap'" class="d-flex">
            <a v-if="$store.getters.getScaleFactor != 1" href="javascript:;" role="button" v-b-tooltip.hover
              title="100%" class="zoom_btn text-info edit_delete_btn center_flex mr-3" @click.prevent="resetZoomScale">
              <i class="fas fa-history icons d-flex center_flex"></i>
            </a>
            <a href="javascript:;" role="button" v-b-tooltip.hover title="Zoom +"
              class="navbar_button zoom_btn text-info edit_delete_btn center_flex mr-3" @click.prevent="zoomInScale">
              <i class="material-icons zoom_in_icon icons d-flex center_flex"></i>
            </a>
            <a href="javascript:;" role="button" v-b-tooltip.hover title="Zoom -"
              class="navbar_button zoom_btn text-info edit_delete_btn mr-3 center_flex" @click.prevent="zoomOutScale">
              <i class="material-icons zoom_out_icon icons d-flex center_flex"></i>
            </a>
          </span>
          <span v-if="currentMindMap.editable && mm_type === 'simple'" class="d-flex flex-row-reverse">
            <span v-b-tooltip.hover title="Delete">
              <a href="javascript:;" role="button" :disabled="!checkSelectedNode"
                :class="{ button_disabled: !checkSelectedNode }"
                class="navbar_button d-flex text-info edit_delete_btn mr-3 center_flex"
                @click.stop="deleteSelectedNode">
                <i class="material-icons delete_icon icons d-flex center_flex"></i>
              </a>
            </span>
            <span v-b-tooltip.hover title="Paste">
              <a href="javascript:;" role="button" :disabled="(!checkSelectedNode || !getCopiedNode)"
                :class="{ button_disabled: (!checkSelectedNode || !getCopiedNode) }"
                class="navbar_button d-flex text-info edit_delete_btn mr-3 center_flex" @click.stop="pasteCopiedNode">
                <i class="fa fa-paste paste_icon icons d-flex center_flex"></i>
              </a>
            </span>
            <span v-b-tooltip.hover title="Cut">
              <a href="javascript:;" role="button" :disabled="!checkSelectedNode"
                :class="{ button_disabled: !checkSelectedNode }"
                class="navbar_button d-flex text-info edit_delete_btn mr-3 center_flex" @click.stop="cutSelectedNode">
                <i class="fa fa-cut cut_icon icons d-flex center_flex"></i>
              </a>
            </span>
            <span v-b-tooltip.hover title="Copy" class="">
              <a href="javascript:;" role="button" :disabled="!checkSelectedNode"
                :class="{ button_disabled: !checkSelectedNode }"
                class="navbar_button d-flex text-info edit_delete_btn mr-3 center_flex" @click.stop="copySelectedNode">
                <i class="material-icons copy_icon icons d-flex center_flex"></i>
              </a>
            </span>
          </span>
        </span>
        <span class="col-12 d-flex justify-content-end pt-2" style="height: 2rem;">
          <a href="javascript:;" role="button" class="navbar_button d-flex text-info pointer mr-3 center_flex"
            v-b-tooltip.hover title="Status">
            <div v-if="duplicateMap && renderUserList && renderUserList.length > 0">
              Editing by:
              <span v-for="user in renderUserList">
                {{ user }},
              </span>
            </div>
          </a>
          <a href="javascript:;" role="button" class="navbar_button d-flex text-info pointer mr-3 center_flex"
            v-b-tooltip.hover title="Status" v-if="duplicateMap && renderTemporaryUser">
            <span> Last Edited By {{ renderTemporaryUser }}</span>
          </a>
        </span>
      <!-- </span> -->
    </div>
    <sweet-modal>
    </sweet-modal>
    <comment-map-modal :mind-map='currentMindMap' ref="comment-box-modal"></comment-map-modal>
    <confirm-save-key-modal @openPrivacy="openPrivacy" @updateInActiveDate="updateMsuite" @deleteMap="deleteMap"
      @isSave="isSave" @changeIsMsuitSaved="handleChangeIsMsuiteSaved" ref="confirm-save-key-modal"
      :current-mind-map="currentMindMap" :isSaveMSuite="isSaveMSuite" :isSaveMap="isSaveMap"
      :defaultDeleteDays="defaultDeleteDays" :deleteAfter="deleteAfter" :expDays="expDays">
    </confirm-save-key-modal>
    <user-map-modal :mind-map='currentMindMap' ref="user-box-modal" @addKey="addKey"></user-map-modal>
    <sweet-modal ref="exportOption" class="of_v" icon="info" title="Export Format">
      Kindly Choose the Format of Export
      <button slot="button" v-if="mm_type === 'Notepad'" @click="exportImage(1)"
        class="btn btn-warning float-left mr-2">Export to Document</button>
      <button slot="button" v-else @click="exportImage(1)" class="btn btn-warning float-left mr-2">Export to
        Image</button>

      <button slot="button" v-if="mm_type === 'Notepad'" @click="exportImage(2)" class="btn btn-info float-left">Export
        to rtf</button>
      <button slot="button" v-else @click="exportImage(2)" class="btn btn-info float-left">Export to Pdf</button>
      <button slot="button" @click="$refs['exportOption'].close()" class="btn btn-secondary">Cancel</button>
    </sweet-modal>
    <sweet-modal ref="exportOptionCsv" class="of_v" icon="info" title="Export Format">
      Kindly Choose the Format of Export
      <button slot="button" @click="exportXLS(1)" class="btn btn-warning float-left mr-2">Export to Excel</button>

      <button slot="button" @click="exportXLS(2)" class="btn btn-info float-left">Export to csv</button>
      <button slot="button" @click="$refs['exportOptionCsv'].close()" class="btn btn-secondary">Cancel</button>
    </sweet-modal>
    <reset-map-modal ref="reset-map-modal" @reset-mindmap="resetMindmap"></reset-map-modal>
    <make-private-modal ref="make-private-modal" @password-apply="passwordProtect"
      @password_mismatched="$refs['passwordMismatched'].open()" :isSaveMSuite="isSaveMSuite">
    </make-private-modal>
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
    <section v-if="exportLoading" class="export-loading-tab">
      <div class="loader-wrap">
        <sync-loader :loading="exportLoading" color="#FFF" size="15px"></sync-loader>
      </div>
    </section>
    <clone-modal ref="clone-modal"></clone-modal>
  </div>
</template>

<script>
import ConfirmSaveKeyModal from "./modals/confirm_save_key_modal"
import { jsPDF } from "jspdf";
import html2canvas from "html2canvas"
import domtoimage from "dom-to-image"
import http from "./http"
import ResetMapModal from '../components/mindmaps/modals/reset_map_modal'
import UserMapModal from "./modals/user_map_modal"
import CommentMapModal from "./modals/comment_map_modal"
import MakePrivateModal from "./modals/make_private_modal"
import DeleteMapModal from './modals/delete_modal'
import DeletePasswordModal from './modals/delete_password_modal'
import TemporaryUser from "../mixins/temporary_user.js"
import CloneModal from './modals/clone_modal'

export default {
  name: "NavigationBar",
  mixins: [TemporaryUser],
  props: ["delMap"],
  data() {
    return {
      mSuiteName: this.$store.getters.getMsuite.title,
      mm_type: this.$store.getters.getmmType,
      defaultDeleteDays: this.$store.getters.getDataMsuite.defaultDeleteDays,
      deleteAfter: this.$store.getters.getDataMsuite.deleteAfter,
      expDays: this.$store.getters.getDataMsuite.expDays,
      editable: false,
      isSaveMSuite: true,
      isMsuiteSaved: true,
      exportLoading: false,
      disableToggle: false,
      failed_password_attempts: Vue.prototype.$failed_password_attempts,
      lockout_period: Vue.prototype.$lockout_period,
      getSelectedNode: null,
      getCopiedNode: null,
      password: JSON.parse(JSON.stringify(this.$store.getters.getMsuite.password)),
      isSaveMap: JSON.parse(JSON.stringify(this.$store.getters.getMsuite.is_save)),
      dateFormate: { month: 'long', weekday: 'long', year: 'numeric', day: 'numeric' }
    }
  },
  created() {
    window.addEventListener('beforeunload', this.isMsuiteEmpty)
  },
  mounted() {
    if (this.delMap) this.delMap(this.deleteMap)
    this.checkDate()
  },
  updated() {
    this.checkDate()
  },
  components: {
    DeletePasswordModal,
    DeleteMapModal,
    ConfirmSaveKeyModal,
    ResetMapModal,
    CommentMapModal,
    UserMapModal,
    MakePrivateModal,
    CloneModal
  },
  computed: {
    checkSelectedNode() {
      if (this.$store.getters.getSelectedNode && this.$store.getters.getSelectedNode.id == "") this.getSelectedNode = null
      else this.getSelectedNode = this.$store.getters.getSelectedNode
      return this.getSelectedNode
    },
    currentMindMap() {
      return this.$store.getters.getMsuite
    },
    renderUserList() {
      if (this.$store.state.userEdit && this.$store.state.userList.length > 0) return this.$store.state.userList
    },
    mSuiteTitle() {
      if (this.mm_type == 'pollvote') return this.$store.getters.getMsuiteParent.title
      else return this.mSuiteName
    },
    selectedNode(){
      return this.$store.getters.getSelectedNode
    },
    copiedNode(){
      return this.$store.getters.getCopiedNode
    },
    pollExpDate() {
      let duedate = JSON.parse(this.$store.getters.getMsuiteParent.canvas).pollData.duedate
      let pollDuedate = moment(new Date(duedate)).format('DD MMM YYYY')
      if (pollDuedate == 'Invalid date') pollDuedate = "Never"
      return pollDuedate
    },
    expireDateTime() {
      let x = moment(new Date(this.$store.getters.getMsuite.will_delete_at)).add(1, 'days').format("ddd MMM Do, YYYY")
      return x
    },
    checkMSuiteTypes() {
      return this.mm_type != 'pollvote'
    },
    renderTemporaryUser() {
      if (this.$store.state.userEdit && this.$store.state.temporaryUser) return this.$store.state.temporaryUser
    },
    duplicateMap() {
      return this.mm_type != 'pollvote'
    }
  },
  filters: {
    truncate: function (data, num) {
      if (data === undefined) return
      let reqdString = data.split("").slice(0, num).join("");
      if (reqdString.length < data.length) {
        reqdString = reqdString.concat('.....')
      }
      return reqdString;
    }
  },
  methods: {
    checkMindmapType(){
      let mycanvas = null
      let isValidJSON = true
      try { mycanvas = JSON.parse(this.currentMindMap.canvas) } catch { isValidJSON = false }
      if (!mycanvas) isValidJSON = false
      if (isValidJSON && mycanvas.user) {
        mycanvas.user = this.$store.getters.getUser
        this.currentMindMap.canvas = JSON.stringify(mycanvas)
      }
      else if (isValidJSON && this.checkMmType()) {
        let _this = this
        mycanvas = {
          ...mycanvas,
          user: _this.$store.getters.getUser
        }
        this.currentMindMap.canvas = JSON.stringify(mycanvas)
      }
      else {
        this.currentMindMap.canvas = this.$store.getters.getUser
      }
    },
    isSave() {
      this.sendLocals(false)
      this.checkMindmapType()
      this.currentMindMap.is_save = 'is_public'
      this.$store.dispatch('updateMSuite', this.currentMindMap)
      if(this.currentMindMap.password) location.reload()
    },
    deleteMap() {
      this.$refs['delete-map-modal'].$refs['deleteMapModal'].open()
    },
    openPrivacy(val) {
      this.isSaveMSuite = val
      this.$refs['make-private-modal'].$refs['makePrivateModal'].open()
    },
    async passwordProtect(new_password, old_password) {
      this.sendLocals(false)
      this.checkMindmapType()
      this.currentMindMap.is_save = 'is_private'
      this.currentMindMap.password = new_password
      this.currentMindMap.old_password = old_password
      await this.$store.dispatch('updateMSuite', this.currentMindMap)

        if (this.$store.getters.getError) {
          this.$refs['errorModal'].open()
        }
        else {
          this.$root.$emit("isSavingDays", true)
          this.$emit("before-save")
          this.currentMindMap.password = this.$store.getters.getMsuite.password
          if (!this.isSaveMSuite) window.open("/", "_self")
          else location.reload()
          this.$root.$emit("isSavingDays", false)
          this.$refs['successModal'].open()
        }
    },
    passwordAgain() {
      this.$refs['passwordMismatched'].close()
      this.openPrivacy()
    },
    confirmDeleteMindmap() {
      if (this.password) {
        this.$refs['delete-password-modal'].$refs['DeletePasswordModal'].open()
      }
      else {
        this.deleteMindmap()
      }
    },
    deleteMindmapProtected(password) {
      http
        .delete(`/msuite/${this.currentMindMap.unique_key}.json?password_check=${password}`)
        .then(res => {
          if (res.data.success) window.open("/", "_self")
          if (!res.data.success && this.currentMindMap.password) {
            this.currentMindMap.failed_password_attempts = this.currentMindMap.failed_password_attempts + 1
            this.$store.dispatch('updateMSuite', this.currentMindMap)
            this.$refs['errorModal'].open()
          }
        })
        .catch(error => {
          console.log(error)
        })
    },
    deleteMindmap() {
      http
        .delete(`/msuite/${this.currentMindMap.unique_key}`)
        .then(res => {
          window.open("/", "_self")
        })
        .catch(error => {
          console.log(error)
        })
      },
      setHeaders(){
        let data = new FormData()
        let token = document.querySelector('meta[name="csrf-token"]').attributes['content'].value
        data.append('unique_key', this.currentMindMap.unique_key)
        data.append("authenticity_token", token)
        return data
      },
    isMsuiteEmpty() {
      if (this.isMsuiteSaved && this.mm_type != "fileshare") {
        navigator.sendBeacon('is_msuite_empty', this.setHeaders())
      }
    },
    handleChangeIsMsuiteSaved() {
      this.isMsuiteSaved = false
    },
    updateMsuite(obj) {
      this.$store.dispatch('updateMSuite', obj)
    },
    putMSuite(value) {
      this.sendLocals(false)
      this.checkMindmapType()
      this.currentMindMap.title = value
      this.$store.dispatch('updateMSuite', this.currentMindMap)
    },
    openUserModal() {
      this.$refs['user-box-modal'].$refs['UserBoxModal'].open()
    },
    openKeyModal() {
      this.$refs['user-box-modal'].$refs['keyModal'].open()
    },
    openCommentModal() {
      this.$refs['comment-box-modal'].$refs['commentBoxModal'].open()
    },
    saveMSuite() {
      this.$emit("before-save")
      this.isSaveMSuite = true
      this.$refs['confirm-save-key-modal'].$refs['confirmSaveKeyModal'].open()
    },
    goHome() {
      if (this.mm_type != 'pollvote') {
        this.$emit("before-save")
        this.isSaveMSuite = false
        this.$refs['confirm-save-key-modal'].$refs['confirmSaveKeyModal'].open()
      }
    },
    routeHome() {
      window.open("/", "_self")
    },
    resetMindmap() {
      this.$store.commit('setSelectedNode',null)
      this.$store.dispatch('resetMindmap')
    },
    exportToWord() {
      this.$emit("exportToWord")
    },
    exportXLS(option) {
      this.$emit("exportXLS", option)
    },
    resetZoomScale() {
      this.$store.dispatch('setScaleFactor', 1)
      this.$emit("resetZoomScale")
    },
    zoomInScale() {
      this.$emit("zoomInScale")
    },
    zoomOutScale() {
      this.$emit("zoomOutScale")
    },
    copySelectedNode() {
      this.$emit("copySelectedNode")
    },
    deleteSelectedNode() {
      this.$store.commit('setCopiedNode' , null)
      this.$emit("deleteSelectedNode")
    },
    pasteCopiedNode() {
      if (this.getSelectedNode) this.$emit("pasteCopiedNode")
    },
    cutSelectedNode() {
      this.$emit("cutSelectedNode")
    },
    resetMap() {
      this.$emit("before-reset")
      this.$refs['reset-map-modal'].$refs['resetMapModal'].open()
    },
    redoMindmap() {
      this.$emit("redoMindmap")
    },
    undoMindmap() {
      this.$emit("undoMindmap")
    },
    makeEditable() {
      if (this.mm_type != 'pollvote') {
        this.editable = true
        setTimeout(() => {
          document.getElementById('mSuiteTitle').focus()
        }, 300)
      }
    },
    mSuiteTitleUpdate() {
      this.editable = false
      this.mSuiteName = this.mSuiteName.trim()
      if (this.mSuiteName) {
        if (this.mSuiteName != 'Title') {
          this.sendLocals(true)
          this.putMSuite(this.mSuiteName)
        }
      }
      else this.mSuiteName = this.currentMindMap.title
    },
    blurEvent(val, e) {
      if (e.target) {
        e.target.blur()
      };
    },
    async changeView(){
      if (!this.disableToggle){
        let data = { mm_type: 'todo'}
        if(this.mm_type == 'todo'){
            data.mm_type = 'calendar'
          this.updateMsuite(data)
        } else if (this.mm_type == 'calendar') this.updateMsuite(data)
      }
    },
    addKey(key){
      this.currentMindMap.password = key
      this.$store.dispatch('updateMSuite', this.currentMindMap)
    },
    exportImage(option) {
      this.exportLoading = true
      if (this.mm_type === 'simple') {
        this.$emit('exportToImage', option)
        this.$refs.exportBtn.blur()
        this.exportLoading = false
        this.$refs['exportOption'].close()
      }
      else if (this.mm_type === 'Notepad') {
        this.$emit('export-to-document', option)
        this.exportLoading = false
      }
      else {
        const _this = this
        let elm = document.getElementById(this.$store.getters.getExportId)
        if (this.mm_type === 'kanban') {
          let inner_list = document.getElementsByClassName('drag-inner-list')
          inner_list.forEach(i => i.classList.add('mh-100'))
        }
        if (this.mm_type === 'spreadsheet') {
          elm = document.getElementsByClassName('jexcel_content')[0]
        }
        if (this.mm_type == 'poll' || this.mm_type == 'pollvote') {
          let inner_elm = document.getElementById('poll-title')
          if (inner_elm) inner_elm.classList.remove("d-none");
        }
        elm.style.transform = "scale(1)"
        let map_key = _this.currentMindMap.unique_key || "image"
        domtoimage.toPng(elm, { height: elm.scrollHeight, width: elm.scrollWidth })
          .then((url) => {
            if (option === 1) {
              let downloadLink = document.createElement("a")
              document.body.appendChild(downloadLink)
              downloadLink.href = url
              downloadLink.download = map_key + ".png"
              downloadLink.click()
              document.body.removeChild(downloadLink)
              this.exportLoading = false
            }
            else {
              var pdf = new jsPDF('l', 'px', [elm.scrollWidth, elm.scrollHeight], true);
              var width = pdf.internal.pageSize.getWidth();
              var height = pdf.internal.pageSize.getHeight();
              html2canvas(elm).then(canvas => {
                pdf.addImage(url, 'JPEG', 0, 0, width, height);
                pdf.save(map_key + '.pdf');
              });
              this.exportLoading = false
            }
            if (_this.mm_type === 'kanban') {
             document.getElementsByClassName('drag-inner-list').forEach(i => i.classList.remove('mh-100'))
            }
            if ((_this.mm_type === 'poll' || _this.mm_type == 'pollvote') && document.getElementById('poll-title')) {
                document.getElementById('poll-title').classList.add('d-none')
            }
            _this.$refs['exportOption'].close()
          })
          .catch((err) => {
            console.error('oops, something went wrong!', err)
            this.exportLoading = false
          })
      }
    },
    beforeClone() {
      if (this.mm_type == 'calendar' || this.mm_type == 'todo') this.$refs['clone-modal'].$refs['cloneModal'].open()
      else this.$store.dispatch('cloneMap')
    },
    checkMmType(){
    return (this.mm_type == 'whiteboard' || this.mm_type == 'poll' || this.mm_type == 'Notepad' || this.mm_type == 'spreadsheet')
    },
    checkDate() {
      if(this.mm_type == 'todo' && this.currentMindMap.nodes){
        for (let i=0; i<this.currentMindMap.nodes.length; i++){
          if(this.currentMindMap.nodes[i].duedate){
            this.disableToggle = false
            return
          }
        }
        this.disableToggle = true
        return
      }
    }
  },
  watch: {
    currentMindMap: {
      handler(value) {
        this.currentMindMap.is_save = value.is_save
        this.mSuiteName = value.title
        this.mm_type = value.mm_type
      }, deep: true
    },
    selectedNode: {
      handler(value) {
        if (value && value.id == "" && !this.getCopiedNode) this.getSelectedNode = null
        else this.getSelectedNode = value
      }
    },
    copiedNode: {
      handler(value) {
        this.getCopiedNode = value
      }
    }
  }
}
</script>

<style lang="scss">
  @import "../components/mindmaps/styles/mindmap_new.scss";
  @import "./styles/navigation_style.scss";

  .mindmap-title {
    resize: none
  }
  input:focus {
    outline: none;
  }
</style>
