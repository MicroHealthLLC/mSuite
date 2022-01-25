<template>
  <div>
    <router-view></router-view>
    <cookie-law theme="dark-lime"></cookie-law>

  </div>
</template>
<script>
  import CookieLaw from 'vue-cookie-law'
  export default {
      components: { CookieLaw }
    }
</script>
