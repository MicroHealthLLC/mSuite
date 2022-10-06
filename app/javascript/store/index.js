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
    mindmap_id        : state.mindmap_id,
    userList          : state.userList,
    temporaryUser     : state.temporaryUser,
    nodeNumber        : state.nodeNumber,
    canvas            : state.canvas
    // getRidOfThisModule: state.getRidOfThisModule (No one likes it.)
  })
})

const store = new Vuex.Store({
  state: {
    user_id        : null,
    mindmap_id     : 0,
    user           : null,
    userEdit       : null,
    mSuite         : null,
    dataMSuite     : null,
    userList       : new Array(),
    scaleFactor    : 1,
    temporaryUser  : null,
    exportId       : null,
    nodeNumber     : 0,
    canvas         : '{"version":"4.6.0","objects":[]}',
    selectedNode   : null,
    copiedNode     : null
  },
  mutations:{
    setMSuite (state, payload){
      state.mSuite = payload
    },
    setCompleteMSuite(state, payload){
      state.dataMSuite = payload
    },
    setScaleFactor (state, payload){
      state.scaleFactor = payload
    },
    setUserList (state, payload){
      if (payload == null) state.userList = []
      else { state.userList.push(payload)
      state.userList = [... new Set(state.userList)] }
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
    },
    setMindMapId(state, payload){
      state.mindmap_id = payload
    },
    emptyUserList(state){
      state.userList = []
    },
    setCanvas(state, payload){
      state.canvas = payload
    },
    setSelectedNode(state, payload){
      state.selectedNode = payload
    },
    setCopiedNode(state, payload){
      state.copiedNode = payload
    },
    setCopiedNodeDisabled(state, payload){
      state.copiedNode.is_disabled = payload
    }
  },
  getters: {
    getMindmapId(state) {
      return state.mindmap_id
    },
    getMsuite (state) {
      return state.mSuite
    },
    getDataMsuite (state) {
      return state.dataMSuite
    },
    getmmType(state) {
      return state.mSuite.mm_type
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
    },
    getCanvas (state) {
      return state.canvas
    },
    getSelectedNode (state) {
      return state.selectedNode
    },
    getCopiedNode (state) {
      return state.copiedNode
    },
  },
  actions: {
    createMsuite({ commit }, strMtype){
      HTTP.post(`/msuite.json`, { mindmap: { name: 'Central Idea', mm_type: strMtype } })
      .then((res) => {
        commit('setMSuite', res.data.mindmap)
        // window.open(`/msuite/${res.data.mindmap.unique_key}`, "_self")
        router.push({ name: 'maproot', params: { key: res.data.mindmap.unique_key} })
        router.go()
      })
      .catch((e) => {
        alert(e)
      })
    },
    async getMSuite({ commit }){
      let mindmap_key = window.location.pathname.split('/')[2]
      await HTTP.get(`/msuite/${mindmap_key}.json`).then( res => {
        commit('setCompleteMSuite', res.data)
        commit('setMSuite', res.data.mindmap)
      })
      return {'status': 200}
    },
    async updateMSuite({ commit, state }, obj){
      await HTTP.put(`/msuite/${state.mSuite.unique_key}`, obj).then(res =>{
        commit('setMSuite', res.data.mindmap)
      })
    },
    async cloneMap({ commit, state }){
      await HTTP.get(`/msuite/${state.mSuite.unique_key}/clone_map`).then(res =>{
        commit('setMSuite', res.data.mindmap)
        router.push({ name: 'maproot', params: { key: res.data.mindmap.unique_key} })
        router.go()
      })
    },
    async resetMindmap ({ commit, state }) {
      if(state.mSuite.mm_type != 'kanban'){
        await HTTP.get(`/msuite/${state.mSuite.unique_key}/reset_mindmap.json`)
          .then((res) => {
            commit('setMSuite', res.data.mindmap)
          })
          .catch((err) => {
            console.log(err)
        })
      } else {
        await HTTP.post('/stages/reset_stages', { mindmap_id: state.mSuite.id })
      }
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
    },
    setCanvas({ commit }, Canvas){
      commit('setCanvas', Canvas)
    },
    setMindMapId({ commit }, mindmap_id){
      commit('setMindMapId', mindmap_id)
    },
    emptyUserList({ commit }){
      commit('emptyUserList')
    }
  },
  plugins: [vuexLocal.plugin]
})

export default store
