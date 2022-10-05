<template>
  <div class="overflow-auto maxHeight">
    <div class="container">
      <div class="d-flex mt-2">
        <h5>Description&nbsp;</h5><span>(optional)</span>
      </div>
      <textarea
        type="input"
        v-model="poll.description"
        class="mt-3 w-100"
        placeholder="Input description text" />
      <div v-for="(questions,index) in poll.Questions">
        <div
          draggable="true"
          @dragstart="dragStartQuestion($event,index)"
          @drop="dragDropQuestion($event,index)"
          ondragover="event.preventDefault();" >
          <hr />
          <div class="d-flex mt-2 w-100">
            <h5 class="input-width">Question*</h5>
            <i class="fas fa-times text-danger" @click="deleteQuestion(index)"></i>
          </div>
            <textarea
                  type="input"
                  v-model="questions.question"
                  class="w-100"
                  :class="questions.question == '' && showError ? 'shake d-block border-danger':''"
                  placeholder="Type Your Question Here..."
                  required />
            <h5>Answer Options*</h5>
            <div class="text-danger">Atleast two options required</div>
            <div v-for="(answer, index) in questions.answerField">
              <div
                draggable="true"
                @dragstart="dragStartAns($event, questions, index)"
                @drop="dragDropAns($event, questions, index)"
                ondragover="event.preventDefault();">
                <div class="row mt-4">
                  <div class="w-100">
                    <input
                      :id="'answer' + index"
                      type="input"
                      v-model="answer.text"
                      class="input-width"
                      :class=" ( answer.text == '' || answer.text == undefined ) && showError ? 'shake d-block border-danger':''"
                      placeholder="Type Your answer Here..."
                      required />
                      <i class="fas fa-times text-danger" @click="delAnswer(questions, answer, index)"></i>
                  </div>
                </div>
              </div>
            </div>
            <button
              class="btn btn-color mt-3 py-0 px-3 rounded-0"
              @click="addAnswersOpt(questions)">
              Add Option
            </button>
            <div class="d-flex">
              <div>Allowable Selected Options</div>
              <select v-model="questions.allowedAnswers" class="form-select">
                <option
                  v-for="(value, index) in questions.answerField"
                  :value="index">
                  {{ index + 1 }}
                </option>
              </select>
            </div>
          </div>
      </div>
      <hr />
      <button
        class="btn btn-color mt-2 py-0 px-3 rounded-0"
        @click="addQuestion">
        Add Question
      </button>
      <div class="mt-5 d-flex">
        <span>
          Poll End Date
        </span>
          <date-picker
            id="input"
            class="border-0 rounded-0 py-0 px-3"
            v-model='poll.duedate'
            :placeholder="poll.duedate ? duedate : 'DD MM YYYY'"
            :format="format"
            ref="datePicker"
            >
          </date-picker>
          <i class="mt-2 fas fa-times text-danger" @click="poll.duedate = ''"></i>
      </div>
      <div>
        <span class="mb-2">
          Require User Names
        </span>
          <input
            id="input"
            type="checkbox"
            class="mt-2 userCheck"
            v-model='poll.userNameRequire'
            />
      </div>
      <div>Poll URL*</div>
      <div>
        <span>
          https://msuite.app/msuite/{{poll.url}}
        </span>
      </div>
      <button
        class="btn bg-dark text-light mt-2 py-0 px-3 rounded-0 float-right"
        :class="createPermit ? 'cursor-disabled':''"
        :disabled = "createPermit"
        @click="createPin()">
        PREVIEW
      </button>
    </div>
    <sweet-modal ref="saved_success" class="of_v" icon="success">
      Poll Saved Successfully
    </sweet-modal>
  </div>
</template>

<script>
  import http from "../../../common/http"
  import DatePicker from 'vue2-datepicker';
  import moment from 'moment'

  export default {
    props:["pollData", "currentMindMap"],
    data () {
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
        format: 'DD MMM YYYY',
        q_position: null,
        a_position: null,
        current_question: null,
        result_data: [],
      }
    },
    components: {
      DatePicker
    },
    computed: {
      duedate(){
        return moment(new Date(this.poll.duedate)).format('DD MMM YYYY')
      }
    },
    mounted() {
      if(this.pollData){
        this.poll = this.pollData
      }
      this.poll_url()
    },
    watch: {
      pollData: {
        handler(value){
          this.poll = value
        }
      }
    },
    methods: {
      addAnswersOpt(questions) {
        questions.answerField.push({
          value: this.poll.Questions[0].answerField.length + 1,
          text: '',
          votes: null
        })
      },
      addQuestion(){
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
        if(this.checkAllFields()){
          this.showError = true
          this.result_data = []
          setTimeout(()=>{
            this.showError = false
          }, 2500)
          return
        }
        this.savePoll()
      },
      savePoll(request) {
        this.$emit("updateVote" , this.poll )
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
      poll_url(){
        if(this.poll.url == ''){
          var url = "";
          var possible = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
          for (var i = 0; i < 19; i++)
            url += possible.charAt(Math.floor(Math.random() * possible.length));
          this.poll.url = url
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
