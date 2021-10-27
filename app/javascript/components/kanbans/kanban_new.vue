<template>
  <div v-if="!loading">
    <nav class="navbar navbar-light navbar-background">
      <a class="navbar-brand" href="#" @click="goHome">
        <img src="/assets/microhealthllc.png"/>
      </a>
      <div class="float-right pt-2 pr-2">
        <button role="button" class="btn btn-success" @click.prevent="addStage">
          <i class="fas fa-plus"></i>
          Add Stage
        </button>
      </div>
    </nav>

    <div class="row kanban_board">
      <kanban-board :stages="computedStages" :blocks="blocks" @update-block="updateBlockPosition">
        <div v-for="stage in computedStages" :slot="stage" class="w-100">
          <div>
            <div class="w-100">
              <div>
                <h2 class="float-left col-10">{{ stage }}</h2>
              </div>
              <div class="float-right">
                <b-dropdown  id="dropdown-left" toggle-class="col-6 bg-transparent border-0" no-caret>
                  <template #button-content>
                    <i class="fas fa-ellipsis-h text-secondary"></i>
                  </template>
                  <b-dropdown-item @click="editStage(stage)">Edit</b-dropdown-item>
                  <b-dropdown-item @click="deleteStage(stage)">Delete</b-dropdown-item>
                </b-dropdown>
              </div>
            </div>
          </div>
        </div>
        <div v-for="block in blocks" :slot="block.id" :key="block.id">
          <div class="d-inline-block w-100 ">
            <div class="text-dark pointer" @click="editBlockKanban(block)">
              {{ block.title }}
            </div>
          </div>
        </div>
        <div v-for="stage,index in computedStages" :slot="`footer-${stage}`">
          <div @mouseover.self="hover_addtask = index" @mouseleave.self="hover_addtask = false" :class="hover_addtask === index ? 'hover_task' : ''" @click.prevent="addBlock(stage)" class="pointer add-block">
            <button class="bg-transparent border-0 pe-none"><i class="material-icons task_plus position-absolute">add</i><span class="task_plus ml-4">Add a Task</span></button>
          </div>
        </div>
      </kanban-board>
    </div>
    <add-stage-to-kanban ref="add-stage-to-kanban" @stage-added="addStageToMindmap"></add-stage-to-kanban>
    <add-block-to-stage ref="add-block-to-stage" @block-added="addBlockToStage"></add-block-to-stage>
    <edit-stage ref="edit-stage" @stage-edit="editStageTitle" :stage="stage"></edit-stage>
    <edit-block ref="edit-block" @block-edit="updateBlock" @block-delete="deleteBlock" :block="block"></edit-block>
  </div>
</template>

<script>
  import http from "../../common/http"
  import vueKanban from 'vue-kanban'
  import AddStageToKanban from './modals/add_stage_to_kanban'
  import AddBlockToStage from './modals/add_block_to_stage'
  import editStage from './modals/edit_stage'
  import editBlock from './modals/edit_block'
  Vue.use(vueKanban)
  export default {
    props: ['currentMindMap'],
    components:{
      AddStageToKanban,
      AddBlockToStage,
      editStage,
      editBlock
    },
    data() {
      return {
        loading: true,
        allStages:[],
        blocks: [],
        stage_id:"",
        stage:{},
        block: {},
        hover_addtask:false
      }
    },
    mounted() {
      this.getAllStages()
      this.getAllNodes()
    },
    computed: {
      computedStages() {
        return this.allStages.map(stage => stage.title)
      },
    },
    watch:{
      "currentMindMap.id"() {
        if (this.currentMindMap.id) {
          this.$cable.subscribe({ channel: 'WebNotificationsChannel', room: this.currentMindMap.id})
        }
      }
    },
    methods: {
      getAllStages() {
        http
        .get(`/stages.json?mindmap_id=${this.currentMindMap.id}`)
        .then((res) => {
          this.allStages = res.data.stages
            //this.stages = res.data.stages.map(stage => stage.title)
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
      addStageToMindmap(stage_name) {
        let data = { stage: { title: stage_name, mindmap_id: this.currentMindMap.id } }
        http
        .post(`/stages.json`, data)
        .then((res) => {
          this.allStages.push(res.data.stage)
        })
        .catch((error) => {
          console.log(error)
        })
      },
      addBlockToStage(block) {
        let data = { node: { title: block.title, stage_id: this.allStages.find(stage => stage.title === this.stage_title).id, mindmap_id: this.currentMindMap.id, status: this.stage_title,description:block.description} }
        http
        .post(`/nodes.json`, data)
        .then((res) => {
          this.blocks.push({id: res.data.node.id, status: res.data.node.status, title: res.data.node.title} )
        })
        .catch((err) => {
          console.log(err)
        })
      },
      updateBlockPosition(id, status) {
        let stage_id = this.allStages.find(stg=>stg.title === status).id
        let block = {node: {id,status,stage_id}}
        http
        .patch(`/nodes/${id}.json`,block)
        .then((res)=>{
          this.blocks.find(b => b.id === res.data.node.id).status = res.data.node.status;
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
      deleteStage(stage){
        let id = this.allStages.find(stg => stg.title === stage).id
        let data={ stage: { id }}
        http.delete(`/stages/${id}.json`,data)
        .then(response =>
        {
          if (response.data.success === true){
            this.allStages = this.allStages.filter(stg => stg.title !== stage)
            this.blocks = this.blocks.filter(block => block.status !== stage)
            console.log(this.allStages)
          }
          else {
            alert("Stage unable to be deleted")
          }
        })
        .catch(error => {console.log(error)})
      },
      editStage(stage){
        if (this.currentMindMap.editable) {
          this.stage=this.allStages.find(st=>st.title===stage)
          this.$refs['edit-stage'].$refs['editStageKanban'].open()
        }
      },
      editStageTitle(stage){
        let data = {stage: {title:stage.title,id:stage.id}}
        http.patch(`/stages/${stage.id}.json`,data)
        .then(result => {
          this.allStages.find(stg => stg.id === result.data.stage.id).title = result.data.stage.title;
        })
        http
        .patch(`/nodes/update_status.json?mindmap_id=${this.currentMindMap.id}&stage_id=${stage.id}&status=${stage.title}`)
        .then(response=>{
          this.blocks = response.data.nodes
        })
      },
      editBlockKanban(block){
        if (this.currentMindMap.editable) {
          this.block=block
          this.$refs['edit-block'].$refs['editBlockKanban'].open()
        }
      },
      updateBlock(block){
        let id = block.id
        let node = {node: {id,title: block.title,description: block.description}}
        http
        .patch(`/nodes/${id}.json`,node)
        .then((res)=>{
          this.blocks.find(b => b.id === res.data.node.id).title = res.data.node.title;
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
            console.log(this.blocks)
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
      }
    }
  }
</script>

<style>
  @import "./styles/kanban_new.scss";
</style>
