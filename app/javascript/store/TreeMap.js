
const state = {
  colorHex: '#69996D',
  currentMindMap: {},
}
const actions = {
  addColor: ({ commit }, hex) => commit('setColor', hex),
  addCurrentMindMap: ({ commit }, currentMindMap) => commit('setMindMap', currentMindMap)
}
const getters = {
  getColorCode: state => state.colorHex,
  getCurrentMindMap: state => state.currentMindMap
}
const mutations = {
  setColor (state, payload) {
    state.colorHex = payload.hex
  },
  setMindMap(state, payload) {
    state.currentMindMap = payload
  }
}
export default new Vuex.Store({
  state,
  getters,
  actions,
  mutations
})
