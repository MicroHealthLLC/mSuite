<template>
  <div>
    <sweet-modal ref="errorModal" class="of_v" icon="error" title="Password Error" blocking="true" hide-close-button="true">
      Incorrect Password, Please Enter correct password!

      <button slot="button" class="btn btn-info" @click="back_to_home"> Back To Home </button>
      <button slot="button" class="btn btn-warning ml-2" @click="try_again"> Try again! </button>
    </sweet-modal>
  </div>
</template>

<script>
  export default {
    name:"ErrorModal",
    methods:{
      try_again() {
        this.$emit("openMindmap")
        this.$refs['errorModal'].close();
      },
      back_to_home() {
        window.open('/', "_self")
        this.$refs['errorModal'].close();
      }
    }
  }
</script>
