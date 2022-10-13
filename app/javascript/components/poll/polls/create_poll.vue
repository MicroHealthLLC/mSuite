<template>
  <div class="overflow-auto maxHeight">
    <div class="container">
      <div class="d-flex">
        <h5>Poll Description&nbsp;</h5><span>(optional)</span>
      </div>
      <el-row>
        <el-col :span="22">
          <el-input class="mt-2" type="textarea" autosize v-model="poll.description" @blur="saveData" placeholder="Add a description here...">
          </el-input>
        </el-col>
      </el-row>
      <hr />
      <div v-for="(questions,index) in poll.Questions">
        <el-card class="box-card mt-2 w-75">
          <div draggable="true" @dragstart="dragStartQuestion($event,index)" @drop="dragDropQuestion($event,index)"
            ondragover="event.preventDefault();">
            <el-button v-if="index != 0" type="danger" class="float-right" icon="el-icon-minus" size="mini" circle v-b-tooltip.hover title="Remove Question"
              @click="deleteQuestion(index)">
            </el-button>
            <div class="d-flex mt-2">
              <h5 class="input-width">Question*</h5>
            </div>
            <el-row :gutter="10">
              <el-col :span="22">
                <el-input autosize type="textarea" v-model="questions.question" @blur="saveData" :class="questions.question == '' && showError ? 'shake d-block border-red':''"
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
                  <el-input :id="'answer' + index" type="input" @blur="saveData" v-model="answer.text"
                    :class=" ( answer.text == '' || answer.text == undefined ) && showError ? 'shake d-block border-red':''"
                    placeholder="Type answer here..." required>
                  </el-input>
                </el-col>
                <el-col :span="2">
                  <el-button v-if="index > 1" type="danger" icon="el-icon-minus" size="mini" circle class="mt-1" v-b-tooltip.hover.right title="Remove Option"
                    @click="delAnswer(questions, answer, index)">
                  </el-button>
                </el-col>
              </el-row>
            </div>
            <el-button round class="btn-color mt-3 py-1" @click="addAnswersOpt(questions)">
              Add Option
            </el-button>
            <div class="mt-2 d-flex">
              <div>Allowed selectable options</div>
              <el-input-number class="ml-2" size="mini" @change="saveData" v-model="questions.allowedAnswers" :min="1"
                :max="questions.answerField.length"></el-input-number>
            </div>
          </div>
        </el-card>
      </div>


      <!-- <button
        class="btn btn-color mt-2 py-0 px-3 rounded-0"
        @click="addQuestion">
        Add Question
      </button> -->
      <el-button round class="mt-4 btn-color py-1" @click="addQuestion">
        Add Question
      </el-button>
      <div class="mt-4 mb-4">
        <span>
          Poll End Date
        </span>
        <date-picker id="input" @change="saveData" class="border-0 rounded-0 py-0 px-3" v-model='poll.duedate'
          :placeholder="poll.duedate ? duedate : 'MM/DD/YYYY'" :format="format" ref="datePicker">
        </date-picker>
        <el-button type="danger" icon="el-icon-close" size="mini" circle @click="poll.duedate = ''" v-b-tooltip.hover.right title="Clear Date">
        </el-button>
      </div>
      <div class="mb-4">
        <span>
          Require User Names
        </span>
        <input id="input" type="checkbox" class="userCheck" @change="saveData" v-model='poll.userNameRequire' />
      </div>
      <div>Poll URL:
        <span id="pollURL" class="ml-2 pollURL">
          https://msuite.app/msuite/{{poll.url}}
        </span>
        <el-button class="ml-2" icon="el-icon-document-copy" size="small" circle v-b-tooltip.hover.right title="Copy Link" @click="copy(poll.url)"></el-button>
      </div>
      <el-button round class="bg-dark text-light mt-2 py-2 px-3 float-right"
        :class="createPermit ? 'cursor-disabled':''" :disabled="createPermit" @click="createPin()">
        PREVIEW
      </el-button>
    </div>
    <sweet-modal ref="saved_success" class="of_v" icon="success">
      Poll Saved Successfully
    </sweet-modal>
  </div>
</template>

<script>
import http from "../../../common/http"
import DatePicker from 'vue2-datepicker'
import moment from 'moment'
import TemporaryUser from "../../../mixins/temporary_user.js"

export default {
  props: ["pollData", "currentMindMap"],
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
        }],
        showResult: false,
        url: ''
      },
      showError: false,
      format: 'MM/DD/YYYY',
      q_position: null,
      a_position: null,
      current_question: null,
      result_data: [],
    }
  },
  mixins: [TemporaryUser],
  components: {
    DatePicker
  },
  computed: {
    duedate() {
      return moment(new Date(this.poll.duedate)).format('MM/DD/YYYY')
    }
  },
  mounted() {
    this.subscribeCable(this.currentMindMap.id)
    if (this.pollData) {
      this.poll = this.pollData
    }
    this.poll_url()
  },
  watch: {
    pollData: {
      handler(value) {
        if (value != null) this.poll = value
      }
    }
  },
  methods: {
    copy(s) {
      let newURL = `https://msuite.app/msuite/${s}`
      navigator.clipboard.writeText(newURL)
        .then(() => {
          alert("Copied to clipboard")
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
      this.$emit("updateVote", this.poll)
    },
    delAnswer(questions, answer, index) {
      if (questions.answerField.length > 2) {
        questions.answerField.splice(index, 1)
      }
    },
    deleteQuestion(index) {
      if (this.poll.Questions.length > 1) {
        this.poll.Questions.splice(index, 1)
      }
    },
    dragStartQuestion(event, question_index) {
      this.q_position = question_index
    },
    dragDropQuestion(event, question_index) {
      const drag_question = this.poll.Questions.splice(this.q_position, 1)[0]
      this.poll.Questions.splice(question_index, 0, drag_question)
    },
    dragStartAns(event, questions, answer_index) {
      this.a_position = answer_index
      this.current_question = event.currentTarget.parentElement.parentElement
    },
    dragDropAns(event, questions, answer_index) {
      if (this.current_question == event.currentTarget.parentElement.parentElement) {
        const drag_ans = questions.answerField.splice(this.a_position, 1)[0]
        questions.answerField.splice(answer_index, 0, drag_ans)
      }
    },
    poll_url() {
      if (this.poll.url == '') {
        var url = "";
        var possible = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
        for (var i = 0; i < 19; i++)
          url += possible.charAt(Math.floor(Math.random() * possible.length));
        this.poll.url = url
        this.saveData()
      }
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
    checkPollPin() {
      return this.poll.pin == undefined || this.poll.pin == ''
      this.savePoll()
    },
    savePoll(request) {
      this.$emit("updateVote" , this.poll)
    },
    saveData(){
      let mycanvas = {
        pollData  : this.poll,
        user      : this.$store.getters.getUser
      }
      mycanvas = JSON.stringify(mycanvas)
      let mindmap = { mindmap: { canvas: mycanvas } }
      this.$store.dispatch('updateMSuite', mindmap)
      this.sendLocals(false)
    },
    delAnswer(questions, answer, index){
      if ( questions.answerField.length > 2 ) {
        questions.answerField.splice(index, 1)
      }
    },
    deleteQuestion(index){
      if ( this.poll.Questions.length > 1 ) {
        this.poll.Questions.splice(index, 1)
      }
    },
    dragStartQuestion(event,question_index){
      this.q_position = question_index
    },
    dragDropQuestion(event,question_index){
      const drag_question = this.poll.Questions.splice(this.q_position, 1)[0]
      this.poll.Questions.splice(question_index, 0, drag_question)
    },
    dragStartAns(event, questions, answer_index){
      this.a_position = answer_index
      this.current_question = event.currentTarget.parentElement.parentElement
    },
    dragDropAns(event, questions, answer_index){
      if ( this.current_question == event.currentTarget.parentElement.parentElement )
      {
        const drag_ans = questions.answerField.splice(this.a_position, 1)[0]
        questions.answerField.splice(answer_index, 0, drag_ans)
      }
    },
    checkAllFields(){
      let _this = this
      let result_value
      _this.poll.Questions.forEach( (question, q_index) => {
        _this.poll.Questions[q_index].answerField.forEach( (answer,index) => {
          if ( _this.poll.Questions[q_index].answerField.length > 2 ) {
            if(answer.text == '') _this.poll.Questions[q_index].answerField.splice(index, 100)
          }
        })
        _this.result_data.push(_this.poll.Questions[q_index].answerField.length < 2 || _this.poll.Questions[q_index].question == '' || _this.poll.Questions[q_index].question == undefined || _this.poll.Questions[q_index].answerField[0].text == '' || _this.poll.Questions[q_index].answerField[1].text == '')
      })
      _this.result_data.filter( value => {
        if (value == true) {
          result_value = value
          return
        }
      });
      return result_value
    },
    checkPollPin(){
      return this.poll.pin == undefined || this.poll.pin == ''
    }
  }
}
</script>

<style lang="scss">
@import "./check_box.scss";
</style>
<style scoped>
@import './poll.css'
</style>
