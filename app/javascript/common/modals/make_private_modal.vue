<template>
  <div>
    <sweet-modal ref="makePrivateModal" class="of_v">
      <div class="sweet_model_icon_div">
        <div class="radius_circle bg-warning center_flex mlr_a text-white">
          <i class="material-icons">security</i>
        </div>
      </div>

      <h4 class="float-left">PASSWORD PROTECT</h4>

      <div v-if="password">
        <input type="password" v-model="old_password" class="form-control" placeholder="Insert old password"  />
        <br/>
      </div>

      <div>
        <input type="password" v-model="new_password" class="form-control" placeholder="Insert new password" />
        <br/>
      </div>

      <div>
        <input type="password" v-model="confirm_password" class="form-control" placeholder="Confirm password"/>
      </div>
      <button slot="button" @click="private_password" :disabled="showSaveBTN" class="btn btn-success"> Save </button>
    </sweet-modal>

    <sweet-modal ref="blankPassword" class="of_v" icon="error" title="Blank Password">
      Blank/Empty spaces not allowed in password!
    </sweet-modal>
  </div>
</template>

<script>

  export default{
    name: "makePrivateModal",
    data(){
      return{
        password: JSON.parse(JSON.stringify(this.$store.getters.getMsuite.password)),
        old_password: "",
        new_password: "",
        confirm_password: "",
      }
    },
    methods:{
      private_password() {
        if(this.password && this.new_password == "" && this.confirm_password == "" ){
            this.new_password = this.password;
            this.confirm_password = this.password;
        }
        if (this.new_password.includes(' '))  {
          this.new_password = ""
          this.old_password = ""
          this.confirm_password = ""
          this.$refs['makePrivateModal'].close();
          this.$refs['blankPassword'].open();
        }
        else if (this.new_password.trim() && this.new_password === this.confirm_password){
          this.$emit("password-apply", this.new_password, this.old_password)
          this.new_password = ""
          this.old_password = ""
          this.confirm_password = ""
          this.$refs['makePrivateModal'].close();
        }
        else if(this.new_password !== this.confirm_password){
          this.$emit("password_mismatched")
          this.new_password = ""
          this.old_password = ""
          this.confirm_password = ""
          this.$refs['makePrivateModal'].close();
        }
      }
    },
    computed:{
      showSaveBTN(){
        if(!this.password){
          if(this.old_password.length < 1 && this.password != null || this.new_password.length < 8 || this.confirm_password.length < 8)return true
        }
        if(this.password){
          if(this.old_password.length < 1 || this.new_password.length < 8 || this.new_password != this.confirm_password) return true
        }
      }
    }
  }
</script>
