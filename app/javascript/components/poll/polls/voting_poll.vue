<template>
  <div>
    <navigation-bar
      ref="navigationBar"
      @mSuiteTitleUpdate="mSuiteTitleUpdate"
      @openPrivacy="openPrivacy"
      @resetMindmap="resetMindmap"
      @exportToDocument="exportToDocument"
      @pollEditData="pollEditData"
      :current-mind-map="currentMindMap"
      :defaultDeleteDays="defaultDeleteDays"
      :expDays="expDays"
      :deleteAfter="deleteAfter"
      :pollPin="pollData"
      :pollEdit="pollEdit"
      :pollExpDate="pollExpDate"
      :exportId="'poll'">
    </navigation-bar>

    <div class="container overflow-auto maxHeight" v-if="validForVote && !returnFun">
      <span>{{ pollData.description }}</span>
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
          class="ml-4"
          :class="errorTriggered ? 'shake d-block border-danger':''">
          Allowable selected options: {{ questions.allowedAnswers + 1 }}
        </span>
        <div class="mt-2 ml-4" v-for="answers in questions.answerField">
          <input
            v-if="questions.allowedAnswers > 0"
            type="checkbox"
            :value="answers"
            v-model="questions.checked"
            @change="checkAnswers(questions.checked)"/>
          <input
            v-else
            type="radio"
            :value="answers"
            v-model="questions.checked"
            @change="checkAnswers(questions.checked)"/>
          <span>
            {{ answers.text }}
          </span>
        </div>
      </div>
      <div class="mt-4">
        <button
          class="btn btn-success mt-4 py-0 px-3 rounded-0"
          @click="submitVote">
          SUBMIT
        </button>
        <button
          class="btn btn-warning text-white ml-4 mt-4 py-0 px-3 rounded-0"
          @click="resetData">RESET</button>
      </div>
    </div>
    <section v-else-if="!validForVote" class="container">
        <h4 class="text-center">
          <strong>
            Time For Votes is Up !!!
          </strong>
        </h4>
    </section>
    <section v-else class="container">
        <h4>
          <strong>
            Your response has been recorded, Thanks for your Time.
          </strong>
        </h4>
    </section>
  </div>
</template>

<script>
  import http from "../../../common/http"
  import MakePrivateModal from "../../../common/modals/make_private_modal"
  import DeletePasswordModal from '../../../common/modals/delete_password_modal';
  import TemporaryUser from "../../../mixins/temporary_user.js"
  import moment from 'moment'

  export default {
    name: "Poll",
    props: ["currentMindMap"],
    mixins: [TemporaryUser],
    data() {
      return {
        pollData: {},
        returnFun: false,
        checkDisable: false,
        errorTriggered: false,
        validForVote: false,
        loopBreaked: false,
        pollExpDate: null
      };
    },
    channels: {
      WebNotificationsChannel: {
        received(data) {
          if (data.message === "Mindmap Deleted" && this.currentMindMap.id === data.mindmap.id)
          {
            window.open('/','_self')
          }
          else if (data.message === "Mindmap Updated" && this.currentMindMap.id === data.mindmap.id){
            this.currentMindMap = data.mindmap
            this.pollData = JSON.parse(data.mindmap.canvas)
          }
        }
      }
    },
    mounted(){
      if(this.currentMindMap) {
        this.pollData = JSON.parse(this.currentMindMap.canvas)
        this.subscribeCable(this.currentMindMap.id)
        this.voted()
        this.pollData.Questions.forEach( question => {
          question.checked = []
        })
        if (this.pollData.duedate == '' || this.pollData.duedate == undefined) this.validForVote = true
        else if (new Date() < new Date(this.pollData.duedate)) this.validForVote = true
        else this.validForVote = false
        this.pollExpDate = moment(new Date(this.pollData.duedate)).format('DD MMM YYYY')
        if (this.pollExpDate == 'Invalid date') this.pollExpDate = "Never"
      }
    },
    updated(){
      if(this.pollData.voters) this.pollData.voters.forEach(voter => {
        if(voter == localStorage.user_id) this.returnFun = true
      })
    },
    methods: {
      resetData(){
        this.pollData.Questions.forEach( question => {
          question.checked = []
        })
      },
      checkAnswers(check){
        this.pollData.Questions.forEach( data => {
          if ( (check[0] && check[0].text) || check.text){
            this.loopBreaked = false
          } else this.loopBreaked = true
        } )
      },
      submitVote(){
        let _this = this
        this.pollData.Questions.some( question => {

          if (question.checked.length > question.allowedAnswers + 1 || question.checked.length < 1){
            this.errorTriggered = true
            this.loopBreaked = true
            setTimeout(()=>{
              this.errorTriggered = false
            },1500)
             return
          } else {
            this.errorTriggered = false
            question.voters.push(localStorage.user_id)
            if ( question.checked.length == undefined ) {
              if ( question.answerField[question.checked.value - 1].votes == null){
                question.answerField[question.checked.value - 1].votes = []
              }
              question.answerField[question.checked.value - 1].votes.push(localStorage.user)
            } else {
              question.checked.forEach( (answer,index) => {
                if ( question.answerField[index].votes == null ) {
                  question.answerField[index].votes = []
                }
                question.answerField.forEach( (question, qn_index) => {
                  if(question == answer){
                    if ( question.votes == null ) {
                      question.votes = []
                    }
                    question.votes.push(localStorage.user)
                  }
                })
              })
            }
          }
        })
        if (!this.returnFun && !this.errorTriggered && !this.loopBreaked ) {
          let mindmap = {
          mindmap: { canvas: JSON.stringify(this.pollData) }
          }
          let id = this.currentMindMap.unique_key
          http.patch(`/msuite/${id}.json`,mindmap).then(res=>{
            _this.voted()
          })
        } else {
          this.errorTriggered = true
        }
      },
      voted(){
        this.pollData.Questions.forEach( question => {
            question.voters.forEach(voter => {
            if(voter == localStorage.user_id) this.returnFun = true
          })
        })
        if (this.returnFun) {
          this.returnFun = true
        } else this.returnFun = false
      },
    }
  };
</script>

<style scoped>
  @import './poll.css'
</style>
