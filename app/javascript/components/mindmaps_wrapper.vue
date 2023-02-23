<template>
  <div v-if="dataLoaded">
    <navigation-bar
      ref="navigationBar"
      :del-map="delMap"
      @undoMindmap="undoMindmap"
      @redoMindmap="redoMindmap"
      @zoomInScale="zoomInScale"
      @zoomOutScale="zoomOutScale"
      @resetZoomScale="resetZoomScale"
      @exportXLS="exportXLS"
      @export-to-document="exportToDoc"
      @exportToImage="exportImage($event)"
      @exportToWord="exportToWord"
      @deleteSelectedNode="deleteSelectedNode"
      @copySelectedNode="copySelectedNode"
      @pasteCopiedNode="pasteCopiedNode"
      @cutSelectedNode="cutSelectedNode"
      @before-reset="beforeReset"
      @before-save="beforeSave"
    ></navigation-bar>
    <component
      :is="viewIs"
      :undo-map="undoMap"
      :redo-map="redoMap"
      :zm-in-scale="zmInScale"
      :zm-out-scale="zmOutScale"
      :reset-zm-scale="resetZmScale"
      :export-def="exportDef"
      :export-doc="exportDoc"
      :export-img="exportImg"
      :export-word="exportWord"
      :del-selected-node="delSelectedNode"
      :copy-sel-node="copySelNode"
      :paste-node="pasteNode"
      :cut-sel-node="cutSelNode"
      :reset-before="resetBefore"
      :save-before="saveBefore"
      @deleteMindMap="deleteMindMap"
    />
  </div>
</template>

<script>
  import http from "./../common/http"
  import MindmapView from "./mindmaps/mindmap_new"
  import KanbanView from "./kanbans/kanban_new"
  import TreeMap from "./treemaps/tree_map"
  import Whiteboard from "./whiteboard/whiteboard"
  import PasswordView from "./password_view"
  import WaitForTime from "./wait_for_time"
  import PermanentLock from "./permanent_lock"
  import TreeChart from "./treechart/tree_chart"
  import ToDo from "./todo/todo"
  import Notepad from "./notepad/notepad"
  import SpreadSheet from "./spreadsheet/spreadsheet"
  import Poll from "./poll/poll"
  import VotingPoll from "./poll/polls/voting_poll"
  import Calendar from "./calendar/calendar"
  import VennDiagram from "./venndiagram/VennDiagram"
  import presentation from "./presentation/Presentation"
  import FileShare from "./fileshare/FileShare"
  import { newEventSource } from 'vue-parent-emit'

  export default {
    components: {
      MindmapView,
      KanbanView,
      TreeMap,
      PasswordView,
      WaitForTime,
      PermanentLock,
      Whiteboard,
      TreeChart,
      ToDo,
      Notepad,
      SpreadSheet,
      Poll,
      VotingPoll,
      Calendar,
      VennDiagram,
      presentation,
      FileShare
    },
    data() {
      return {
        loading: true,
        is_verified: false,
        dataLoaded: false,
        failedPasswordAttempts: 0,
        S_failedPasswordAttempts: Vue.prototype.$failed_password_attempts,
        S_lockTime: Vue.prototype.$lockout_period,
        lockTime: new Date(),
        undoMap         : newEventSource(),
        redoMap         : newEventSource(),
        zmInScale       : newEventSource(),
        zmOutScale      : newEventSource(),
        resetZmScale    : newEventSource(),
        exportDef       : newEventSource(),
        exportDoc       : newEventSource(),
        delMap          : newEventSource(),
        exportImg       : newEventSource(),
        exportWord      : newEventSource(),
        delSelectedNode : newEventSource(),
        copySelNode     : newEventSource(),
        pasteNode       : newEventSource(),
        cutSelNode      : newEventSource(),
        resetBefore     : newEventSource(),
        saveBefore      : newEventSource()
      }
    },
    beforeCreate: async function() {
      await this.$store.dispatch('getMSuite')
      this.is_verified = this.$store.getters.getDataMsuite.is_verified
      this.failedPasswordAttempts = this.$store.getters.getMsuite.failed_password_attempts
      this.lockTime = this.$store.getters.getMsuite.lockout_period
      this.$store.commit('setMsuiteParent', this.$store.getters.getMsuite.parent)
      await this.checkAttempts()
      this.dataLoaded = true
    },
    mounted: async function() {
      this.checkNotifs('event')
    },
    computed: {
      viewIs() {
        if(this.$store.getters.getMsuite.permanent_lock){
          return "PermanentLock"
        } else {
          if(this.failedPasswordAttempts > this.S_failedPasswordAttempts - 1){
            return "WaitForTime"
          } else {
            if(this.is_verified){
              switch (this.$store.getters.getMsuite.mm_type) {
                case "kanban":
                  return "KanbanView"
                case "tree_map":
                  return "TreeMap"
                case "whiteboard":
                  return "Whiteboard"
                case "tree_chart":
                  return "TreeChart"
                case "flowmap":
                  return "TreeChart"
                case "todo":
                  return "ToDo"
                case "Notepad":
                  return "Notepad"
                case "spreadsheet":
                  return "SpreadSheet"
                case "poll":
                  return "Poll"
                case "pollvote":
                  return "VotingPoll"
                case "calendar":
                  return "Calendar"
                case "venndiagram":
                  return "VennDiagram"
                case "presentation":
                  return "presentation"
                case "fileshare":
                  return "FileShare"
                default:
                  return "MindmapView"
              }
            }
            else if(this.$store.getters.getMsuite){
              return "PasswordView"
            }
            else{
              window.open("/","_self")
            }
          }
        }
      }
    },
    methods: {
      async checkAttempts(){
        let _this = this
        let time = new Date(new Date(_this.lockTime).getTime() + parseInt(_this.S_lockTime) * 60 * 1000)
        if(new Date() > time){
          await this.$store.dispatch('updateMSuite', {mindmap: {failed_password_attempts: 0}})
        }
      },
      zoomInScale () {
        this.zmInScale.emit()
      },
      zoomOutScale () {
        this.zmOutScale.emit()
      },
      resetZoomScale () {
        this.resetZmScale.emit()
      },
      undoMindmap () {
        this.undoMap.emit()
      },
      redoMindmap () {
        this.redoMap.emit()
      },
      deleteMindMap(){
        this.delMap.emit()
      },
      exportXLS (option) {
        this.exportDef.emit(option)
        this.$refs['navigationBar'].$refs['exportOptionCsv'].close()
      },
      beforeReset () {
        this.resetBefore.emit()
      },
      beforeSave () {
        this.saveBefore.emit()
      },
      exportToDoc (option) {
        this.exportDoc.emit(option)
        this.$refs['navigationBar'].$refs['exportOption'].close()
      },
      exportImage (option) {
        this.exportImg.emit(option)
      },
      exportToWord () {
        this.exportWord.emit()
      },
      deleteSelectedNode () {
        this.delSelectedNode.emit()
      },
      copySelectedNode () {
        this.copySelNode.emit()
      },
      pasteCopiedNode () {
        this.pasteNode.emit()
      },
      cutSelectedNode () {
        this.cutSelNode.emit()
      },
      checkNotifs(obj){
        if (!("Notification" in window)) {
        }
        else if (Notification.permission === "granted") {
          this.getKeys();
        }
        else if (Notification.permission !== 'denied') {
          Notification.requestPermission(function (permission) {
            if (permission === "granted") {
              this.getKeys();
            }
          });
        }
      },
      getKeys(){
        let _this = this
        navigator.serviceWorker.register('/serviceworker.js', {scope: '/'})
        .then(function(registration) {
          return registration.pushManager.getSubscription()
          .then(function(subscription) {
            if (subscription) {
              return subscription;
            }
            return registration.pushManager.subscribe({
              userVisibleOnly: true,
              applicationServerKey: Vue.prototype.$vapidPublicKey
            });
          });
        })
        .then(function(subscription) {
          _this.sendKeys(subscription.toJSON())
        });
      },

      sendKeys(subscription){
        http.post(`/msuite/${this.$route.params.key}/sendkeys`, {
          subscription: subscription,
          message: 'Sending subscription'
        });
      }
    }
  }
</script>
