<template>
  <div>
    <sweet-modal ref="editStageKanban" id="edit_stage" class="of_v">
      <h2 class="center_flex">EDIT STAGE TITLE</h2>
      <div class="form-outline">
        <input type="text" id="edit_title_stage" v-model="stage_title" class="form-control form-icon-trailing" />
        <label class="form-label" for="form1">Title of Stage</label>
      </div>
      <div class="center_flex mt_2">
        <a
          href="javascript:;"
          class="btn_2 bg-success text-white mr_1"
          @click.stop="stage_edit"
        >
          <i class="material-icons mr-1">save</i>
          Update
        </a>
        <a
          href="javascript:;"
          class="btn_2 bg-primary text-white mr_1"
          @click.stop="closeModal"
        >
          <i class="material-icons mr-1">cancel</i>
          Cancel
        </a>
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
        stage_title: ""
      }
    },
    mounted()
    {
      this.stage_title=this.stage
    },
    methods:{
      closeModal(){
        this.$refs.editStageKanban.close()
      },
      stage_edit(){
        this.$emit('stage-edit',this.stage_title)
        this.stage_title=""
        this.$refs.editStageKanban.close()
      }
    }
  }
</script>
