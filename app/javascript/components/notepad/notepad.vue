<template>
  <div class="todo-app">
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
  import { QuillDeltaToHtmlConverter } from 'quill-delta-to-html'

  export default {
    data() {
      return {
        currentMindMap : this.$store.getters.getMsuite,
        content        : '',
        isReset        : false,
        savingStatus   : null,
        toolbar        : null,
        qeditor        : null,
        temporaryUser  : '',
      }
    },
    props:['exportDoc', 'undoMap', 'redoMap'],
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
            this.qeditor.setContents([
              { insert: '' },
            ])
          }
          else if(data.message === "storage updated" && this.currentMindMap.id == data.content.mindmap_id){
            this.$store.dispatch('setUserEdit'     , data.content.userEdit)
            this.$store.dispatch('setTemporaryUser', data.content.userEdit)
            this.$store.dispatch('setUserList'     , data.content.userEdit)
            this.temporaryUser = data.content.userEdit
          }
          else if (data.message === "Mindmap Updated" && this.currentMindMap.id === data.mindmap.id){
            this.$store.commit('setMSuite', data.mindmap)
            this.content = JSON.parse(JSON.parse(data.mindmap.canvas).notepad)
            if(this.content == null){
              this.qeditor.setContents([
                { insert: '' },
              ])
            }
            else {
              let element = $('.ql-editor')[0]
              let notepadHeight = element.scrollTop
              if(this.temporaryUser !=this.$store.getters.getUser){
                  this.qeditor.blur()
                  this.qeditor.setContents(new Delta(this.content))
                  this.strongTagStyleBold()
                  element.scrollTop = notepadHeight
              }
            }
          }
        }
      }
    },
    methods: {
      updateDocument() {
        let _this = this
        let mycanvas = {
          notepad : JSON.stringify(this.qeditor.getContents()),
          user    : _this.$store.getters.getUser
        }
        let mindmap = { mindmap: { canvas: JSON.stringify(mycanvas)}}
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
              [{ align:'' }, {'align': 'center'},{'align': 'right'},{'align': 'justify'}] ],
            history: {
              delay: 1000,
              maxStack: 500,
              userOnly: true
            }
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
              list.classList.remove('ql-size-small')
            } else if (list.firstChild.className == 'ql-size-huge'){
              list.classList.add('ql-size-huge')
              list.classList.remove('ql-size-small')
              list.classList.remove('ql-size-large')
            } else {
              list.classList.remove('ql-size-small')
              list.classList.remove('ql-size-large')
              list.classList.remove('ql-size-huge')
            }
          })
          if (source == 'user') {
            setTimeout(() => {
              _this.strongTagStyleBold()
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
        http.get(`/msuite/${id}/reset_mindmap.json`)
      },
      exportToDocument(option) {
        var preHtml = "<html xmlns:o='urn:schemas-microsoft-com:office' xmlns:w='urn:schemas-microsoft-com:office:word' xmlns='head' charset='utf-8'><title>Export html to Doc</title></head><body style='font-family: sans-serif;'>"
        var postHtml = "</body></html>"
        let deltaOps = this.qeditor.getContents();
        var cfg = {
          inlineStyles: {
           font: {
              'serif': 'font-family: Georgia, Times New Roman, serif',
              'monospace': "font-family: Monaco, Comic Sans MS, monospace"
            },
            size: {
              'small': 'font-size: 0.75em',
              'large': 'font-size: 1.5em',
              'huge': 'font-size: 2.5em'
            },
            indent: (value, op) => {
              var indentSize = parseInt(value, 10) * 3;
              var side = op.attributes['direction'] === 'rtl' ? 'right' : 'left';
              return 'padding-' + side + ':' + indentSize + 'em';
            },
            direction: (value, op) => {
              if (value === 'rtl') {
                 return 'direction:rtl' + ( op.attributes['align'] ? '' : '; text-align: inherit' );
              } else {
                 return '';
              }
            }
          }
         };
        let converter = new QuillDeltaToHtmlConverter(deltaOps.ops, cfg);
        let htmlContent = converter.convert();

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
      },
      strongTagStyleBold(){
        var strong_list = document.querySelectorAll('strong');
        var strong_array = [...strong_list];
        strong_array.forEach(el => {
          el.style.fontWeight = 'bold'
        });
      },
      undoNotepad(){
        this.qeditor.history.undo()
      },
      redoNotepad(){
        this.qeditor.history.redo()
      }
    },
    mounted: async function()  {
      this.subscribeCable(this.currentMindMap.id)
      this.sendLocals(false)
      window.katex = katex
      if (this.currentMindMap.canvas && JSON.parse(this.currentMindMap.canvas).notepad) this.content = JSON.parse(JSON.parse(this.currentMindMap.canvas).notepad)
      this.setUserOnMountC()
      this.createEditor()
      this.editorEvents()
      this.qeditor.setContents(this.content)
      this.getUserOnMount()
      this.exportDoc(this.exportToDocument)
      this.undoMap(this.undoNotepad)
      this.redoMap(this.redoNotepad)
    },
    updated() {
      this.strongTagStyleBold()
    }
  }
</script>
<style>
  .ql-editor .ql-size-huge::before {
    font-size: 2.5em !important;
  }
  .ql-editor .ql-size-large::before {
    font-size: 1.5em;
  }
  .ql-editor .ql-size-small::before {
    font-size: 0.75em;
  }
  /* .ql-editor strong{
     font-weight:bold;
 } */
</style>
