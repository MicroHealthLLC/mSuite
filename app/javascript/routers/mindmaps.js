import NewMindMap from '../components/mindmaps/mindmap_new'

export default new VueRouter({
  routes: [
    {
      path     : '/new',
      component: NewMindMap
    }
  ],
  hashbang: false,
  mode    : 'history',
  base    : '/mindmaps',
  scrollBehavior () {
    return { x: 0, y: 0 }
  }
})
