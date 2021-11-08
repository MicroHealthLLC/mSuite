<template>
  <div>
  <sweet-modal ref="editBlockKanban" title="Edit Task" @open="openedModalBlock">
    <div>
      <b-row class="mb-2 align-items-center">
        <b-col cols="2"><span class="float-left align-self-center font-weight-bold">Title</span></b-col>
        <b-col cols="10">
          <input type="text" v-model="block_update.title" class="form-control" placeholder="Add a Title of Task" />
        </b-col>
      </b-row>
      <b-row class="align-items-center">
        <b-col cols="2"><span class="font-weight-bold">Description</span></b-col>
        <b-col cols="10">
          <textarea v-model="block_update.description" class="form-control"  placeholder="Add a Detailed Description"></textarea>
        </b-col>
      </b-row>
    </div>
    <button slot="button" @click="block_edit"class="btn btn-success mr-2" :disabled="EmptyTitle">Save</button>
    <button slot="button" @click="block_delete" class="btn btn-danger">Delete</button>
  </sweet-modal>
  </div>
</template>

<script>
  export default {
    name:"editBlock",
    props:['block'],
    data(){
      return{
        editable_title: false,
        editable_description: false,
        block_update:{}
      }
    },
    computed:{
      EmptyTitle(){
        return this.block_update.title < 1 ? true : false
      }
    },
    methods:{
      closeModal(){
        this.$refs.editBlockKanban.close()
      },
      block_delete() {
        this.$emit('block-delete',this.block)
        this.block_title=""
        this.$refs.editBlockKanban.close()
      },
      block_edit() {
        this.$emit('block-edit',this.block_update)
        this.$refs.editBlockKanban.close()
      },
      openedModalBlock(){
        this.block_update = JSON.parse(JSON.stringify(this.block))
      },
    }
  }
</script>
