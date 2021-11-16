<template>
  <div>
    <sweet-modal ref="deleteBlock" icon="warning" class="of_v" title="Delete Task">
        Do you want to delete this task?
      <button slot="button" @click="delete_task"class="btn btn-danger" >Delete</button>
      <button slot="button" @click="closeModal"class="btn btn-info ml-2" >Cancel</button>
    </sweet-modal>
  </div>
</template>

<script>
  export default {
    name:"DeleteBlockModal",
    methods:{
      closeModal(){
        this.$refs.deleteBlock.close()
      },
      delete_task(){
        this.$emit('delete_task')
        this.$refs.deleteBlock.close()
      }
    }
  }
</script>
