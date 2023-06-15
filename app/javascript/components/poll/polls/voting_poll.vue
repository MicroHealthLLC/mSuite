<template>
  <div>
    <div id="poll-vote">
      <div class="container overflow-auto maxHeight" v-if="validForVote && !returnFun">
        <h3 id="poll-title" class="d-none"><strong>{{ currentMindMap.title }}</strong></h3>
        <span>{{ pollData.description }}</span>
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
            class="ml-4"
            :class="errorTriggered ? 'shake d-block border-danger':''">
            Allowed selectable options: {{ questions.allowedAnswers }}
          </span>
          <div class="mt-2 ml-4" v-for="(answers, index) in questions.answerField">
            <input
              v-if="questions.allowedAnswers > 1"
              type="checkbox"
              :name="questions.question"
              :value="answers"
              v-model="questions.checked"
              :disabled="questions.checked.length >= questions.allowedAnswers && questions.checked.indexOf(answers) == -1"
              @click="checkCheckedAns($event)" />
            <input
              v-else
              type="radio"
              :name="questions.question"
              :value="answers"
              v-model="questions.checked"
              @click="checkCheckedAns($event)" />
            <span>
              {{ answers.text }}
            </span>
          </div>
        </div>
        <div class="mt-4">
          <el-button
            round
            type="success"
            class="mt-4 py-1 px-3"
            @click="submitVote">
            SUBMIT
          </el-button>
          <el-button
            round
            type="warning"
            class="text-white ml-4 mt-4 py-1 px-3"
            @click="resetData">RESET</el-button>
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
              {{ msg }}
            </strong>
          </h4>
      </section>
    </div>
  </div>
</template>

<script>
  import http from "../../../common/http"
  import TemporaryUser from "../../../mixins/temporary_user.js"
  
  export default {
    name: "Poll",
    mixins: [TemporaryUser],
    data() {
      return {
        currentMindMap: this.$store.getters.getMsuite,
        msg: 'Your response has been recorded, Thanks for your Time.',
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
          if ( (data.message === "Mindmap Deleted" || data.message === "Reset mindmap") && this.currentMindMap.parent_id === data.mindmap.id)
          {
            window.open('/','_self')
          }
          else if (data.message === "Mindmap Updated" && this.currentMindMap.parent_id === data.mindmap.id){
            this.$store.commit('setMsuiteParent', data.mindmap)
            let poll = JSON.parse(data.mindmap.canvas).pollData
            this.voted(poll)
            if(!this.returnFun){
              this.pollData.Questions.forEach((question, index) => {
                poll.Questions[index].checked = question.checked
              })
            this.pollData = poll
            }
          }
        }
      }
    },
    mounted: async function(){
      if(this.currentMindMap) {
        this.pollData = await JSON.parse(this.currentMindMap.parent.canvas).pollData
        this.subscribeCable(this.currentMindMap.parent_id)
        this.$store.dispatch('setExportId', 'poll-vote')
        this.voted()
        if(!this.returnFun){
          this.resetData()
        }
        if (this.pollData.duedate == '' || this.pollData.duedate == undefined) this.validForVote = true
        else if (new Date() < new Date(this.pollData.duedate)) this.validForVote = true
        else this.validForVote = false
        this.pollExpDate = moment(new Date(this.pollData.duedate)).format('DD MMM YYYY')
        if (this.pollExpDate == 'Invalid date') this.pollExpDate = "Never"
      }
    },
    updated(){
      if(this.pollData.voters) this.pollData.voters.forEach(voter => {
        if(voter == this.$store.state.user_id) this.returnFun = true
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

          if (question.checked.length > question.allowedAnswers || question.checked.length < 1){
            this.errorTriggered = true
            this.loopBreaked = true
            setTimeout(()=>{
              this.errorTriggered = false
            },1500)
             return
          } else {
            this.errorTriggered = false
            this.loopBreaked = false
            question.voters.push(this.$store.state.user_id)
            if ( question.checked.length == undefined ) {
              if ( question.answerField[question.checked.value - 1].votes == null){
                question.answerField[question.checked.value - 1].votes = []
              }
              question.answerField[question.checked.value - 1].votes.push(this.$store.state.user)
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
                    question.votes.push(this.$store.state.user)
                  }
                })
              })
            }
          }
        })
        if ( !this.returnFun && !this.errorTriggered && !this.loopBreaked){

          let mycanvas = {
            pollData  : this.pollData,
            user      : this.$store.getters.getUser
          }
          mycanvas = JSON.stringify(mycanvas)
          let mindmap = { mindmap: { canvas: mycanvas } }

          http.patch(`/msuite/${this.currentMindMap.parent.unique_key}`, mindmap).then(res =>{
            _this.voted()
          })
        } else {
          this.errorTriggered = true
        }
      },
      voted(poll){
        let voteData = this.pollData
        if (poll) voteData = poll
        voteData.Questions.forEach( question => {
          if (question.voters.length > 0){
            question.voters.forEach(voter => {
              if(voter == this.$store.state.user_id) this.returnFun = true
            })
          } else {
            this.returnFun = false
          }
        })
        if (this.returnFun) {
          this.returnFun = true
        } else this.returnFun = false
      },
      checkCheckedAns(event){
        if(event.target.checked) event.target.setAttribute("checked", "checked")
        else event.target.removeAttribute("checked")
      },
    }
  };
</script>
<style lang="scss" scoped>
  @import './poll.scss';
</style>
