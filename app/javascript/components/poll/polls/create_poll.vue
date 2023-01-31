<template>
  <div class="overflow-auto maxHeight">
    <div class="container">
      <div v-if="!showResult">
      <div class="d-flex">
        <h5>Poll Description&nbsp;</h5><span>(optional)</span>
      </div>
      <el-row>
        <el-col :span="22">
          <el-input :disabled="disableFields" class="mt-2" type="textarea" autosize v-model="poll.description"
            @blur="saveData" placeholder="Add a description here...">
          </el-input>
        </el-col>
      </el-row>
      <hr />
      <div v-for="(questions, index) in poll.Questions">
        <el-card class="box-card mt-2 w-75">
          <div draggable="true" @dragstart="dragStartQuestion($event, index)" @drop="dragDropQuestion($event, index)"
            ondragover="event.preventDefault();">
            <el-button :disabled="disableFields" v-if="index != 0" type="danger" class="float-right"
              icon="el-icon-minus" size="mini" circle v-b-tooltip.hover title="Remove Question"
              @click="deleteQuestion(index)">
            </el-button>
            <div class="d-flex mt-2">
              <h5 class="input-width">Question*</h5>
            </div>
            <el-row :gutter="10">
              <el-col :span="22">
                <el-input :disabled="disableFields" autosize type="textarea" v-model="questions.question"
                  @blur="saveData" :class="questions.question == '' && showError ? 'shake d-block border-red' : ''"
                  placeholder="Type question here..." required>
                </el-input>
              </el-col>
            </el-row>
            <h5 class="mt-3">Answer Options*</h5>
            <div class="text-danger">Two options required</div>
            <div v-for="(answer, index) in questions.answerField" draggable="true"
              @dragstart="dragStartAns($event, questions, index)" @drop="dragDropAns($event, questions, index)"
              ondragover="event.preventDefault();">
              <el-row :gutter="10" class="mt-2">
                <el-col :span="22">
                  <el-input :disabled="disableFields" :id="'answer' + index" type="input" @blur="saveData"
                    v-model="answer.text"
                    :class="(answer.text == '' || answer.text == undefined) && showError ? 'shake d-block border-red' : ''"
                    placeholder="Type answer here..." required>
                  </el-input>
                </el-col>
                <el-col :span="2">
                  <el-button :disabled="disableFields" v-if="index > 1" type="danger" icon="el-icon-minus" size="mini"
                    circle class="mt-1" v-b-tooltip.hover.right title="Remove Option"
                    @click="delAnswer(questions, answer, index)">
                  </el-button>
                </el-col>
              </el-row>
            </div>
            <el-button :disabled="disableFields" round class="btn-color mt-3 py-1" @click="addAnswersOpt(questions)">
              Add Option
            </el-button>
            <div class="mt-2 d-flex">
              <div>Allowed selectable options</div>
              <el-input-number :disabled="disableFields" class="ml-2" size="mini" @change="saveData"
                v-model="questions.allowedAnswers" :min="1" :max="questions.answerField.length"></el-input-number>
            </div>
          </div>
        </el-card>
      </div>
      <el-button :disabled="disableFields" round class="mt-4 btn-color py-1" @click="addQuestion">
        Add Question
      </el-button>
      <div class="mt-4 mb-2">
        <span>
          Poll End Date
        </span>
        <date-picker id="input" @change="saveData" class="border-0 rounded-0 py-0 px-3" v-model='poll.duedate'
          :placeholder="poll.duedate ? duedate : 'MM/DD/YYYY'" :format="format" ref="datePicker">
        </date-picker>
        <el-button type="danger" icon="el-icon-close" size="mini" circle @click="poll.duedate = ''"
          v-b-tooltip.hover.right title="Clear Date">
        </el-button>
      </div>
      <div class="mb-1">Poll URL:
        <span id="pollURL" class="ml-2 pollURL">
          {{ baseURL }}/msuite/{{ poll.url }}
        </span>
        <el-button class="ml-2" icon="el-icon-document-copy" size="small" circle v-b-tooltip.hover.right
          title="Copy Link" @click="copy(poll.url)"></el-button>
        <el-button v-if="!isPollPublished" round type="success" class="ml-4 py-2 px-3" @click="publishMap">
          LAUNCH POLL
        </el-button>
      </div>
      <span class="text-danger" v-if="isPollPublished">
          Poll has been published. Please copy link above to share.
      </span>
      <div class="mt-3">
        <el-button v-if="disableFields" round type="primary"
          class="py-2 px-3" @click="showResult = !showResult">
          SHOW RESULTS
        </el-button>
        <el-button v-if="disableFields" round type="danger" class="ml-4 py-2 px-3" @click="resetPollVotes()">
          RESET POLL VOTES
        </el-button>
        <span class="ml-4" v-if="disableFields">Votes Cast:
          {{ pollData.Questions[0].voters.length }}
        </span>
      </div>
      <el-button round class="bg-dark text-light py-2 px-3 float-right"
        :class="createPermit ? 'cursor-disabled' : ''" :disabled="createPermit" @click="createPin()">
        PREVIEW
      </el-button>
    </div>
    <poll-results :pollData="pollData" @showPoll="showResult = !showResult" v-else>
    </poll-results>
    <sweet-modal ref="saved_success" class="of_v" icon="success">
      Poll launched successfully and shareable link copied to clipboard
    </sweet-modal>
    <sweet-modal ref="errorModal" class="of_v" icon="error">
      {{ errorMsg }}
      <!-- <button v-if="mindmapExists" slot="button" class="btn btn-secondary mr-2" @click="resetPollVotes()">Reset Poll Votes</button>
                <button slot="button" class="btn btn-secondary mr-2" @click="tryAgain()">Try Again</button>
                <button slot="button" class="btn btn-info" @click="generateRandomURL()">Create Random URL</button> -->
    </sweet-modal>
    </div>
  </div>
</template>

<script>
import http from "../../../common/http"
import DatePicker from 'vue2-datepicker'
import TemporaryUser from "../../../mixins/temporary_user.js"
import PollResults from "./poll_view_results/poll_results"

export default {
  props: ["pollData", "undoCanvas", "currentMindMap", "pollEdit"],
  data() {
    return {
      poll: {
        title: '',
        description: '',
        Questions: [{
          question: '',
          answerField: [
            { value: 1, text: '', votes: [] },
            { value: 2, text: '', votes: [] }
          ],
          allowedAnswers: 0,
          voters: [],
          checked: [],
        }],
        showResult: false,
        url: ''
      },
      showError: false,
      showResult: false,
      errorMsg: null,
      format: 'MM/DD/YYYY',
      q_position: null,
      a_position: null,
      current_question: null,
      result_data: [],
      baseURL: window.location.origin,
      mindmapExists: false
    }
  },
  mixins: [TemporaryUser],
  components: {
    DatePicker,
    PollResults
  },
  computed: {
    duedate() {
      return moment(new Date(this.poll.duedate)).format('MM/DD/YYYY')
    },
    disableFields() {
      if (this.pollData && this.pollData.Questions[0].voters.length == 0) {
        return false
      } else return true
    },
    isPollPublished() {
      return JSON.parse(this.$store.getters.getMsuite.canvas).pollData.isPublished
    }
  },
  mounted() {
    this.subscribeCable(this.currentMindMap.id)
    if (this.pollData) {
      this.poll = this.pollData
    }
    this.pollUrl()
  },
  watch: {
    pollData: {
      handler(value) {
        if (value != null) this.poll = value
        if (this.poll.url == '') this.pollUrl()
        console.log(this)
        //console.log(this)
      }
    }
  },
  methods: {
    publishMap() {
      if (this.checkAllFields()) {
        this.showError = true
        this.result_data = []
        setTimeout(() => {
          this.showError = false
        }, 2500)
        return
      }
      this.createPollingMap()
    },
    createPollingMap() {
      console.log(this)
      let _this = this
      http.post(`/msuite.json`, { mindmap: { name: this.pollData.url || "Central Idea", title: this.pollTitle, mm_type: 'pollvote', parent_id: this.currentMindMap.id, canvas: JSON.stringify(this.pollData) } }).then(async (res) => {
        if (res.data.mindmap.id !== null) {
          this.pollData.isPublished = true
          this.pollData.url = res.data.mindmap.unique_key
          let mycanvas = {
            pollData: this.pollData,
            user: this.$store.getters.getUser
          }
          mycanvas = JSON.stringify(mycanvas)
          let mindmap = { mindmap: { canvas: mycanvas } }
          await this.$store.dispatch('updateMSuite', mindmap)
          //alert("Poll Launched and copying link to clipboard")
          _this.$refs['saved_success'].open()
          this.copy(res.data.mindmap.unique_key, false)
          this.$emit('pollEditData', true)
          //window.open(`/msuite/${res.data.mindmap.unique_key}`)
        }
      }).catch((error) => {
        console.log(error.response.data)
        if (error.response.data.messages[0] == "Unique key has already been taken") _this.mindmapExists = true
        _this.errorMsg = 'This Poll Url ' + error.response.data.messages[0]
        /* _this.selectedType = error.response.data.mindmap.mm_type
        _this.uniqueKey = error.response.data.mindmap.unique_key
        _this.oldMSuiteName = error.response.data.mindmap.name
        _this.mindmapName = '' */
        _this.$refs['errorModal'].open()
      })
    },
    resetPollVotes() {
      this.pollData.Questions.forEach(data => {
        data.voters = []
        data.answerField.forEach(voters => {
          voters.votes = []
        })
      })
      let mycanvas = {
        pollData: this.pollData,
        user: this.$store.getters.getUser
      }
      mycanvas = JSON.stringify(mycanvas)
      let mindmap = { mindmap: { canvas: mycanvas } }
      this.$emit("updateVote", mindmap)
      this.$emit('pollEditData', true)
      //this.$refs['errorModal'].close()
    },
    copy(s, popup = true) {
      //console.log(s)
      let newURL = `${this.baseURL}/msuite/${s}`
      navigator.clipboard.writeText(newURL)
        .then(() => {
          if (popup) {
            alert("Copied to clipboard")
          }
        })
        .catch(() => {
          alert("Unable to copy")
        })
    },
    addAnswersOpt(questions) {
      questions.answerField.push({
        value: this.poll.Questions[0].answerField.length + 1,
        text: '',
        votes: null
      })
      this.saveData()
    },
    addQuestion() {
      this.poll.Questions.push({
        question: '',
        answerField: [
          { value: 1, text: '', votes: [] },
          { value: 2, text: '', votes: [] }
        ],
        voters: [],
        allowedAnswers: 0,
      })
      this.saveData()
    },
    createPin() {
      if (this.checkAllFields()) {
        this.showError = true
        this.result_data = []
        setTimeout(() => {
          this.showError = false
        }, 2500)
        return
      }
      this.savePoll()
    },
    savePoll(request) {
      let mindmap = this.createMindmapCanvas(this.$store.getters.getUser)
      this.$emit("pollEditData", false)
      this.$emit("updateVote", mindmap)
    },
    delAnswer(questions, answer, index) {
      if (questions.answerField.length > 2) {
        questions.answerField.splice(index, 1)
        this.saveData()
      }
    },
    deleteQuestion(index) {
      if (this.poll.Questions.length > 1) {
        this.poll.Questions.splice(index, 1)
        this.saveData()
      }
    },
    dragStartQuestion(event, question_index) {
      this.q_position = question_index
    },
    dragDropQuestion(event, question_index) {
      const drag_question = this.poll.Questions.splice(this.q_position, 1)[0]
      this.poll.Questions.splice(question_index, 0, drag_question)
      this.saveData()
    },
    dragStartAns(event, questions, answer_index) {
      this.a_position = answer_index
      this.current_question = event.currentTarget.parentElement.parentElement
    },
    dragDropAns(event, questions, answer_index) {
      if (this.current_question == event.currentTarget.parentElement.parentElement) {
        const drag_ans = questions.answerField.splice(this.a_position, 1)[0]
        questions.answerField.splice(answer_index, 0, drag_ans)
        this.saveData()
      }
    },
    async pollUrl() {
      let mindmap = this.createMindmapCanvas(this.$store.getters.getUser)
      if (this.poll.url == '') {
        var url = "";
        var possible = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
        for (var i = 0; i < 15; i++)
          url += possible.charAt(Math.floor(Math.random() * possible.length));
        this.poll.url = url
        mindmap = this.createMindmapCanvas(null)
        await this.$store.dispatch('updateMSuite', mindmap)
      }
      this.$emit('updateUndoCanvas',mindmap)
    },
    checkAllFields() {
      let _this = this
      let result_value
      _this.poll.Questions.forEach((question, q_index) => {
        _this.poll.Questions[q_index].answerField.forEach((answer, index) => {
          if (_this.poll.Questions[q_index].answerField.length > 2) {
            if (answer.text == '') _this.poll.Questions[q_index].answerField.splice(index, 100)
          }
        })
        _this.result_data.push(_this.poll.Questions[q_index].answerField.length < 2 || _this.poll.Questions[q_index].question == '' || _this.poll.Questions[q_index].question == undefined || _this.poll.Questions[q_index].answerField[0].text == '' || _this.poll.Questions[q_index].answerField[1].text == '')
      })
      _this.result_data.filter(value => {
        if (value == true) {
          result_value = value
          return
        }
      });
      return result_value
    },
    saveData(){
      let _this = this
      let mindmap = this.createMindmapCanvas(this.$store.getters.getUser)
      this.$store.dispatch('updateMSuite', mindmap).then(res => {
        _this.$emit('updateUndoCanvas',mindmap)
      })
      this.sendLocals(false)
    },
    createMindmapCanvas(tUser) {
      let mycanvas = {
        pollData: this.poll,
        user: tUser
      }
      mycanvas = JSON.stringify(mycanvas)
      let mindmap = { mindmap: { canvas: mycanvas } }
      return mindmap
    }
  }
}
</script>

<style lang="scss" scoped>
  @import "./check_box.scss";
  @import "./poll.scss";
</style>
