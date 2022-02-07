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
      :deleteAfter="deleteAfter"
      :whiteboard-image="currentMindMap.image"
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

  export default {
    components: {
      MindmapView,
      KanbanView,
      TreeMap,
      PasswordView,
      Whiteboard,
      TreeChart
    },
    data() {
      return {
        loading: true,
        currentMindMap: {},
        defaultDeleteDays: '',
        deleteAfter: '',
        is_verified: false
      }
    },
    mounted() {
      if (this.$route.params.key) {
        this.getMindmap(this.$route.params.key)
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
            this.currentMindMap = res.data.mindmap
            this.defaultDeleteDays = res.data.defaultDeleteDays
            this.deleteAfter = res.data.deleteAfter
            this.is_verified = res.data.is_verified
            this.loading = false
          })
      }
    }
  }
</script>
