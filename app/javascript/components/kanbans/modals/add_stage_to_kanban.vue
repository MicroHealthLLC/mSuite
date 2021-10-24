<template>
  <div>
    <sweet-modal ref="addStageToKanban" id="add_stage" class="of_v">
      <div class="form-outline">
        <input type="text" id="title_stage" v-model="stageName" class="form-control form-icon-trailing" />
        <label class="form-label" for="form1">Title of Stage</label>
      </div>
      <div class="center_flex mt_2">
        <a
          href="javascript:;"
          class="btn_2 bg-success text-white mr_1"
          @click.stop="stage_added"
        >
          <i class="material-icons mr-1">save</i>
          Save
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
    name:"AddStageToKandban",
    data(){
      return{
        stageName: ""
      }
    },
    methods:{
      closeModal(){
        this.$refs.addStageToKanban.close()
      },
      stage_added(){
        this.$emit('stage-added',this.stageName)
        this.stageName=""
        this.$refs.addStageToKanban.close()
      }
    }
  }
</script>
