<template>
  <div class="container">
    <span class="heading d-block text-center">Your Dreams, With votes</span>
    <span v-if="showError" class="shake d-block text-center">
      All Fields are Required. Minimum Two answers are required
    </span>
    <div class="overflow-auto maxHeight">
      <div class="">
        <div class="form__group__parent field">
          <input
            type="input"
            v-model="poll.question"
            class="form__field"
            placeholder="Type Your Question Here..."
            @keydown.enter="updateQuestion"
            required />
          <label for="name" class="form__label">Question Please!</label>
        </div>
      </div>
      <div class="mt-5">
        <div v-for="(answer, index) in answerFields">
          <div class="row mt-4">
            <div class="form__group field">
              <input
                :id="'answer' + index"
                type="input"
                v-model="answer.text"
                class="form__field"
                placeholder="Type Your answer Here..."
                @keydown.enter="answers"
                required />
              <label for="name" class="form__label">Answer You Want</label>
            </div>
          </div>
        </div>
        <div class="mt-2 ml-2">
          <label class="toggle" for="uniqueID">
            <input type="checkbox" v-model="poll.showResult" class="toggle__input" id="uniqueID" />
            <span class="toggle-track">
              <span class="toggle-indicator">
                <!--  This check mark is optional  -->
                <span class="checkMark">
                  <svg viewBox="0 0 24 24" id="ghq-svg-check" role="presentation" aria-hidden="true">
                    <path d="M9.86 18a1 1 0 01-.73-.32l-4.86-5.17a1.001 1.001 0 011.46-1.37l4.12 4.39 8.41-9.2a1 1 0 111.48 1.34l-9.14 10a1 1 0 01-.73.33h-.01z"></path>
                  </svg>
                </span>
              </span>
            </span>
            Show Results
          </label>
        </div>
      </div>
      <div>
        <button
          class="btn btn-info mt-5 mx-auto d-block"
          @click="createPin">
          Create Poll
        </button>
      </div>
    </div>
    <sweet-modal ref="set_pin">
      <div class="">
        <div class="form__group__parent field">
          <input
            id="pin"
            type="input"
            ref="pin"
            v-model="poll.pin"
            class="form__field"
            :class="showError ? 'shake': ''"
            placeholder="your pin please"
            @blur="savePoll"
            @keyup.enter="savePoll"
            required />
          <label
            for="name"
            class="form__label"
            :class="showError ? 'shake': ''">
            Pin is required
          </label>
        </div>
      </div>
    </sweet-modal>
  </div>
</template>

<script>
  import http from "../../../common/http"

  export default {
    props:["pollData"],
    data () {
      return {
        poll: {
          question: '',
          answerField: [
            { value: 1, text: '', votes: null },
            { value: 2, text: '', votes: null }
          ],
          pin: '',
          voters: [],
          showResult: false
        },
        showError: false,
      }
    },
    computed: {
      answerFields(){
        return this.poll.answerField
      }
    },
    mounted() {
      if(this.pollData){
        this.poll = this.pollData
      }
    },
    watch: {
      pollData: {
        handler(value){
          this.poll = value
        }
      }
    },
    methods: {
      updateQuestion() {
        document.getElementById( 'answer' + (this.poll.answerField.length -1) ).focus()
      },
      answers() {
        if(this.poll.answerField.length >= 1){

          this.poll.answerField.push({
            value: this.poll.answerField.length + 1,
            text: '',
            votes: null
          })
          setTimeout(()=>{
            document.getElementById( 'answer' + (this.poll.answerField.length -1) ).focus()
          }, 250)
        }
      },
      createPin() {
        if(this.checkAllFields()){
          this.showError = true
          setTimeout(()=>{
            this.showError = false
          }, 2500)
          return
        }
        this.$refs['set_pin'].open()
        setTimeout(()=>{
          document.getElementById("pin").focus()
        }, 100)
      },
      savePoll() {
        if(this.checkPollPin()){
          this.showError = true
          setTimeout(()=>{
            this.showError = false
          }, 2500)
          return
        }
        this.$emit("updateVote" , this.poll)
        this.$refs['set_pin'].close()
      },
      checkAllFields(){
        this.poll.answerField.forEach( (answer,index) => {
          if ( this.answerFields.length > 2 ) {
            if(answer.text == '') this.poll.answerField.splice(index, 100)
          }
        })
        return this.poll.answerField.length < 2 || this.poll.question == '' || this.poll.question == undefined
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
<style>
  .maxHeight{
    height: 80vh;
  }
  .heading{
    font-weight: 500;
    font-size: 45px;
  }
  .shake {
    animation: shake 0.82s cubic-bezier(0.36, 0.07, 0.19, 0.97) both;
    transform: translate3d(0, 0, 0);
    color: #FC1B31 !important;
  }
  .shake:focus {
    border-width: 3px;
    border-image: linear-gradient(to right, #FC1B31, #A23E48);
    border-image-slice: 1;
  }
  @keyframes shake {
    10%,
    90% {
      transform: translate3d(-1px, 0, 0);
    }

    20%,
    80% {
      transform: translate3d(2px, 0, 0);
    }

    30%,
    50%,
    70% {
      transform: translate3d(-4px, 0, 0);
    }

    40%,
    60% {
      transform: translate3d(4px, 0, 0);
    }
  }
</style>
