<template>
  <div class="export-main">
    <div ref="exportDoc" class="export-doc">
      <div class="export-head">
        <h5>{{mindMap.name}}</h5>
        <div v-if="mindMap.description" class="text-secondary" v-html="mindMap.description"></div>
        <p v-else class="text-secondary font-italic">No description</p>
      </div>
      <nested-list :list="DV_mindmap.children" />
    </div>
    <div v-if="mindMap" class="export-btn mt_2">
      <a
        href="javascript:;" 
        class="btn_1 btn-sm bg-primary text-white mr_1"
        @click.stop="export2Doc" 
      >
        <i class="material-icons mr-1">save_alt</i>
        Download
      </a>
    </div>
  </div>
</template>

<script>
  import NestedList from "../shared/nested_list.vue"
  export default {
    components: {
      NestedList
    },
    props: [
      'mindMap',
      'nodes'
    ],
    data() {
      return {
        DV_mindmap: {
          id: 0,
          name: this.mindMap.name,
          description: this.mindMap.description,
          children: []
        }
      }
    },
    mounted() {
      this.computeChildNodes(this.DV_mindmap)
    },
    methods: {
      computeChildNodes(node) {
        node.children = this.nodes.filter((n) => n.parent_node == node.id)
        node.children.map((nod) => this.computeChildNodes(nod))
      },
      export2Doc(){
        let preHtml = "<html xmlns:o='urn:schemas-microsoft-com:office:office' xmlns:w='urn:schemas-microsoft-com:office:word' xmlns='http://www.w3.org/TR/REC-html40'><head><meta charset='utf-8'><title>Export HTML To Doc</title></head><body>"
        let postHtml = "</body></html>"
        let html = preHtml + this.$refs.exportDoc.innerHTML + postHtml

        let blob = new Blob(['\ufeff', html], {
          type: 'application/msword'
        })
        
        let url = 'data:application/vnd.ms-word;charset=utf-8,' + encodeURIComponent(html)
        let filename = this.mindMap ? this.mindMap.unique_key + ".doc" : "document.doc"
        let downloadLink = document.createElement("a")
        document.body.appendChild(downloadLink)
        
        if (navigator.msSaveOrOpenBlob) {
          navigator.msSaveOrOpenBlob(blob, filename)
        } 
        else {
          downloadLink.href = url
          downloadLink.download = filename
          downloadLink.click()
        }
        
        document.body.removeChild(downloadLink)
      }
    }
  }
</script>

<style scoped lang="scss">
  @import "./styles/export_to_word.scss";
</style>
