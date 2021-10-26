<template>
  <div>
    <sweet-modal ref="addBlockToStage" id="add_block" class="of_v">
      <div class="form-outline">
        <input type="text" id="title_block" v-model="blockName" class="form-control form-icon-trailing" />
        <label class="form-label">Title of Block</label>
      </div>
      <div class="center_flex mt_2">
        <a
          href="javascript:;"
          class="btn_2 bg-success text-white mr_1"
          @click.stop="block_added"
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
    name:"AddBlockToStage",
    data(){
      return{
        blockName: "",
      }
    },
    methods:{
      closeModal(){
        this.$refs.addBlockToStage.close()
      },
      block_added(){
        let block = { title: this.blockName }
        this.$emit('block-added', block)
        this.blockName = ""
        this.$refs.addBlockToStage.close()
      }
    }
  }
</script>
