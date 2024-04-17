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
          minDimensions: [32,32],
          headers: [],
        },
        isReset: false,
        userList: [],
        isEditing: false,
        saveElement: true,
        changeRequest: 1,
        addColumnReq: false,
        showPiviotTable: false,
        lastSavedSheet: {
          data: [[]],
          style: {},
          width: [],
          rows: null,
          column: null,
          columns: [],
          minDimensions: [32,32],
          headers: [],
        },
        intermittentSave: {
          data: [[]],
          style: {},
          width: [],
          rows: null,
          column: null,
          columns: [],
          minDimensions: [32,32],
          headers: [],
        },
        dataChangeRequest: 0,
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

              let tableHeaders = this.table.getHeaders(true)
              if(this.sheetData.data != null && (tableHeaders.length != this.sheetData.headers.length || this.sheetData.data[0].length != this.table.getData()[0].length)){
                //Change in grid size requires the table to be recreated
                this.table.destroy()
                this.createSheet(data.mindmap.canvas)
              }else {
                this.updateSheet()
                //Update the headers
                for(let i = 0; i < Math.min(tableHeaders.length, this.sheetData.headers.length); i++){
                  if(this.sheetData.headers == null || this.sheetData.headers.length == 0){
                    break
                  }
                  if(this.sheetData.headers[i] != tableHeaders[i]){
                    this.table.setHeader(i, this.sheetData.headers[i])
                  }
                }
              }

              if(this.currentSelection != null){
                let x = Number(this.currentSelection[0])
                let y = Number(this.currentSelection[1])
                let x1 = Number(this.currentSelection[2])||x
                let y1 = Number(this.currentSelection[3])||y
                this.table.updateSelectionFromCoords(x,y,x1,y1)
                jexcel.current = this.table
              }
              this.lastSavedSheet = JSON.parse(JSON.stringify(this.sheetData))
              this.intermittentSave = JSON.parse(JSON.stringify(this.lastSavedSheet))
              //console.log('SavedSheet updated')
              //console.log(this.lastSavedSheet.data)
            } else {
              setTimeout(() => {
              this.lastSavedSheet = JSON.parse(JSON.stringify(this.sheetData))
              this.intermittentSave = JSON.parse(JSON.stringify(this.lastSavedSheet))
              //console.log('SavedSheet updated')
              //console.log(this.lastSavedSheet.data) 
              }, 500);
            }
            this.changeRequest = this.changeRequest + 1
            this.sheetStyles()
            
          }
          else {}
        }
      }
    },
    methods: {
      updateSheet(){
        if(this.table == null) 
        {
          this.createSheet(this.currentMindMap.canvas)
          return
        }
        if(this.lastSavedSheet.data == null || this.lastSavedSheet.style == null) {
          //console.log('Last saved sheet is null')
          this.table.setData(this.sheetData.data)
          this.table.setStyle(this.sheetData.style)
          return
        }
        //console.log('Update Sheet - Start')
        let tableData = this.table.getData()
        let tableStyle = this.getTableStyle()
        let currLastSaved = JSON.parse(JSON.stringify(this.lastSavedSheet))
        let lastSavedData = JSON.parse(JSON.stringify(currLastSaved.data))
        let lastSavedStyle = JSON.parse(JSON.stringify(currLastSaved.style))

        //console.log('Table Data')
        //console.log(tableData)
        //console.log('Last Saved Data')
        //console.log(lastSavedData)
        //console.log('Websocket Sheet Data')
        //console.log(this.sheetData.data)
        //console.log('Table Style')
        //console.log(tableStyle)
        //console.log('Last Saved Style')
        //console.log(lastSavedStyle)
        //console.log('Websocket Sheet Style')
        //console.log(this.sheetData.style)

        //console.log('Update table - data comparison')

        //check the difference of data between the last saved data and the current data, if there is a difference, put tableData in that cell, if none, put sheetData in that cell
        for(let i = 0; i < lastSavedData.length && i < tableData.length; i++){
          for(let j = 0; j < lastSavedData[i].length && j < tableData[i].length; j++){
            if(lastSavedData[i][j] != tableData[i][j]){
              this.sheetData.data[i][j] = tableData[i][j]
              this.$nextTick(() => {
                this.dataChange()
              })
            }
          }
        }
        //console.log('Style comparison start')
        //check the difference of style between the last saved style and the current style, if there is a difference, put tableStyle in that cell, if none, put sheetData in that cell
        for(const [cell, style] of Object.entries(lastSavedStyle)){
          if(style != tableStyle[cell]){
            this.sheetData.style[cell] = tableStyle[cell]
            this.$nextTick(() => {
              this.changeStyle()
            })
          }
        }
        //console.log('Update table - set data and style')
        //console.log(this.sheetData.data)
        try{
          this.table.setData(this.sheetData.data)
          this.table.setStyle(this.sheetData.style)
        } catch(e){
          this.table.destroy()
          this.createSheet(JSON.stringify(this.sheetData))
        }

      },
      compareRow(gridExtenstion, lastSavedData, otherData){
        //loop through and see if any rows data has been moved up or down
        for(let i = 0; i < lastSavedData.length && i < otherData.length; i++){
            if(lastSavedData[i] != otherData[i]){
              gridExtenstion.y = i
              gridExtenstion.type = lastSavedData[i].length < otherData[i].length
              return true
            }
        }
        gridExtenstion.y = 1
        gridExtenstion.type = true
        return true
      },
      compareColumn(gridExtenstion, lastSavedData, otherData){
        //loop through and see if any column data has been moved up or down
        for(let i = 0; i < lastSavedData[0].length && i < otherData[0].length; i++){
          //create a new array of the column data
          let savedColumnData = []
          for(let j = 0; j < lastSavedData.length; j++){
            savedColumnData.push(lastSavedData[j][i])
          }
          let tableColumnData = []
          for(let j = 0; j < otherData.length; j++){
            tableColumnData.push(otherData[j][i])
          }
          if(savedColumnData != tableColumnData){
            gridExtenstion.x = i
            gridExtenstion.type = savedColumnData.length < tableColumnData.length
            return true
          }
        }
        gridExtenstion.x = 1
        gridExtenstion.type = true
        return true
      },
      createSheet(sheetData){
        let _this = this
        if(_this.currentMindMap.canvas != null) {
          _this.sheetData = JSON.parse(sheetData)
        }
        if(_this.lastSavedSheet.data == null || _this.lastSavedSheet.style == null) {
          _this.lastSavedSheet = JSON.parse(sheetData)
          _this.intermittentSave = JSON.parse(sheetData)
        }
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
          onbeforechange: _this.saveSheet,
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
          onundo: _this.dataChange,
          onredo: _this.dataChange,
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
                _this.undoTable()
              }
            },
            {
              type: 'i',
              content: 'redo',
              onclick: function() {
                _this.redoTable()
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
      saveSheet(){
        this.lastSavedSheet.data = this.intermittentSave.data
        this.lastSavedSheet.style = this.intermittentSave.style
        this.$nextTick(() => {
          this.intermittentSave.data = this.table.getData()
          this.intermittentSave.style = this.getTableStyle()
          //console.log('Sheet saved')
          //console.log(this.lastSavedSheet.data)
        })
        
      },
      dataChange(){
        setTimeout(() => {
          if(this.dataChangeRequest > 0) return
          let _this = this
          _this.sheetData.data    = _this.table.getData()
          _this.sheetData.columns = _this.table.options.columns
          _this.sheetData.headers = _this.table.getHeaders(true)
          _this.sheetData.style   = _this.getTableStyle()
          _this.sheetData.user = this.$store.getters.getUser
          let mindmap = { mindmap: { canvas: JSON.stringify(_this.sheetData) } }
          let id = _this.currentMindMap.unique_key
          if(!_this.isReset){
            //console.log('Data send start')
            //console.log(_this.sheetData.data)
            let response = http.patch(`/msuite/${id}.json`,mindmap)
            if (response) {             
              _this.dataChangeRequest = _this.dataChangeRequest + 1
              //console.log(_this.dataChangeRequest)
              //console.log('Data change saved')
              _this.saveElement = true
              _this.sendLocals(false)
              setTimeout(() => {
                _this.dataChangeRequest = 0
                //console.log(_this.dataChangeRequest)
              }, 25);
            }
          }
          else this.isReset = false
        }, 100);
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
      getTableStyle(){
        let out = {}
        //When a new column or row is added from another user, the style of the table is lost, so we need to catch the error and set the style again
        try {
          out = this.table.getStyle()
        } catch (e) {
          this.changeRequest = this.changeRequest + 1
          this.table.setStyle(this.sheetData.style)
          //console.log(this.sheetData.style)
          out = this.table.getStyle()
        }
        return out
      },
      changeStyle(){
        if(this.changeRequest < 1){
          this.changeRequest = this.changeRequest + 1
          this.sheetData.style = this.getTableStyle()
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
        let tempSelection = this.table.getHighlighted()||null
        if(tempSelection == null || tempSelection == undefined || tempSelection[0] == undefined) return
        if(tempSelection.length == 1){
          this.currentSelection = new Array(4)
          this.currentSelection[0] = tempSelection[0].dataset['x']
          this.currentSelection[1] = tempSelection[0].dataset['y']
        }
        else if(tempSelection[0].dataset['x'] == tempSelection[tempSelection.length - 1].dataset['x'] || tempSelection[0].dataset['y'] == tempSelection[tempSelection.length - 1].dataset['y']){
          //if the user selects a column or row, the selection will be a thin line
          this.currentSelection = new Array(4)
          this.currentSelection[0] = tempSelection[0].dataset['x']
          this.currentSelection[1] = tempSelection[0].dataset['y']
          this.currentSelection[2] = tempSelection[tempSelection.length - 1].dataset['x']
          this.currentSelection[3] = tempSelection[tempSelection.length - 1].dataset['y']
        }
        else if(tempSelection.length > 1){
          //get the opposite corner of the selection considering currentSelection 0 and 1 is the starting point
          let x = this.currentSelection[0]
          let y = this.currentSelection[1]
          let lastElData = tempSelection[tempSelection.length - 1].dataset
          this.currentSelection[2] = tempSelection[0].dataset['x'] == x ? lastElData['x'] : tempSelection[0].dataset['x'];
          this.currentSelection[3] = tempSelection[0].dataset['y'] == y ? lastElData['y'] : tempSelection[0].dataset['y'];
        }
        //console.log(this.currentSelection)
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
