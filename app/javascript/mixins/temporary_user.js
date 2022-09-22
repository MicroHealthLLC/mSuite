export default {
  data(){
    return{
      mindmap_id: 0,
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
          content: localStorage
        }
      });
    },
    sendLocals(isEditing){
      localStorage.userEdit = localStorage.user
      localStorage.mindmap_id = this.mindmap_id
      this.cableSend(isEditing)

      setTimeout(()=>{
        this.saveElement = false
      },1200)
    },
    getUserOnMount(){
      if(localStorage.mindmap_id == this.mindmap_id){
        if(localStorage.userEdit != 'null'){
          if(localStorage.userList) this.userList = JSON.parse(localStorage.userList)
          else this.userList.push(localStorage.userEdit)
          this.temporaryUser = localStorage.userEdit
        }
      }
    }
  }
}
