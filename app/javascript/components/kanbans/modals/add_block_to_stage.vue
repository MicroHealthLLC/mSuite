<template>
  <div>
    <sweet-modal ref="addBlockToStage" id="add_block" class="of_v">
      <div class="d-grid">
        <div>
          <i class="material-icons float-left mr-2">
            description
          </i>
          <h4 class="float-left">Title</h4>
        </div>
        <div>
          <input type="text" v-model="title_block" class="form-control" placeholder="Title" />
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
        <textarea v-model="description_block" class="form-control"  placeholder="Place Some Value Here"></textarea>
      </div>
    </div>
    <div class="d-flex mt-2">
      <div @click="block_added" class="pointer edit_buttons">
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
