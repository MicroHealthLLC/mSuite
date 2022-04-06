<template>
  <div>
    <vue-recaptcha
      :class="verifiedCaptcha ? 'd-none' : 'content-center'"
      :sitekey="sitekey"
      @verify="verifyMethod"
      @error="errorMethod"
    >
    </vue-recaptcha>
    <cookie-law theme="dark-lime"></cookie-law>
  </div>
</template>
<script>
  import { VueRecaptcha } from 'vue-recaptcha';
  import CookieLaw from 'vue-cookie-law';
  export default {
    data() {
      return{
        sitekey: Vue.prototype.$google_recaptcha_site_key,
        verifiedCaptcha: false,
      }
    },
    components: { CookieLaw, VueRecaptcha },
    methods:{
      verifyMethod(){
        this.verifiedCaptcha = true
        // this.$refs['recaptcha'].close()
        this.$cookies.set('verifiedCaptcha',this.verifiedCaptcha)
        window.location.reload();
      },
      errorMethod(){
        alert("Verification Failed Please Try Again");
        this.verifiedCaptcha = false
      },
    },
    mounted() {
      // this.$refs['recaptcha'].open()
    },
  }
</script>
<style>
  .content-center {
    margin-left: 40%;
    margin-top: 10%;
  }
</style>
