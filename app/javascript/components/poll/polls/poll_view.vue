<template>
  <div v-if="dataLoaded" class="container">
    <div class="overflow-auto maxHeight" v-if="!showResult">
      <h3 id="poll-title" class="d-none"><strong>{{ currentMindMap.title }}</strong></h3>
      <h5>{{ pollData.description }}</h5>
      <div>
        <span class="text-danger" :class="errorTriggered ? 'shake d-block border-danger':''">
          All Questions require atleast one answer. Questions that allow more than one answer will have checkboxes, with the allowed selectable options indicated.
        </span>
      </div>
      <div class="mt-3" v-for="(questions,index) in pollData.Questions">
        <h5>
          {{ index + 1 }}. {{ questions.question }}
        </h5>
        <span
          v-if="questions.allowedAnswers > 1"
          class="ml-4" :class="errorTriggered ? 'shake d-block border-danger':''">
          Allowed selectable options: {{ questions.allowedAnswers }}
        </span>
        <div class="mt-2 ml-4" v-for="(answers, index) in questions.answerField">
          <input
            v-if="questions.allowedAnswers > 1"
            type="checkbox"
            :value="answers"
            :name="questions.question"
            v-model="questions.preview_checked"
            @change="checkDisabled(questions)"
            :disabled="ans_count >= questions.allowedAnswers && questions.preview_checked.indexOf(answers) == -1 ? true:false"
            @click="checkCheckedAns($event)" />

          <input
            v-else
            type="radio"
            :value="answers"
            :name="questions.question"
            v-model="questions.preview_checked"
            @click="checkCheckedAns($event)" />
          <span :class="errorTriggered ? 'shake d-block border-danger':''">
            {{ answers.text }}
          </span>
        </div>
      </div>
      <div class="my-4">
        <!-- <el-button
        v-if="!childMindmap"
          round
          type="success"
          class="mt-4 py-2 px-3"
          @click="createPollingMap">
          LAUNCH POLL
        </el-button>
        <el-button
          v-if="childMindmap"
          round
          type="primary"
          class="ml-4 mt-4 py-2 px-3"
          @click="showResult = !showResult">
          SHOW RESULTS
        </el-button> -->
        <el-button
          round
          type="warning"
          class="text-white ml-4 mt-4 py-2 px-3"
          @click="$emit('pollEditData')">
          CLOSE
        </el-button>
        <!-- <div class="mt-4" v-else>Poll URL:
          <span class="font-weight-bold">
            {{baseURL}}/msuite/{{pollData.url}}
          </span>
          <el-button class="ml-2" icon="el-icon-document-copy" size="small" circle v-b-tooltip.hover.right title="Copy Link" @click="copy(pollData.url)">
          </el-button>
        </div> -->
      </div>
    </div>
    <poll-results
      :pollData="pollData"
      @showPoll="showResult = !showResult"
      v-else>
    </poll-results>
    <sweet-modal ref="errorModal" class="of_v" icon="error">
      {{ errorMsg }}
      <!-- <button v-if="mindmapExists" slot="button" class="btn btn-secondary mr-2" @click="resetPollVotes()">Reset Poll Votes</button>
      <button slot="button" class="btn btn-secondary mr-2" @click="tryAgain()">Try Again</button>
      <button slot="button" class="btn btn-info" @click="generateRandomURL()">Create Random URL</button> -->
    </sweet-modal>
  </div>
</template>

<script>
  import http from "../../../common/http"
  import PollResults from "./poll_view_results/poll_results"

  export default {
    name: "Poll",
    props: ["pollData", "childMindmap"],
    data() {
      return {
        pollTitle: this.$store.getters.getMsuite.title,
        dataLoaded: false,
        showResult: false,
        errorMsg: null,
        selectedType: null,
        uniqueKey: null,
        oldMSuiteName: null,
        mindmapName: '',
        mindmapExists: false,
        errorTriggered: false,
        ans_count: 0,
        checkedAns: false,
        baseURL: window.location.origin
      };
    },
    components: {
      PollResults
    },
    computed: {
      currentMindMap(){
        return this.$store.getters.getMsuite
      }
    },
    watch: {
      currentMindMap: {
        handler(value) {
          this.pollTitle = value.title
        }, deep: true
      },
    },
    mounted(){
      if(this.pollData) {
        this.dataLoaded = true
        this.pollData.Questions.forEach( question => {
          question.checked = []
          question.preview_checked = []
        })
      }
    },
    methods: {
      async getVoteData() {
        let _this = this
        let response = await http.get(`/msuite/${this.pollData.url}.json`)
        if( response.data.mindmap &&
          JSON.parse(response.data.mindmap.canvas).Questions[0].voters.length > 0) return false
        else return true
      },
      /* createPollingMap() {
        let _this = this
        http.post(`/msuite.json`, { mindmap: { name: this.pollData.url || "Central Idea", title: this.pollTitle, mm_type: 'pollvote',parent_id: this.currentMindMap.id, canvas: JSON.stringify(this.pollData) } }).then( async (res) => {
          if(res.data.mindmap.id !== null)
          {
            this.pollData.url = res.data.mindmap.unique_key
            let mycanvas = {
              pollData  : this.pollData,
              user      : this.$store.getters.getUser
            }
            mycanvas = JSON.stringify(mycanvas)
            let mindmap = { mindmap: { canvas: mycanvas } }
            await this.$store.dispatch('updateMSuite', mindmap)
            window.open(`/msuite/${res.data.mindmap.unique_key}`)
          }
        }).catch((error) => {
          if(error.response.data.messages[0] == "Unique key has already been taken") _this.mindmapExists = true
          _this.errorMsg = 'This Poll Url ' + error.response.data.messages[0]
          _this.selectedType = error.response.data.mindmap.mm_type
          _this.uniqueKey = error.response.data.mindmap.unique_key
          _this.oldMSuiteName = error.response.data.mindmap.name
          _this.mindmapName = ''
          _this.$refs['errorModal'].open()
        })
      }, */
      checkDisabled(checked){
        this.ans_count = checked.preview_checked.length
      },
      checkCheckedAns(event){
        if(event.target.checked) event.target.setAttribute("checked", "checked")
        else event.target.removeAttribute("checked")
      },
      /*tryAgain(){
        this.$refs['errorModal'].close()
      },
       resetPollVotes(){
        this.pollData.Questions.forEach( data => {
          data.voters = []
          data.answerField.forEach( voters => {
            voters.votes = []
          })
        })
        let mycanvas = {
          pollData  : this.pollData,
          user      : this.$store.getters.getUser
        }
        mycanvas = JSON.stringify(mycanvas)
        let mindmap = { mindmap: { canvas: mycanvas } }
        this.$emit("updateVote", mindmap)
        this.$refs['errorModal'].close()
      }, 
      generateRandomURL(){
        this.pollData.url = "Central Idea"
        this.createPollingMap()
        this.$refs['errorModal'].close()
      },*/
    }
  };
</script>
<style lang="scss" scoped>
  @import './poll.scss';
</style>
