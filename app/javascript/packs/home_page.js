import HomePage from 'components/home_page.vue'
import { SweetModal, SweetModalTab } from "sweet-modal-vue"
// eslint-disable-next-line no-unused-vars
Vue.component('sweet-modal', SweetModal)
Vue.component('sweet-modal-tab', SweetModalTab)
const homePage = new Vue({
  el: '#home_page',
  template: '<HomePage />',
  components: { HomePage }
})
