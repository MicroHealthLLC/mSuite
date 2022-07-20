<template>
  <div>
    <navigation-bar
      v-if="isMounted"
      @mSuiteTitleUpdate="mSuiteTitleUpdate"
      @openPrivacy="openPrivacy"
      @deleteMindmap="deleteMap"
      @resetMindmap="resetMindmap"
      @exportXLS="exportXLS($event)"
      :current-mind-map="currentMindMap"
      :defaultDeleteDays="defaultDeleteDays"
      :expDays="expDays"
      :deleteAfter="deleteAfter"
      :exportId="'spreadSheet'"
      :isEditing="isEditing"
      :saveElement="saveElement"
      :excel_data="sheetData.data"
      ref="spreadSheetNavigation">
    </navigation-bar>
    <div id="spreadSheet" class="overflow-auto">
      <div id="mytable" class="w-100"></div>
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
  import jexcel from 'jspreadsheet-ce'
  import { jsontoexcel } from "vue-table-to-excel";
  import "./styles/bossanova.css";
  import "./styles/jsuites.css";

  export default {
    props: ['currentMindMap','defaultDeleteDays','deleteAfter','expDays'],
    data() {
      return {
        isMounted: false,
        formula: '',
        sheetData: {
          data: [[]],
          style: {},
          width: [],
          rows: null,
          column: null,
          columns: [],
        },
        isReset: false,
        isEditing: false,
        saveElement: true,
        changeRequest: 0,
        addColumnReq: false
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
          }
          else if(data.message === "Reset mindmap" && this.currentMindMap.id === data.mindmap.id){
            this.sheetData = JSON.parse(data.mindmap.canvas)
            this.table.setData(this.sheetData.data)
            if(this.sheetData.style != undefined) this.table.setStyle(this.sheetData.style)

            this.table.destroy()
            this.createSheet(data.mindmap.canvas)
            $(".jexcel_content").addClass('h-100 w-100')
            $(".jexcel").addClass('w-100 h-100')
            $(".jexcel_content")[0].style.maxHeight = '100vh'
            setTimeout(()=>{
              let navbarHeight = $(".buttons_container").height()
              let toolbarHeight= $('.jexcel_toolbar').height()
              let totalHeight = navbarHeight + toolbarHeight
              let heightVal = `calc(100vh - ${totalHeight + 52}px)`;
              $('#mytable')[0].style.height = heightVal
            },200)
          }
          else if(data.message === "Mindmap Updated" && this.currentMindMap.id === data.mindmap.id){
            setTimeout(() => {
              this.currentMindMap = data.mindmap
              this.sheetData = JSON.parse(data.mindmap.canvas)
              if(this.sheetData.data != undefined) this.table.setData(this.sheetData.data)
              this.changeRequest = this.changeRequest + 1
              if(this.sheetData.style != undefined) this.table.setStyle(this.sheetData.style)
              if(this.sheetData.column != undefined) {
                if(this.sheetData.columns.length != this.table.options.columns.length){

                  if(this.sheetData.column.addCol){
                    this.table.insertColumn({
                      insertBefore: this.sheetData.column.insertBefore,
                      numOfColumns: this.sheetData.column.numOfColumns,
                      columnNumber: this.sheetData.column.columnNumber,
                    })
                  } else if(this.sheetData.column.delCol){
                    this.table.deleteColumn(this.sheetData.column.columnNumber, this.sheetData.column.numOfColumns)
                    this.sheetData.columns.pop()
                  }

                  this.sheetData.column = null

                  let mindmap = { mindmap: { canvas: JSON.stringify(this.sheetData) } }
                  let id = this.currentMindMap.unique_key
                  if(!this.isReset){
                    http.patch(`/msuite/${id}.json`,mindmap)
                    this.isEditing = false
                    this.saveElement = true
                  }
                }
              }
            }, 500)
          }
          else {}
        }
      }
    },
    methods: {
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
      resetMindmap() {
        this.isReset = true
        http.get(`/msuite/${this.currentMindMap.unique_key}/reset_mindmap.json`)
      },
      createSheet(sheetData){
        if(this.currentMindMap.canvas != null) this.sheetData = JSON.parse(sheetData)
        let table = jexcel(document.getElementById('mytable'), {
          data: this.sheetData.data,
          style: this.sheetData.style,
          colWidths: this.sheetData.width,
          formula: true,
          tableOverflow: true,
          tableHeight: '100vh',
          minDimensions:[32,32],
          allowRenameColumn: false,
          onchange: this.dataChange,
          onchangestyle: this.changeStyle,
          onresizecolumn: this.changeSizeColmun,
          onselection: this.selectionCreated,
          oneditionstart: this.editStart,
          oneditionend: this.editEnd,
          oninsertrow: this.insertRow,
          ondeleterow: this.dataChange,
          oninsertcolumn: this.insertColumn,
          ondeletecolumn: this.deleteColumn,
          onsort: this.sort,
          csvFileName: `${this.currentMindMap.unique_key}`,
          toolbar:[
            {
              type: 'i',
              content: 'undo',
              onclick: function() {
                table.undo();
              }
            },
            {
              type: 'i',
              content: 'redo',
              onclick: function() {
                table.redo();
              }
            },
            {
              type: 'select',
              k: 'font-family',
              v: ['Arial','Verdana']
            },
            {
              type: 'select',
              k: 'font-size',
              v: ['9px','10px','11px','12px','13px','14px','15px','16px','17px','18px','19px','20px','40px','60px']
            },
            {
              type: 'i',
              content: 'format_align_left',
              k: 'text-align',
              v: 'left'
            },
            {
              type:'i',
              content:'format_align_center',
              k:'text-align',
              v:'center'
            },
            {
              type: 'i',
              content: 'format_align_right',
              k: 'text-align',
              v: 'right'
            },
            {
              type: 'i',
              content: 'format_bold',
              k: 'font-weight',
              v: 'bold'
            },
             {
              type: 'color',
              content: 'format_color_text',
              k: 'color'
            },
            {
              type: 'color',
              content: 'format_color_fill',
              k: 'background-color'
            },
          ],
        });
        this.table = table
      },
      dataChange(){
        this.sheetData.data = this.table.getData()
        let mindmap = { mindmap: { canvas: JSON.stringify(this.sheetData) } }
        let id = this.currentMindMap.unique_key
        if(!this.isReset){
          http.patch(`/msuite/${id}.json`,mindmap)
          this.isEditing = false
          this.saveElement = true
        }
        else this.isReset = false
      },
      editStart(){
        this.isEditing = true
      },
      editEnd(){
        this.sheetData.data = JSON.stringify(this.table.getData())
      },
      changeSizeColmun(){
        this.sheetData.width = this.table.getWidth().map(function (x) {
          return parseInt(x, 10);
        });
        this.changeStyle()
      },
      changeStyle(){
        if(this.changeRequest < 1){
          setTimeout(()=>{
            if(this.table.getStyle()) this.sheetData.style = this.table.getStyle()
            let mindmap = { mindmap: { canvas: JSON.stringify(this.sheetData) } }
            let id = this.currentMindMap.unique_key
            if(!this.isReset){
              http.patch(`/msuite/${id}.json`,mindmap)
              this.isEditing = false
              this.saveElement = true
            }
            else this.isReset = false
          },500)
        }
      },
      selectionCreated(){
        this.changeRequest = 0
      },
      insertRow(el, rowNumber, numOfRows, historyRecords, insertBefore){
        this.sheetData.row = {
          rowNumber      : rowNumber,
          numOfRows      : numOfRows,
          historyRecords : historyRecords,
          insertBefore   : insertBefore
        }
        let mindmap = { mindmap: { canvas: JSON.stringify(this.sheetData) } }
        let id = this.currentMindMap.unique_key
        if(!this.isReset){
          http.patch(`/msuite/${id}.json`,mindmap)
          this.isEditing = false
          this.saveElement = true
        }

      },
      insertColumn(worksheet, columnNumber, numOfColumns, historyRecords, insertBefore){
        this.table.resetSelection(true)
        this.sheetData.column = {
          columnNumber   : columnNumber,
          numOfColumns   : numOfColumns,
          historyRecords : historyRecords,
          insertBefore   : insertBefore,
          addCol         : true
        }
        this.sheetData.columns = this.table.options.columns

          let mindmap = { mindmap: { canvas: JSON.stringify(this.sheetData) } }
          let id = this.currentMindMap.unique_key
          if(!this.isReset){
            http.patch(`/msuite/${id}.json`,mindmap)
            this.isEditing = false
            this.saveElement = true
          }
      },
      deleteColumn(worksheet, columnNumber, numOfColumns, affectedDOMElements, historyProperties, cellAttributes){
        this.table.resetSelection(true)
        this.sheetData.column = {
            columnNumber        : columnNumber,
            numOfColumns        : numOfColumns,
            affectedDOMElements : affectedDOMElements,
            historyProperties   : historyProperties,
            cellAttributes      : cellAttributes,
            delCol              : true
          }
        this.sheetData.columns = this.table.options.columns
          let mindmap = { mindmap: { canvas: JSON.stringify(this.sheetData) } }
          let id = this.currentMindMap.unique_key
          if(!this.isReset){
            http.patch(`/msuite/${id}.json`,mindmap)
            this.isEditing = false
            this.saveElement = true
          }
      },
      exportXLS(option){
        if(option === 1){

          var tab_text="<table border='0.5px'><tr>";
          var textRange; var j=0;
          let tab = document.getElementsByClassName('jexcel')[0];

          for(j = 1 ; j < tab.rows.length ; j++)
          {
              tab_text = tab_text+tab.rows[j].innerHTML+"</tr>";
              tab_text = tab_text.replace(`<td data-y="${j-1}" class="jexcel_row">${j}</td>`,"")
          }
          tab_text = tab_text.replace(`<td data-y="0" class="jexcel_row">${tab.rows.length}</td>`,"")

          tab_text=tab_text+"</table>";
          tab_text= tab_text.replace(/<A[^>]*>|<\/A>/g, "");
          tab_text= tab_text.replace(/<img[^>]*>/gi,"");
          tab_text= tab_text.replace(/<input[^>]*>|<\/input>/gi, "");

          var ua = window.navigator.userAgent;
          var msie = ua.indexOf("MSIE ");
          let sa = null
          if (msie > 0 || !!navigator.userAgent.match(/Trident.*rv\:11\./)) {
            txtArea1.document.open("txt/html","replace");
            txtArea1.document.write(tab_text);
            txtArea1.document.close();
            txtArea1.focus();
            sa=txtArea1.document.execCommand("SaveAs",true,"Say Thanks to Sumit.xls");
          } else {
              this.$refs['spreadSheetNavigation'].$refs['exportOptionCsv'].close()
              let myDocument = 'data:application/vnd.ms-excel,' + encodeURIComponent(tab_text);
              let link = document.createElement("a");
              document.body.appendChild(link);
              link.download = `${this.currentMindMap.unique_key}.xls`;
              link.href = myDocument;
              link.click();
              document.body.removeChild(link);
            }
          return (sa);
        }
        if(option === 2){
          this.table.download();
        }
        this.$refs['spreadSheetNavigation'].$refs['exportOptionCsv'].close()
      }
    },
    created() {
      setTimeout(() => this.saveElement = false, 1200)
    },
    updated() {
      setTimeout(() => this.saveElement = false, 1200)
      setTimeout(()=>{
        if($('.arrow-down').length > 0 && $('.arrow-up').length < 1){
          $('.arrow-down').addClass('arrow-up').removeClass('arrow-down')
        } else if ($('.arrow-up').length > 0 && $('.arrow-down').length < 1){
          $('.arrow-up').addClass('arrow-down').removeClass('arrow-up')
        }
      }, 500)
    },
    mounted() {
      this.$cable.subscribe({ channel:"WebNotificationsChannel", room: this.currentMindMap.id })
      this.createSheet(this.currentMindMap.canvas)
      $(".jexcel_content").addClass('h-100 w-100')
      $(".jexcel").addClass('w-100 h-100')
      $(".jexcel_content")[0].style.maxHeight = '100vh'
      setTimeout(()=>{
        let navbarHeight = $(".buttons_container").height()
        let toolbarHeight= $('.jexcel_toolbar').height()
        let totalHeight = navbarHeight + toolbarHeight
        let heightVal = `calc(100vh - ${totalHeight + 52}px)`;
        $('#mytable')[0].style.height = heightVal
      },200)
      this.isMounted = true
    },
  }
</script>
