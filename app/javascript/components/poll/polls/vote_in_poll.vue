<template>
  <div class="container mt-2" id="poll">
    <vue-poll v-bind="myOpt" @addvote="addVote"/>
  </div>
</template>
<script>
  import VuePoll from 'vue-poll'
  export default{
    props:["pollData"],
    components: {
      VuePoll
    },
    computed: {
      myOpt(){
        return this.options = {
          question: `<strong> ${this.pollData.question} </strong>`,
          answers: this.pollData.answerField,
          showResults: true
        }
      }
    },
  }
</script>
<style>

</style>
