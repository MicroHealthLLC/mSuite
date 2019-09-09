import NewMindMap from '../components/mindmaps/mindmap_new'
import Demo from '../components/mindmaps/demo'

export default new VueRouter({
  routes: [
    {
      path: '/new',
      component: NewMindMap
    },
    {
      path: '/demo',
      component: Demo
    }
  ],
  hashbang: false,
  mode: 'history',
  base: '/mindmaps',
  scrollBehavior () {
    return { x: 0, y: 0 }
  }
});
