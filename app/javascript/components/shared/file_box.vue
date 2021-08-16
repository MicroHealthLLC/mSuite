<template>
  <div class="file-wrap py-2" :class="{'shadow-sm':slideRight}">
    <transition name="slide-fade-right">
      <div v-if="!slideRight" class="file-tap">
        <span class="files-name text-left mr-1 p-1">
          {{ file.uri.split("/").pop().replace(/%20/g, ' ') }}
        </span>
        <span class="files-action d-flex align-items-center">
          <a :href="fileLink" target="_blank" class="download-btn mr-2">
            <i class="material-icons">get_app</i>
          </a>
          <a href="javascript:;" class="remove-btn" @click.prevent="slideRight=true">
            <i class="material-icons">close</i>
          </a>
        </span>
      </div>
    </transition>
    <transition name="slide-fade-left">
      <div v-if="slideRight" class="confirm-dialog">
        <span class="p-1 mr-1">Are you sure? </span>
        <span>
          <button class="btn_file btn btn-primary btn-sm mr-2" @click.prevent="slideRight = !slideRight">
            Cancel
          </button>
          <button class="btn_file btn btn-danger btn-sm" @click.prevent="removeFile(file)">
            Yes, Delete
          </button>
        </span>
      </div>
    </transition>
  </div>
</template>

<script>
import http from "../../common/http"
export default {
  props: [
    'file',
    'central',
    'node'
  ],
  data() {
    return {
      slideRight: false
    }
  },
  computed: {
    fileLink() {
      return window.location.origin + this.file.uri
    }
  },
  methods: {
    removeFile() {
      let url = this.central ? `/mindmaps/${this.node.unique_key}/destroy_file.json` : `/nodes/${this.node.id}/destroy_file.json`

      http
        .put(url, { file: this.file })
        .then(async (res) => {
          this.$emit('remove-file', this.file)
          _.remove(this.node.attach_files, (f) => f.id === this.file.id)
          this.$foreUpdate()
        }).catch((error) => {
          console.log("Unable to remove the file..")
        })
    }
  }
}
</script>

<style lang="scss" scoped>
  .file-wrap {
    display: flex;
    align-items: center;
    width: 100%;
    height: 32px;
    &:hover {
      cursor: pointer;
      box-shadow: 0 0.125rem 0.25rem rgba(0, 0, 0, 0.075);
    }
  }
  .file-tap {
    width: 85%;
    position: absolute;
    display: flex;
    justify-content: space-between;
    align-items: center;
  }
  .confirm-dialog {
    width: 85%;
    position: absolute;
    display: flex;
    justify-content: space-between;
    align-items: center;
  }
  i {
    font-size: 15px;
    padding: 0.3em;
  }
  .files-name {
    white-space: nowrap;
    width: 20em;
    text-overflow: ellipsis;
    overflow: hidden;
  }
  a {
    color: black;
    &:hover {
      color: white;
      border-radius: 50%;
      background-color: red;
    }
  }
  .btn_file {
    font-size: 78%;
  }

  /*slide animations*/
  .slide-fade-right-enter-active {
    transition: all .6s ease;
  }
  .slide-fade-right-leave-active {
    transition: all .3s ease;
  }
  .slide-fade-right-enter, .slide-fade-right-leave-to {
    transform: translateX(10em);
    opacity: 0;
  }

  .slide-fade-left-enter-active {
    transition: all .4s ease;
  }
  .slide-fade-left-leave-active {
    transition: all .2s ease;
  }
  .slide-fade-left-enter, .slide-fade-left-leave-to {
    transform: translateX(-10em);
    opacity: 0;
  }
</style>
