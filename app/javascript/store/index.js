import HTTP from '../common/http.js';
import router from '../routers/mindmaps.js'
import VuexPersistence from 'vuex-persist'

const vuexLocal = new VuexPersistence({
  key: 'mSuite',
  storage: window.localStorage,
  reducer: state => ({
    user_id           : state.user_id,
    user              : state.user,
    userEdit          : state.userEdit,
    mindmap_id        : state.mSuite.id,
    userList          : state.userList,
    temporaryUser     : state.temporaryUser,
    nodeNumber        : state.nodeNumber
    // getRidOfThisModule: state.getRidOfThisModule (No one likes it.)
  })
})

const store = new Vuex.Store({
  state: {
    user_id        : null,
    user           : null,
    userEdit       : null,
    mSuite         : null,
    userList       : new Array(),
    scaleFactor    : 1,
    temporaryUser  : null,
    exportId       : null,
    nodeNumber     : 0
  },
  mutations:{
    setMSuite (state, payload){
      state.mSuite = payload
    },
    setScaleFactor (state, payload){
      state.scaleFactor = payload
    },
    setUserList (state, payload){
      state.userList.push(payload)
      state.userList = [... new Set(state.userList)]
    },
    setTemporaryUser (state, payload){
      state.temporaryUser = payload
    },
    setUserEdit (state, payload) {
      state.userEdit = payload
    },
    setUserId (state, payload) {
      state.user_id = payload
    },
    setUser (state, payload) {
      state.user = payload
    },
    setNodeNumber (state, payload) {
      state.nodeNumber = payload
    },
    setExportId(state , payload){
      state.exportId = payload
    }
  },
  getters: {
    getMsuite (state) {
      return state.mSuite
    },
    getUsers (state) {
      return state.userList
    },
    getTemporaryUser (state) {
      return state.temporaryUser
    },
    getExportId (state) {
      return state.exportId
    },
    getScaleFactor (state) {
      return state.scaleFactor
    },
    getUser (state) {
      return state.user
    },
    getUserId (state) {
      return state.user_id
    }
  },
  actions: {
    createMsuite({ commit }, strMtype){
      HTTP.post(`/msuite.json`, { mindmap: { name: 'Central Idea', mm_type: strMtype } })
      .then((res) => {
        commit('setMSuite', res.data.mindmap)
        window.open(`/msuite/${res.data.mindmap.unique_key}`, "_self")
        // router.push({ name: 'maproot', params: { key: res.data.mindmap.unique_key} })
      })
      .catch((e) => {
        alert(e)
      })
    },
    async getMSuite({ commit }){
      let mindmap_key = window.location.pathname.split('/')[2]
      let mm_type = ''
      await HTTP.get(`/msuite/${mindmap_key}.json`).then( res => {
        mm_type = res.data.mindmap.mm_type
        commit('setMSuite', res.data.mindmap)
      })
      return {'status': 200}
    },
    async updateMSuite({ commit, state }, obj){
      await HTTP.put(`/msuite/${state.mSuite.unique_key}`, obj).then(res =>{
        commit('setMSuite', res.data.mindmap)
      })
    },
    setScaleFactor({ commit }, scaleFactor){
      commit('setScaleFactor', scaleFactor)
    },
    setUserId({ commit }, userId){
      commit('setUserId', userId)
    },
    setUser({ commit }, user){
      commit('setUser', user)
    },
    setTemporaryUser({ commit }, user){
      commit('setTemporaryUser', user)
    },
    setUserList({ commit }, users){
      commit('setUserList', users)
    },
    setUserEdit({ commit }, user){
      commit('setUserEdit', user)
    },
    setNodeNumber({ commit }, number){
      commit('setNodeNumber', number)
    },
    setExportId({ commit }, exportID){
      commit('setExportId', exportID)
    }
  },
  plugins: [vuexLocal.plugin]
})

export default store
