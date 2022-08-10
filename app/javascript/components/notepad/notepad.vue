
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
      @sendLocals="sendLocals"
      :current-mind-map="currentMindMap"
      :defaultDeleteDays="defaultDeleteDays"
      :expDays="expDays"
      :deleteAfter="deleteAfter"
      :temporaryUser="temporaryUser"
      :isEditing="isEditing"
      :saveElement="saveElement"
      :exportId="'notepad'">
    </navigation-bar>
    <div id="notepad"></div>
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
  import Quill from 'quill'
  import Delta from 'quill-delta'
  import katex from 'katex'
  import 'katex/dist/katex.min.css'

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
        qeditor: null,
        temporaryUser: '',
        saveElement: false,
      }
    },
    components: {
      DeleteMapModal,
      DeletePasswordModal,
      MakePrivateModal
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
          } else if(data.message === "storage updated" && this.currentMindMap.id == data.content.mindmap_id)
          {
            localStorage.nodeNumber = data.content.nodeNumber
            localStorage.userNumber = data.content.userNumber
            this.temporaryUser = data.content.userEdit
            this.isEditing = data.isEditing
            if (!this.isEditing) {
              this.saveElement = true
              setTimeout(()=>{
                this.saveElement = false
              },1200)
            }
            if (this.qeditor.hasFocus() && data.content.user != localStorage.user) {
              this.qeditor.blur()
            }
          }
          else if (data.message === "Mindmap Updated" && this.currentMindMap.id === data.mindmap.id){
            this.currentMindMap = data.mindmap
            this.content = JSON.parse(data.mindmap.canvas)
            if(this.content == null){
              this.qeditor.setContents([
                { insert: '' },
              ])
            } else {
              let range = this.qeditor.getSelection();
              if(range == null) this.qeditor.setContents(this.content)
            }
          }
        }
      }
    },
    methods: {
      async getMindmap(id) {
        await http
        .get(`/msuite/${id}.json`)
        .then((res) => {
          this.expDays = res.data.expDays
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
        let _this = this
        let range = this.qeditor.getSelection();
        if(range && (range.length == 0 || range.index == 0)) {
          let mindmap = { mindmap: { canvas: JSON.stringify(this.qeditor.getContents())}}
          let id = this.currentMindMap.unique_key
          if(!this.isReset){
            http.patch(`/msuite/${id}.json`,mindmap).then(res => {
              this.sendLocals(false)
              this.saveElement = true
              setTimeout(()=>{
                this.saveElement = false
              },1200)
            })
          }
          else this.isReset = false
        }
      },
      createEditor(){
        this.qeditor = new Quill('#notepad', {
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
             ['align', {'align': 'center'},{'align': 'right'},{'align': 'justify'}] ]
          },
          theme: 'snow'
        });

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
      editorEvents() {
        let _this = this
        let change = new Delta();
        let myDelta = this.qeditor.getContents();

        this.qeditor.on('text-change', function(delta) {
          let lists = document.getElementsByTagName('li')

          lists.forEach( list => {
            if(list.firstChild.tagName && list.firstChild.style.color != ''){
              list.style.color = list.firstChild.style.color
            }
            if (list.firstChild.className == 'ql-size-small'){
              list.classList.add('ql-size-small')
              list.classList.remove('ql-size-huge')
              list.classList.remove('ql-size-large')
            } else if (list.firstChild.className == 'ql-size-large'){
              list.classList.add('ql-size-large')
              list.classList.remove('ql-size-huge')
            } else if (list.firstChild.className == 'ql-size-huge'){
              list.classList.add('ql-size-huge')
              list.classList.remove('ql-size-large')
            } else {
              list.classList.remove('ql-size-small')
              list.classList.remove('ql-size-large')
              list.classList.remove('ql-size-huge')
            }
          })
          change = change.compose(delta);
        });

        setInterval(function() {
          if (change.length() > 0) {
            _this.updateDocument()
            change = new Delta();
          }
        }, 500);

        window.onbeforeunload = function() {
          if (change.length() > 0) {
            return 'There are unsaved changes. Are you sure you want to leave?';
          }
        }
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
        this.$refs['navigationBar'].$refs['exportOption'].close()
      },
      strongTagStyleBold(){
        var strong_list = document.querySelectorAll('strong');
        var strong_array = [...strong_list];
        strong_array.forEach(el => {
          el.style.fontWeight = 'bold'
        });
      },
      cableSend(){
        this.$cable.perform({
          channel: 'WebNotificationsChannel',
          room: this.currentMindMap.id,

          data: {
            message: 'storage updated',
            isEditing: this.isEditing,
            content: localStorage
          }
        });
      },
      sendLocals(isEditing){
        localStorage.userEdit = localStorage.user
        localStorage.mindmap_id = this.currentMindMap.id
        this.isEditing = isEditing
        this.cableSend()
      },
    },
    updated() {
      this.savingStatus.style.fontWeight = '450';
      if (JSON.stringify(this.qeditor.getContents()) === this.currentMindMap.canvas ||
          JSON.stringify(this.qeditor.getContents()) === '{"ops":[{"insert":"\\n"}]}') {
        this.savingStatus.innerHTML = 'Saved';
        this.savingStatus.style.color = 'green';
      } else {
        this.savingStatus.innerHTML = 'Editing...';
        this.savingStatus.style.color = 'blue';
        this.sendLocals(true)
      }
      this.strongTagStyleBold()
    },
    mounted() {
      if (this.$route.params.key) {
        this.getMindmap(this.$route.params.key)
        window.katex = katex
      }
      this.content = JSON.parse(this.currentMindMap.canvas)

      this.createEditor()
      this.editorEvents()
      this.qeditor.focus()

      this.qeditor.setContents(this.content)
    },
  }
</script>
<style scoped>
</style>
