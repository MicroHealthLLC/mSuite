import ElementUI from 'element-ui';
import 'element-ui/lib/theme-chalk/index.css';
import Mindmap from 'components/dashboard.vue'
import NavigationBar from "common/navigation_bar";
import router from 'routers/mindmaps'
import ActionCableVue from 'actioncable-vue'
import SyncLoader from 'vue-spinner/src/SyncLoader.vue'
import { SweetModal, SweetModalTab } from "sweet-modal-vue"
import { Chrome, Sketch } from 'vue-color'
import Vuex from 'vuex'
import VueTree from '@ssthouse/vue-tree-chart'
import store from '../store/index.js'
import vueDebounce from 'vue-debounce'
import VueTextareaAutosize from 'vue-textarea-autosize'
import VueCookies from 'vue-cookies';
import moment from 'moment';
import Hightcharts from "highcharts";
import vennInit from "highcharts/modules/venn";
import exportingInit from 'highcharts/modules/exporting'
import draggablePointsInit from 'highcharts/modules/draggable-points'
import customEventsInit from 'highcharts-custom-events'
import HighchartsVue from "highcharts-vue";

const base_url = window.location.origin.replace("https", "wss").replace("http", "ws")

// const base_url = document.querySelector('meta[name="action-cable-url"]').content


Vue.use(ActionCableVue, {
  debug: true,
  debugLevel: 'error',
  connectionUrl: `${base_url}/cable`,
  connectImmediately: true
})

Vue.directive('focus', {
  inserted(el) {
    el.focus()
  }
})

Vue.use(HighchartsVue)
vennInit(Hightcharts)
exportingInit(Hightcharts)
draggablePointsInit(Hightcharts)
customEventsInit(Hightcharts)
Vue.use(Vuex);
Vue.use(ElementUI);
Vue.use(VueTextareaAutosize)
Vue.use(VueCookies);
Vue.use(router)
Vue.use(moment)
Vue.component('vue-tree', VueTree)
Vue.component('navigation-bar', NavigationBar)
Vue.component('sync-loader', SyncLoader)
Vue.component('sweet-modal', SweetModal)
Vue.component('chrome-picker', Chrome)
Vue.component('sketch-picker', Sketch)
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
