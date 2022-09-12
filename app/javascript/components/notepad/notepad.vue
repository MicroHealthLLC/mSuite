
<template>
  <div class="todo-app">
    <navigation-bar
      ref="navigationBar"
      @mSuiteTitleUpdate="mSuiteTitleUpdate"
      @deleteMindmap="deleteMap"
      @resetMindmap="resetMindmap"
      @exportToDocument="exportToDocument"
      @sendLocals="sendLocals"
      :current-mind-map="currentMindMap"
      :defaultDeleteDays="defaultDeleteDays"
      :expDays="expDays"
      :deleteAfter="deleteAfter"
      :temporaryUser="temporaryUser"
      :isEditing="isEditing"
      :saveElement="saveElement"
      :userList="userList"
      :exportId="'notepad'">
    </navigation-bar>
    <div class="m-2">
     <quill-editor
        v-model="content"
        ref="contentEditor"
        :options="editorOption"
        v-debounce:1000ms="blurEvent"
        @change="changeNotepad"
      >
     </quill-editor>
   </div>
  </div>
</template>
<script>
  import http from "../../common/http"
  import domtoimage from "dom-to-image-more"
  import { quillEditor } from "vue-quill-editor"
  import "quill/dist/quill.core.css"
  import "quill/dist/quill.snow.css"
  import "quill/dist/quill.bubble.css"
  import TemporaryUser from "../../mixins/temporary_user.js"
  Vue.config.errorHandler = function(msg, vm, info) {}

  export default {
    props: ['currentMindMap'],
    data() {
      return {
        content: this.currentMindMap.canvas,
        isReset: false,
        userList: [],
        temporaryUser: '',
        isSaveNotepad: true,
        X: null,
        saveElement: false,
        editorOption      : {
          modules : {
            toolbar : [
              ['bold', 'italic', 'underline', 'strike'],        // toggled buttons
              ['blockquote', 'code-block'],
              [{ 'header': 1 }, { 'header': 2 }],               // custom button values
              [{ 'list': 'ordered'}, { 'list': 'bullet' }],
              [{ 'script': 'sub'}, { 'script': 'super' }],      // superscript/subscript
              [{ 'indent': '-1'}, { 'indent': '+1' }],          // outdent/indent
              [{ 'direction': 'rtl' }],                         // text direction

              [{ 'size': ['small', false, 'large', 'huge'] }],  // custom dropdown
              [{ 'header': [1, 2, 3, 4, 5, 6, false] }],

              [{ 'color': [] }, { 'background': [] }],          // dropdown with defaults from theme
              [{ 'font': [] }],
              [{ 'align': [] }],
              ['clean']
            ],
            syntax : {
              highlight: text => hljs.highlightAuto(text).value
            }
          }
        },
      }
    },
    components: { quillEditor },
    mixins: [TemporaryUser],
    channels: {
      WebNotificationsChannel: {
        received(data) {
          if (data.message === "Mindmap Deleted" && this.currentMindMap.id === data.mindmap.id)
          {
            window.open('/','_self')
          } else if (data.message === "Password Updated" && this.currentMindMap.id === data.mindmap.id) {
            setTimeout(() => {
              location.reload()
            }, 500)
          } else if (data.message === "Reset mindmap" && this.currentMindMap.id === data.mindmap.id) {
            this.currentMindMap = data.mindmap
          } else if(data.message === "storage updated" && this.currentMindMap.id == data.content.mindmap_id)
          {
            localStorage.nodeNumber = data.content.nodeNumber
            localStorage.userNumber = data.content.userNumber
            this.temporaryUser = data.content.userEdit
            this.userList.push(data.content.userEdit)
            localStorage.userList = JSON.stringify(this.userList);

          }
          else if (data.message === "Mindmap Updated" && this.currentMindMap.id === data.mindmap.id){
            this.error = '';
            this.currentMindMap = data.mindmap
            this.changeNotepad = false
            let range = this.$refs.contentEditor.quill.getSelection()
            this.$refs.contentEditor.quill.setSelection(range.index, 0, 'api')
            this.content = this.currentMindMap.canvas
            this.$refs.contentEditor.quill.update()
            this.sendLocals(false)
          }
        }
      }
    },
    methods: {
      changeNotepad() {
        this.sendLocals(true)
        this.isSaveNotepad = true
      },
      blurEvent(val, event){
        this.currentMindMap.canvas = this.content
      },
      updateDocument() {
        if(!this.isSaveNotepad) return
        let id = this.currentMindMap.unique_key
        http.patch(`/msuite/${id}.json`,this.currentMindMap)
      },
      resetMindmap() {
        this.isReset = true
        let mindmap = { mindmap: { canvas: null, title: 'Title' } }
        let id = this.currentMindMap.unique_key
        http.patch(`/msuite/${id}.json`,mindmap)
        this.qeditor.focus()
      },
      exportToDocument(option) {
       var preHtml = "<html xmlns:o='urn:schemas-microsoft-com:office' xmlns:w='urn:schemas-microsoft-com:office:word' xmlns='head' charset='utf-8'><title>Export html to Doc</title></head><body>"
        var postHtml = "</body></html>"

        let htmlContent = document.querySelector('#notepad').innerHTML

        var html = preHtml + htmlContent + postHtml ;
        if(option === 1){
          var blob = new Blob(['\ufeff', html], {
            type:'application/msword'
          });
          var url = 'data:application/vnd.ms-word; charset-utf-8,' + encodeURIComponent(html);
          var filename = filename? filename+'.doc':'document.doc'
        } else if (option === 2) {
          var blob = new Blob(['\ufeff', html], {
            type:'application/rtf'
          });
          var url = 'data:application/vnd.rft; charset-utf-8,' + encodeURIComponent(html);
          var filename = filename? filename+'.rtf':'document.rtf'
        }
        var downloadLink = document.createElement('a')
        document.body.appendChild(downloadLink)
        if (navigator.msSaveOrOpenBlob) {
          navigator.msSaveOrOpenBlob(blob, filename)
        } else {
          downloadLink.href = url
          downloadLink.download =filename
          downloadLink.click()
        }
        document.body.removeChild(downloadLink);
        this.$refs['navigationBar'].$refs['exportOption'].close();
      }
    },
    mounted() {
      this.subscribeCable(this.currentMindMap.id)
      if(localStorage.mindmap_id == this.currentMindMap.id){
        this.userList = JSON.parse(localStorage.userList)
        this.temporaryUser = localStorage.userEdit
      }
      $(".ql-container")[0].style.height = '75vh'
    },
    watch: {
      content:{
        handler(value) {
          this.currentMindMap.canvas = value
          clearTimeout(this.X)
          this.X = setTimeout(() => {
            this.updateDocument()
          },1000)
        }
      },
    }
  }
</script>
<style scoped>
</style>
