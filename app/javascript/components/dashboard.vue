<template>
  <div>
    <Recaptcha v-if="is_config && !fromCaptcha"></Recaptcha>
    <router-view v-else></router-view>
    <Beta v-if="beta_status" />
    <cookie-law theme="dark-lime"></cookie-law>
  </div>
</template>
<script>
  import Recaptcha from './recaptcha';
  import CookieLaw from 'vue-cookie-law'
  import Beta from './beta';
  export default {
    data(){
      return{
        fromCaptcha: true,
        is_config: true,
        beta_status: Vue.prototype.$beta_status
      }
    },
    components: { CookieLaw, Recaptcha, Beta },
    mounted(){
      if(this.$cookies.get('verifiedCaptcha') == null) this.fromCaptcha = false
      if(Vue.prototype.$google_recaptcha_site_key == "") this.is_config = false
      if(this.beta_status === 'true') {
        this.beta_status = true
      } else {
        this.beta_status = false
      }
    },
  }
</script>
