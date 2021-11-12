<template>
  <div>
    <div v-if="loading">
      <sync-loader :loading="loading" color="#FFF" size="15px"></sync-loader>
    </div>
    <component
      v-else
      :is="viewIs"
      :current-mind-map="currentMindMap"
    />
  </div>
</template>

<script>
  import http from "./../common/http"
  import MindmapView from "./mindmaps/mindmap_new"
  import KanbanView from "./kanbans/kanban_new"
  import TreeMap from "./treemaps/tree_map"
  import PasswordView from "./password_view"

  export default {
    components: {
      MindmapView,
      KanbanView,
      TreeMap,
      PasswordView
    },
    data() {
      return {
        loading: true,
        currentMindMap: {},
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
          .get(`/mindmaps/${id}.json`)
          .then((res) => {
            this.currentMindMap = res.data.mindmap
            this.is_verified = res.data.is_verified
            this.loading = false
          })
      }
    }
  }
</script>
