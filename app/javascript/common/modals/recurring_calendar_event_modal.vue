<template>
  <sweet-modal ref="RecurringCalendarEventModal" class="of_v">
    <div class="sweet_model_icon_div">
      <div class="radius_circle bg-warning center_flex mlr_a">
        <i class="material-icons text-white">delete</i>
      </div>
    </div>
    <h3 class="f_smooth_auto">Add Recurrence</h3>
    <div>
      <span>
        <p>Repeat Every <input type="number" v-model="repeatTime" min="1" max="100" class="w-10"/>
          <select name="repeat" id="repeat" v-model="repeatType">
            <option disabled value="">Select option</option>
            <option value="Week" >Week</option>
            <option value="Month">Month</option>
          </select>
        </p> 
      </span>
      <span>
        <p> Repeat on</p>
        <p>
          <span class="day">S</span>
          <span class="day">M</span>
          <span class="day">T</span>
          <span class="day">W</span>
          <span class="day">T</span>
          <span class="day">F</span>
          <span class="day">S</span>
        </p>
      </span>
      <span>
        <p>Ends</p>
      <div>
        <input type="radio" id="never" name="drone" value="never"checked v-model="endsOn">
        <label for="never">Never</label>
      </div>

    <div>
      <input type="radio" id="on" name="drone" value="on" v-model="endsOn">
      <label for="on">On</label>
      <date-picker 
        v-model="endOnDate" 
        :format="format"
      ></date-picker>
    </div>

    <div>
      <input type="radio" id="after" name="drone" value="after" v-model="endsOn">
      <label for="after">After</label>
      <input type="number" value="1" class="w-10" v-model="occurences"/> Occurences
    </div>
      </span>
    </div>    
    <div class="center_flex mt_2">
      <a
        href="javascript:;"
        class="btn_2 bg-danger text-white mr_1"
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
    data () {
      return{
        repeatTime: 1,
        repeatType: 'Week',
        endsOn: null,
        occurences: 1,
        endOnDate: new Date(),
        format: 'YYYY-MM-DD',
        events: []
      }
    },
    components: { DatePicker },
    methods: {
      calculateRecurrence() {
        let eventDate = new Date()
        if (this.repeatType == "Month"){
          this.calculateMonthRecurrence(eventDate)
        }
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
              newEvents.push(myDate)
              i = i + parseInt(this.repeatTime)
            }
          }
        }

        this.events = newEvents
      }
    }
  }
</script>
<style>
  .day{
  background-color:powderblue;
  border-radius: 50%;
  padding: 1vh 1vh;
  }
  .mx-datepicker-popup {
    z-index: 9001 !important;
  }
</style>
