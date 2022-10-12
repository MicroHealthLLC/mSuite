<template>
  <div>
    <password-modal ref="password-modal" @passwordCheck="passwordCheck"></password-modal>
    <error-modal ref="error-modal" @openMindmap="openMindmap"></error-modal>
  </div>
</template>

<script>
  import http from "./../common/http"
  import PasswordModal from '../common/modals/password_modal'
  import ErrorModal from '../common/modals/error_modal'
  export default {
    data() {
      return {
        password: "",
        currentMindMap: this.$store.getters.getMsuite
      }
    },
    mounted() {
      this.$refs['password-modal'].$refs['passwordModal'].open()
    },
    components:{
      PasswordModal,
      ErrorModal
    },
    methods: {
      passwordCheck(password) {
        http.get(`/msuite/${this.currentMindMap.unique_key}.json?password_check=${password}`).then((res)=>{
          if (res.data.is_verified) {
            window.open(`/msuite/${res.data.mindmap.unique_key}`, "_self")
          }
          else {
            this.$refs['error-modal'].$refs['errorModal'].open()
          }

        }).catch(error=>{
          this.$refs['error-modal'].$refs['errorModal'].open()
          console.log(error)
        })
      },
      openMindmap() {
        window.open(`/msuite/${this.currentMindMap.unique_key}`, "_self")
      }
    }
  }
</script>
