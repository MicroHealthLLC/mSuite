<template>
  <sweet-modal @close="nullifyAttachmentModal" ref="centralAttachmentModal" id="central-attachment-modal" class="of_v">
    <div class="sweet_model_icon_div">
      <div class="radius_circle bg-success center_flex mlr_a">
        <i class="material-icons text-white">post_add</i>
      </div>
    </div>
    <sweet-modal-tab title="Description" id="central-description-tab">
      <div>
        <section>
          <quill-editor
            v-model="centralNotes"
            ref="contentEditor"
            :options="editorOption"
            :disabled="!currentMindMap.editable"
            v-debounce:1000ms="blurEvent"
          >
          </quill-editor>

          <div v-if="currentMindMap.editable" class="right_flex mt_2">
            <a
              href="javascript:;"
              class="btn_1 btn-sm text-white mr_1"
              :class="statusBtn == 'Saved' ? 'bg-success':'bg-danger'"
            >
              <i v-if="statusBtn == 'Saved'" class="material-icons mr-1">done</i>
              {{ statusBtn }}
            </a>
          </div>
        </section>
      </div>
    </sweet-modal-tab>
  </sweet-modal>
</template>

<script>
  import { quillEditor } from "vue-quill-editor"
  import "quill/dist/quill.core.css"
  import "quill/dist/quill.snow.css"
  import "quill/dist/quill.bubble.css"

  export default {
    name: "CentralAttachmentModal",
    props: ['editorOption', 'currentMindMap'],
    components: {
      quillEditor
    },
    data() {
      return {
        statusBtn: "Saved",
        centralNotes: ""
      }
    },
    mounted() {
      if (this.currentMindMap.id) {
        this.centralNotes = this.currentMindMap.description
      }
    },
    methods: {
      blurEvent(val, event){
        if(event.keyCode == 13) return false;
        this.updateMapNotes()
      },
      nullifyAttachmentModal() {
        this.$emit('nullify-attachment-modals')
      },
      updateMapNotes() {
        this.$emit('update-map-notes', this.centralNotes)
      },
    },
    updated(){
      if(this.centralNotes === this.currentMindMap.description) this.statusBtn = 'Saved';
      else this.statusBtn = 'Editing...';
    },
    watch: {
      currentMindMap: {
        handler(value) {
          this.centralNotes = value.description
        }, deep: true
      }
    }
  }
</script>

<style lang=scss scoped>
  #central-attachment-modal ::v-deep .sweet-modal {
    min-width: 800px;
    .sweet-content {
      padding-top: 1.5em;
      padding-bottom: 2.5em;
    }
  }

  #central-attachment-modal ::v-deep .ql-container {
    height: 40vh;
    max-height: 40vh;
    border-top: 1px solid #ccc;
  }

  #central-attachment-modal ::v-deep .ql-toolbar {
    display: none;
  }

  .edit-icon {
    position: absolute;
    top: 88px;
    border-radius: 50%;
    left: 14px;
    font-size: 0px;
    padding: 10px;
    background-color: #edeeef;
    color: #17a2b8;
    cursor: pointer;
    z-index: 99;
    i {
      font-size: 20px;
    }
  }

  .edit-icon:hover {
    i {
      font-size: 22px;
    }
  }
</style>
