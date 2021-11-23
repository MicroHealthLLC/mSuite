<template>
  <sweet-modal ref="DeletePasswordModal" class="of_v">
    <div class="sweet_model_icon_div">
      <div class="radius_circle bg-warning center_flex mlr_a text-white">
        <i class="material-icons">security</i>
      </div>
    </div>
    <h4 class="float-left">PASSWORD</h4>
    <div>
      <input type="password" v-model="password" class="form-control" placeholder="Insert Password to Delete Map" autocomplete="new-password"/>
    </div>
    <button slot="button" @click="private_password" class="btn btn-success"> Verify </button>
  </sweet-modal>
</template>
<script>
  export default {
    name:"DeletePasswordModal",
    data(){
      return{
        password:""
      }
    },
    methods:{
      private_password(){
        this.$emit("deletePasswordCheck", this.password)
        this.password = ""
        this.$refs['DeletePasswordModal'].close();
      }
    }
  }
</script>
