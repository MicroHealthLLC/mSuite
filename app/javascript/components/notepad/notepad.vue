
<template>
  <div class="todo-app">
    <navigation-bar
      v-if="isMounted"
      ref="navigationBar"
      @mSuiteTitleUpdate="mSuiteTitleUpdate"
      @openPrivacy="openPrivacy"
      @deleteMindmap="deleteMap"
      @resetMindmap="resetMindmap"
      @exportToDocument="exportToDocument"
      :current-mind-map="currentMindMap"
      :defaultDeleteDays="defaultDeleteDays"
      :deleteAfter="deleteAfter"
      :exportId="'ofice'">
    </navigation-bar>
    <div id="office">
      <div>
        <quill-editor
          ref="notepad"
          v-model:content="content"
          :options="editorOption"
          @focus="contentUpdate"
          v-debounce:1000ms="blurEvent"></quill-editor>
      </div>
    </div>
    <make-private-modal ref="make-private-modal" @password-apply="passwordProtect" @password_mismatched="$refs['passwordMismatched'].open()" :password="currentMindMap.password" :isSaveMSuite="isSaveMSuite"></make-private-modal>
    <delete-map-modal ref="delete-map-modal" @delete-mindmap="confirmDeleteMindmap"></delete-map-modal>
    <delete-password-modal ref="delete-password-modal" @deletePasswordCheck="deleteMindmapProtected"></delete-password-modal>
    <confirm-save-key-modal ref="confirm-save-key-modal" :current-mind-map="currentMindMap"></confirm-save-key-modal>
    <sweet-modal ref="passwordMismatched" class="of_v" icon="error" title="Password Mismatch">
      Your Password and Confirm Password are Mismatched, Please Try Again!
      <button slot="button" @click="passwordAgain" class="btn btn-warning mr-2">Try Again</button>
      <button slot="button" @click="$refs['passwordMismatched'].close()" class="btn btn-secondary">Cancel</button>
    </sweet-modal>
    <sweet-modal ref="errorModal" class="of_v" icon="error" title="Password Error">
      Incorrect Password, Please Try Again!
    </sweet-modal>
    <sweet-modal ref="successModal" class="of_v" icon="success">
      Password updated successfully!
    </sweet-modal>
  </div>
</template>
<script>
  import http from "../../common/http"
  import domtoimage from "dom-to-image-more"
  import DeleteMapModal from '../../common/modals/delete_modal';
  import MakePrivateModal from "../../common/modals/make_private_modal"
  import DeletePasswordModal from '../../common/modals/delete_password_modal';
  import { quillEditor } from 'vue-quill-editor'

  export default {
    props: ['currentMindMap'],
    data() {
      return {
        isMounted: false,
        content: '',
        editor: null,
        isReset: false,
        savingStatus: null,
        saveText: null,
        toolbar: null,
        editorOption: {
          placeholder: '',
          modules:{
            toolbar: [
             ['bold','italic','underline','strike'],
             ['blockquote','code-block'],
             ['formula'],
             [{ 'header': 1 },{'header': 2}],
             [{'list':'ordered'}, {'list':'bullet' }],
             [{'indent':'-1'}, {'indent':'+1' }],
             [{'size': ['small', false,'large','huge'] }],
             [{'header': [1, 2, 3, 4, 5, 6, false] }],
             [{'color': [] }, {'background': [] }],
             [{'font': [] }],
             [{'align': [] }]
             ]
          }
        }
      }
    },
    components: {
      DeleteMapModal,
      DeletePasswordModal,
      MakePrivateModal,
      quillEditor
    },
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
          }
          else {
            this.currentMindMap = data.mindmap
            this.content = data.mindmap.canvas
          }
        }
      }
    },
    methods: {
      async getMindmap(id) {
        await http
        .get(`/msuite/${id}.json`)
        .then((res) => {
          this.defaultDeleteDays = res.data.defaultDeleteDays
          this.deleteAfter = res.data.deleteAfter
          this.currentMindMap = res.data.mindmap
          this.isMounted = true
          this.$cable.subscribe({ channel:"WebNotificationsChannel", room: this.currentMindMap.id })
        })
      },
      openPrivacy(val) {
        this.isSaveMSuite = val
        this.$refs['make-private-modal'].$refs['makePrivateModal'].open()
      },
      deleteMap() {
        this.$refs['delete-map-modal'].$refs['deleteMapModal'].open()
      },
      confirmDeleteMindmap() {
        if (this.currentMindMap.password){
          this.$refs['delete-password-modal'].$refs['DeletePasswordModal'].open()
        } else {
          this.deleteMindmap()
        }
      },
      deleteMindmapProtected(password) {
        http
        .delete(`/msuite/${this.currentMindMap.unique_key}.json?password_check=${password}`)
        .then(res=>{
          if (!res.data.success && this.currentMindMap.password)
            this.$refs['errorModal'].open()
        })
        .catch(error => {
          console.log(error)
        })
      },
      deleteMindmap() {
        http
        .delete(`/msuite/${this.currentMindMap.unique_key}.json`)
        .then(res => {
          window.open("/", "_self")
        })
        .catch(error => {
          console.log(error)
        })
      },
      passwordProtect(new_password, old_password, is_mSuite) {
        http
        .patch(`/msuite/${this.currentMindMap.unique_key}.json`,{mindmap:{password: new_password, old_password: old_password}})
        .then(res => {
          if (res.data.mindmap) {
            this.currentMindMap.password = res.data.mindmap.password
            if(!is_mSuite) window.open("/", "_self")
            else location.reload()
            this.$refs['successModal'].open()
          } else {
            if (res.data.error) this.$refs['errorModal'].open()
          }
        })
      },
      passwordAgain() {
        this.$refs['passwordMismatched'].close()
        this.openPrivacy()
      },
      updateDocument() {
        let mindmap = { mindmap: { canvas: this.content } }
        let id = this.currentMindMap.unique_key
        if(!this.isReset){
          http.patch(`/msuite/${id}.json`,mindmap)
        }
        else this.isReset = false
      },
      resetMindmap() {
        this.isReset = true
        let mindmap = { mindmap: { canvas: '', title: 'Title' } }
        let id = this.currentMindMap.unique_key
        http.patch(`/msuite/${id}.json`,mindmap)
      },
      exportToDocument(option) {
        var preHtml = "<html xmlns:o='urn:schemas-microsoft-com:office' xmlns:w='urn:schemas-microsoft-com:office:word' xmlns='head' charset='utf-8'><title>Export html to Doc</title></head><body>"
        var postHtml = "</body></html>"
        var html = preHtml + this.content + postHtml ;

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
        this.$refs['navigationBar'].$refs['exportOption'].close()
      },
      contentUpdate(){
        setTimeout(()=>{
          this.updateDocument()
        },500)
      },
      blurEvent(val, e){
        this.updateDocument()
      },
      strongTagStyleBold(){
        var strong_list = document.querySelectorAll('strong');
        var strong_array = [...strong_list];
        strong_array.forEach(el => {
          el.style.fontWeight = 'bold'
        });
      }
    },
    updated() {
      this.savingStatus.style.fontWeight = '450';
      if(this.content === this.currentMindMap.canvas){
        this.savingStatus.innerHTML = 'Saved';
        this.savingStatus.style.color = 'green';
      } else {
        this.savingStatus.innerHTML = 'Editing...';
        this.savingStatus.style.color = 'blue';
      }
      this.strongTagStyleBold()
    },
    mounted() {
      if (this.$route.params.key) {
        this.getMindmap(this.$route.params.key)
      }
      this.content = this.currentMindMap.canvas
      this.editorStyle = document.querySelectorAll('.ql-editor')[0].style
      this.editorStyle.height = '82.5vh'
      this.editorStyle.border = '20px'
      this.editorStyle.padding = "3% 8% 0% 8%"
      this.editorStyle.border = "20px solid #ccc"

      document.querySelectorAll('.ql-snow.ql-toolbar button, .ql-snow .ql-toolbar button').forEach(function (editorToolbar) {
        editorToolbar.classList.add('ml-2');
      });
      this.toolbar = $(".ql-toolbar")[0]
      this.savingStatus = document.createElement("span");
      this.toolbar.appendChild(this.savingStatus);
      setTimeout(()=>{
        this.strongTagStyleBold()
      },100)
    },
  }
</script>
<style scoped>
</style>
