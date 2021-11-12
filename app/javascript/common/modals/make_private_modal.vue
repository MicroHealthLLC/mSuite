<template>
  <sweet-modal ref="makePrivateModal" class="of_v">
    <div class="sweet_model_icon_div">
      <div class="radius_circle bg-warning center_flex mlr_a text-white">
        <i class="material-icons">security</i>
      </div>
    </div>

    <h4 class="float-left">PASSWORD PROTECT</h4>

    <div v-if="password">
      <input type="password" v-model="old_password" class="form-control" placeholder="Insert Old password"/>
      <br/>
    </div>

    <div>
      <input type="password" v-model="new_password" class="form-control" placeholder="Insert new password"/>
    </div>

    <button slot="button" @click="private_password" class="btn btn-success"> Save </button>
  </sweet-modal>
</template>
<script>

  export default{
    name:"makePrivateModal",
    props:['password'],
    data(){
      return{
        old_password: "",
        new_password: ""
      }
    },
    methods:{
      private_password(){
        this.$emit("password-apply", this.new_password, this.old_password)
        this.new_password = ""
        this.old_password = ""
        this.$refs['makePrivateModal'].close();
      }
    }
  }
</script>
