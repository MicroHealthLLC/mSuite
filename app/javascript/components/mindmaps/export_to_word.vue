<template>
  <div class="export-main">
    <div ref="exportDoc" class="WordSection export-doc">
      <div class="export-head">
        <h2>{{mindMap.name}}</h2>
        <div v-if="mindMap.description" class="text-secondary" v-html="mindMap.description"></div>
        <p v-else class="text-secondary font-italic">No description</p>
      </div>
      <div class="text-left">
        <nested-list
          v-if="!loading"
          :editable="mindMap.editable"
          :children="DV_mindmap.children"
          group="_0_"
          prefix-index="0"
        />
      </div>
    </div>
    <div v-if="mindMap" class="export-btn mt_2">
      <a href="javascript:;" class="btn_1 btn-sm bg-primary text-white mr_1" @click.stop="export2Doc">
        <i class="material-icons mr-1">save_alt</i>
        Download
      </a>
    </div>
  </div>
</template>

<script>
  import http from "../../common/http"
  import NestedList from "../shared/nested_list.vue"

  export default {
    components: {
      NestedList
    },
    props: [
      'mindMap'
    ],
    data() {
      return {
        loading: true,
        DV_mindmap: {
          children: []
        }
      }
    },
    mounted() {
      this.computeChildNodes()
    },
    methods: {
      computeChildNodes() {
        http
          .get(`/msuite/${this.mindMap.unique_key}/compute_child_nodes.json`)
          .then((res) => {
            this.DV_mindmap.children = res.data.mindmap.children
            this.loading = false
          }).catch((error) => {
            console.error(error)
            this.loading = false
          })
      },
      export2Doc() {
        let preHtml = "<html xmlns:o='urn:schemas-microsoft-com:office:office' xmlns:w='urn:schemas-microsoft-com:office:word' xmlns='http://www.w3.org/TR/REC-html40'><head><meta charset='utf-8'><title>Export Mindmap to Document</title><link href='https://stackpath.bootstrapcdn.com/bootstrap/4.4.1/css/bootstrap.min.css' rel='stylesheet' integrity='sha384-Vkoo8x4CGsO3+Hhxv8T/Q5PaXtkKtu6ug5TOeNV6gBiFeWPGFN9MuhOf23Q9Ifjh' crossorigin='anonymous'></head><body>"
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
