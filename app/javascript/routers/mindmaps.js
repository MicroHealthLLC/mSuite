
import MindmapsWrapper from '../components/mindmaps_wrapper'

export default new VueRouter({
  routes: [
    {
      name: 'maproot',
      path: '/:key',
      component: MindmapsWrapper
    }
  ],
  hashbang: false,
  mode: 'history',
  base: '/mindmaps',
  scrollBehavior () {
    return { x: 0, y: 0 }
  }
})
