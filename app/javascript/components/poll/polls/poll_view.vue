<template>
  <section v-if="dataLoaded" class="container">
    <div v-if="!returnFun">
      <h4><strong>{{pollData.question}}</strong></h4>
      <ul>
        <li
          v-for="option in pollData.answerField"
          :key="option.id"
          :class="{ selected: selectedOption.value == option.value }"
          @click="vote(option)"
        >
          {{option.text}}
        </li>
        <button
          class="btn btn-success bg-color mx-auto d-block py-2 px-5 "
          @click="submitVote()"
        >
          Submit Vote
        </button>
      </ul>
    </div>
    <div v-else>
      <h4>
        <strong>
        Your response has been recorded, Sit tight and wait for results.
        </strong>
      </h4>
    </div>
    <sweet-modal ref="errorModal" class="of_v" icon="info" title="Vote Error">
      Your response has already been recorded, Sit tight and wait for results.
    </sweet-modal>
  </section>
</template>

<script>
  export default {
    name: "Poll",
    props: ["pollData","voters"],
    data() {
      return {
        selectedOption: {},
        dataLoaded: false,
        returnFun: false
      };
    },
    mounted(){
      if(this.pollData) this.dataLoaded = true
    },
    updated(){
      if(this.pollData.voters) this.pollData.voters.forEach(voter => {
        if(voter == localStorage.user_id) this.returnFun = true
      })
    },
    methods: {
      vote(option) {
        this.selectedOption = option;
      },
      submitVote(){
        if(this.pollData.voters) this.pollData.voters.forEach(voter => {
          if(voter == localStorage.user_id) this.returnFun = true
        })
        if (this.returnFun) {
          this.$refs['errorModal'].open()
          return
        }
        this.pollData.voters.push(localStorage.user_id)
        this.pollData.answerField[this.selectedOption.value -1].votes =  this.pollData.answerField[this.selectedOption.value -1].votes + 1
        this.$emit("updateVote", this.pollData)
      }
    }
  };
</script>

<style scoped>
  section {
    padding: 10px 25px;
    border-radius: 6px;
    box-shadow: 0 10px 24px rgba(0, 0, 0, 0.2);
    width: 40%;
    display: flex;
    flex-direction: column;
    justify-content: center;
    border-top: 5px solid purple;
  }

  h4 {
    font-family: poiret-one, sans-serif;
    text-transform: uppercase;
    font-size: 16px;
    letter-spacing: 0.7px;
    margin-bottom: 30px;
  }

  ul {
    list-style: none;
    padding-left: 0;
  }

  li {
    padding: 22px 17px;
    border: 1px solid rgba(0, 0, 0, 0.1);
    margin-bottom: 15px;
    border-radius: 6px;
    cursor: pointer;
  }

  li.selected {
    border-left: 5px solid purple;
  }

  .bg-color {
    background: linear-gradient(to right, #AB9AFD, #3F96FF) !important;
  }
  .btn:focus {
    outline: none;
    box-shadow: none;
  }

</style>
