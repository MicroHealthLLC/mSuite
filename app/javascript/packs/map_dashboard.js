
import Mindmap from 'components/dashboard.vue'
import NavigationBar from "common/navigation_bar";
import router from 'routers/mindmaps'
import ActionCableVue from 'actioncable-vue'
import SyncLoader from 'vue-spinner/src/SyncLoader.vue'
import { SweetModal, SweetModalTab } from "sweet-modal-vue"
import { Chrome } from 'vue-color'
import Vuex from 'vuex'
import VueTree from '@ssthouse/vue-tree-chart'
import store from '../store/TreeMap'
import vueDebounce from 'vue-debounce'
import VueTextareaAutosize from 'vue-textarea-autosize'
import VueCookies from 'vue-cookies';

const base_url = window.location.origin.replace("https", "wss").replace("http", "ws")

Vue.use(ActionCableVue, {
  debug: true,
  debugLevel: 'error',
  connectionUrl: `${base_url}/cable`,
  connectImmediately: true
})
Vue.use(Vuex);
Vue.use(VueTextareaAutosize)
Vue.use(VueCookies);
Vue.component('vue-tree', VueTree)
Vue.component('navigation-bar', NavigationBar)
Vue.component('sync-loader', SyncLoader)
Vue.component('sweet-modal', SweetModal)
Vue.component('chrome-picker', Chrome)
Vue.component('sweet-modal-tab', SweetModalTab)
Vue.use(vueDebounce,{
  listenTo: 'keyup',
})

// eslint-disable-next-line no-unused-vars
window._MindmapApp_ = new Vue({
  router,
  el: '#map_dashboard',
  store,
  template: '<Mindmap />',
  components: { Mindmap }
})
