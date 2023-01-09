<template>
  <sweet-modal @close="nullifyAttachmentModal" ref="attachmentModal" id="attachment-modal" class="of_v">
    <div class="sweet_model_icon_div">
      <div class="radius_circle bg-success center_flex mlr_a">
        <i class="material-icons text-white">post_add</i>
      </div>
    </div>
    <sweet-modal-tab title="Description" id="description-tab">
      <template v-if="editedNode">
        <section>
          <quill-editor
            v-model="nodeNotes"
            ref="contentEditor"
            :options="editorOption"
            v-debounce:1000ms="blurEvent"
          >
          </quill-editor>

          <div v-if="editable" class="right_flex mt_2">
            <a
              href="javascript:;"
              class="btn_1 btn-sm text-white mr_1"
              :class="statusBtn == 'Saved' ? 'bg-success':'bg-danger'"
              @click.prevent.stop="updateNodeDescription"
            >
              <i v-if="statusBtn == 'Saved'" class="material-icons mr-1">done</i>
              {{statusBtn}}
            </a>
          </div>
        </section>
      </template>
    </sweet-modal-tab>
  </sweet-modal>
</template>

<script>
import AttachmentInput from '../../shared/attachment_input'
import { quillEditor } from "vue-quill-editor"
import "quill/dist/quill.core.css"
import "quill/dist/quill.snow.css"
import "quill/dist/quill.bubble.css"

export default {
  name: "AttachmentModal",
  props: ['editorOption', 'editable'],
  components: {
    quillEditor,
    AttachmentInput,
  },
  data() {
    return {
      nodeNotes: "",
      statusBtn: "Saved",
      editedNode: this.selectedNode
    }
  },
  mounted() {
    if (this.selectedNode?.id) {
      this.editedNode = this.selectedNode
      this.nodeNotes = this.editedNode.description
    }
  },
  methods: {
    blurEvent(val, event){
      if(event.keyCode == 13) return false;
      this.updateNodeDescription()
    },
    nullifyAttachmentModal() {
      this.$emit('nullify-attachment-modals')
    },
    updateNodeDescription() {
      this.$emit('update-node-description', this.nodeNotes)
    },
  },
  updated(){
    if(this.nodeNotes === this.editedNode.description) this.statusBtn = 'Saved';
    else this.statusBtn = 'Editing...';
  },
  computed: {
    selectedNode () {
      return this.$store.getters.getSelectedNode
    },
  },
  watch: {
    selectedNode: {
      handler(value) {
        if (value) {
          this.editedNode = value
        }
      }, deep: true
    },
    editedNode: {
      handler(value) {
        if (value) {
          this.nodeNotes = value.description
        }
      }, deep: true
    }
  }
}
</script>

<style lang=scss scoped>
  #attachment-modal ::v-deep .sweet-modal {
    min-width: 800px;
    .sweet-content {
      padding-top: 1.5em;
      padding-bottom: 2.5em;
    }
  }

  #attachment-modal ::v-deep .ql-container {
    height: 40vh;
    max-height: 40vh;
    border-top: 1px solid #ccc;
  }

  #attachment-modal ::v-deep .ql-toolbar {
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

  .loading-tab {
    height: 40vh;
    max-height: 40vh;
    display: flex;
    align-items: center;
    justify-content: center;
  }
</style>
