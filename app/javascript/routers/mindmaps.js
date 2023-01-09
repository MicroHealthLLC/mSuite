
import MindmapsWrapper from '../components/mindmaps_wrapper'
import HomePage from '../components/home_page'

export default new VueRouter({
  routes: [
    {
      name: 'home_page',
      path: '/',
      component: HomePage
    },
    {
      name: 'maproot',
      path: '/:key',
      component: MindmapsWrapper
    }
  ],
  hashbang: false,
  mode: 'history',
  base: '/msuite',
  scrollBehavior () {
    return { x: 0, y: 0 }
  }
})
