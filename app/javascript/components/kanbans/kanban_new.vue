<template>
  <div class="row kanban_board" id="kanban-board">
    <kanban-board :stages="computedStages" :blocks="blocks" :config="config" @update-block="updateBlockPosition">
      <div v-for="stage, index in computedStages" :slot="stage" :key="index" class="w-100 font-serif" >
        <div class="w-100 mb-2" :id="'stage_'+index">
          <div class="d-inline-block w-100 block">
            <div class="pointer w-100 d-flex">
              <div @click="updateStage(stage)" class="w-75">
                <textarea-autosize @keydown.enter.prevent.native :id="index" :rows="1" type="text" v-debounce:3000ms="blurEvent" :value="stage" class="border-0 stage-title" @blur.native="newStageTitle($event)" placeholder="Enter Stage Title" />
              </div>
              <div class="d-flex w-25 justify-content-end">
                <div class="pointer" @click="stage.length > 0 ? selectedElementBg(stage,$event) : '' ">
                  <i class="fas fa-eye-dropper color-picker mt-1 icon-opacity" title="Color Picker"></i>
                </div>
                <div class="pointer text-center" @click="stage.length > 0 ? addNewStage(stage,index) : ''">
                    <i class="fas fa-plus mt-1 add-icon icon-opacity" title="Add Stage"></i>
                </div>
                <div class="pointer" @click="deleteStageConfirm(stage)">
                  <i class="fas ml-2 fa-times mt-1 icon-delete-stage" title="Delete Stage"></i>
                </div>
              </div>
            </div>
          </div>
        </div>
        <div v-if="stage !== '' " @mouseover="hover_addtask = index" @mouseleave="hover_addtask = '' " :class="hover_addtask === index ? 'hover_task rounded' : ''" @click.prevent="addBlockToStage(stage)" class="pointer d-inline-block w-100" title="Add a Task">
          <a role="button" class="bg-transparent border-0 pe-none">
            <i class="fas fa-solid fa-list position-absolute mt-1 text-secondary"></i>
            <span class="task_plus ml-4"> Add a Task </span>
          </a>
        </div>
      </div>
      <div v-for="block,index in blocks" :slot="block.id" :key="block.id">
        <div :id="'block' + block.id" class="d-inline-block w-100 block">
          <div class="pointer w-100 d-flex" @click="selectedNode(index)">
            <textarea-autosize @keydown.enter.prevent.native :rows="1" type="text" v-debounce:3000ms="blurEvent" v-model="block.title" @blur.native="updateBlock(block, $event, index)" class=" border-0 resize-text block-title" placeholder="Add text here" />
            <div class="pointer float-right">
              <div @click="deleteBlockConfirm(block)">
                <i class="fas ml-2 fa-times text-danger position-relative icon-opacity ml-2" title="Delete Task"></i>
              </div>
              <div @click="selectedElementBg(block,$event)">
                <i class="fas fa-eye-dropper text-muted color-picker ml-2 icon-opacity" title="Color Picker"></i>
              </div>
              <div>
                <i class="fas fa-arrows-alt text-secondary position-relative ml-2 icon-opacity" title="Drag Task"></i>
              </div>
            </div>
          </div>
        </div>
      </div>
    </kanban-board>
    <div v-if="colorSelected">
      <div class="card p-0 border-none color-picker-placement">
        <color-palette
          :selected-node="selectedStage"
          :selected-block="selectedBlock"
          :nodes="allStages"
          :currentMindMap="currentMindMap"
          :customPallete="customPallete"
          :uniqueColors="uniqueColors"
          @updateColorNode="updateColor"
          @saveNodeColor="saveNodeColor"
          @closeModelPicker="closeModelPicker"
          @updateTreeChartNode="updateStageRequest"
          ></color-palette>
      </div>
    </div>
  </div>
</template>

<script>
  import http from "../../common/http"
  import vueKanban from 'vue-kanban'
  import Sortable from 'sortablejs';
  import ColorPalette from '../../common/modals/color_palette_modal'
  import Common from "../../mixins/common.js"
  import TemporaryUser from "../../mixins/temporary_user.js"
  import History from "../../mixins/history.js"
  import "./styles/kanban_new.css";

  var autoScroll = require('dom-autoscroller');
  Vue.use(vueKanban);

  export default {
    mixins: [Common, TemporaryUser, History],
    data() {
      return {
        new_stage: false,
        color: {hex: ''},
        allStages: [],
        blocks: [],
        mapColors: [],
        uniqueColors: [],
        colorSelected: false,
        stage: null,
        block: {},
        new_index: -1,
        new_color:'',
        previousColor: null,
        selectedStage: null,
        selectedBlock: null,
        selectedElement: null,
        hover_addtask: '',
        selected: '',
        isSaveMSuite: false,
        customPallete: [],
        nodeNumber: 0,
        undoNodes: [],
        redoNodes: [],
        undoDone: false,
        config: {
          accepts(block, target, source){
            return target.dataset.status !== ''
          }
        }
      }
    },
    props: ['undoMap','redoMap'],
    channels: {
      WebNotificationsChannel: {
        received: async function(data) {
          if (data.message === "Mindmap Deleted" && this.currentMindMap.id === data.mindmap.id)
          {
            window.open('/','_self')
          }
          else if(data.message === "Password Updated" && this.currentMindMap.id === data.mindmap.id)
          {
            setTimeout(() => {
              location.reload()
            }, 500)
          }
          else if(data.message === "Mindmap Updated" && this.currentMindMap.id === data.mindmap.id)
          {
            Vue.set(this.currentMindMap, 'title', data.mindmap.title)
          }
          else if(data.message === "storage updated" && this.currentMindMap.id == data.content.mindmap_id )
          {
            this.$store.dispatch('setUserEdit'     , data.content.userEdit)
            this.$store.dispatch('setNodeNumber' , data.content.nodeNumber)
            this.$store.dispatch('setTemporaryUser', data.content.userEdit)
            this.$store.dispatch('setUserList'     , data.content.userEdit)
          }
          else if(data.message === "Stage Reset"){
            this.getMindmap()
          }
          else {
            this.getMindmap()
            if(data.message === "Stage Updated"){
              this.allStages = data.stages
              this.updateBackgroundColors()
            } else if(data.message === "Node is updated"){
              this.updateBlockColors()
            }
          }
        }
      }
    },
    mounted: async function() {
      this.subscribeCable(this.currentMindMap.id)
      this.$store.dispatch('setExportId', 'kanban-board')
      this.$store.dispatch('setMindMapId', this.$store.getters.getMsuite.id)
      this.undoMap(this.undoObj)
      this.redoMap(this.redoObj)
      await this.getMindmap()
      if (this.currentMindMap.canvas !=null){
        this.$store.dispatch('setUserEdit', this.currentMindMap.canvas)
        this.$store.dispatch('setTemporaryUser', this.currentMindMap.canvas)
        this.setUserOnMount()
      }
      else{
        this.$store.dispatch('setUserEdit', this.currentMindMap.canvas)
        this.$store.dispatch('setTemporaryUser', this.currentMindMap.canvas)
        this.$store.dispatch('emptyUserList')
      }
      this.mountKanBan()
      this.getUserOnMount()
      setTimeout(()=>{
        let height = document.getElementById('nav').offsetHeight
        document.getElementById('kanban-board').style.height = `calc(100vh - ${height}px)`
      }, 1400)
    },
    components:{
      ColorPalette
    },
    computed: {
      currentMindMap() {
        return this.$store.getters.getMsuite
      },
      computedStages() {
        return this.allStages.map(stage => stage.title.length > 0 ? stage.title : '')
      },
      checkTempDelete() {
        return this.allStages.some(stage => stage.title === '')
      }
    },
    watch: {
      currentMindMap: {
        handler(value){
          this.allStages = value.stages
          this.blocks = value.nodes
        }, deep: true
      }
    },
    methods: {
      mountKanBan(){
        this.$nextTick(function () {
          setTimeout(()=>{
            var elements = Array.from(document.querySelectorAll(".drag-inner-list, #kanban-board"));
            autoScroll(
              elements,
              {
                margin: 20,
                maxSpeed: 7,
                scrollWhenOutside: true,
                autoScroll: function() {
                  return this.down
                }
              }
            );
            var dragElement = document.getElementsByClassName('drag-list')[0];
            var newStageEle = null
            var _this = this
            var sortable = new Sortable(dragElement, {
              sort: true,
              delay: 0,
              draggable: ".drag-column",
              dragClass: "sortable-drag",
              ghostClass: "sortable-ghost",
              filter: ".drag-column-",
              onEnd: function (evt) {
                var itemEl = evt.item
                let title = itemEl.getElementsByTagName('textarea')[0].value
                _this.changeStagePositions(title, evt.oldIndex, evt.newIndex)
              },
              onFilter: function (evt) {
                var item = evt.item, ctrl = evt.target
                if (Sortable.utils.is(ctrl, ".drag-column-")) {
                  item.getElementsByTagName('textarea')[0].focus()
                }
                else if (Sortable.utils.is(ctrl, ".block-title")) {
                  ctrl.focus()
                }
              }
            });
            this.updateBackgroundColors()
            this.updateBlockColors()
          }, 1500)
        })
      },
      updateKanbanUser(){
        http.put(`/msuite/${this.currentMindMap.unique_key}`, {
          canvas: this.$store.state.userEdit
        });
      },
      //=====================GETTING MINDMAP==============================//
      getMindmap: async function(){
        await this.$store.dispatch('getMSuite')
        this.updateBackgroundColors()
        this.updateColors()
      },
      async updateColors(){
        this.mapColors = []
        this.uniqueColors = []
        await this.getColorNode('.drag-column')
        await this.getColorNode('.block-title')
        this.updateBlockColors()
        Object.values(this.allStages).forEach(stage => {
          this.mapColors.push(stage.stage_color)
        })
        Object.values(this.blocks).forEach(block => {
          this.mapColors.push(block.line_color)
        })
        this.uniqueColors = this.getUniqueColors(this.mapColors)
        this.new_stage = false
      },
      // =====================STAGES CRUD OPERATIONS==============================//
      updateStageRequest(obj){
        let data = {
          stage:{
            stage_color : obj.stage_color,
            mindmap_id : this.currentMindMap.id,
            title : obj.title,
            position : obj.position
          }
        }
        this.colorSelected = false
        if (obj.line_color) this.selectedStage = null
        this.sendLocals(false)
        this.updateKanbanUser()
        return http.patch(`/stages/${obj.id}.json`,data)
      },
      updateBackgroundColors(){
        let ArraybgColors = Array.from(document.getElementsByClassName('drag-column'))
        ArraybgColors.forEach((bg, index) => {
          bg.style.backgroundColor = this.allStages[index].stage_color
        })
      },
      updateBlockColors(){
        let _this = this
        let BlockbgColors = Array.from(document.getElementsByClassName('block'))
        BlockbgColors.forEach( color => {
          if(color.id != ''){
            for(let index=0; index < _this.blocks.length; index++){
              if (color.id === 'block' + _this.blocks[index].id){
                color.parentElement.parentElement.style.background = _this.blocks[index].line_color
                color.children[0].children[0].style.backgroundColor = _this.blocks[index].line_color
                break
              }
            }
          }
        })
      },
      updateColor(){
        if (this.selectedStage) {
          this.selectedElement.style.backgroundColor = this.selectedStage.stage_color.hex
          this.getColorNode('.drag-column')
        }
        else {
          this.selectedElement.parentElement.parentElement.style.backgroundColor = this.selectedBlock.line_color.hex
          this.selectedElement.children[0].children[0].style.backgroundColor = this.selectedBlock.line_color.hex
          this.getColorNode('.block-title')
        }
      },
      selectedElementBg(element, e){
        if(this.selectedElement){
          if(this.selectedStage){
            let stage_index = this.allStages.findIndex(stg => stg.id === this.selectedStage.id)
            Vue.set(this.allStages[stage_index], 'stage_color', this.previousColor)
            this.selectedElement.style.backgroundColor = this.previousColor
            this.getColorNode('.drag-column')
          } else if (this.selectedBlock){
            let block_index = this.blocks.findIndex(blk => blk.id === this.selectedBlock.id)
            Vue.set(this.blocks[block_index], 'line_color', this.previousColor)
            this.selectedElement.parentElement.parentElement.style.backgroundColor = this.previousColor
            this.selectedElement.children[0].children[0].style.backgroundColor = this.previousColor
            this.getColorNode('.block-title')
          }
          this.selectedStage = null
          this.selectedBlock = null
          this.colorSelected = false
          this.selectedElement = null
        }
        if ( typeof(element) == 'string' ){
          this.selectedStage = this.allStages.find(stg => stg.title === element)
          this.previousColor = this.selectedStage.stage_color
          this.selectedElement = document.getElementsByClassName('drag-column-' + element)[0]
        } else {
          this.selectedBlock = this.blocks.find(blk => blk.id === element.id)
          this.previousColor = this.selectedBlock.line_color
          this.selectedElement = document.getElementById('block'+element.id)
          if(this.selectedBlock.line_color == null) this.selectedBlock.line_color = "#FFFFFF"
        }
        this.colorSelected = true
      },
      async saveNodeColor(){
        let _this = this
        this.sendLocals(true)
        if(this.selectedStage){
          this.selectedStage.stage_color = this.selectedStage.stage_color.hex
          const response = await this.updateStageRequest(this.selectedStage)
            if (response) {
            let index = this.allStages.findIndex( stg => stg.id === this.selectedStage.id)
            Vue.set(this.allStages[index], 'stage_color', response.data.stage.stage_color)
          } else {
            console.log("stage not updated")
          }
        } else if (this.selectedBlock){
          this.selectedBlock.line_color = this.selectedBlock.line_color.hex
          const response = this.updateBlockRequest(this.selectedBlock)
          await response.then((res) => {
            let index = _this.blocks.findIndex( blk => blk.id === _this.selectedBlock.id)
            Vue.set(_this.blocks[index], 'line_color', res.data.node.line_color)
          })
        }
        this.selectedStage = null
        this.selectedBlock = null
        this.selectedElement = null
        this.colorSelected = false
      },
      saveTempColor(){
        let index = this.allStages.findIndex( stg => stg.title === this.selectedStage.title)
        this.allStages[index].stage_color = this.selectedStage.stage_color.hex
        let block_index = this.blocks.findIndex( blk => blk.id === this.selectedBlock.id )
        this.blocks[block_index].line_color = this.selectedBlock.line_color.hex
        this.selectedStage = null
        this.selectedElement = null
        this.colorSelected = false
        this.sendLocals(true)
      },
      closeModelPicker(){
        if (this.selectedStage != null){
          let stage_index = this.allStages.findIndex( stg => stg.id === this.selectedStage.id)
          Vue.set(this.allStages[stage_index], 'stage_color', this.previousColor)
          this.selectedElement.style.backgroundColor = this.previousColor

          Object.values(this.allStages).forEach((stage, index) => {
            let element = document.getElementsByClassName('drag-column')[index]
            element.style.backgroundColor = stage.stage_color
          });
          this.getColorNode('.drag-column')
        } else {
          let block_index = this.blocks.findIndex( blk => blk.id === this.selectedBlock.id)
          Vue.set(this.blocks[block_index], 'line_color', this.previousColor)
          this.selectedElement.parentElement.parentElement.style.backgroundColor = this.previousColor
          this.selectedElement.children[0].children[0].style.backgroundColor = this.previousColor

          Object.values(this.blocks).forEach((blk, index) => {
            let block = document.getElementById('block' + blk.id)
            block.parentElement.parentElement.style.backgroundColor = blk.line_color
            block.children[0].children[0].style.backgroundColor = blk.line_color
          });
          this.getColorNode('.block-title')
        }
        this.selectedStage = null
        this.selectedBlock = null
        this.colorSelected = false
        this.selectedElement = null
      },
      addNewStage(stage, stage_index){
        if (this.new_stage) {
          return;
        }
        this.allStages.splice(stage_index + 1, 0, {title: ''})
        this.new_stage = true
        this.new_index = stage_index + 1

        this.$store.dispatch('setMindMapId', this.currentMindMap.id)
        if(this.allStages.length > 2 && this.$store.state.nodeNumber != 'NaN'){
          this.$store.dispatch('setNodeNumber', parseInt(this.$store.state.nodeNumber) + 1)
        } else {
          this.$store.dispatch('setNodeNumber', this.nodeNumber + 1)
        }
        this.createNewStage('STAGE ' + this.$store.state.nodeNumber)
        setTimeout(()=>{
          this.getColorNode('.drag-column')
        },50)

        this.sendLocals(false)
      },
      createNewStage(val){
        this.sendLocals(true)
        let index = this.allStages.findIndex(stg => stg.title === '')
        if(this.checkDuplicate(val))
        {
          this.$refs['duplicateStageModal'].open()
          this.stage = null
          this.selectedElement = null
          this.selectedStage = null
          this.colorSelected = false
        }

        let data = {
          stage: {
            title: val,
            mindmap_id: this.currentMindMap.id,
            position: index,
            stage_color: this.allStages[index].stage_color
          }
        }
        this.updateKanbanUser()
        http
        .post(`/stages.json`, data)
        .then((res) => {
          if(res.data.status == 500){
            val = val + '0'
            this.createNewStage(val)
          } else {
            this.new_stage = false
            this.stage = null
            this.selectedElement = null
            this.selectedStage = null
            this.colorSelected = false
            this.getColorNode('.drag-column')
            this.undoNodes.push({'req': 'addStage', stage: res.data.stage})
            this.sendLocals(false)
          }
        })
        .catch((error) => {
          this.stage = null
          this.selectedElement = null
          this.selectedStage = null
          this.colorSelected = false
          console.log(error)
        })
      },
      addBlockToStage(stage) {
        let data = {
          node: {
            title: "",
            stage_id: this.allStages.find(stg => stg.title === stage).id,
            mindmap_id: this.currentMindMap.id,
            status: stage,
            line_color: '#FFFFFF',
          }
        }
        http
        .post(`/nodes.json`, data)
        .then((res) => {
          this.undoNodes.push({'req': 'addNode', 'node': res.data.node})
          this.sendLocals(false)
          this.updateKanbanUser()
        })
        .catch((err) => {
          console.log(err)
        })
      },
      deleteStage() {
        if(this.stage === '')
        {
          this.allStages.splice(this.new_index,1)
          this.stage = null
          this.new_stage = false
          return;
        }
        let id = this.allStages.find(stg => stg.title === this.stage).id
        let data = {
          stage: {
            id: id
          }
        }
        this.updateKanbanUser()
        http
        .delete(`/stages/${id}.json`,data)
        .then(response =>
        {
          if (response.data.success === true){
            this.allStages = this.allStages.filter(stg => stg.title !== this.stage)
            this.blocks = this.blocks.filter(block => block.status !== this.stage)
            this.stage = null
            this.undoNodes.push({'req': 'deleteStage', stage: response.data.stage, nodes: response.data.nodes })
            this.sendLocals(false)
          }
          else {
            alert("Stage unable to be deleted")
          }
        })
        .catch(error => {console.log(error)})
      },
      updateStage(stage) {
        if (stage === null) {
          this.stage = {}
        }
        else if (this.currentMindMap.editable) {
          this.stage = this.allStages.find(stg => stg.title === stage)
        }
      },

      editStageTitle: async function(val){
        this.sendLocals(true)
        val = val.replace(/\r?\n|\r/g, "")
        val.length < 1 ? this.$refs['errorStageModal'].open() : ''
        if (val.length > 0 && this.checkDuplicate(val)){
          this.$refs['duplicateStageModal'].open()
          let index = this.allStages.findIndex(stg => stg.id === this.stage.id)
          this.allStages[index].title = ''
          this.getMindmap()
          this.sendLocals(false)
          return
        }

        this.stage.title =  val.length > 0 ? val : this.stage.title
        const response = await this.updateStageRequest(this.stage)
        if (response) {
          let index = this.allStages.findIndex(stg => stg.id === response.data.stage.id)
          this.getColorNode('.drag-column')
          if (val.length < 1){
            this.allStages[index].title = ''
            this.getMindmap()
            this.sendLocals(false)
          }
          else if (index > -1) {
            Vue.set(this.allStages[index], 'title', '')
            Vue.set(this.allStages[index], 'title', response.data.stage.title.trim())
            let stage_style = document.getElementsByClassName('drag-column-' + response.data.stage.title)[0]
            stage_style.style.backgroundColor = response.data.stage.stage_color
            this.updateStageTasks(this.stage.id)
            this.stage = null
            this.sendLocals(false)
          }
        }
      },
      updateStageTasks(stageId) {
        let stage = this.allStages.find(s => s.id === stageId)
        this.blocks.filter(b => b.stage_id == stage.id).map((b) => {
          b.status = stage.title
        })
        this.sendLocals(false)
      },
      newStageTitle(e) {
        if (this.stage !== null && this.stage.title) {
          this.sendLocals(true)
          this.editStageTitle(e.target.value.trim())
        }
        else if (this.new_stage && e.target.value !== '') {
          this.sendLocals(true)
          this.createNewStage(e.target.value.trim())
        }
        else {
          return;
        }

      },
      changeStagePositions(title, old_pos, new_pos) {
        let stage = this.allStages.find(stg => stg.title === title)
        stage.position = new_pos
        const response = this.updateStageRequest(stage)
        response
        .then(result => {
          this.getColorNode('.drag-column')
        })
        .catch(err=>{
          console.log(err)
        })
      },
      deleteStageConfirm(stage){
        this.stage = stage
        this.colorSelected = false
        this.deleteStage()
      },
      // =====================STAGES CRUD OPERATIONS==============================//


      //=====================NODE CRUD OPERATIONS==============================//
      updateBlockRequest(obj){
        let data = {
          node: {
            id: obj.id,
            title: obj.title,
            position: obj.position,
            line_color: obj.line_color,
            stage_id: obj.stage_id
          }
        }
        this.updateKanbanUser()
        return http.patch(`/nodes/${obj.id}.json`,data)
      },

      async updateBlockPosition(id, status, position) {
        let _this = this
        let stage_id = this.allStages.find(stg => stg.title === status).id
        let block = this.blocks.find(blk => blk.id === Number(id))
        block.position = position
        block.stage_id = stage_id
        const response = await this.updateBlockRequest(block)
        if(response){
          let res = response
          this.sendLocals(true)
          let block_id = this.blocks.findIndex(b => b.id === Number(id))
          _this.blocks[block_id].index = res.data.node.position
          _this.blocks[block_id].status = status
          _this.updateBlockColors()
          this.getColorNode('.block-title')
        } else alert('block position didn\'t updated')
      },


      updateBlock(block,event){
        this.selected = ""
        let title = event.target.value
        block.title = title
        const response = this.updateBlockRequest(block)
        response
        .then((res)=>{
          this.sendLocals(true)
          let index = this.blocks.findIndex(b => b.id === res.data.node.id)
          Vue.set(this.blocks, index, res.data.node)
          this.getColorNode('.block-title')
        })
        .catch(err => {
          console.log(err)
        })
      },

      deleteBlock(block){
        let id = this.block.id
        let data = {node: {id}}
        this.updateKanbanUser()
        http
        .delete(`/nodes/${id}.json`,data)
        .then(response => {
          if (response.data.success === true){
            this.sendLocals(true)
            this.blocks = this.blocks.filter(blk => blk.id !== block.id)
            let receivedNodes = response.data.node
            if(receivedNodes && receivedNodes.length > 0){
              this.undoNodes.push({'req': 'deleteNode', 'node' : receivedNodes})
            }
            if (!this.undoDone || true) {
              let myNode = {
                id: block.id,
                title: block.title,
                line_color: block.line_color,
                mindmap_id: block.mindmap_id,
                parent_node: block.parent_node,
                stage_id: block.stage_id
              }
              this.undoNodes.push({'req': 'deleteNode', node: myNode})
            }
          }
          else {
            alert("Stage unable to be deleted")
          }
        })
        .catch(err => {
          console.log(err)
        })
      },
      //=====================NODE CRUD OPERATIONS==============================//

      //=====================OTHER FUNCTIONS ==============================//
      blurEvent(val, e){
        if (e.target) e.target.blur()
      },
      deleteBlockConfirm(block){
        this.block = block;
        this.deleteBlock(this.block)
      },
      selectedNode(index){
        this.selected = index
      },
      checkDuplicate(val){
        let is_val = false
        this.allStages.forEach((x) => {
          if(this.stage){
            if(x.title.toLowerCase() === val.toLowerCase() && x.title.toLowerCase() !== this.stage.title.toLowerCase()) is_val = true
          }
        })
        return is_val
      },
      //=====================OTHER FUNCTIONS ==============================//
      async undoObj(){
        this.undoDone = true
        let undoObj = await this.undoNode(this.undoNodes)
        if(undoObj){
          this.undoNodes.pop()
          let req  = undoObj.req
          let node = undoObj.node
          if(req === 'addStage' || req === 'deleteStage'){
            this.redoNodes.push({req, stage: node, nodes: undoObj.childNode})
          } else {
            this.redoNodes.push({req, node})
          }
        }
      },
      async redoObj(){
        let redoObj = await this.redoNode(this.redoNodes)
        if(redoObj){
          this.redoNodes.pop()
          if(redoObj.req === 'addStage' || redoObj.req === 'deleteStage'){
            this.undoNodes.push({req: redoObj.req, stage: redoObj.node, nodes: redoObj.childNode})
          } else {
            this.undoNodes.push({req: redoObj.req, node: redoObj.node})
          }
        }
      },
    }
  }
</script>
