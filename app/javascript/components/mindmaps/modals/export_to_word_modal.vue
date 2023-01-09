<template>
  <sweet-modal
    ref="exportToWordModal"
    class="of_v"
    id="export-word-modal"
    :hide-close-button="true"
    @close="nullifyAttachmentModal"
    >
    <export-to-word
      v-if="openVModal"
      :mind-map="currentMindMap"
    />
  </sweet-modal>
</template>

<script>
  import ExportToWord from "./../export_to_word"
  export default {
    name: "ExportToWordModal",
    components: {
      ExportToWord
    },
    props: ['openVModal', 'currentMindMap'],
    methods: {
      nullifyAttachmentModal() {
        this.$emit('nullify-attachment-modals')
      }
    }
  }
</script>

<style lang=scss scoped>
  #export-word-modal ::v-deep .sweet-modal {
    min-width: 800px;
  }
</style>
