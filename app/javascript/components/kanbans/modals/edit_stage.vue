<template>
  <div>
    <sweet-modal ref="editStageKanban" id="edit_stage" class="of_v">
      <div class="d-grid">
        <div>
          <i class="material-icons float-left mr-2">
            description
          </i>
          <h4 class="float-left">Title of Stage</h4>
        </div>
        <div>
          <input type="text" v-model="stage.title" class="form-control" placeholder="Title" />
        </div>
      </div>
    <div class="d-flex mt-2">
      <div @click="stage_edit" class="pointer edit_buttons">
        <span class="material-icons float-left delete_size mr-2 ">
          save
        </span>Save
      </div>
    </div>
    </sweet-modal>
  </div>
</template>

<script>
  export default {
    name:"editStage",
    props:['stage'],
    data(){
      return{

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
    }
  }
</script>
