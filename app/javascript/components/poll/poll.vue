<template>
  <div class="poll-app">
    <navigation-bar
      ref="navigationBar"
      @mSuiteTitleUpdate="mSuiteTitleUpdate"
      @openPrivacy="openPrivacy"
      @deleteMindmap="deleteMap"
      @resetMindmap="resetMindmap"
      @exportToDocument="exportToDocument"
      @pollEditData="pollEditData"
      :current-mind-map="currentMindMap"
      :defaultDeleteDays="defaultDeleteDays"
      :expDays="expDays"
      :deleteAfter="deleteAfter"
      :pollPin="pollData"
      :pollEdit="pollEdit"
      :exportId="'poll'">
    </navigation-bar>

    <vote-in-poll
      v-if="pollData && pollData.showResult && !pollEdit"
      :pollData="pollData">
    </vote-in-poll>

    <poll-view
      class="mt-5"
      v-else-if="!pollEdit && dataLoaded && pollData && pollData.pin"
      :pollData="pollData"
      @updateVote="updateVote"></poll-view>

    <create-poll
      v-else
      :pollData = "pollData"
      @updateVote="updateVote">
    </create-poll>


    <make-private-modal ref="make-private-modal" @password-apply="passwordProtect" @password_mismatched="$refs['passwordMismatched'].open()" :password="currentMindMap.password" :isSaveMSuite="isSaveMSuite"></make-private-modal>
    <delete-map-modal ref="delete-map-modal" @delete-mindmap="confirmDeleteMindmap"></delete-map-modal>
    <delete-password-modal ref="delete-password-modal" @deletePasswordCheck="deleteMindmapProtected"></delete-password-modal>
    <confirm-save-key-modal ref="confirm-save-key-modal" :current-mind-map="currentMindMap"></confirm-save-key-modal>
    <sweet-modal ref="passwordMismatched" class="of_v" icon="error" title="Password Mismatch">
      Your Password and Confirm Password are Mismatched, Please Try Again!
      <button slot="button" @click="passwordAgain" class="btn btn-warning mr-2">Try Again</button>
      <button slot="button" @click="$refs['passwordMismatched'].close()" class="btn btn-secondary">Cancel</button>
    </sweet-modal>
    <sweet-modal ref="errorModal" class="of_v" icon="error" title="Password Error">
      Incorrect Password, Please Try Again!
    </sweet-modal>
    <sweet-modal ref="errorReset" class="of_v" icon="error" title="Password Error">
      Sorry, but the creator could olny reset when he is edit mode!
    </sweet-modal>
    <sweet-modal ref="successModal" class="of_v" icon="success">
      Password updated successfully!
    </sweet-modal>
  </div>
</template>
<script>
  import http from "../../common/http"
  import domtoimage from "dom-to-image-more"
  import DeleteMapModal from '../../common/modals/delete_modal';
  import MakePrivateModal from "../../common/modals/make_private_modal"
  import DeletePasswordModal from '../../common/modals/delete_password_modal';
  import createPoll from './polls/create_poll'
  import voteInPoll from './polls/vote_in_poll'
  import pollView from './polls/poll_view'
  import TemporaryUser from "../../mixins/temporary_user.js"

  export default {
    props: ['currentMindMap'],
    data() {
      return {
        dataLoaded: false,
        isReset: false,
        pollData: null,
        pollEdit: false
      }
    },
    components: {
      DeleteMapModal,
      DeletePasswordModal,
      MakePrivateModal,
      createPoll,
      voteInPoll,
      pollView
    },
    mixins: [TemporaryUser],
    channels: {
      WebNotificationsChannel: {
        received(data) {
          if (data.message === "Mindmap Deleted" && this.currentMindMap.id === data.mindmap.id)
          {
            window.open('/','_self')
          } else if (data.message === "Password Updated" && this.currentMindMap.id === data.mindmap.id) {
            setTimeout(() => {
              location.reload()
            }, 500)
          } else if (data.message === "Reset mindmap" && this.currentMindMap.id === data.mindmap.id) {
            this.currentMindMap = data.mindmap
          }
          else if (data.message === "Mindmap Updated" && this.currentMindMap.id === data.mindmap.id){
            this.currentMindMap = data.mindmap
            this.pollData = JSON.parse(data.mindmap.canvas)
          }
        }
      }
    },
    mounted(){
      if(this.currentMindMap){
        this.subscribeCable(this.currentMindMap.id)
        this.dataLoaded = true
        this.pollData = JSON.parse(this.currentMindMap.canvas)
      }
    },
    methods: {
      openPrivacy(val) {
        this.isSaveMSuite = val
        this.$refs['make-private-modal'].$refs['makePrivateModal'].open()
      },
      deleteMap() {
        this.$refs['delete-map-modal'].$refs['deleteMapModal'].open()
      },
      confirmDeleteMindmap() {
        if (this.currentMindMap.password){
          this.$refs['delete-password-modal'].$refs['DeletePasswordModal'].open()
        } else {
          this.deleteMindmap()
        }
      },
      deleteMindmapProtected(password) {
        http
        .delete(`/msuite/${this.currentMindMap.unique_key}.json?password_check=${password}`)
        .then(res=>{
          if (!res.data.success && this.currentMindMap.password)
            this.$refs['errorModal'].open()
        })
        .catch(error => {
          console.log(error)
        })
      },
      deleteMindmap() {
        http
        .delete(`/msuite/${this.currentMindMap.unique_key}.json`)
        .then(res => {
          window.open("/", "_self")
        })
        .catch(error => {
          console.log(error)
        })
      },
      passwordProtect(new_password, old_password, is_mSuite) {
        http
        .patch(`/msuite/${this.currentMindMap.unique_key}.json`,{mindmap:{password: new_password, old_password: old_password}})
        .then(res => {
          if (res.data.mindmap) {
            this.currentMindMap.password = res.data.mindmap.password
            if(!is_mSuite) window.open("/", "_self")
            else location.reload()
            this.$refs['successModal'].open()
          } else {
            if (res.data.error) this.$refs['errorModal'].open()
          }
        })
      },
      passwordAgain() {
        this.$refs['passwordMismatched'].close()
        this.openPrivacy()
      },
      updateVote(data){
        let mindmap = { mindmap: { canvas: JSON.stringify(data) } }
        let id = this.currentMindMap.unique_key
        http.patch(`/msuite/${id}.json`,mindmap).then( res =>{
          this.pollEdit = false
        })
      },
      pollEditData() {
        this.pollEdit = true
        setTimeout(()=>{
          $('.btn-info')[2].innerHTML = 'Update Poll'
        },300)
      },
      resetMindmap() {
        if(!this.pollEdit && JSON.parse(this.currentMindMap.canvas).pin != ''){
          this.$refs['navigationBar'].$refs['editPoll'].open()
        } else {
          let canvasData = {
            question: '',
            answerField: [
              { value: 1, text: '', votes: null },
              { value: 2, text: '', votes: null }
            ],
            pin: '',
            voters: [],
            showResult: false
          }
          let mindmap = { mindmap: {
            canvas: JSON.stringify(canvasData),
            title: 'Title' }
          }
          let id = this.currentMindMap.unique_key
          http.patch(`/msuite/${id}.json`,mindmap)
        }
      },
    },
  }
</script>
<style lang="scss">
</style>
