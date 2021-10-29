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

  export default {
    components: {
      MindmapView,
      KanbanView
    },
    data() {
      return {
        loading: true,
        currentMindMap: {}
      }
    },
    mounted() {
      if (this.$route.params.key) {
        this.getMindmap(this.$route.params.key)
      }
    },
    computed: {
      viewIs() {
        switch (this.currentMindMap.mm_type) {
          case "kanban":
            return "KanbanView"
          default:
            return "MindmapView"
        }
      }
    },
    methods: {
      getMindmap(id) {
        http
          .get(`/mindmaps/${id}.json`)
          .then((res) => {
            this.currentMindMap = res.data.mindmap
            this.loading = false
          })
      }
    }
  }
</script>
