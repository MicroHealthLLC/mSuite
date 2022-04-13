<template>
  <div>
    <Recaptcha v-if="is_config && !fromCaptcha"></Recaptcha>
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
        fromCaptcha: false,
        is_config: true
      }
    },
    components: { CookieLaw, Recaptcha },
    mounted(){
      if(this.$cookies.get('verifiedCaptcha') == 'true') this.fromCaptcha = true
      if(Vue.prototype.$google_recaptcha_site_key == "") this.is_config = false
    },
  }
</script>
