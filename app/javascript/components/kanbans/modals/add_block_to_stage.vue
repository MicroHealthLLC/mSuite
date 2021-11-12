<template>
  <div>
    <sweet-modal ref="addBlockToStage" id="add_block" class="of_v" title="Add Task">
    <div>
      <b-row class="mb-2 align-items-center">
        <b-col cols="2"><span class="float-left align-self-center font-weight-bold">Title</span></b-col>
        <b-col cols="10">
          <input type="text" v-model="title_block" class="form-control" placeholder="Add a Title of Task" />
        </b-col>
      </b-row>
      <b-row class="align-items-center">
        <b-col cols="2"><span class="font-weight-bold">Description</span></b-col>
        <b-col cols="10">
          <textarea v-model="description_block" class="form-control"  placeholder="Add a Detailed Description"></textarea>
        </b-col>
      </b-row>
    </div>
    <button slot="button" @click="block_added"class="btn btn-success" :disabled="title_block.length < 1">Save</button>
    </sweet-modal>
  </div>
</template>

<script>
  export default {
    name:"AddBlockToStage",
    data(){
      return{
        title_focus: false,
        description_focus: false,
        title_block: "",
        description_block:"",
        block:Object
      }
    },
    methods:{
      closeModal(){
        this.$refs.addBlockToStage.close()
      },
      block_added(){
        this.block = { title: this.title_block,description:this.description_block}
        this.$emit('block-added', this.block)
        this.title_block= ""
        this.description_block=""
        this.$refs.addBlockToStage.close()
      }
    }
  }
</script>
