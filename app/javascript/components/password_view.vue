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
    props:['currentMindMap'],
    data() {
      return {
        password: ""
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
        http.get(`/mindmaps/${this.currentMindMap.unique_key}.json?password_check=${password}`).then((res)=>{
          if (res.data.is_verified) {
            window.open(`/mindmaps/${res.data.mindmap.unique_key}`, "_self")
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
        window.open(`/mindmaps/${this.currentMindMap.unique_key}`, "_self")
      }
    }
  }
</script>
