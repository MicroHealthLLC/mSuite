import VuexPersistence from 'vuex-persist'
import HTTP from '../common/http.js';
import router from '../routers/mindmaps.js'

const store = new Vuex.Store({
  state: {
    mSuite: null,
  },
  mutations:{
    SET_MSUITE(state, payload){
      state.mSuite = payload
    }
  },
  getters: {
  },
  actions: {
    createMsuite({ commit }, strMtype){
      HTTP.post(`/msuite.json`, { mindmap: { name: 'Central Idea', mm_type: strMtype } })
      .then((res) => {
        commit('SET_MSUITE', res.data.mindmap)
        window.open(`/msuite/${res.data.mindmap.unique_key}`, "_self")
        // router.push({ name: 'maproot', params: { key: res.data.mindmap.unique_key} })
      })
      .catch((e) => {
        alert(e)
      })
    }
  },
  plugins: [new VuexPersistence().plugin]
})

export default store
