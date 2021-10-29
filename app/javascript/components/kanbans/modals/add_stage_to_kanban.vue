<template>
  <div>
    <sweet-modal ref="addStageToKanban" id="add_stage" class="of_v">
      <div class="d-grid">
        <div>
          <i class="material-icons float-left mr-2">
            description
          </i>
          <h4 class="float-left">Title of Stage</h4>
        </div>
        <div>
          <input v-model="stageName" class="form-control" placeholder="Title"/>
        </div>
      </div>
    <div class="d-flex mt-2">
      <div @click="stage_added" class="pointer edit_buttons">
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
