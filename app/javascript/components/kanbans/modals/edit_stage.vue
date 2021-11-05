<template>
  <div>
    <sweet-modal ref="editStageKanban" id="edit_stage" class="of_v" title="Edit Stage">
      <b-row class="align-items-center">
        <b-col cols="2"><span class="float-left align-self-center font-weight-bold">Title</span></b-col>
        <b-col cols="10">
          <input v-model="stage.title" class="form-control" placeholder="Add a Title for Stage"/>
        </b-col>
      </b-row>
      <button @click="stage_edit"  slot="button" class="btn btn-success" :disabled="EmptyTitle">
        Save
      </button>
    </sweet-modal>
  </div>
</template>

<script>
  export default {
    name:"editStage",
    props:['stage'],
    computed:{
      EmptyTitle(){
        return this.stage.title < 1 ? true : false
      }
    },
    methods:{
      closeModal(){
        this.$refs.editStageKanban.close()
      },
      stage_edit(){
        this.$emit('stage-edit',this.stage)
        this.$refs.editStageKanban.close()
      },
    },
  }
</script>
