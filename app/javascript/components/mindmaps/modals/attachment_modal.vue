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
              class="btn_1 btn-sm bg-danger text-white mr_1"
              @click.prevent.stop="updateNodeDescription"
            >
              <i class="material-icons mr-1">done</i>
              {{statusBtn}}
            </a>
          </div>
        </section>
      </template>
    </sweet-modal-tab>
    <sweet-modal-tab title="Files" id="files-tab">
      <section v-if="fileLoading" class="loading-tab">
        <sync-loader :loading="fileLoading" color="#31A1DF" size="20px"></sync-loader>
      </section>
      <section v-else class="row node-files-tab">
        <div class="col" v-if="editable">
          <attachment-input
            :show-label="true"
            @input="addFileToNode"
          >
          </attachment-input>
        </div>
        <div class="col node-files-list">
          <div v-if="attachFiles && attachFiles.length > 0">
            <div class="files-list p-2" v-for="file in attachFiles">
              <file-box
                :file="file"
                :key="file.id"
                :central="false"
                :node="editedNode"
                @remove-file="removeFile"
                :editable="editable"
              ></file-box>
            </div>
          </div>
          <div v-else class="empty-file-list text-secondary">
            No files attached...
          </div>
        </div>
      </section>
    </sweet-modal-tab>
  </sweet-modal>
</template>

<script>
import AttachmentInput from '../../shared/attachment_input'
import FileBox from '../../shared/file_box'
import { quillEditor } from "vue-quill-editor"
import "quill/dist/quill.core.css"
import "quill/dist/quill.snow.css"
import "quill/dist/quill.bubble.css"

export default {
  name: "AttachmentModal",
  props: ['selectedNode', 'editorOption', 'editable'],
  components: {
    quillEditor,
    AttachmentInput,
    FileBox
  },
  data() {
    return {
      fileLoading: false,
      nodeNotes: "",
      attachFiles: [],
      statusBtn: "Saved",
      editedNode: this.selectedNode
    }
  },
  mounted() {
    if (this.selectedNode?.id) {
      this.editedNode = this.selectedNode
      this.nodeNotes = this.editedNode.description
      this.attachFiles = this.editedNode.attach_files
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
    async addFileToNode(files) {
      this.fileLoading = true
      await this.$emit('add-file-to-node', files)
      this.fileLoading = false
    },
    removeFile(file) {
      _.remove(this.editedNode.attach_files, f => f.id === file.id)
      this.$forceUpdate()
    }
  },
  updated(){
    if(this.nodeNotes === this.editedNode.description) this.statusBtn = 'Saved';
    else this.statusBtn = 'Editing...';
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
          this.attachFiles = value.attach_files
        }
      }, deep: true
    }
  }
}
</script>

<style lang=scss scoped>
  #attachment-modal /deep/ .sweet-modal {
    min-width: 800px;
    .sweet-content {
      padding-top: 1.5em;
      padding-bottom: 2.5em;
    }
  }

  #attachment-modal /deep/ .ql-container {
    height: 40vh;
    max-height: 40vh;
    border-top: 1px solid #ccc;
  }

  #attachment-modal /deep/ .ql-toolbar {
    display: none;
  }

  .node-files-tab {
    height: 40vh;
    max-height: 40vh;
    font-size: 78%;
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

  .node-files-list {
    height: 100%;
    border: 1px solid #ccc;
    overflow: auto;

    .files-list {
      display: flex;
      justify-content: space-between;
      width: 100%;
      word-break: break-word;
    }
    .empty-file-list {
      font-size: 15px;
      font-style: italic;
      padding: 1em;
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
