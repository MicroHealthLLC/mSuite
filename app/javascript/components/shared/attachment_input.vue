<template>
  <div class="area">
    <transition name="slide-fade-up">
      <div
        v-if="C_invalidFiles" 
        class="invalid-files"
      >
        <div class="alert alert-danger alert-dismissible mb-0" role="alert">
          <h4 class="alert-heading">File alert!</h4>
          <p>These files are not uploaded..</p>
          <hr>
          <ul class="text-left">
            <li v-for="file in invalidFiles">
              {{ (file.size/1000000).toPrecision(4) + "mb" }} - {{ file.name }}
            </li>
          </ul>
          <button type="button" class="close" @click.prevent="closeInvalidModal">
            <span aria-hidden="true">&times;</span>
          </button>
        </div>
      </div>
    </transition>
    <div
      v-if="!C_invalidFiles"
      class="drop-area"
      :class="{'drop-area--active': isDragActive}"
      @click.stop="onChange"
      @dragleave="onDragLeave"
      @dragover.prevent="onDragEnter"
      @drop="onDrop"
    >
      <label class="drop__label text-center">
        Drop files here or click to upload
        <span
          v-if="showLabel"
          class="drop__sub-label mt-4 d-block"
        >Max file size 7mb.</span>
      </label>
      <input
        ref="fileInput"
        type="file"
        class="drop__file-input"
        name="file"
        multiple
        @change="onFileChange"
      >
    </div>
  </div>
</template>

<script>
export default {
  props: {
    showLabel: Boolean
  },

  data() {
    return {
      files       : [],
      validFiles  : [],
      invalidFiles: [],
      inputError  : null,
      isDragActive: false
    };
  },

  computed: {
    C_invalidFiles() {
      return this.invalidFiles.length > 0;
    }
  },
  
  methods: {
    onDrop(e) {
      e.stopPropagation()
      e.preventDefault()
      let file = null
      this.isDragActive = false
      
      for (let idx = 0; idx < e.dataTransfer.files.length; idx += 1) 
      {
        file = e.dataTransfer.files[idx]
        if (file.size <= 7000000) {
          this.validFiles.push(file)
        } else {
          this.invalidFiles.push(file)
        }
      }
      this.submitFiles()
    },

    onChange() {
      this.$refs.fileInput.click()
      this.inputError = null
    },

    onFileChange(e) {
      if (!e.currentTarget) { return; }
      let file = null
      
      for (let idx = 0; idx < this.$refs.fileInput.files.length; idx += 1) 
      {
        file = this.$refs.fileInput.files[idx]
        if (file.size <= 7000000) {
          this.validFiles.push(file)
        } else {
          this.invalidFiles.push(file)
        }
      }
      this.submitFiles()
    },

    submitFiles() {
      if(this.validFiles.length > 0) {
        this.$emit('input', this.validFiles)
        this.validFiles = []
      }
    },

    onDragEnter() {
      this.isDragActive = true
    },

    onDragLeave() {
      this.isDragActive = false
    },

    closeInvalidModal() {
      this.invalidFiles = []
    }
  }
}
</script>

<style scoped lang="scss">
  @import "./styles/attachment_input.scss";
</style>
