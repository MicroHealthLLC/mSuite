<template>
  <div>
  <sweet-modal ref="editBlockKanban">
    <sweet-modal-tab title="Edit" id="edit">
      <h2 class="center_flex">EDIT BLOCK TITLE</h2>
      <div class="form-outline">
        <input type="text" id="edit_title_block" v-model="block_title" class="form-control form-icon-trailing" />
        <label class="form-label" for="form1">Title of Block</label>
      </div>
      <div class="center_flex mt_2">
        <a
          href="javascript:;"
          class="btn_2 bg-success text-white mr_1"
          @click.stop="block_edit"
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
    </sweet-modal-tab>
    <sweet-modal-tab title="Delete" id="delete">
      <h2 class="center_flex">Do you want to delete this block</h2>
      <div class="center_flex mt_2">
        <a
          href="javascript:;"
          class="btn_2 bg-success text-white mr_1"
          @click.stop="block_delete"
        >
          <i class="material-icons mr-1">delete</i>
          YES
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
    </sweet-modal-tab>
  </sweet-modal>
  </div>
</template>

<script>
  export default {
    name:"editBlock",
    props:['block'],
    data(){
      return{
        block_title: this.block.title
      }
    },
    methods:{
      closeModal(){
        this.$refs.editBlockKanban.close()
      },
      block_edit(){
        this.$emit('block-edit',this.block_title)
        this.block_title=""
        this.$refs.editBlockKanban.close()
      },
      block_delete() {
        this.$emit('block-delete',this.block)
        this.block_title=""
        this.$refs.editBlockKanban.close()
      }
    }
  }
</script>
