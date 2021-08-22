<template>
  <sweet-modal ref="resetMapModal" class="of_v">
    <div class="sweet_model_icon_div">
      <div class="radius_circle bg-warning center_flex mlr_a">
        <i class="material-icons text-white">restore</i>
      </div>
    </div>
    <h3 class="f_smooth_auto">Are you Sure you want to reset this Map?</h3>
    <p class="text-muted fs_18">Your current changes will be discarded, you won't be able to revert this!</p>
    <div class="center_flex mt_2">
      <a
        href="javascript:;"
        class="btn_2 bg-danger text-white mr_1"
        @click.stop="resetMindmap"
      >
        <i class="material-icons mr-1">done</i>
        Continue
      </a>
      <a
        href="javascript:;"
        class="btn_2 bg-primary text-white mr_1"
        @click.stop="closeMapModal"
      >
        <i class="material-icons mr-1">cancel</i>
        Cancel
      </a>
    </div>
  </sweet-modal>
</template>

<script>
  export default {
    Name: "ResetMapModal",
    methods: {
      resetMindmap() {
        this.$emit('reset-mindmap')
        this.closeMapModal()
      },
      closeMapModal() {
        this.$refs.resetMapModal.close()
      }
    }
  }
</script>
