
const state = {
  colorHex: ''
}
const actions = {
  addColor: ({ commit }, hex) => commit('setColor', hex),
}
const getters = {
  getColorCode: state => state.colorHex
}
const mutations = {
  setColor (state, payload) {
    state.colorHex = payload.hex
  }
}
export default new Vuex.Store({
  state,
  getters,
  actions,
  mutations
})
