export default {

  data(){
    return{
      mindmap_id: 0,
      storage: JSON.parse(localStorage.mSuite)
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
      let unique_userList = [... new Set(JSON.parse(localStorage.mSuite).userList)]
      let storage_data = {
        user_id       : this.storage.user_id,
        user          : this.storage.user,
        userEdit      : this.storage.userEdit,
        temporaryUser : this.storage.temporaryUser,
        userList      : unique_userList,
        mindmap_id    : this.storage.mindmap_id
      }

      this.$cable.perform({
        channel: 'WebNotificationsChannel',
        room: this.mindmap_id,

        data: {
          message: 'storage updated',
          isEditing: editing,
          content: storage_data
        }
      });
    },
    sendLocals(isEditing){
      this.$store.dispatch('setUserEdit', JSON.parse(localStorage.mSuite).user)
      this.$store.dispatch('mindmapId', this.mindmap_id)
      this.cableSend(isEditing)

      setTimeout(()=>{
        this.saveElement = false
      },1200)
    },
    getUserOnMount(){
      if(this.storage.mindmap_id == this.mindmap_id){
        if(this.storage.userEdit != 'null'){
          if(this.storage.userList) this.userList = this.storage.userList
          else this.$store.dispatch('setUserList', this.storage.userEdit)
          this.$store.dispatch('setTemporaryUser', this.storage.userEdit)
        }
      }
    }
  }
}
