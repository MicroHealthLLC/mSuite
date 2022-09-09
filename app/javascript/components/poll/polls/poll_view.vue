<template>
  <div v-if="dataLoaded" class="container">
    <div class="overflow-auto maxHeight" v-if="!showResult">
      <h3><strong>{{ pollData.title }}</strong></h3>
      <div>
        <span class="text-danger">
          All Questions require atleast one answer. Questions that allow more than one answer will have checkboxes, with the allowable selected options indicated.
        </span>
      </div>
      <div class="mt-3" v-for="(questions,index) in pollData.Questions">
        <h5>
          {{ index + 1 }}. {{ questions.question }}
        </h5>
        <span
          v-if="questions.allowedAnswers + 1 > 1"
          class="ml-4">
          Allowable selected options: {{ questions.allowedAnswers + 1 }}
        </span>
        <div class="mt-2 ml-4" v-for="answers in questions.answerField">
          <input
            v-if="questions.allowedAnswers > 0"
            type="checkbox"
            :value="answers"
            v-model="questions.checked" />
          <input
            v-else
            type="radio"
            :value="answers"
            v-model="questions.checked"/>
          <span>
            {{ answers.text }}
          </span>
        </div>
      </div>
      <div class="mt-4">
        <button
          class="btn btn-success mt-4 py-0 px-3 rounded-0"
          @click="createPollingMap">
          FINALIZE
        </button>
        <button
          class="btn btn-info ml-4 mt-4 py-0 px-3 rounded-0"
          @click="showResult = !showResult">
          SHOW RESULTS
        </button>
        <button
          class="btn btn-warning text-white ml-4 mt-4 py-0 px-3 rounded-0"
          @click="$emit('pollEditData')">CANCEL</button>
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
      </sweet-modal>
  </div>
</template>

<script>
  import http from "../../../common/http"
  import PollResults from "./poll_view_results/poll_results"
  export default {
    name: "Poll",
    props: ["pollData"],
    data() {
      return {
        dataLoaded: false,
        showResult: false,
        errorMsg: null,
        selectedType: null,
        uniqueKey: null,
        oldMSuiteName: null,
        mindmapName: '',
        mindmapExists: false
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
        })
      }
    },
    methods: {
      createPollingMap() {
        let _this = this
        http.post(`/msuite.json`, { mindmap: { name: this.pollData.url || "Central Idea", mm_type: 'pollvote', canvas: JSON.stringify(this.pollData) } }).then((res) => {
          if(res.data.mindmap.id !== null)
          {
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
      tryAgain(){
        this.$refs['errorModal'].close()
      },
      updateMindMap(){
        http
        .patch(`/msuite/${this.pollData.url}.json`, {
          mindmap: { canvas: JSON.stringify(this.pollData) } })
        window.open(`/msuite/${this.pollData.url}`)
        this.$refs['errorModal'].close()
      }
    }
  };
</script>

<style scoped>
  @import './poll.css'
</style>
