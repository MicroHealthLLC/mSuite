<template>
  <div>
    <div class="file-container">
      <div class="file-overlay position-fixed vw-100 vh-100"></div>
      <div class="file-wrapper position-fixed d-block p-2 m-auto rounded">
        <input class="file-input position-absolute w-100 h-100 bg-dark pointer" ref="fileInput" type="file" @change="sendFile"/>
        <div class="file-content position-relative d-block w-100 h-100 rounded">
          <div class="file-infos position-absolute d-flex flex-column w-50 h-50 m-auto justify-content-center">
            <p class="file-icon position-relative w-100 h-100 m-0 rounded p-2 mb-5">
              <i class="fas fa-file-upload fa-7x mb-5 my-4 w-100 d-block text-center font-weight-bold"></i>
              <span class="icon-shadow position-relative d-block mx-auto rounded-circle"></span>
              <span class="position-absolute d-block text-center font-weight-bold">Click to browse <span :class="{ 'has-drag': supportDrag }">or drop file here</span></span>
            </p>
          </div>
          <div class="d-flex file-name position-absolute m-auto w-50 z-20 flex-column h-16 overflow-auto mb-5">
            <div class="d-flex justify-content-around" v-for="(file,index) in receivedFiles">
              <p class="">{{ file.description }}</p>
              <i class="fas fa-download pointer mt-1" @click="downloadFile(file)"></i>
            </div>
          </div>
        </div>
        <div v-if="isSending" class="d-flex sending-container position-absolute w-100 text-center m-auto z-20">
            <div class="box position-relative">
                <div class="border one position-absolute"></div>
                <div class="border two position-absolute"></div>
                <div class="border three position-absolute"></div>
                <div class="border four position-absolute"></div>

                <div class="line one"></div>
                <div class="line two"></div>
                <div class="line three"></div>
            </div>
            <div>
              <i v-if="cancel" class="fas fa-times mt-3 ml-2 text-danger" @click="cancelUpload"></i>
            </div>
          </div>
      </div>
    </div>
  </div>
</template>

<script>
import TemporaryUser from "../../mixins/temporary_user.js"
import http from "../../common/http"
import { saveAs } from 'file-saver'

export default {
  data() {
    return {
      currentMindMap: this.$store.getters.getMsuite,
      files: [],
      receivedFiles: [],
      supportDrag: (function () {
        let div = document.createElement("div");
        return (
          ("draggable" in div || ("ondragstart" in div && "ondrop" in div)) &&
          "FormData" in window &&
          "FileReader" in window
        );
      })(),
      fileName: 'No file selected',
      fileString: '',
      fileType: '',
      chunks: [],
      isSending: false,
      fileName: null,
      cancel: false,
    };
  },
  mixins: [TemporaryUser],
  channels: {
    WebNotificationsChannel: {
      received(data) {
        if (
          data.message === "Mindmap Deleted"      &&
          this.currentMindMap.id === data.mindmap.id
        ) {
          window.open('/','_self')
        } else if (
          data.message === "Password Updated"     &&
          this.currentMindMap.id === data.mindmap.id
        ) {
          setTimeout(() => {
            location.reload()
          }, 500)
        } else if (
          data.message === "Reset mindmap"        &&
          this.currentMindMap.id === data.mindmap.id
        ) {
          this.getMindmap()
        } else if (
          data.message === "storage updated"             &&
          this.currentMindMap.id == data.content.mindmap_id
        ) {
          this.$store.dispatch('setUserEdit'     , data.content.userEdit)
          this.$store.dispatch('setTemporaryUser', data.content.userEdit)
          this.$store.dispatch('setUserList'     , data.content.userEdit)
        }
        else if (
          data.message === "Node is deleted"             &&
          this.currentMindMap.id == data.node.mindmap_id
        ) {
          this.getMindmap()
        }
        else if (
          data.message === "File Share Begin"         &&
          this.currentMindMap.id == data.mindmap_id
        ) {
          this.isSending = true
        }
        else {
          this.fileName = data.file_name
          let fileChunk = data.file.split(',') ? data.file.split(',')[1] : data.file
          this.chunks.push(fileChunk)
          let percentage = (data.offset / data.totalSize) * 100
          if(data.offset + data.chunkSize >= data.totalSize){
            this.fileString = this.chunks.join('')
            this.isSending = false
            this.fileType = data.type
          }
          this.getMindmap()
        }
      }
    }
  },
  mounted() {
    this.subscribeCable(this.currentMindMap.id)
    this.$refs.fileInput.addEventListener(
      'change',
      (e) => {
        this.fileName = this.$refs.fileInput.files[0].name;
        this.$el.querySelector('.file-input').classList.remove('file-input--active');
      },
      false
    );

    if (this.supportDrag) {
      this.$refs.fileInput.addEventListener('dragenter', (e) => {
        this.$el.querySelector('.file-input').classList.add('file-input--active');
      });

      this.$refs.fileInput.addEventListener('dragleave', (e) => {
        this.$el.querySelector('.file-input').classList.remove('file-input--active');
      });
    }
    this.getMindmap()
    this.updateUser()
  },
  methods: {
    async getMindmap() {
      await this.$store.dispatch('getMSuite')
      this.currentMindMap = await this.$store.getters.getMsuite
      this.receivedFiles = this.currentMindMap.nodes
    },
    updateUser(){
      http.put(`/msuite/${this.currentMindMap.unique_key}`, {
        canvas: this.$store.state.user
      });
    },
    async downloadFile(myFile) {
      let file
      await http.post('/files/download', {filename: myFile.title}).then(res=> {
        file = res.data
      })

      let receivedFile = this.convertBase64ToFile(file.split(',')[1], myFile.description)
      saveAs(receivedFile, myFile.description);

      // Perform an AJAX request to let the server know that the file has been downloaded
      // await http.post('/files/file_downloaded', { filename: myFile.title })
    },
    sendFile() {
      let _this = this
      this.chunks = []
      this.isSending = true
      setTimeout(()=>{
        this.cancel = true
      }, 500)
      let file
      try{
        file = this.$refs.fileInput.files[0];
      }
      catch(e) {
        alert('Try Again Uploading File')
        return
      }
      if(file == undefined) {
        this.isSending = false
        return
      }
      const reader = new FileReader();
      const chunkSize = 3188 * 3188; // 10 MB chunk
      let offset = 0;
      let totalChunks = file.size / chunkSize

      if(file.size > chunkSize) {
        alert('File Greater than 10MB not supported')
        this.isSending = false
        return
      }
      this.$cable.perform({
        channel: 'WebNotificationsChannel',
        room: this.mindmap_id,
        action: 'release_memory'
      });

      function readNextChunk() {
        let chunk = file.slice(offset, offset + chunkSize);
        reader.readAsDataURL(file);
        reader.onload = () => {
          _this.$cable.perform({
            channel: 'WebNotificationsChannel',
            room: _this.mindmap_id,
            data: {
              name: file.name,
              file: reader.result,
              type: file.type,
              offset: offset,
              totalSize: file.size,
              chunkSize: chunkSize,
              totalChunks: totalChunks
            }
          });
          offset += chunkSize;
          if (offset < file.size) {
            readNextChunk();
          }
        };
      }
      readNextChunk();
    },
    async cancelUpload() {
      let file = this.$refs.fileInput.files[0];
      if(!file){
        this.isSending = false
        this.$el.querySelector('.file-input').classList.remove('file-input--active');
      }
      await http.post('/files/file_canceled', { filename: file.name }).then(res=>{
        this.isSending = false
      })
      .catch( err =>{
        this.isSending = false
      })
    },
    convertBase64ToFile (base64String, fileName)  {
      try {
        atob(base64String)
      } catch (e) {
        alert("File you tried didn't read by the system, reloading ...")
        location.reload()
        return
      }
      let bstr = atob(base64String)
      let n = bstr.length
      let uint8Array = new Uint8Array(n)
      while (n--) {
        uint8Array[n] = bstr.charCodeAt(n)
      }
      let file = new File([uint8Array], fileName, { type: this.fileType })
      return file;
    }
  }
};
</script>
<style lang="scss" scoped>
  @import './styles.scss'
</style>
