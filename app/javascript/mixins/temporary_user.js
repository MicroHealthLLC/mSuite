export default {

  data(){
    return{
      mindmap_id: 0,
      msuite: this.$store.getters.getMsuite,
      storage: this.$store.state
    }
  },
  methods: {
    subscribeCable(mindmap_id){
      this.mindmap_id = mindmap_id
      this.$cable.subscribe({
        channel: "WebNotificationsChannel",
        room: mindmap_id,
      });
    },
    cableSend(editing){
      let state = this.$store.state
      let data = {
        user_id           : state.user_id,
        user              : state.user,
        userEdit          : state.userEdit,
        mindmap_id        : state.mindmap_id,
        userList          : state.userList,
        temporaryUser     : state.temporaryUser,
        nodeNumber        : state.nodeNumber,
        canvas            : state.canvas
      }
      this.$cable.perform({
        channel: 'WebNotificationsChannel',
        room: this.mindmap_id,

        data: {
          message: 'storage updated',
          isEditing: editing,
          content: data
        }
      });
    },
    sendLocals(isEditing){
      this.$store.dispatch('setUserEdit', this.storage.user)
      this.$store.dispatch('mindmapId', this.mindmap_id)
      this.cableSend(isEditing)

      setTimeout(()=>{
        this.saveElement = false
      },1200)
    },
    setUserOnMount(){
      this.$store.dispatch('setMindMapId', this.msuite.id)
      if (this.msuite.canvas != '{"version":"4.6.0","columns":[], "data":[], "style":{}, "width": []}' && this.msuite.canvas != ''){
        this.$store.dispatch('setUserList', null)
        this.$store.dispatch('setUserEdit', this.msuite.canvas)
        this.$store.dispatch('setUserList', this.msuite.canvas)
      }
    },
    setUserOnMountC(){
      this.$store.dispatch('setMindMapId', this.msuite.id)
      if (this.msuite.canvas && JSON.parse(this.msuite.canvas).user){
        this.$store.dispatch('setUserList', null)
        this.$store.dispatch('setUserEdit', JSON.parse(this.msuite.canvas).user)
        this.$store.dispatch('setUserList', JSON.parse(this.msuite.canvas).user)
      } else {
        this.$store.dispatch('setUserEdit', null)
        this.$store.dispatch('setTemporaryUser', null)
      }
    },
    getUserOnMount(){
      if(this.storage.mindmap_id == this.mindmap_id){
        if(this.storage.userEdit != null){
          this.$store.dispatch('setTemporaryUser', this.storage.userEdit)
          if (this.$store.getters.getmmType == 'spreadsheet' && this.storage.userList.length < 0){
            this.$store.dispatch('setUserList', null)
            this.$store.dispatch('setTemporaryUser', null)
          }
        } else {
          this.$store.dispatch('setUserList', null)
          this.$store.dispatch('setTemporaryUser', null)
        }
      }
    }
  }
}
