export default{
  methods:{
    async undoNode(undoNodes){
      await this.$store.dispatch("undoMindmapNodes", undoNodes)
      return this.$store.getters.getUndoNode
    },
    async redoNode(redoNodes){
      await this.$store.dispatch("redoMindmapNodes", redoNodes)
      return this.$store.getters.getRedoNode
    },
  }
}
