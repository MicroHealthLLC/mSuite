<template>
  <div v-if="!loading">
    <nav class="navbar navbar-light navbar-background d-block">
      <a class="navbar-brand" href="#" @click="goHome">
        <img src="/assets/microhealthllc.png"/>
      </a>
      <button role="button" class="btn btn-info" @click.prevent="openPrivacy">
          <i class="fas fa-shield-alt"></i>
          Make Private
      </button>
      <div class="float-right pt-2 pr-2">
        <button :disabled="checkTempDelete" role="button" class="btn btn-success" @click.prevent="addStageToMindmap">
          <i class="fas fa-plus"></i>
          Add Stage
        </button>
        <button role="button" class="btn btn-danger" @click.prevent="$refs['delete-map-modal'].$refs['deleteMapModal'].open">
          <i class="fas fa-trash"></i>
          Delete Map
        </button>
      </div>
    </nav>

    <div class="row kanban_board" id="kanban-board">
      <kanban-board :stages="computedStages" :blocks="blocks" :config="config" @update-block="updateBlockPosition">
        <div v-for="stage,index in computedStages" :slot="stage" class="w-100">
          <div class="w-100">
            <div class="d-inline-block w-100 block">
              <div class="text-dark pointer w-100 d-flex" @click="updateStage(stage)" >
                <textarea-autosize :id="index" :rows="1" type="text" v-debounce:1000ms="blurEvent" :value="stage" class=" border-0 resize-text stage-title " placeholder="Enter Stage Title to Save"/>
                <div class="pointer float-right" @click="checkDeleteStatus(stage)">
                  <i class="fas fa-times text-danger position-absolute mt-1" title="Delete Task"></i>
                </div>
              </div>
            </div>
          </div>
          <div v-if="stage!=='' " @mouseover="hover_addtask = index" @mouseleave="hover_addtask = '' " :class="hover_addtask === index ? 'hover_task rounded' : ''" @click.prevent="addBlock(stage)" class="pointer d-inline-block w-100">
            <button class="bg-transparent border-0 pe-none"><i class="material-icons task_plus position-absolute">add</i><span class="task_plus ml-4">Add a Task</span></button>
          </div>
        </div>
        <div v-for="block,index in blocks" :slot="block.id" :key="block.id">
            <div class="d-inline-block w-100 block">
              <div class="text-dark pointer w-100 d-flex" @click="selectedNode(index)" >
                <textarea-autosize :rows="1" type="text" v-debounce:1000ms="blurEvent" v-model="block.title" @blur.native="updateBlock(block,$event,index)" class=" border-0 resize-text"/>
                <div class="pointer float-right" @click="deleteBlockConfirm(block)">
                  <i class="fas fa-times text-danger position-absolute icon-delete" title="Delete Task"></i>
                </div>
              </div>
            </div>
        </div>
      </kanban-board>
    </div>
    <add-block-to-stage ref="add-block-to-stage" @block-added="addBlockToStage"></add-block-to-stage>

    <edit-stage v-if="stage.title" @stage-edit="editStageTitle" ref="edit-stage" :stage="stage"></edit-stage>

    <make-private-modal ref="make-private-modal" @password-apply="passwordProtect" @password_mismatched="$refs['passwordMismatched'].open()" :password="currentMindMap.password"></make-private-modal>
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

    <sweet-modal ref="deleteStageConfirm" class="of_v" icon="warning" title="Delete Stage">
      Do you want to delete this stage?
      <button slot="button" @click="deleteStage(stage)" class="btn btn-warning mr-2">Delete</button>
      <button slot="button" @click="$refs['deleteStageConfirm'].close()" class="btn btn-secondary">Cancel</button>
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

    <delete-password-modal ref="delete-password-modal" @deletePasswordCheck="passwordCheck">
    </delete-password-modal>
  </div>
</template>

<script>
  import http from "../../common/http"
  import vueKanban from 'vue-kanban'
  import AddBlockToStage from './modals/add_block_to_stage'
  import editStage from './modals/edit_stage'
  import MakePrivateModal from "../../common/modals/make_private_modal"
  import DeleteBlockModal from './modals/delete_block_modal'
  import DeleteMapModal from '../../common/modals/delete_modal'
  import DeletePasswordModal from '../../common/modals/delete_password_modal'
  import vueDebounce from 'vue-debounce'
  import VueTextareaAutosize from 'vue-textarea-autosize'

  Vue.use(VueTextareaAutosize)

  var autoScroll = require('dom-autoscroller');
  Vue.use(vueKanban);
  Vue.use(vueDebounce,{
    listenTo: 'keyup',
  })

  export default {
    props: ['currentMindMap'],
    components:{
      AddBlockToStage,
      editStage,
      MakePrivateModal,
      DeleteBlockModal,
      DeleteMapModal,
      DeletePasswordModal
    },
    data() {
      return {
        loading: true,
        allStages:[],
        blocks: [],
        stage_id:"",
        stage:{},
        block: {},
        hover_addtask:'',
        selected:'',
        new_stage: '',
        config:{
          accepts(block,target,source){
            return target.dataset.status !== ''
          }
        }
      }
    },
    mounted() {
      this.getAllStages()
      this.getAllNodes()
      setTimeout(()=>{
        var elements = Array.from(document.querySelectorAll(".drag-inner-list,#kanban-board"));
        autoScroll(
          elements,
          {
            margin: 20,
            maxSpeed: 7,
            scrollWhenOutside: true,
            autoScroll: function(){
                //Only scroll when the pointer is down, and there is a child being dragged.
               return this.down
            }
          }
        );
      },1000)
    },
    computed: {
      computedStages() {
        return this.allStages.map(stage => stage.title.length>0 ? stage.title : '')
      },
      checkTempDelete() {
        return this.allStages.some(stage=>stage.title==='')
      }
    },
    methods: {
      getAllStages() {
        http
        .get(`/stages.json?mindmap_id=${this.currentMindMap.id}`)
        .then((res) => {
          this.allStages = res.data.stages
          })
        .catch((err) => {
          console.log(err)
        })
      },
      getAllNodes(){
        http
        .get(`/nodes.json?mindmap_id=${this.currentMindMap.id}`)
        .then((res) => {
          this.blocks = res.data.nodes
          this.loading = false
        })
        .catch((err) => {
          console.log(err)
        })
      },

      addStageToMindmap() {
        let stage = {title:''}
        this.allStages.push(stage)
        this.new_stage = this.allStages.length - 1
      },
      createNewStage(val){
        if (val.length < 1){
          this.$refs['errorStageModal'].open()
          this.getAllStages()
          return
        }
        else if(this.checkDuplicate(val))
        {
          this.$refs['duplicateStageModal'].open()
          this.getAllStages()
          return
        }
        let data = {
          stage: {
            title: val,
            mindmap_id: this.currentMindMap.id
          }
        }
        http
        .post(`/stages.json`, data)
        .then((res) => {
          this.allStages.pop()
          this.allStages.push(res.data.stage)
          this.new_stage = ''
        })
        .catch((error) => {
        })
      },
      addBlockToStage(block) {
        let data = {
          node: {
            title: block.title,
            stage_id: this.allStages.find(stage => stage.title === this.stage_title).id,
            mindmap_id: this.currentMindMap.id,
            status: this.stage_title,
            description: block.description
          }
        }

        http
        .post(`/nodes.json`, data)
        .then((res) => {
          this.blocks.push(res.data.node)
        })
        .catch((err) => {
          console.log(err)
        })
      },

      updateBlockPosition(id, status, position) {
        let stage_id = this.allStages.find(stg => stg.title === status).id
        let block = {
          node: {
            stage_id: stage_id,
            position: position
          }
        }

        http
        .patch(`/nodes/${id}.json`,block)
        .then((res)=>{
          let block_id = this.blocks.findIndex(b => b.id === Number(id))
          this.blocks[block_id].index = res.data.node.position
          this.blocks[block_id].status = status
        })
        .catch(err => {
          console.log(err)
        })
      },

      addStage(){
        if (this.currentMindMap.editable) {
          this.$refs['add-stage-to-kanban'].$refs['addStageToKanban'].open()
        }
      },

      addBlock(stage){
        if (this.currentMindMap.editable) {
          this.stage_title = stage
          this.$refs['add-block-to-stage'].$refs['addBlockToStage'].open()
        }
      },
      checkDeleteStatus(stage){
        stage !=='' ? this.deleteStageConfirm(stage) : this.deleteTempStage()
      },
      deleteStage(){
        this.$refs['deleteStageConfirm'].close()
        let id = this.allStages.find(stg => stg.title === this.stage.title).id
        let data={
          stage: {
            id: id
          }
        }
        http
        .delete(`/stages/${id}.json`,data)
        .then(response =>
        {
          if (response.data.success === true){
            this.allStages = this.allStages.filter(stg => stg.title !== this.stage.title)
            this.blocks = this.blocks.filter(block => block.status !== this.stage.title)
          }
          else {
            alert("Stage unable to be deleted")
          }
        })
        .catch(error => {console.log(error)})
      },
      deleteTempStage(){
        this.getAllStages()
        this.new_stage = ''
      },
      updateStage(stage){
        if (this.currentMindMap.editable) {
            this.stage = this.allStages.find(stg=>stg.title===stage)
        }
      },

      editStageTitle(val){
        val.length < 1 ? this.$refs['errorStageModal'].open() : ''
        if (this.checkDuplicate(val)){
          this.$refs['duplicateStageModal'].open()
          return
        }
        let data = {
          stage: {
            title: val.length > 0 ? val : this.stage.title
          }
        };
        http
        .patch(`/stages/${this.stage.id}.json`, data)
        .then(result => {
          let index = this.allStages.findIndex(stg => stg.id === result.data.stage.id)
          if (val.length<1){
            this.allStages[index].title = ''
            this.getAllStages()
            this.getAllNodes()
          }
          else if (index > -1) {
            Vue.set(this.allStages, index, result.data.stage)
          }
          this.updateStageTasks(this.stage.id)
        })
      },

      updateBlock(block,event){
        this.selected=""
        let title = event.target.value.length < 1 ? '0' : event.target.value
        let id = block.id
        let node = {node: {id,title: title,description: block.description}}
        http
        .patch(`/nodes/${id}.json`,node)
        .then((res)=>{
          let index = this.blocks.findIndex(b => b.id === res.data.node.id)
          Vue.set(this.blocks,index,res.data.node)
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
          }
          else {
            alert("Stage unable to be deleted")
          }
        })
        .catch(err => {
          console.log(err)
        })
      },
      goHome(){
        window.open('/',"_self")
      },
      updateStageTasks(stageId) {
        let stage = this.allStages.find(s => s.id === stageId)
        this.blocks.filter(b => b.stage_id == stage.id).map((b) => {
          b.status = stage.title
        })
      },
      openPrivacy() {
        this.$refs['make-private-modal'].$refs['makePrivateModal'].open()
      },
      passwordAgain(){
        this.$refs['passwordMismatched'].close()
        this.openPrivacy()
      },
      passwordProtect(new_password, old_password){
        http
        .patch(`/mindmaps/${this.currentMindMap.unique_key}.json`,{mindmap:{password: new_password, old_password: old_password}})
        .then(res=>{
          if (res.data.mindmap) {
            this.currentMindMap.password = res.data.mindmap.password
            this.$refs['successModal'].open()
          }
          else {
            this.$refs['errorModal'].open()
          }
        })
      },
      blurEvent(val,e){
        e.target.blur()
        this.new_stage === '' ? this.editStageTitle(val) : this.createNewStage(val)
      },
      deleteBlockConfirm(block){
        this.block = block;
        this.$refs['delete-block-modal'].$refs['deleteBlock'].open()
      },
      selectedNode(index){
        this.selected = index
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
        http.get(`/mindmaps/${this.currentMindMap.unique_key}.json?password_check=${password}`)
        .then(res=>{
          if (res.data.is_verified){
            this.deleteMindmap()
          }
          else{
            this.$refs['errorModal'].open()
          }
        })
      },
      deleteMindmap(){
        http
        .delete(`/mindmaps/${this.currentMindMap.unique_key}`)
        .then(res=>{
          window.open('/','_self')
        })
        .catch(error=>{
          console.log(error)
        })
      },
      deleteStageConfirm(stage){
        this.stage = stage
        this.$refs['deleteStageConfirm'].open()
      },
      checkDuplicate(val){
        let is_val = false
        this.allStages.forEach((x) => {
          if(x.title === val && x.title!==this.stage.title) is_val = true
        })
        return is_val
      }
    }
  }
</script>

<style>
  @import "./styles/kanban_new.scss";
</style>
