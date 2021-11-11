<template>
  <sweet-modal ref="homePasswordModal" class="of_v">
    <div class="sweet_model_icon_div">
      <div class="radius_circle bg-warning center_flex mlr_a text-white">
        <i class="material-icons">security</i>
      </div>
    </div>
    <div class="d-grid">
        <div>
          <h4 class="float-left">PASSWORD</h4>
        </div>
        <div>
          <input type="password" v-model="password" class="form-control" placeholder="Insert Password to Access Mindmap" autocomplete="new-password"/>
        </div>
      </div>
    <div class="d-flex mt-2">
      <button @click="private_password" class="btn btn-success">
        Save
      </button>
    </div>
  </sweet-modal>
</template>
<script>

  export default{
    name:"HomePasswordModal",
    data(){
      return{
        password:""
      }
    },
    methods:{
      private_password(){
        this.$emit("passwordCheck",this.password)
        this.password=""
        this.$refs['homePasswordModal'].close();
      }
    }
  }
</script>
