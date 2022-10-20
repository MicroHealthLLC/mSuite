<template>
  <sweet-modal ref="passwordModal" class="of_v" blocking="true" hide-close-button="true">
    <div class="sweet_model_icon_div">
      <div class="radius_circle bg-warning center_flex mlr_a text-white">
        <i class="material-icons">security</i>
      </div>
    </div>
    <h4 class="float-left">PASSWORD</h4>
    <div>
      <input type="password" v-model="password" class="form-control" placeholder="Insert Password to Access Mindmap" autocomplete="new-password"/>
    </div>
    <button slot="button" @click="goHome" class="btn btn-info mr-2"> Back To Home </button>
    <button slot="button" @click="private_password" class="btn btn-success"> Verify </button>
  </sweet-modal>
</template>
<script>

  export default {
    name:"PasswordModal",
    data(){
      return{
        password:""
      }
    },
    methods:{
      private_password(){
        this.$emit("passwordCheck", this.password)
        this.password = ""
        this.$refs['passwordModal'].close();
      },
      goHome(){
        window.open("/", "_self")
      }
    }
  }
</script>
