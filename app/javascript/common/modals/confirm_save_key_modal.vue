<template>
  <sweet-modal ref="confirmSaveKeyModal" class="of_v">
    <div class="sweet_model_icon_div">
      <div class="radius_circle bg-warning center_flex mlr_a text-white">
        <i class="material-icons">notification_important</i>
      </div>
    </div>
    <h3 class="f_smooth_auto">Did you save the map key?</h3>
    <p class="text-muted fs_18">You will need this key <i><code>{{ currentMindMap.unique_key }}</code></i> to view the map again!</p>
    <div class="center_flex mt_2">
      <a
        href="javascript:;"
        class="btn_2 bg-danger text-white mr_1"
        @click.stop="goHome"
      >
        <i class="material-icons mr-1">done</i>
        Continue
      </a>
      <a
        href="javascript:;"
        class="btn_2 bg-primary text-white mr_1"
        @click.stop="closeModal"
      >
        <i class="material-icons mr-1">cancel</i>
        Cancel
      </a>
    </div>
  </sweet-modal>
</template>

<script>
  export default {
    name: "ConfirmSaveKeyModal",
    props: ['currentMindMap'],
    methods: {
      goHome() {
        window.open("/", "_self")
      },
      closeModal() {
        this.$refs.confirmSaveKeyModal.close()
      }
    }
  }
</script>
