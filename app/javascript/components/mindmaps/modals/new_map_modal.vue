<template>
  <sweet-modal ref="newMapModal" class="of_v">
    <div class="sweet_model_icon_div">
      <div class="radius_circle bg-warning center_flex mlr_a">
        <i class="material-icons text-white">error_outline</i>
      </div>
    </div>
    <h3 class="f_smooth_auto">Are you Sure?</h3>
    <p class="text-muted fs_18">You may want to open in new Tab!</p>
    <div class="center_flex mt_2">
      <a
        href="javascript:;"
        class="btn_2 bg-danger text-white mr_1"
        @click.stop="openNewMap"
      >
        <i class="material-icons mr-1">done</i>
        Continue Here
      </a>
      <a
        href="javascript:;"
        class="btn_2 bg-warning text-white mr_1"
        @click.stop="openNewMapNewWindow"
      >
        <i class="material-icons mr-1">open_in_new</i>
        Open new Tab!
      </a>
      <a
        href="javascript:;"
        class="btn_2 bg-primary text-white mr_1"
        @click.stop="closeNewMap"
      >
        <i class="material-icons mr-1">cancel</i>
        Cancel
      </a>
    </div>
  </sweet-modal>
</template>

<script>
  export default  {
    name: "NewMindmapModal",
    methods: {
      openNewMap() {
        this.$emit('open-new-map')
        this.closeNewMap()
      },
      closeNewMap() {
        this.$refs.newMapModal.close()
      },
      openNewMapNewWindow() {
        window.open(window.location.origin+'/msuite/new')
      }
    }
  }
</script>
