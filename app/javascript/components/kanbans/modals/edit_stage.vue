<template>
  <div>
    <sweet-modal ref="editStageKanban" @open="openedModal" id="edit_stage" class="of_v" title="Edit Stage" @close="closedModal">
      <b-row class="align-items-center">
        <b-col cols="2"><span class="float-left align-self-center font-weight-bold">Title</span></b-col>
        <b-col cols="10">
          <input v-model="update_stage.title" class="form-control" placeholder="Add a Title for Stage"/>
        </b-col>
      </b-row>
      <button @click.prevent="stage_edit"  slot="button" class="btn btn-success" :disabled="EmptyTitle">
        Save
      </button>
    </sweet-modal>
  </div>
</template>

<script>
  export default {
    name:"editStage",
    props:['stage'],
    data(){
      return{
        update_stage: Object
      }
    },
    computed:{
      EmptyTitle(){
        return this.update_stage.title < 1 ? true : false
      }
    },
    methods:{
      stage_edit(){
        this.$emit('stage-edit',this.update_stage)
        this.$refs.editStageKanban.close()
      },
      openedModal(){
        this.update_stage = JSON.parse(JSON.stringify(this.stage))
      },
      closedModal(){
        this.update_stage = {}
      },
    },
  }
</script>
