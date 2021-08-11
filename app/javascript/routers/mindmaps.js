
import NewMindMap from '../components/mindmaps/mindmap_new'

export default new VueRouter({
  routes: [
    {
      path: '/:key',
      component: NewMindMap
    }
  ],
  hashbang: false,
  mode: 'history',
  base: '/mindmaps',
  scrollBehavior () {
    return { x: 0, y: 0 }
  }
})
