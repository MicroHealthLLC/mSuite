import Mindmap from 'components/mindmaps/mindmap.vue';
import router from 'routers/mindmaps'
import ActionCableVue from 'actioncable-vue';

const base_url = window.location.origin.replace("https", "wss").replace("http", "ws")

Vue.use(ActionCableVue, {
  debug: true,
  debugLevel: 'error',
  connectionUrl: `${base_url}/cable`,
  connectImmediately: true
});
// eslint-disable-next-line no-unused-vars
const mindmapApp = new Vue({
  router,
  el: '#mapDashboard',
  template: '<Mindmap />',
  components: { Mindmap }
});
