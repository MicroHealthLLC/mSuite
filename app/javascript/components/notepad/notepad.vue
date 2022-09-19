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
    <div id="notepad"></div>
  </div>
</template>
<script>
  import http from "../../common/http"
  import Quill from 'quill'
  import Delta from 'quill-delta'
  import katex from 'katex'
  import 'katex/dist/katex.min.css'
  import TemporaryUser from "../../mixins/temporary_user.js"

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
        editorCursor:null,
        temporaryUser: '',
        userList:[],
      }
    },
    mixins: [TemporaryUser],
    channels: {
      WebNotificationsChannel: {
        received(data) {
          if (data.message === "Mindmap Deleted" && this.currentMindMap.id === data.mindmap.id){
            window.open('/','_self')
          } else if (data.message === "Password Updated" && this.currentMindMap.id === data.mindmap.id) {
            setTimeout(() => {
              location.reload()
            }, 500)
          }
          else if (data.message === "Reset mindmap" && this.currentMindMap.id === data.mindmap.id) {
            this.currentMindMap = data.mindmap
          }
          else if(data.message === "storage updated" && this.currentMindMap.id == data.content.mindmap_id){
            localStorage.nodeNumber = data.content.nodeNumber
            localStorage.userNumber = data.content.userNumber
            this.temporaryUser = data.content.userEdit
            this.userList.push(data.content.userEdit)
            localStorage.userList = JSON.stringify(this.userList);
          }
          else if (data.message === "Mindmap Updated" && this.currentMindMap.id === data.mindmap.id){
            this.currentMindMap = data.mindmap
            this.content = JSON.parse(data.mindmap.canvas)
            if(this.content == null){
              this.qeditor.setContents([
                { insert: '' },
              ])
            }
            else {
              if(this.temporaryUser !=localStorage.user){
                  this.qeditor.blur()
                  this.qeditor.setContents(this.content)
              }
            }
          }
        }
      }
    },
    methods: {
      updateDocument() {
        let mindmap = { mindmap: { canvas: JSON.stringify(this.qeditor.getContents())}}
        let id = this.currentMindMap.unique_key
        http.patch(`/msuite/${id}.json`,mindmap)
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
        let editSource = ''
        this.qeditor.on('text-change', function(delta, oldContents, source) {
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
            } else {
              list.classList.remove('ql-size-small')
              list.classList.remove('ql-size-large')
              list.classList.remove('ql-size-huge')
            }
          })
          if (source == 'user') {
            setTimeout(() => {
              change = change.compose(delta)
              if (change.length() > 0) {
                _this.sendLocals(true)
                _this.updateDocument()
                change = new Delta();
              }
              else{
                _this.sendLocals(false)
              }
            },500);
          }
          else{
              change = change.compose(delta);
          }
        });
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
    },
    mounted() {
      if (this.$route.params.key) {
        this.subscribeCable(this.currentMindMap.id)
        window.katex = katex
      }
      this.content = JSON.parse(this.currentMindMap.canvas)
      this.createEditor()
      this.editorEvents()
      this.qeditor.setContents(this.content)
      if(localStorage.mindmap_id == this.currentMindMap.id){
        this.userList = JSON.parse(localStorage.userList)
        this.temporaryUser = localStorage.userEdit
      }
    },
    updated() {
      this.strongTagStyleBold()
    }
  }
</script>
<style scoped>
</style>
