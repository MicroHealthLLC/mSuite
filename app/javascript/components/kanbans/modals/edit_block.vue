<template>
  <div>
  <sweet-modal ref="editBlockKanban">
    <div class="d-inline-block">
      <div class="float-left">
        <div class="d-inline-block">
          <div>
            <i class="material-icons float-left mr-2">
              description
            </i>
            <h4 class="float-left">Title</h4>
          </div>
          <div>
            <textarea v-model="block.title" class="textarea_title"   @focus="editable_title = true" @blur="blurTitle" :class="[editable_title ? 'editable' : 'non-editable']"></textarea>
          </div>
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
          <textarea v-model="block.description" class="form-control textarea_description" @focus="editable_description = true" @blur="blurDescription" :class="[(editable_description ? 'editable' : 'non-editable'),(block.description === '' ? 'bg-light' : 'bg-white')]" placeholder="Place Some Value Here"></textarea>
        </div>
      </div>
    </div>
    <div class="float-right bg-light">
      <div @click="block_delete" class="pointer">
        <i class="material-icons float-left delete_size">
          delete
        </i>Delete Task
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
      blurTitle() {
        this.editable_title = false
        this.$emit('block-edit',this.block)
      },
      blurDescription() {
        this.editable_description = false
        this.$emit('block-edit',this.block)
      }
    }
  }
</script>
