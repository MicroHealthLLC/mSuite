<template>
  <div class="poll-app">
    <navigation-bar
      ref="navigationBar"
      @mSuiteTitleUpdate="mSuiteTitleUpdate"
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
  </div>
</template>
<script>
  import http from "../../common/http"
  import domtoimage from "dom-to-image-more"
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
