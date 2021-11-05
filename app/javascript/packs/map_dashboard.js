
import Mindmap from 'components/dashboard.vue'
import router from 'routers/mindmaps'
import ActionCableVue from 'actioncable-vue'
import SyncLoader from 'vue-spinner/src/SyncLoader.vue'
import { SweetModal, SweetModalTab } from "sweet-modal-vue"
import { Chrome } from 'vue-color'

const base_url = window.location.origin.replace("https", "wss").replace("http", "ws")

Vue.use(ActionCableVue, {
  debug: true,
  debugLevel: 'error',
  connectionUrl: `${base_url}/cable`,
  connectImmediately: true
})
Vue.component('sync-loader', SyncLoader)
Vue.component('sweet-modal', SweetModal)
Vue.component('chrome-picker', Chrome)
Vue.component('sweet-modal-tab', SweetModalTab)

// eslint-disable-next-line no-unused-vars
window._MindmapApp_ = new Vue({
  router,
  el: '#map_dashboard',
  template: '<Mindmap />',
  components: { Mindmap }
})
