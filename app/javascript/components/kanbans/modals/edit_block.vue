<template>
  <div>
  <sweet-modal ref="editBlockKanban">
    <div class="d-grid">
      <div>
        <i class="material-icons float-left mr-2">
          description
        </i>
        <h4 class="float-left">Title</h4>
      </div>
      <div>
        <input v-model="block.title" class="form-control" placeholder="Title" />
      </div>
      <div class="d-flex mt-2">
        <div>
          <i class="material-icons float-left mr-2">
            toc
          </i>
          <h4 class="float-left">Description</h4>
        </div>
      </div>
      <div>
        <textarea v-model="block.description" class="form-control " placeholder="Description"></textarea>
      </div>
    </div>
    <div class="d-flex mt-2">
      <div @click="block_delete" class="edit_buttons pointer mr-2">
        <i class="material-icons float-left delete_size mr-2">
          delete
        </i>Delete Task
      </div>
      <div @click="block_edit" class="pointer edit_buttons">
        <span class="material-icons float-left delete_size mr-2 ">
          save
        </span>Save Task
      </div>
    </div>
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
        editable_description: false
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
        this.$emit('block-edit',this.block)
        this.$refs.editBlockKanban.close()
      },
    }
  }
</script>
