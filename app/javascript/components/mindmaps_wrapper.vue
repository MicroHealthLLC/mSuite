<template>
  <div>
    <div v-if="loading">
      <sync-loader :loading="loading" color="#FFF" size="15px"></sync-loader>
    </div>
    <component
      v-else
      :is="viewIs"
      :current-mind-map="currentMindMap"
      :defaultDeleteDays="defaultDeleteDays"
      :expDays="expDays"
      :deleteAfter="deleteAfter"
      :whiteboard-image="currentMindMap.canvas"
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
  import TreeChart from "./treechart/tree_chart"
  import Flowmap from "./flowmap/flowmap"
  import ToDo from "./todo/todo"
  import Notepad from "./notepad/notepad"
  import SpreadSheet from "./spreadsheet/spreadsheet"
  import Poll from "./poll/poll"
  import Calendar from "./calendar/calendar"
  export default {
    components: {
      MindmapView,
      KanbanView,
      TreeMap,
      PasswordView,
      Whiteboard,
      TreeChart,
      Flowmap,
      ToDo,
      Notepad,
      SpreadSheet,
      Poll,
      Calendar
    },
    data() {
      return {
        loading: true,
        currentMindMap: {},
        defaultDeleteDays: '',
        expDays: '',
        deleteAfter: '',
        is_verified: false
      }
    },
    mounted() {
      if (this.$route.params.key) {
        this.getMindmap(this.$route.params.key)
        this.checkNotifs('event')
      }
    },
    computed: {
      viewIs() {
        if (this.is_verified) {
          switch (this.currentMindMap.mm_type) {
            case "kanban":
              return "KanbanView"
            case "tree_map":
              return "TreeMap"
            case "whiteboard":
              return "Whiteboard"
            case "tree_chart":
              return "TreeChart"
            case "flowmap":
              return "Flowmap"
            case "todo":
              return "ToDo"
            case "Notepad":
              return "Notepad"
            case "spreadsheet":
              return "SpreadSheet"
            case "poll":
              return "Poll"
            case "calendar":
              return "Calendar"
            default:
              return "MindmapView"
          }
        }
        else {
          return "PasswordView"
        }
      }
    },
    methods: {
      getMindmap(id) {
        http
          .get(`/msuite/${id}.json`)
          .then((res) => {
            if(res.data.mindmap == undefined) window.open('/', "_self");
            this.currentMindMap = res.data.mindmap
            this.defaultDeleteDays = res.data.defaultDeleteDays
            this.expDays = res.data.expDays
            this.deleteAfter = res.data.deleteAfter
            this.is_verified = res.data.is_verified
            this.loading = false
          })
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
