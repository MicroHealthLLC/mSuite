<template>
  <div>
    <sweet-modal ref="timeModal" class="of_v" hide-close-button blocking>
      <div id="pomodoro">
        This Mindmap is temporarily Locked.
        <div id="clock">
          <div id="timer">
            <span id="title">Please Wait</span>
            <div id="countdown">
              <span id="minutes"></span>
              <span id="seconds"></span>
            </div>
          </div>
        </div>
      </div>
      <button slot="button" @click="goHome" class="btn btn-secondary">Home Page</button>
    </sweet-modal>
  </div>
</template>

<script>
  import $ from 'jquery'
  export default {
    data() {
      return {
        time       : 0,
        delayTime  : 0,
        displayTime: 0,
        S_lockTime : Vue.prototype.$lockout_period,
        lockTime   : this.$store.getters.getMsuite.lockout_period,
        computeTime: null,
      }
    },
    mounted() {
      this.time = new Date(new Date(this.lockTime).getTime() + parseInt(this.S_lockTime) * 60 * 1000)
      this.delayTime = (new Date(this.time).getTime() - new Date().getTime()) / 60 / 1000
      this.displayTime = new Date().getTime() + new Date(this.delayTime * 60 * 1000).getTime()
      this.computeTime = Math.abs((new Date().getTime() - this.displayTime) / 1000)
      this.countdownTimer()
      this.$refs['timeModal'].open()
    },
    methods: {
      goHome() {
        window.open(`/`, "_self")
      },
      countdownTimer(){
        let _this = this
        $(() => {

        let $theme = $(".theme"),
            $minutes = $("#minutes"),
            $seconds = $("#seconds"),
            $start = $("#start"),
            sessionLength = 30 * 60,
            sessionMax = 60,
            sessionMin = 5,
            countdown,
            remainingTime = sessionLength;

        init();

        function init(){
          start(_this.computeTime);
        }
        function start(timeLeft){
          clearInterval(countdown);
          countdown = setInterval(() => {
            timeLeft--;
            remainingTime = timeLeft
            let minLeft = Math.floor(timeLeft / 60),
                secLeft = parseInt(Math.ceil(timeLeft - minLeft * 60))
            if(minLeft <= 0 && secLeft <= 1) {
              updateMindmap()
            } else {
              updateMinutes(minLeft)
              updateSeconds(secLeft < 10 ? "0" + secLeft : secLeft)
            }
          }, 1000);
        }
        function updateMinutes(num){
          $minutes.text(num);
        }
        function updateSeconds(num){
          $seconds.text(num);
        }
        function updateMindmap(){
          _this.$store.dispatch('updateMSuite', {mindmap: {failed_password_attempts: 0}})
          location.reload()
        }
      });
      }
    },
  }
</script>
<style type="text/css" lang="scss" scoped>
  @import "../common/styles/temporarily_locked.scss"
</style>
