import VuexPersistence from "vuex-persist";

const state = {
  user: '123',
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
const vuexLocalStorage = new VuexPersistence({
  key: 'msuite',
  storage: window.localStorage,
  reducer: state => ({
    user: state.user,
    colorHex: state.colorHex,
    mindmap: state.currentMindMap
    // getRidOfThisModule: state.getRidOfThisModule (No one likes it.)
  })
});

export default new Vuex.Store({
  state,
  getters,
  actions,
  mutations,
  plugins: [vuexLocalStorage.plugin]
})
