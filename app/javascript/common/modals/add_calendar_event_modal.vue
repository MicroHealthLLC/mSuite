<template>
  <sweet-modal ref="AddCalendarEventModal" class="of_v">
    <div class="sweet_model_icon_div">
      <div class="radius_circle bg-warning center_flex mlr_a">
        <i class="material-icons text-white">add</i>
      </div>
    </div>
    <h3 class="f_smooth_auto">Add Event</h3>
    <div class="w-100">
      <div class="row my-2">
        <input class="inputBox col-12" type="text" placeholder="Enter Title" v-model="title" :validateValues="validateValues"/>
      </div>
      <div class="row my-2">
        <input class="inputBox col-12" type="text" placeholder="Enter Description" v-model="description"/>
      </div>
      <div class="row">
        <div class="col-10 d-flex content-justified-start px-0" v-if="allDay">
          <label class="form-label mt-1">Start</label>
          <DatePicker class="mx-1" type="date" v-model="startDate"></DatePicker>
          <label class="form-label mt-1">End</label>
          <DatePicker class="mx-1" type="date" v-model="endDate"></DatePicker>
        </div>
        <div class="col-10 d-flex content-justified-start px-0" v-else>
          <label class="form-label mt-1">Start</label>
          <DatePicker class="mx-1" type="datetime" v-model="startDate"></DatePicker>
          <label class="form-label mt-1">End</label>
          <DatePicker class="mx-1" type="datetime" v-model="endDate"></DatePicker>
        </div>
        <div class="col-2 pr-0 pl-2 d-flex content-justified-start" v-if="allDayNotHidden" >
          <input type="checkbox" class="mr-2" v-model="allDay">
          <label class="form-label mt-2" for="checkbox">All Day</label>
        </div>
      </div>
      <div v-if="" class="row">
        <span class="text-danger">{{errorMessage}}</span>
      </div>
      <div class="row w-25 py-2">
        <select name="state" class="form-control" v-model="state">
            <option disabled value="">Select option</option>
            <option value="Busy">Busy</option>
            <option value="Free">Free</option>
          </select>
      </div>
    </div>    
    <div class="center_flex mt_2">
      <a
        disabled
        href="javascript:;"
        class="btn_2 bg-success text-white mr_1"
        @click.stop="createEvent"
        v-if="actionType == 'create'"
      >
        <i class="material-icons mr-1">done</i>
        Add
      </a>
      <a
        href="javascript:;"
        class="btn_2 bg-success text-white mr_1"
        @click.stop="updateEvent"
        v-if="actionType == 'update'"
      >
        <i class="material-icons mr-1">update</i>
        Update
      </a>
      <a
        href="javascript:;"
        class="btn_2 bg-primary text-white mr_1"
        @click.stop="openRecurringEventModal"
      >
        <i class="material-icons mr-1">unfold_more_double</i>
        More Options
      </a>
    </div>
  </sweet-modal>
</template>

<script>
  import DatePicker from 'vue2-datepicker';
  import 'vue2-datepicker/index.css';

  export default {
    Name: "AddCalendarEventModal",
    props:['eventDates','showEvent'],
    data () {
      return{
        title: '',
        description: '',
        startDate: null,
        endDate: null,
        allDay: false,
        state: 'Busy',
        actionType: '',
        allDayNotHidden: true,
        isValueInvalid: false,
        errorMessage: '',
        invalidMessage: false
      }
    },
    components: { DatePicker },
    watch:{
      eventDates(newValue, oldValue){
        this.setDefaultValues()
        this.updateSelectedDate()
      },
      showEvent: {
        handler(newValue, oldValue) {
          this.setDefaultValues()
          this.showSelectedEvent('update')
        },
        deep: true
      },
      startDate: {
        handler(newValue, oldValue) {
        this.toggleAllDay
        },
        deep: true
      },
      endDate: {
        handler(newValue, oldValue) {
        this.toggleAllDay
        },
        deep: true
      },
      allDay(){
        this.toggleAllDay
      }
    },
    methods: {
      closeMapModal() {
        this.$refs.AddCalendarEventModal.close()
      },
      updateSelectedDate(){
        this.startDate = this.eventDates.start
        this.endDate = this.eventDates.end
        this.actionType = 'create'
        this.disableEventCreation()
      },
      showSelectedEvent(actType){
        this.title = this.showEvent.title
        this.description = this.showEvent.body
        this.startDate = this.showEvent.start.d.d
        this.endDate = this.showEvent.end.d.d
        this.allDay = this.showEvent.isAllday
        this.state = this.showEvent.state
        this.actionType = actType
      },
      generateDataObj(){
        let data = {
            title: this.title,
            body: this.description,
            start: this.startDate,
            end: this.endDate,
            isAllday: this.allDay,
            state: this.state,
            id: null
          }
        if(this.actionType == 'update') data.id = this.showEvent.id
        return data
      },
      createEvent(){
          if (this.title && this.description && !this.isValueInvalid ){
            this.$emit('createEvent', this.generateDataObj())
            this.closeMapModal()
          }
      },
      updateEvent(){
          if (this.title && this.description && !this.isValueInvalid){
            this.$emit('updateEvent', this.generateDataObj())
            this.closeMapModal()
          }
      },
      setDefaultValues(){
        this.title = ''
        this.description = ''
        this.startDate = null
        this.endDate = null
        this.allDay = false
        this.state = 'Busy'
        this.actionType = ''
        this.allDayNotHidden = true
      },
      openRecurringEventModal(){
        if (this.title && this.description && this.state && !this.isValueInvalid){
          let data = {
            start: this.startDate,
            end: this.endDate
          }
          this.$emit('openRecurringModal',data)
        }
      },
      disableEventCreation(){
        $(".btn_2").attr('disabled','disabled')
      },
      enableEventCreation(){
        $(".btn_2").removeAttr('disabled')
        if (!this.title && !this.description){
          this.disableEventCreation()
        }
      }
    },
    computed: {
      toggleAllDay(){
        this.isValueInvalid = false
        let dateTwoUTC = Date.UTC(
          this.endDate.getFullYear(),
          this.endDate.getMonth(),
          this.endDate.getDate()
        )
        let dateOneUTC = Date.UTC(
          this.startDate.getFullYear(),
          this.startDate.getMonth(),
          this.startDate.getDate()
        )
        let diffrence = dateTwoUTC - dateOneUTC
        diffrence = diffrence/(1000 * 60 * 60 * 24)
        if (diffrence > 0){
          this.invalidMessage = false
          this.allDayNotHidden = false
          this.errorMessage = ''
          this.allDay = true
        }
        else if(diffrence < 0){
          this.isValueInvalid = true
          this.errorMessage = 'End Date is Less Than Start Date'
          this.invalidMessage = true
        }
        else{
          if ((this.endDate - this.startDate) <= 0 && this.allDay == false ){
            this.isValueInvalid = true
            this.errorMessage = 'Event End Time Should Be Greater Than Event Start Time'
            this.invalidMessage = true
          }
          else{
            this.errorMessage = ''
            this.invalidMessage = false
          }
          this.allDayNotHidden = true
        }
      },
      validateValues(){
        if (this.title && this.description && !this.isValueInvalid){
          this.enableEventCreation()
        }
        else{
          this.disableEventCreation()
        }
      }
    }
  }
</script>
<style>
.inputBox{
  border: none;
  border-bottom: 1px solid;
  margin-bottom: 5px;
  padding: 2px;
  width: 100%;
}
input:focus {
  outline: none;
  }
</style>
