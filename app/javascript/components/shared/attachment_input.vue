<template>
  <div class="area">
    <div
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
        >Max file size 10mb.</span>
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
      inputError  : null,
      isDragActive: false
    };
  },
  
  methods: {
    onDrop(e) {
      e.stopPropagation()
      e.preventDefault()
      this.isDragActive = false
      
      for (let idx = 0; idx < e.dataTransfer.files.length; idx += 1) {
        this.$emit('input', {data: e.dataTransfer.files[idx], length: e.dataTransfer.files.length})
      }
    },

    onChange() {
      this.$refs.fileInput.click()
      this.inputError = null
    },

    onFileChange(e) {
      if (!e.currentTarget) { return; }
      for (let idx = 0; idx < this.$refs.fileInput.files.length; idx += 1) {
        this.$emit('input', {data: this.$refs.fileInput.files[idx], length: this.$refs.fileInput.files.length})
      }
    },

    onDragEnter() {
      this.isDragActive = true
    },

    onDragLeave() {
      this.isDragActive = false
    }
  }
}
</script>

<style lang="scss" scoped>
.dz-details {
  background   : white;
  border       : 1px dotted #e7e7e7;
  border-radius: 10px;
  font-style   : italic;
  padding      : 5px;
}

.drop__file-input {
  visibility: hidden;
}

.drop__label {
  color         : gray;
  cursor        : inherit;
  left          : 50%;
  position      : absolute;
  text-transform: uppercase;
  top           : 50%;
  transform     : translate(-50%, -50%);
  width         : 80%;
  font-size     : 18px;

  > a {
    text-decoration: underline;
  }
}

.drop__sub-label {
  font-size     : 80%;
  text-transform: none;
}

.drop__img {
  height   : 100%;
  left     : 50%;
  margin   : auto;
  position : absolute;
  top      : 50%;
  transform: translate(-50%, -50%);
  width    : auto;
}

.drop-area {
  background-color   : white;
  border             : 2px dashed #ccc;
  color              : white;
  cursor             : pointer;
  height             : inherit;
  width              : inherit;
  margin             : auto;
  overflow           : hidden;
  position           : relative;
  transition         : auto;
  transition-property: border-color;
  vertical-align     : middle;

  &:hover {
    border-color: #17a2b8;
  }
}

.drop-area--active {
  border-color    : #17a2b8;
  background-color: #cfe;
  cursor          : copy !important;
}

.area {
  height: 100%;
}
</style>
