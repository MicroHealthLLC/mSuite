<template>
  <div v-if="!loading">
    <navigation-bar
      @mSuiteTitleUpdate="mSuiteTitleUpdate"
      @openPrivacy="openPrivacy"
      @deleteMindmap="deleteMap"
      @exportToImage="exportImage"
      @resetMindmap="resetMindmap"
      @undoMindmap="undoObj"
      @redoMindmap="redoObj"
      @sendLocals="sendLocals"
      :current-mind-map="currentMindMap"
      ref="kanbanNavigation"
      :defaultDeleteDays="defaultDeleteDays"
      :expDays="expDays"
      :deleteAfter="deleteAfter"
      :temporaryUser="temporaryUser"
      :isEditing="isEditing"
      :saveElement="saveElement"
      :userList="userList"
      :exportId="'kanban-board'">
    </navigation-bar>
    
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
                  <div class="pointer" @click="stage.length > 0 ? selectedStageBg(stage,$event) : '' ">
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
              <i class="fas fa-plus position-absolute mt-1 text-secondary"></i>
              <span class="task_plus ml-4"> Add a Task </span>
            </a>
          </div>
        </div>
        <div v-for="block,index in blocks" :slot="block.id" :key="block.id">
          <div class="d-inline-block w-100 block">
            <div class="pointer w-100 d-flex" @click="selectedNode(index)">
              <textarea-autosize @keydown.enter.prevent.native :rows="1" type="text" v-debounce:3000ms="blurEvent" v-model="block.title" @blur.native="updateBlock(block, $event, index)" class=" border-0 resize-text block-title" placeholder="Add Title to Task"/>
              <div class="pointer float-right">
                <div @click="deleteBlockConfirm(block)">
                  <i class="fas ml-2 fa-times text-danger position-relative icon-opacity ml-2" title="Delete Task"></i>
                </div>
                <div>
                  <i class="fas fa-arrows-alt position-relative ml-2 icon-opacity" title="Drag Task"></i>
                </div>
              </div>
            </div>
          </div>
        </div>
      </kanban-board>
      <div v-if="colorSelected">
        <div class="card p-0 border-none color-picker-placement">
          <color-palette
            :treeNode="selectedStage"
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

    <make-private-modal ref="make-private-modal" @password-apply="passwordProtect" @password_mismatched="$refs['passwordMismatched'].open()" :password="currentMindMap.password" :isSaveMSuite="isSaveMSuite"></make-private-modal>
    <delete-block-modal ref="delete-block-modal" @delete_task="deleteBlock(block)"></delete-block-modal>
    <sweet-modal ref="errorModal" class="of_v" icon="error" title="Password Error">
      Incorrect Password, Please Try Again!
    </sweet-modal>

    <sweet-modal ref="errorStageModal" class="of_v" icon="error" title="Stage Title Error">
      Stage Title Cannot Be Empty
    </sweet-modal>

    <sweet-modal ref="duplicateStageModal" class="of_v" icon="error" title="Stage Title Duplicate Error">
      Stage Title Cannot Be Duplicate
    </sweet-modal>

    <sweet-modal ref="passwordMismatched" class="of_v" icon="error" title="Password Mismatch">
      Your Password and Confirm Password are Mismatched, Please Try Again!
      <button slot="button" @click="passwordAgain" class="btn btn-warning mr-2">Try Again</button>
      <button slot="button" @click="$refs['passwordMismatched'].close()" class="btn btn-secondary">Cancel</button>
    </sweet-modal>
    <sweet-modal ref="successModal" class="of_v" icon="success">
      Password updated successfully!
    </sweet-modal>

    <delete-map-modal ref="delete-map-modal" @delete-mindmap="confirmDeleteMindmap"></delete-map-modal>
    <delete-password-modal ref="delete-password-modal" @deletePasswordCheck="deleteMindmapProtected"></delete-password-modal>
  </div>
</template>

<script>
  import http from "../../common/http"
  import vueKanban from 'vue-kanban'
  import MakePrivateModal from "../../common/modals/make_private_modal"
  import DeleteMapModal from '../../common/modals/delete_modal'
  import DeletePasswordModal from '../../common/modals/delete_password_modal'
  import Sortable from 'sortablejs';
  import ColorPalette from '../../common/modals/color_palette_modal'
  import Common from "../../mixins/common.js"
  import TemporaryUser from "../../mixins/temporary_user.js"


  var autoScroll = require('dom-autoscroller');
  Vue.use(vueKanban);

  export default {
    components:{
      MakePrivateModal,
      DeleteMapModal,
      DeletePasswordModal,
      ColorPalette
    },
    mixins: [Common, TemporaryUser],
    data() {
      return {
        loading: true,
        currentMindMap: {},
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
        selectedElement: null,
        hover_addtask: '',
        selected: '',
        isSaveMSuite: false,
        customPallete: [],
        nodeNumber: 0,
        undoNodes: [],
        redoNodes: [],
        undoDone: false,
        temporaryUser: '',
        saveElement: false,
        userList: [],
        config: {
          accepts(block, target, source){
            return target.dataset.status !== ''
          }
        }
      }
    },
    props: ['currentMindMap', 'defaultDeleteDays', 'expDays', 'deleteAfter'],
    channels: {
      WebNotificationsChannel: {
        received(data) {
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
          else if(data.message === "storage updated" && this.currentMindMap.id == data.content.mindmap_id)
          {
            localStorage.nodeNumber = data.content.nodeNumber
            localStorage.userNumber = data.content.userNumber
            this.temporaryUser = data.content.userEdit
            this.userList.push(data.content.userEdit)
            localStorage.userList = JSON.stringify(this.userList);
            this.isEditing = data.isEditing
            if (!this.isEditing) {
              this.saveElement = true
              setTimeout(()=>{
                this.saveElement = false
              },1200)
            }
          }
          else {
            this.getAllStages()
            this.getAllNodes()
            setTimeout(() => {
              this.updateBackgroundColors()
            }, 100)
          }
        }
      }
    },
    mounted() {
      this.subscribeCable(this.currentMindMap.id)
      if (this.$route.params.key) {
        this.getMindmap()
      }
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
            filter: ".drag-column-, .block-title",
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
        }, 1500)
      })
      if(localStorage.mindmap_id == this.currentMindMap.id){
        this.userList = JSON.parse(localStorage.userList)
        this.temporaryUser = localStorage.userEdit
      }
    },
    computed: {
      computedStages() {
        return this.allStages.map(stage => stage.title.length > 0 ? stage.title : '')
      },
      checkTempDelete() {
        return this.allStages.some(stage => stage.title === '')
      }
    },
    methods: {
      //=====================GETTING MINDMAP==============================//
      getMindmap(){
        this.getAllStages()
        this.getAllNodes()
      },
      //=====================GETTING MINDMAP==============================//

      //=====================MINDMAP DELETE ==============================//
      deleteMindmapProtected(password){
        http
        .delete(`/msuite/${this.currentMindMap.unique_key}.json?password_check=${password}`)
        .then(res=>{
          if(res.data.success) window.open("/", "_self")
          if (!res.data.success && this.currentMindMap.password)
            this.$refs['errorModal'].open()
        })
        .catch(error=>{
          console.log(error)
        })
      },
      deleteMindmap(){
        http
        .delete(`/msuite/${this.currentMindMap.unique_key}.json`)
        .then(res=>{
          window.open("/", "_self")
        })
        .catch(error=>{
          console.log(error)
        })
      },
      confirmDeleteMindmap(){
        if (this.currentMindMap.password){
          this.$refs['delete-password-modal'].$refs['DeletePasswordModal'].open()
        }
        else{
          this.deleteMindmap()
        }
      },
      passwordCheck(password){
        http.get(`/msuite/${this.currentMindMap.unique_key}.json?password_check=${password}`)
        .then(res=>{
          if (res.data.is_verified){
            this.deleteMindmap()
          }
          else{
            this.$refs['errorModal'].open()
          }
        })
      },
          //=====================MINDMAP DELETE ==============================//



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
        return http.patch(`/stages/${obj.id}.json`,data)
      },
      updateBackgroundColors(){
        let ArraybgColors = Array.from(document.getElementsByClassName('drag-column'))
        ArraybgColors.forEach((bg, index) => {
          bg.style.backgroundColor = this.allStages[index].stage_color
        })
      },
      updateColor(){
        this.selectedElement.style.backgroundColor = this.selectedStage.stage_color.hex
        this.getColorNode('.drag-column')
        this.getColorNode('.drag-column')
      },
      selectedStageBg(stage, e){
        if(this.selectedStage !== null && this.selectedElement !== null){
          let stage_index = this.allStages.findIndex(stg => stg.id === this.selectedStage.id)
          Vue.set(this.allStages[stage_index], 'stage_color', this.previousColor)
          this.selectedElement.style.backgroundColor = this.previousColor
        }
        this.selectedStage = this.allStages.find(stg => stg.title === stage)
        this.previousColor = this.selectedStage.stage_color
        this.selectedElement = document.getElementsByClassName('drag-column-' + stage)[0]
        this.colorSelected = true

        this.sendLocals(true)
      },
      saveNodeColor(){
        this.selectedStage.stage_color = this.selectedStage.stage_color.hex
        const response = this.updateStageRequest(this.selectedStage)
        response.then((res) => {
          let index = this.allStages.findIndex( stg => stg.id === this.selectedStage.id)
          Vue.set(this.allStages[index], 'stage_color', res.data.stage.stage_color)
        })
        .catch( err => {
          console.log(err)
        })
        this.selectedStage = null
        this.selectedElement = null
        this.colorSelected = false
        this.getColorNode('.drag-column')
      },
      saveTempColor(){
        let index = this.allStages.findIndex( stg => stg.title === this.selectedStage.title)
        this.allStages[index].stage_color = this.selectedStage.stage_color.hex
        this.selectedStage = null
        this.selectedElement = null
        this.colorSelected = false
        this.sendLocals(true)
      },
      closeModelPicker(){
        let stage_index = this.allStages.findIndex( stg => stg.id === this.selectedStage.id)
        Vue.set(this.allStages[stage_index], 'stage_color', this.previousColor)
        this.selectedElement.style.backgroundColor = this.previousColor
        this.selectedElement = null
        this.selectedStage = null

        Object.values(this.allStages).forEach((stage, index) => {
          let element = document.getElementsByClassName('drag-column')[index]
          element.style.backgroundColor = stage.stage_color
        });

        this.colorSelected = false
        this.getColorNode('.drag-column')
      },
      reset_stages() {
        let data = {
          mindmap_id: this.currentMindMap.id
        }
        http
        .post('/stages/reset_stages', data)
        .then((res) => {
          this.getAllStages()
          })
        .catch((err) => {
          console.log(err)
        })
      },
      getAllStages() {
        http
        .get(`/stages.json?mindmap_id=${this.currentMindMap.id}`)
        .then((res) => {
          this.allStages = res.data.stages
          if(this.allStages.length == 3 &&
              this.allStages[0].title == 'TO DO' &&
              this.allStages[1].title == 'IN PROGRESS' &&
              this.allStages[2].title == 'DONE'){
            localStorage.nodeNumber = 0
          }
          this.mapColors = []
          this.uniqueColors = []
          setTimeout(()=>{
            this.getColorNode('.drag-column')
          },1400)
          Object.values(this.allStages).forEach(stage => {
            this.mapColors.push(stage.stage_color);
          });
          this.uniqueColors = this.getUniqueColors(this.mapColors);
          this.new_stage = false
          })
        .catch((err) => {
          console.log(err)
        })

      },
      addNewStage(stage, stage_index){
        if (this.new_stage) {
          return;
        }
        this.allStages.splice(stage_index + 1, 0, {title: ''})
        this.new_stage = true
        this.new_index = stage_index + 1

        localStorage.mindmap_id = this.currentMindMap.id
        if(this.allStages.length > 2 && localStorage.nodeNumber != 'NaN'){
          localStorage.nodeNumber = parseInt(localStorage.nodeNumber) + 1
        } else {
          localStorage.nodeNumber = this.nodeNumber + 1
        }

        this.$cable.perform({
            channel: 'WebNotificationsChannel',
            room: this.currentMindMap.id,

            data: {
              message: 'storage updated',
              content: localStorage
            }
        });

        this.createNewStage('STAGE ' + localStorage.nodeNumber)
        setTimeout(()=>{
          this.getColorNode('.drag-column')
        },50)

        this.sendLocals(false)
      },
      deleteMap(){
        this.$refs['delete-map-modal'].$refs['deleteMapModal'].open()
      },
      createNewStage(val){
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
        http
        .post(`/stages.json`, data)
        .then((res) => {
          if(res.data.status == 500){
            val = val + '0'
            this.createNewStage(val)
          } else {
            this.allStages.splice(index, 1, res.data.stage)
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
          }
        }

        http
        .post(`/nodes.json`, data)
        .then((res) => {
          this.blocks.push(res.data.node)
          this.undoNodes.push({'req': 'addNode', receivedData: res.data.node})
          this.sendLocals(false)
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

      editStageTitle(val){
        this.sendLocals(true)
        val = val.replace(/\r?\n|\r/g, "")
        val.length < 1 ? this.$refs['errorStageModal'].open() : ''
        if (val.length > 0 && this.checkDuplicate(val)){
          this.$refs['duplicateStageModal'].open()
          let index = this.allStages.findIndex(stg => stg.id === this.stage.id)
          this.allStages[index].title = ''
          this.getAllStages()
          this.getAllNodes()
          this.sendLocals(false)
          return
        }

        this.stage.title =  val.length > 0 ? val : this.stage.title
        const response = this.updateStageRequest(this.stage)
        response
        .then(result => {
          let index = this.allStages.findIndex(stg => stg.id === result.data.stage.id)
          if (val.length < 1){
            this.allStages[index].title = ''
            this.getAllStages()
            this.getAllNodes()
            this.sendLocals(false)
          }
          else if (index > -1) {
            Vue.set(this.allStages[index], 'title', '')
            Vue.set(this.allStages[index], 'title', result.data.stage.title.trim())
            let stage_style = document.getElementsByClassName('drag-column-' + result.data.stage.title)[0]
            stage_style.style.backgroundColor = result.data.stage.stage_color
            this.updateStageTasks(this.stage.id)
            this.stage = null
            this.sendLocals(false)
          }
        })
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
            stage_id: obj.stage_id
          }
        }
        return http.patch(`/nodes/${obj.id}.json`,data)
      },
      getAllNodes(){
        http
        .get(`/nodes.json?mindmap_id=${this.currentMindMap.id}`)
        .then((res) => {
          this.blocks = res.data.nodes
          this.new_stage = false
          this.loading = false
        })
        .catch((err) => {
          console.log(err)
        })
      },

      updateBlockPosition(id, status, position) {
        let stage_id = this.allStages.find(stg => stg.title === status).id

        let block = this.blocks.find(blk => blk.id === Number(id))
        block.position = position
        block.stage_id = stage_id
        const response = this.updateBlockRequest(block)
        response
        .then((res)=>{
          let block_id = this.blocks.findIndex(b => b.id === Number(id))
          this.blocks[block_id].index = res.data.node.position
          this.blocks[block_id].status = status
        })
        .catch(err => {
          console.log(err)
        })
      },


      updateBlock(block,event){
        this.selected = ""
        let title = event.target.value
        block.title = title
        const response = this.updateBlockRequest(block)
        response
        .then((res)=>{
          let index = this.blocks.findIndex(b => b.id === res.data.node.id)
          Vue.set(this.blocks, index, res.data.node)
          this.sendLocals(false)
        })
        .catch(err => {
          console.log(err)
        })
      },

      deleteBlock(block){
        let id = this.block.id
        let data = {node: {id}}
        http
        .delete(`/nodes/${id}.json`,data)
        .then(response => {
          if (response.data.success === true){
            this.blocks = this.blocks.filter(blk => blk.id !== block.id)
            let receivedNodes = response.data.node
            if(receivedNodes && receivedNodes.length > 0){
              this.undoNodes.push({'req': 'deleteNode', node: receivedNodes})
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

      //=====================PASSWORD PROTECT==============================//
      openPrivacy(val) {
        this.isSaveMSuite = val
        this.$refs['make-private-modal'].$refs['makePrivateModal'].open()
      },
      passwordAgain(){
        this.$refs['passwordMismatched'].close()
        this.openPrivacy()
      },
      passwordProtect(new_password, old_password, is_mSuite){
        http
        .patch(`/msuite/${this.currentMindMap.unique_key}.json`,{mindmap: {password: new_password, old_password: old_password}})
        .then(res => {
          if (res.data.mindmap) {
            this.currentMindMap.password = res.data.mindmap.password
            if(!is_mSuite) window.open("/", "_self")
            else location.reload()
            this.$refs['successModal'].open()
          }
          else {
            if (res.data.error) this.$refs['errorModal'].open()
          }
        })
      },
      //=====================PASSWORD PROTECT==============================//
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
      resetMindmap() {
        http
          .get(`/msuite/${this.currentMindMap.unique_key}/reset_mindmap.json`)
          .then((res) => {
            this.currentMindMap.nodes = []
            this.allStages = []
            this.undoNodes = []
            this.redoNodes = []
            localStorage.nodeNumber = 0
            this.reset_stages()
            this.getMindmap()
          })
          .catch((err) => {
            console.log(err)
          })
      },
      undoObj(){
        this.undoDone = true
        http
          .post(`/msuite/${this.currentMindMap.unique_key}/undo_mindmap.json`, { undoNode: this.undoNodes })
          .then((res) => {
            this.undoNodes.pop()
            let req = res.data.node.req
            let node = null
            node = res.data.node.node
            if(req === 'addStage' || req === 'deleteStage'){
              this.redoNodes.push({req, stage: node, nodes: res.data.node.childNode})
            } else {
              this.redoNodes.push({req, node})
            }
          })
          .catch((err) => {
            console.log(err)
          })
      },
      redoObj(){
        this.redoDone = true
        http
          .put(`/msuite/${this.currentMindMap.unique_key}/redo_mindmap.json`, { redoNode: this.redoNodes })
          .then((res) => {
            this.redoNodes.pop()
            let req = res.data.node.req
            let receivedData =null
            receivedData = res.data.node.node
            if(req === 'addStage' || req === 'deleteStage'){
              this.undoNodes.push({req, stage: receivedData, nodes: res.data.node.childNode})
            } else {
              this.undoNodes.push({req, node: receivedData})
            }
          })
          .catch((err) => {
            console.log(err)
          })
      },
    }
  }
</script>

<style>
  @import "./styles/kanban_new.scss";
</style>
