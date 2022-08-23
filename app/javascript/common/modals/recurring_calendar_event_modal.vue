<template>
  <sweet-modal ref="RecurringCalendarEventModal" class="of_v">
    <div class="sweet_model_icon_div">
      <div class="radius_circle bg-info center_flex mlr_a">
        <i class="material-icons text-white">event_repeat</i>
      </div>
    </div>
    <h3 class="f_smooth_auto">Add Recurrence</h3>
    <div class="w-100">
      <div class="row  my-2">
        <span class="col-3 d-flex align-items-center mt-1 pr-0">
          <label class="form-label ">Repeat Every</label>
        </span>
        <span class="col-9 d-flex px-0">
          <input type="number" v-model="repeatTime" min="1" max="100" class="w-25 mx-2 form-control"/>
          <select name="repeat" id="repeat" class="w-50 form-control" v-model="repeatType">
            <option disabled value="">Select option</option>
            <option value="Week" >Week</option>
            <option value="Month">Month</option>
          </select>
        </span>
      </div>
      <div class="row my-2 mt-4">
        <span class="col-3 d-flex align-items-center pr-0">
          Repeat on
        </span>
        <span class="col-9 d-flex content-justified-start pl-1">
          <span class="day ml-1" id="0">S</span>
          <span class="day ml-1" id="1">M</span>
          <span class="day ml-1" id="2">T</span>
          <span class="day ml-1" id="3">W</span>
          <span class="day ml-1" id="4">T</span>
          <span class="day ml-1" id="5">F</span>
          <span class="day ml-1" id="6">S</span>
        </span>
      </div>
      <div class="row my-2 mt-4">
        <span class="col-12 form-label d-flex content-justified-start font-weight-bold">
          Ends
        </span>
      </div>
      <div class="row my-2">  
        <span class="col-1 d-flex ">
          <input type="radio" id="never" class="form-control" name="drone" value="never"checked v-model="endsOn">
        </span>
        <span class="col-11 d-flex content-justified-start px-0 mt-2">
          <label for="never" class="form-label">Never</label>
        </span>
      </div>
      <div class="row my-2">
        <span class="col-1">
          <input type="radio" id="on" class="form-control" name="drone" value="on" v-model="endsOn">
        </span>
        <span class="col-1 pb-0 mt-2 px-0 d-flex content-justified-start">
          <label for="on" class="form-label">On</label>
        </span>
          <span class="col-6 mt-1 d-flex content-justified-start align-items-center ml-2">
          <date-picker :disabled="endsOn !='on'" v-model="endOnDate" :format="format"></date-picker>
        </span>
      </div>
      <div class="row my-2">
        <span class="col-1">
            <input type="radio" class="form-control" id="after" name="drone" value="after" v-model="endsOn">
        </span>
        <span class="col-1 mt-2 px-0 d-flex content-justified-start">
          <label for="after" class="form-label">After</label>
        </span>
          <span class="col-3 ml-2 d-flex content-justified-start">  
            <input :disabled="endsOn !='after'" class="form-control" type="number" value="1" v-model="occurences"/>
          </span>
          <span class="col-1 mt-2 px-0">
            Occurences
          </span>
      </div>  
    </div>
    <div class="center_flex mt_2">
      <a
        href="javascript:;"
        class="btn_2 bg-success text-white mr_1"
        @click.stop="calculateRecurrence"
      >
        <i class="material-icons mr-1">done</i>
        Continue
      </a>
      <a
        href="javascript:;"
        class="btn_2 bg-primary text-white mr_1"
        @click.stop="closeMapModal"
      >
        <i class="material-icons mr-1">cancel</i>
        Cancel
      </a>
    </div>
  </sweet-modal>
</template>

<script>
  import DatePicker from 'vue2-datepicker';
  import 'vue2-datepicker/index.css';

  export default {
    Name: "RecurringCalendarEventModal",
    props: ['recurringEventsDate'],
    data () {
      return{
        repeatTime: 1,
        repeatType: 'Week',
        endsOn: 'never',
        occurences: 1,
        endOnDate: null,
        format: 'YYYY-MM-DD',
        events: []
      }
    },
    components: { DatePicker },
    watch:{
      recurringEventsDate(newVal, oldVal){
        this.endOnDate = newVal
        this.showDay(newVal.getDay())
      }
    },
    methods: {
      calculateRecurrence() {
        this.events = []
        let eventDate = new Date(this.recurringEventsDate)
        if (this.repeatType == "Month"){
          this.calculateMonthRecurrence(eventDate)
        }
        else{
          this.calculateWeekRecurrence(eventDate)
        }
        this.$emit('continue', this.events)
        this.setDefaultValues()
        this.closeMapModal()
      },
      closeMapModal() {
        this.$refs.RecurringCalendarEventModal.close()
      },
      calculateMonthRecurrence(eventDate){
        let newEvents = []
        let i = 0
        let myDate = null
        if (this.endsOn == "never"){
          while(12-i >=this.repeatTime){
            myDate = new Date(eventDate.setMonth(eventDate.getMonth() + parseInt(this.repeatTime)))
            newEvents.push(myDate)
            i = i + parseInt(this.repeatTime)
          }
        }
        else if(this.endsOn == "on"){
          if (this.endOnDate.getTime() > eventDate.getTime()){
            while(12-i >=this.repeatTime){
              myDate = new Date(eventDate.setMonth(eventDate.getMonth() + parseInt(this.repeatTime)))
              if (myDate.getTime() > this.endOnDate.getTime()){
                break
              }
              newEvents.push(myDate)
              i = i + parseInt(this.repeatTime)
            }
          }
        }
        else{
          let count = 0
          while(12-i >=this.repeatTime){
            if (count == this.occurences){
              break
            }
            myDate = new Date(eventDate.setMonth(eventDate.getMonth() + parseInt(this.repeatTime)))
            newEvents.push(myDate)
            i = i + parseInt(this.repeatTime)
            count++
          }
        }
        this.events = newEvents
      },
      calculateWeekRecurrence(eventDate){
        let newEvents = []
        let i = 0
        let myDate = null
        if (this.endsOn == "never"){
          while(52-i >=this.repeatTime){
            myDate = new Date(eventDate.setDate(eventDate.getDate() + parseInt(this.repeatTime)*7 ))
            newEvents.push(myDate)
            i = i + parseInt(this.repeatTime)
          }
        }
        else if(this.endsOn == "on"){
          if (this.endOnDate.getTime() > eventDate.getTime()){
            while(52-i >=this.repeatTime){
              myDate = new Date(eventDate.setDate(eventDate.getDate() + parseInt(this.repeatTime)*7 ))
              if (myDate.getTime() > this.endOnDate.getTime()){
                break
              }
              newEvents.push(myDate)
              i = i + parseInt(this.repeatTime)
            }
          }
        }
        else{
          let count = 0
          while(12-i >=this.repeatTime){
            if (count == this.occurences){
              break
            }
            myDate = new Date(eventDate.setDate(eventDate.getDate() + parseInt(this.repeatTime)*7 ))
            newEvents.push(myDate)
            i = i + parseInt(this.repeatTime)
            count++
          }
        }
        this.events = newEvents
      },
      setDefaultValues(){
        this.repeatTime = 1
        this.repeatType = 'Week'
        this.endsOn = 'never'
        this.occurences = 1
        this.format = 'YYYY-MM-DD'
        this.events = []
      },
      showDay(val){
        $('.day').css('background-color' ,'rgb(51, 144, 255)')
        $('#' + val).css('background-color', 'rgb(4, 63, 133)')
      }
    }
  }
</script>
<style>
  .day {
    font-weight: bold;
    color: white;
    border-radius: 50%;
    padding: 1vh 1vh;
    height: 5vh;
    width: 5vh;
    display: inline-block;
  }
  .mx-datepicker-popup {
    z-index: 9001 !important;
  }
</style>
