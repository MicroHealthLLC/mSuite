export default {

  data(){
    return{
      mindmap_id: 0,
      storage: null
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
      this.$cable.perform({
        channel: 'WebNotificationsChannel',
        room: this.mindmap_id,

        data: {
          message: 'storage updated',
          isEditing: editing,
          content: this.storage
        }
      });
    },
    sendLocals(isEditing){
      let state = this.$store.state
      this.storage = {   
        user_id           : state.user_id,
        user              : state.user,
        userEdit          : state.userEdit,
        mindmap_id        : state.mindmap_id,
        userList          : state.userList,
        temporaryUser     : state.temporaryUser,
        nodeNumber        : state.nodeNumber,
        canvas            : state.canvas
      }
      this.$store.dispatch('setUserEdit', this.storage.user)
      this.$store.dispatch('mindmapId', this.mindmap_id)
      this.cableSend(isEditing)

      setTimeout(()=>{
        this.saveElement = false
      },1200)
    },
    getUserOnMount(){
      if(this.storage.mindmap_id == this.mindmap_id){
        if(this.storage.userEdit != null){
          if(this.storage.userList) this.userList = this.storage.userList
          else this.$store.dispatch('setUserList', this.storage.userEdit)
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
