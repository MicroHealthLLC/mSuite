<template>
  <div class="overflow-auto maxHeight">
    <span v-if="showPiviotTable" class="px-2" @click="showTable">
      <i class="table_icon fas fa-table fa-2x"></i>
    </span>
    <div id="graphs" class="w-100"></div>
    <div id="spreadSheet">
      <div id="mytable" class="w-100"></div>
    </div>
  </div>
</template>
<script>
  import http from "../../common/http"
  import jexcel from 'jspreadsheet-ce'
  import "./styles/bossanova.css";
  import "./styles/jsuites.css";
  import TemporaryUser from "../../mixins/temporary_user.js"
  import 'pivottable'
  import 'pivottable/dist/pivot.min.js'
  import 'pivottable/dist/pivot.min.css'
  import $ from 'jquery'
  import 'jquery-ui-bundle'
  import 'jquery-ui-bundle/jquery-ui.css'
  import '../../common/plotly.js'
  import '../../common/plotly_renderers.min.js' 
  export default {
    props: {
      exportDef : Function,
      undoMap   : Function,
      redoMap   : Function
    },
    data() {
      return {
        currentMindMap: this.$store.getters.getMsuite,
        formula: '',
        sheetData: {
          data: [[]],
          style: {},
          width: [],
          rows: null,
          column: null,
          columns: [],
          minDimensions: [32,32]
        },
        isReset: false,
        userList: [],
        isEditing: false,
        saveElement: true,
        changeRequest: 1,
        addColumnReq: false,
        showPiviotTable: false
      }
    },
    components: {},
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
            this.currentMindMap = data.mindmap
            this.$store.commit('setMSuite', data.mindmap)
            this.sheetData = JSON.parse(data.mindmap.canvas)
            this.table.setData(this.sheetData.data)
            if(this.sheetData.style != undefined) this.table.setStyle(this.sheetData.style)
            this.table.destroy()
            this.createSheet(data.mindmap.canvas)
            this.sheetStyles()
          } else if (
            data.message === "storage updated"             &&
            this.currentMindMap.id == data.content.mindmap_id
          ) {
            this.$store.dispatch('setUserEdit'     , data.content.userEdit)
            this.$store.dispatch('setTemporaryUser', data.content.userEdit)
            this.$store.dispatch('setUserList'     , data.content.userEdit)
            this.temporaryUser = data.content.userEdit
          } else if (
            data.message === "Mindmap Updated"      &&
            this.currentMindMap.id === data.mindmap.id
          ) {
            this.$store.commit('setMSuite', data.mindmap)
            this.currentMindMap = data.mindmap
            this.sheetData = JSON.parse(data.mindmap.canvas)

            if(this.temporaryUser != this.$store.getters.getUser){
              this.table.destroy()
              this.createSheet(data.mindmap.canvas)
            }
            this.changeRequest = this.changeRequest + 1
            this.sheetStyles()
          }
          else {}
        }
      }
    },
    methods: {
      createSheet(sheetData){
        let _this = this
        if(_this.currentMindMap.canvas != null) _this.sheetData = JSON.parse(sheetData)
        if(this.currentMindMap.canvas && this.sheetData.data.length > 0 && this.sheetData.columns.length > 0) this.sheetData.minDimensions = [_this.sheetData.columns.length, _this.sheetData.data.length]
        else{
          this.sheetData.minDimensions = [32,32]
        }
        let table = jexcel(document.getElementById('mytable'), {
          data: _this.sheetData.data,
          columns: _this.sheetData.columns,
          style: _this.sheetData.style,
          colWidths: _this.sheetData.width,
          formula: true,
          tableOverflow: true,
          tableHeight: '100vh',
          minDimensions: _this.sheetData.minDimensions,
          allowRenameColumn: true,
          onchange: _this.dataChange,
          onchangestyle: _this.changeStyle,
          onresizecolumn: _this.changeSizeColmun,
          onselection: _this.selectionCreated,
          oneditionstart: _this.editStart,
          oneditionend: _this.editEnd,
          oninsertrow: _this.dataChange,
          ondeleterow: _this.dataChange,
          oninsertcolumn: _this.dataChange,
          ondeletecolumn: _this.dataChange,
          onchangeheader: _this.dataChange,
          csvFileName: `${_this.currentMindMap.unique_key}`,
          toolbar:[
            {
              type: 'i',
              content: 'table-pivot',
              onclick: function() {
                _this.createPivotTable()
              }
            },
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
        _this.table = table
      },
      sheetStyles(){
        $(".jexcel_content").addClass('h-100 w-100')
        $(".jexcel").addClass('w-100 h-100')
        $(".jexcel_content")[0].style.maxHeight = '100vh'
        setTimeout(()=>{
          let navbarHeight = $(".buttons_container").height()
          let toolbarHeight= $('.jexcel_toolbar').height()
          let totalHeight = navbarHeight + toolbarHeight
          let heightVal = `calc(100vh - ${totalHeight + 52}px)`
          $('#mytable')[0].style.height = heightVal
        },200)
      },
      async dataChange(){
        let _this = this
        _this.sheetData.data    = _this.table.getData()
        _this.sheetData.columns = _this.table.options.columns
        if(_this.table.getStyle()) _this.sheetData.style = _this.table.getStyle()
        _this.sheetData.user = this.$store.getters.getUser
        let mindmap = { mindmap: { canvas: JSON.stringify(_this.sheetData) } }
        let id = _this.currentMindMap.unique_key
        if(!_this.isReset){
          let response = await http.patch(`/msuite/${id}.json`,mindmap)
          if (response) {
            _this.saveElement = true
            _this.sendLocals(false)
          }
        }
        else this.isReset = false
      },
      editStart(){
        this.sendLocals(true)
      },
      editEnd(){
        this.sheetData.data = JSON.stringify(this.table.getData())
      },
      changeSizeColmun(){
        this.sheetData.width = this.table.getWidth().map(function (x) {
          return parseInt(x, 30);
        });
          this.changeStyle()
      },
      changeStyle(){
        if(this.changeRequest < 1){
          if(this.table) this.sheetData.style = this.table.getStyle()
          this.sheetData.user = this.$store.getters.getUser
          let mindmap = { mindmap: { canvas: JSON.stringify(this.sheetData) } }
          let id = this.currentMindMap.unique_key
          if(!this.isReset){
            http.patch(`/msuite/${id}.json`,mindmap)
            this.saveElement = true
            this.sendLocals(false)
          }
          else this.isReset = false
        }
      },
      selectionCreated(){
        this.changeRequest = 0
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
      },
      createPivotTable(){
        this.showPiviotTable = true
        let pivotData        = this.table.getData()
        let element          = ''
        while(element == ''){
          if(pivotData[0][pivotData[0].length - 1] == '') pivotData[0].pop()
          element = pivotData[0][pivotData[0].length - 1]
        }
        this.table.destroy()
        $('#graphs').append( '<div id="pivot_table"></div>' )
        var derivers = $.pivotUtilities.derivers;
        var renderers = $.extend($.pivotUtilities.renderers,$.pivotUtilities.plotly_renderers);
        $("#pivot_table").pivotUI(pivotData,{
          renderers: renderers,
          });       
      },
      showTable(){
        this.showPiviotTable = false
        $("#pivot_table").remove()
        this.createSheet(this.currentMindMap.canvas)
      },
      undoTable(){
        this.table.undo()
      },
      redoTable(){
        this.table.redo()
      }
    },
    created() {
      setTimeout(() => this.saveElement = false, 1200)
    },
    updated() {
      setTimeout(() => this.saveElement = false, 1200)
    },
    mounted() {
      this.subscribeCable(this.currentMindMap.id)
      this.$store.dispatch('setExportId', 'spreadSheet')
      this.sendLocals(false)
      this.setUserOnMountC()
      this.createSheet(this.currentMindMap.canvas)
      this.sheetStyles()

      this.getUserOnMount()
      this.exportDef(this.exportXLS)
      this.undoMap(this.undoTable)
      this.redoMap(this.redoTable)
      $( ".jexcel_toolbar" ).mouseover(()=>{
        this.selectionCreated()
      })
    },
  }
</script>
<style>
  .arrow-down{
    background-image: url("data:image/svg+xml,%0A%3Csvg xmlns='http://www.w3.org/2000/svg' width='24' height='24' viewBox='0 0 24 24'%3E%3Cpath fill='none' d='M0 0h24v24H0V0z'/%3E%3Cpath d='M7 14l5-5 5 5H7z' fill='gray'/%3E%3C/svg%3E") !important;
  }
  .arrow-up{
    background-image: url("data:image/svg+xml,%0A%3Csvg xmlns='http://www.w3.org/2000/svg' width='24' height='24' viewBox='0 0 24 24'%3E%3Cpath fill='none' d='M0 0h24v24H0V0z'/%3E%3Cpath d='M7 10l5 5 5-5H7z' fill='gray'/%3E%3C/svg%3E") !important;
  }
  .pvtUi{
    width: 100% !important;
  }
  .pvtTable{
    width: 100% !important;
  }
  .pvtAxisContainer.pvtRows.pvtUiCell.ui-sortable{
    width: 25% !important;
  }
  .table_icon{
    font-weight: 500 !important;
    cursor: pointer;
  }
  thead > tr > th.pvtTotalLabel, .rowTotal, .pvtGrandTotal { display: none; }
  tbody > tr > th.pvtTotalLabel, .colTotal, .pvtGrandTotal { display: none; }

  
</style>
