<template>
  <nav class="navbar navbar-expand-lg navbar-light bg-light">
    <span class="mb-3 mt-1 ml-5">
      <a href="#" role="button" class="navbar-brand p-0">
        <img src="/assets/msuite.png" />
      </a>
    </span>
      <ul class="navbar-nav ml-auto">
        <li class="nav-item">
          <a class="nav-link" target="_blank" :href="about_url">About</a>
        </li>
        <li class="nav-item">
          <a class="nav-link" target="_blank" :href="public_url">Help</a>
        </li>
        <li class="nav-item">
          <a class="nav-link" target="_blank" :href="terms_url">Terms</a>
        </li>
        <li class="nav-item">
          <a class="nav-link" target="_blank" :href="privacy_url">Privacy</a>
        </li>
        <li class="nav-item" v-if="is_login">
          <a class="nav-link" href="/users/sign_out">Log out</a>
        </li>
      </ul>
  </nav>
</template>

<script>
  import http from '../../common/http'
  export default {
    name: 'home_navbar',

    data () {
      return {
        about_url: Vue.prototype.$about_url,
        public_url: Vue.prototype.$public_url,
        terms_url: Vue.prototype.$terms_url,
        privacy_url: Vue.prototype.$privacy_url,
        is_login: Vue.prototype.$user_login,
      }
    },
  }
</script>

<style lang="scss" scoped>
  @import "../styles/navigation_style.scss";
</style>
