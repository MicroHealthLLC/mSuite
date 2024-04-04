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
        lastDelta      : null,
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
                  let cursor = this.qeditor.getSelection()
                  let curContent = this.qeditor.getContents()
                  let testChange = new Delta(this.content)
                  let change = new Delta(curContent).diff(new Delta(this.content))
                  
                  //console.log(testChange)
                  if(this.lastDelta==null) this.lastDelta = new Delta()
                  
                  //console.log("websocket change")
                  //console.log(change)
                  //console.log("lastDelta")
                  //console.log(this.lastDelta)
                  //console.log("lastdelta length " + this.lastDelta.ops.length)
                  if(this.lastDelta.ops.length > 0) {
                    //console.log("lastDelta")
                    change = this.resolveConflict(this.content, curContent, change)
                    //console.log("resolved change")
                    //console.log(change)
                  }

                  if(cursor) cursor.index = this.adjustCursorIndex(change, cursor.index)
                  
                  this.qeditor.updateContents(change)

                  if(this.lastDelta.ops.length > 0) {
                    this.lastDelta = new Delta()
                    //console.log("lastDelta reset")
                  }

                  this.strongTagStyleBold()
                  element.scrollTop = notepadHeight

                  if(cursor) this.qeditor.setSelection(cursor)
              }
            }
          }
        }
      }
    },
    methods: {
      insertToString(delta) {
        let outString = delta.slice(0).ops.map(function(op) {
          if (typeof op.insert !== 'string') return ''
          if (op.attributes) {
            let attributes = ''
            for(let [key, value] of Object.entries(op.attributes)) {
              attributes += key + ':' + value + ';'
            }
            return '<' + attributes + '>' + op.insert
          }
          return op.insert
        }).join('');
        return outString
      },
      resolveConflict(inContent, curContent, change) {
        let check = Math.max(this.lastDelta.length(), change.length())
        let newChange = new Delta()
        let inContentStr = this.insertToString(new Delta(inContent))
        let curContentStr = this.insertToString(new Delta(curContent))

        check = Math.min(check, inContentStr.length, curContentStr.length)
        //console.log(inContentStr)
        //console.log(curContentStr)
        //console.log("inContentStr.length " + inContentStr.length + "| curContentStr.length " + curContentStr.length)
        //console.log(inContentStr.length != curContentStr.length)
        //console.log(inContentStr.substring(0) != curContentStr.substring(0))

        if (inContentStr.length != curContentStr.length || inContentStr.substring(0) != curContentStr.substring(0)) {
          //console.log("conflict")
          //console.log("incoming change:")
          //console.log(change)
          //console.log("current change:")
          //console.log(this.lastDelta.ops)
          
          let copyChange = new Delta(change)
          let copyLastDelta = new Delta(this.lastDelta)
          let opChangeIndex = 0
          let opLastDeltaIndex = 0
          
          let opChangeIndexArray = new Array(copyChange.ops.length)
          for(let i = 0; i < copyChange.ops.length; i++) {
            opChangeIndexArray[i] = opChangeIndex
            opChangeIndex += copyChange.ops[i].retain || copyChange.ops[i].delete || copyChange.ops[i].insert.length
          }
          
          let opLastDeltaIndexArray = new Array(copyLastDelta.ops.length)
          for(let i = 0; i < copyLastDelta.ops.length; i++) {
            opLastDeltaIndexArray[i] = opLastDeltaIndex
            opLastDeltaIndex += copyLastDelta.ops[i].retain || copyLastDelta.ops[i].delete || copyLastDelta.ops[i].insert.length
          }

          let i = 0
          let j = 0
          //console.log(copyChange)
          //console.log(copyLastDelta)

          while (i < copyChange.ops.length && j < copyLastDelta.ops.length) {
            //if the ops are at the same index and not retain ops, then check for conflicts
            if (opChangeIndexArray[i] == opLastDeltaIndexArray[j] && !copyChange.ops[i].retain && !copyLastDelta.ops[j].retain) {
              //console.log("same index not retain ops")
              //if the ops are both delete ops, add the delete from lastDelta to the new change
              if(copyChange.ops[i].delete && copyLastDelta.ops[j].delete) {
                if(copyChange.ops[i].delete != copyLastDelta.ops[j].delete) {
                  //newChange = newChange.concat(new Delta(copyLastDelta.ops.slice(j)))
                  //console.log("break due to same index delete conflict")
                  break //breaks due to a same index delete conflict
                } else if(copyChange.ops[i].delete == copyLastDelta.ops[j].delete) {
                  newChange = newChange.concat(new Delta(copyChange.ops.slice(i, i+1)))
                  i++
                  j++
                  continue //continues are for readability
                }
              }
              //if the ops are both insert ops, add the insert from change to the new change
              else if(copyChange.ops[i].insert && copyLastDelta.ops[j].insert) {
                if(copyChange.ops[i].insert != copyLastDelta.ops[j].insert) {
                  //newChange = newChange.concat(new Delta(copyLastDelta.ops.slice(j)))
                  //console.log("break due to a same index insert conflict")
                  break //breaks due to a same index insert conflict
                } else if(copyChange.ops[i].insert == copyLastDelta.ops[j].insert) {
                  newChange = newChange.concat(new Delta().retain(copyChange.ops[i].insert.length))
                  i++
                  j++
                  continue
                }
              }
              //otherwise they are opposite ops, then put in the lastDelta op into newchange
              else {
                newChange = newChange.concat(new Delta().retain(copyLastDelta.ops[j].retain || copyLastDelta.ops[j].delete || copyLastDelta.ops[j].insert.length))
                i++
                j++
                continue
              }
            }
            //if both are retain ops at the same index, add the smaller retain to change and inc both indexes
            else if (opChangeIndexArray[i] == opLastDeltaIndexArray[j] && copyChange.ops[i].retain && copyLastDelta.ops[j].retain) {
              //console.log("same index retain ops")
              if(copyChange.ops[i].retain < copyLastDelta.ops[j].retain) {
                //console.log("add retain from change")
                newChange = newChange.concat(new Delta(copyChange.ops.slice(i, i+1)))
              } else if(copyChange.ops[i].retain > copyLastDelta.ops[j].retain) {
                //console.log("add retain from lastDelta")
                newChange = newChange.concat(new Delta(copyLastDelta.ops.slice(j, j+1)))
              } else {
                //console.log("add retain from both")
                newChange = newChange.concat(new Delta(copyLastDelta.ops.slice(j, j+1)))
              }
              j++
              i++
              continue
            } 
            //if the indexes are the same, then add the op that is smaller and advance both i and j
            else if (opChangeIndexArray[i] == opLastDeltaIndexArray[j]) {
              //console.log("same index one retain and one not retain op")
              let changeOp = copyChange.ops[i].retain || copyChange.ops[i].delete || copyChange.ops[i].insert.length
              let lastDeltaOp = copyLastDelta.ops[j].retain || copyLastDelta.ops[j].delete || copyLastDelta.ops[j].insert.length
              let largerOp = Math.max(changeOp, lastDeltaOp)
              if(largerOp == changeOp) {
                newChange = newChange.concat(new Delta(copyChange.ops.slice(i, i+1)))
              } else if(largerOp == lastDeltaOp) {
                newChange = newChange.concat(new Delta().retain(lastDeltaOp))
              }
              j++
              i++
              continue
            }
            //add the op at the lower index to the new change and inc that index
            while (i < copyChange.ops.length && opChangeIndexArray[i] < opLastDeltaIndexArray[j]) {
              //console.log("add change op")
              newChange = newChange.concat(new Delta(copyChange.ops.slice(i, i+1)))
              //increase lastdelta index if the change op was a insert op
              if(copyChange.ops[i].insert) {
                opLastDeltaIndexArray = opLastDeltaIndexArray.map(function(index) {
                  return index + copyChange.ops[i].insert.length
                })
              }
              i++
            }
            while (j < copyLastDelta.ops.length && opChangeIndexArray[i] > opLastDeltaIndexArray[j]) {
              //console.log("keep lastDelta op")
              newChange = newChange.concat(new Delta().retain(copyLastDelta.ops[j].retain || copyLastDelta.ops[j].delete || copyLastDelta.ops[j].insert.length))
              //increase change index if the lastDelta op was a insert op
              if(copyLastDelta.ops[j].insert) {
                opChangeIndexArray = opChangeIndexArray.map(function(index) {
                  return index + copyLastDelta.ops[j].insert.length
                })
              }
              j++
            }
            //console.log(newChange.ops)
          }

          // Add the remaining ops to the new change
          if (i == copyChange.ops.length) {
            //console.log("add remaining lastDelta ops")
            newChange = newChange.concat(new Delta(copyLastDelta.ops.slice(j)))
          } else if (j == copyLastDelta.ops.length) {
            //console.log("add remaining change ops")
            newChange = newChange.concat(new Delta(copyChange.ops.slice(i)))
          }

        }else {
          //console.log("no conflict")
          newChange = change
        }
        return newChange
      },
      adjustCursorIndex(change, cursorIndex) {
        let cursor = cursorIndex
        let currentAffectedIndex = 0
        //console.log("change ops length " + change.ops.length)
        //console.log("change ops")
        //console.log(change.ops)
        //console.log("cursorIndex " + cursorIndex)
        for(let i = 0; i < change.ops.length; i++) {
          if(currentAffectedIndex > cursorIndex) {
            break
          }
          let op = change.ops[i]
          if(op.insert) {
            cursor += op.insert.length
          }
          else if(op.delete) {
            cursor -= op.delete
          }
          currentAffectedIndex += op.retain || op.delete || op.insert.length
        }
        //console.log("new cursor " + cursor)
        return cursor
      },
      updateDocument() {
        let _this = this
        let mycanvas = {
          notepad : JSON.stringify(this.qeditor.getContents()),
          user    : _this.$store.getters.getUser
        }
        let mindmap = { mindmap: { canvas: JSON.stringify(mycanvas)}}
        let id = this.currentMindMap.unique_key
        http.patch(`/msuite/${id}.json`,mindmap)
        this.lastDelta = new Delta()
        //console.log("lastDelta reset")
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
            change = change.compose(delta)
            //console.log("user change")
            //console.log(change)
            if(_this.lastDelta == null) _this.lastDelta = new Delta()
            _this.lastDelta = _this.lastDelta.compose(delta)
            //console.log("inc lastDelta")
            //console.log(_this.lastDelta)
            setTimeout(() => {
              _this.strongTagStyleBold()
              
              
              if (change.length() > 0) {
                _this.sendLocals(true)
                _this.updateDocument()
                change = new Delta();
              }
              else{
                _this.sendLocals(false)
              }
            },300);
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
