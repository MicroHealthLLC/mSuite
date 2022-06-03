<template>
  <sweet-modal ref="openMapModal" class="of_v">
    <div class="sweet_model_icon_div">
      <div class="radius_circle bg-success center_flex mlr_a">
        <i class="material-icons text-white">folder_open</i>
      </div>
    </div>
    <p class="text-muted fs_18">Enter the document key you want to open here!</p>
    <div class="form-horizontal">
      <div class="row form-group mt-2">
        <label class="control-label col-4" for="mindmap_name">Mindmap Name:</label>
        <input type="text" placeholder="Enter document key" v-model="openMindMapKey" class="form-control col-6 ">
      </div>
    </div>
    <div class="center_flex mt_2">
      <a
        href="javascript:;"
        class="btn_2 bg-success text-white mr_1"
        @click.stop.prevent="openPreviousMap"
      >
        <i class="material-icons mr-1">done</i>
        Open
      </a>
      <a
        href="javascript:;"
        class="btn_2 bg-primary text-white mr_1"
        @click.stop.prevent="closeMapModal"
      >
        <i class="material-icons mr-1">cancel</i>
        Cancel
      </a>
    </div>
  </sweet-modal>
</template>

<script>
  export default {
    name: "OpenMapModal",
    data() {
      return {
        openMindMapKey: ''
      }
    },
    methods: {
      openPreviousMap() {
        this.$emit('open-previous-map', this.openMindMapKey)
        this.closeMapModal()
      },
      closeMapModal() {
        this.openMindMapKey = ''
        this.$refs.openMapModal.close()
      }
    }
  }
</script>
