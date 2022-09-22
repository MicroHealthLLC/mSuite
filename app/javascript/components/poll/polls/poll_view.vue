<template>
  <div v-if="dataLoaded" class="container">
    <div class="overflow-auto maxHeight" v-if="!showResult">
      <h5><strong>{{ pollData.description }}</strong></h5>
      <div>
        <span class="text-danger" :class="errorTriggered ? 'shake d-block border-danger':''">
          All Questions require atleast one answer. Questions that allow more than one answer will have checkboxes, with the allowable selected options indicated.
        </span>
      </div>
      <div class="mt-3" v-for="(questions,index) in pollData.Questions">
        <h5>
          {{ index + 1 }}. {{ questions.question }}
        </h5>
        <span
          v-if="questions.allowedAnswers + 1 > 1"
          class="ml-4" :class="errorTriggered ? 'shake d-block border-danger':''">
          Allowable selected options: {{ questions.allowedAnswers + 1 }}
        </span>
        <div class="mt-2 ml-4" v-for="(answers, index) in questions.answerField">
          <input
            v-if="questions.allowedAnswers > 0"
            type="checkbox"
            :value="answers"
            :name="questions.question"
            v-model="questions.preview_checked"
            :disabled="questions.preview_checked.length > questions.allowedAnswers && questions.preview_checked.indexOf(answers) == -1 ? true:false"
            @change="checkAnswers(questions.preview_checked)" />

          <input
            v-else
            type="radio"
            :value="answers"
            :name="questions.question"
            v-model="questions.preview_checked"
            @change="checkAnswers(questions.preview_checked)" />
          <span :class="errorTriggered ? 'shake d-block border-danger':''">
            {{ answers.text }}
          </span>
        </div>
      </div>
      <div class="my-4">
        <button
          class="btn btn-success mt-4 py-0 px-3 rounded-0"
          @click="createPollingMap">
          LAUNCH POLL
        </button>
        <button
          class="btn btn-info ml-4 mt-4 py-0 px-3 rounded-0"
          @click="showResult = !showResult">
          SHOW RESULTS
        </button>
        <button
          class="btn btn-warning text-white ml-4 mt-4 py-0 px-3 rounded-0"
          @click="$emit('pollEditData')">
          EDIT
        </button>
      </div>
    </div>
    <poll-results
      :pollData="pollData"
      @showPoll="showResult = !showResult"
      v-else>
    </poll-results>
    <sweet-modal ref="errorModal" class="of_v" icon="error">
      {{ errorMsg }}
      <button v-if="mindmapExists" slot="button" class="btn btn-secondary mr-2" @click="updateMindMap()">Update Poll</button>
      <button slot="button" class="btn btn-secondary mr-2" @click="tryAgain()">Try Again</button>
      <button slot="button" class="btn btn-info" @click="generateRandomURL()">Create Random URL</button>
    </sweet-modal>
  </div>
</template>

<script>
  import http from "../../../common/http"
  import PollResults from "./poll_view_results/poll_results"
  export default {
    name: "Poll",
    props: ["pollData","currentMindMap"],
    data() {
      return {
        dataLoaded: false,
        showResult: false,
        errorMsg: null,
        selectedType: null,
        uniqueKey: null,
        oldMSuiteName: null,
        mindmapName: '',
        mindmapExists: false,
        errorTriggered: false,
        loopBreaked: false
      };
    },
    components: {
      PollResults
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
      createPollingMap() {
        let _this = this
        http.post(`/msuite.json`, { mindmap: { name: this.pollData.url || "Central Idea", title: this.currentMindMap.title, mm_type: 'pollvote', canvas: JSON.stringify(this.pollData) } }).then((res) => {
          if(res.data.mindmap.id !== null)
          {
            this.pollData.url = res.data.mindmap.unique_key
            this.$emit("updateVote" , this.pollData, 'create')
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
      },
      checkAnswers(check){
        this.pollData.Questions.forEach( data => {
          if ( (check[0] && check[0].text) || check.text){
            this.loopBreaked = false
          } else this.loopBreaked = true
        } )
      },
      tryAgain(){
        this.$refs['errorModal'].close()
      },
      updateMindMap(){
        http
        .patch(`/msuite/${this.pollData.url}.json`, {
          mindmap: { title: this.currentMindMap.title, canvas: JSON.stringify(this.pollData) } })
        window.open(`/msuite/${this.pollData.url}`)
        this.$refs['errorModal'].close()
      },
      generateRandomURL(){
        this.pollData.url = "Central Idea"
        this.createPollingMap()
        this.$refs['errorModal'].close()
      },
    }
  };
</script>

<style scoped>
  @import './poll.css'
</style>
