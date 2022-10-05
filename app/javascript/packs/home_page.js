import HomePage from 'components/home_page.vue'
import { SweetModal, SweetModalTab } from "sweet-modal-vue"
import VueCookies from 'vue-cookies';
import store from '../store/index.js'
import router from 'routers/mindmaps'
// eslint-disable-next-line no-unused-vars
Vue.use(VueCookies);
Vue.component('sweet-modal', SweetModal)
Vue.component('sweet-modal-tab', SweetModalTab)
const homePage = new Vue({
  router,
  el: '#home_page',
  store,
  template: '<HomePage />',
  components: { HomePage }
})
