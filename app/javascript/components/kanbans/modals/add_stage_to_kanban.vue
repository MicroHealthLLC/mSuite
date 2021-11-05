<template>
  <div>
    <sweet-modal ref="addStageToKanban" id="add_stage" class="of_v" title="Add Stage">
      <b-row class="align-items-center">
        <b-col cols="2"><span class="float-left align-self-center font-weight-bold">Title</span></b-col>
        <b-col cols="10">
          <input v-model="stageName" class="form-control" placeholder="Add a Title for Stage"/>
        </b-col>
      </b-row>
    <button slot="button" @click="stage_added"class="btn btn-success" :disabled="stageName.length < 1">Save</button>
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
