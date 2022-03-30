<template>
  <div>
    <Recaptcha v-if="!fromCaptcha"></Recaptcha>
    <router-view v-if="fromCaptcha"></router-view>
    <cookie-law theme="dark-lime"></cookie-law>

  </div>
</template>
<script>
  import Recaptcha from './recaptcha';
  import CookieLaw from 'vue-cookie-law'
  export default {
    data(){
      return{
        fromCaptcha: false
      }
    },
    components: { CookieLaw, Recaptcha },
    mounted(){
      this.fromCaptcha = this.$cookies.get('verifiedCaptcha')
    },
  }
</script>
