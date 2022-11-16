<template>
  <sweet-modal ref="AddCalendarEventModal" class="of_v">
    <div class="sweet_model_icon_div">
      <div class="radius_circle bg-warning center_flex mlr_a">
        <i class="material-icons text-white">add</i>
      </div>
    </div>
    <h3 v-if="actionType == 'update'" class="f_smooth_auto">Edit Event</h3>
    <h3 v-else class="f_smooth_auto">Add Event</h3>
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
          <DatePicker class="mx-1" type="date" format="MM/DD/YYYY" v-model="startDate"></DatePicker>
          <label class="form-label mt-1">End</label>
          <DatePicker class="mx-1" type="date" format="MM/DD/YYYY" v-model="endDate"></DatePicker>
        </div>
        <div class="col-10 d-flex content-justified-start px-0" v-else>
          <label class="form-label mt-1">Start</label>
          <DatePicker class="mx-1" format="MM/DD/YYYY HH:mm" type="datetime" :minute-options="datePickerMinutes" v-model="startDate"></DatePicker>
          <label class="form-label mt-1">End</label>
          <DatePicker class="mx-1" format="MM/DD/YYYY HH:mm" :minute-options="datePickerMinutes" type="datetime" v-model="endDate"></DatePicker>
        </div>
        <div class="col-2 pr-0 pl-2 d-flex content-justified-start" v-if="allDayNotHidden" >
          <input type="checkbox" class="mr-2" v-model="allDay">
          <label class="form-label mt-2" for="checkbox">All Day</label>
        </div>
      </div>
      <div class="row">
        <span class="text-danger">{{errorMessage}}</span>
      </div>
    </div>    
    <div class="center_flex mt_2">
      <a
        disabled
        href="javascript:;"
        class="calendar_btn btn_2 bg-success text-white mr_1"
        @click.stop="createEvent"
        v-if="actionType == 'create'"
      >
        <i class="material-icons mr-1">done</i>
        Add
      </a>
      <a
        href="javascript:;"
        class="calendar_btn btn_2 bg-success text-white mr_1"
        @click.stop="updateEvent"
        v-if="actionType == 'update'"
      >
        <i class="material-icons mr-1">update</i>
        Update
      </a>
      <a
        href="javascript:;"
        class="calendar_btn btn_2 bg-primary text-white mr_1"
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
  import Common from "../../mixins/common.js"
  export default {
    Name: "AddCalendarEventModal",
    props:['eventDates','showEvent'],
    mixins: [Common],
    data () {
      return{
        title:             '',
        description:       '',
        startDate:         null,
        endDate:           null,
        allDay:            false,
        actionType:        '',
        allDayNotHidden:   true,
        isValueInvalid:    false,
        errorMessage:      '',
        invalidMessage:    false,
        datePickerMinutes: [0,15,30,45]

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
        this.validateValues
        },
        deep: true
      },
      endDate: {
        handler(newValue, oldValue) {
        this.toggleAllDay
        this.validateValues
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
        this.endDate   = this.eventDates.end
        this.allDay    = this.eventDates.isAllday
        this.actionType = 'create'
        let midnight = '12:00 am'
        if (midnight == moment(this.startDate).format("hh:mm a") && midnight == moment(this.endDate).format("hh:mm a") && this.eventDates.isAllday == false){
          let hours   = new Date().getHours()
          let minutes = new Date().getMinutes()
          this.startDate.setHours(hours)
          this.startDate.setMinutes(minutes)
          this.endDate.setHours(hours + 1)
          this.endDate.setMinutes(minutes)
        }
        this.disableEventCreation()
      },
      showSelectedEvent(actType){
        this.title = this.showEvent.title
        this.description = this.showEvent.body
        this.startDate = this.showEvent.start.d.d
        this.endDate = this.showEvent.end.d.d
        this.allDay = this.showEvent.isAllday
        this.actionType = actType
      },
      generateDataObj(){
        let _this = this
        let data = {
            title: _this.title,
            body: _this.description,
            start: _this.startDate,
            end: _this.endDate,
            isAllday: _this.allDay,
            backgroundColor:'#18A2B8',
            id: null
          }
        if(this.actionType == 'update'){
          data.id = this.showEvent.id
          data.backgroundColor = this.showEvent.backgroundColor
        } 
        return data
      },
      createEvent(){
        if (this.title && !this.isValueInvalid ){
          this.$emit('createEvent', this.generateDataObj())
          this.closeMapModal()
        }
      },
      updateEvent(){
        if (this.title && !this.isValueInvalid){
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
        this.actionType = ''
        this.allDayNotHidden = true
      },
      openRecurringEventModal(){
        if (this.title && !this.isValueInvalid){
          let data = {
            start: this.startDate,
            end: this.endDate
          }
          this.$emit('openRecurringModal',data)
        }
      },
      disableEventCreation(){
        $(".calendar_btn").attr('disabled','disabled')
      },
      enableEventCreation(){
        $(".calendar_btn").removeAttr('disabled')
        if (!this.title && !this.description){
          this.disableEventCreation()
        }
      }
    },
    computed: {
      toggleAllDay(){
        this.isValueInvalid = false
        let difference = this.getDateDifference(this.startDate,this.endDate)
        if (difference > 0){
          this.invalidMessage = false
          this.allDayNotHidden = false
          this.errorMessage = ''
        }
        else if(difference < 0){
          /* this.isValueInvalid = true
          this.errorMessage = 'End Date is Less Than Start Date'
          this.invalidMessage = true */
          this.isValueInvalid = true
          let startDateMonth = new Date(this.startDate).getMonth()
          let startDateDate = new Date(this.startDate).getDate()
          let startDateYear = new Date(this.startDate).getYear()
          let endDateMonth = new Date(this.endDate).getMonth()
          let endDateDate = new Date(this.endDate).getDate()
          let endDateYear = new Date(this.endDate).getYear()

          if (endDateYear - startDateYear < 0) {
            this.endDate.setYear(startDateYear + 1900)
          } else if (endDateMonth - startDateMonth < 0) {
            this.endDate.setMonth(startDateMonth)
          } else if (endDateDate - startDateDate < 0) {
            this.endDate.setDate(startDateDate)
          }
        }
        else{
          if ((this.endDate - this.startDate) <= 0 && this.allDay == false ){
            /* this.isValueInvalid = true
            this.errorMessage = 'Event End Time Should Be Greater Than Event Start Time'
            this.invalidMessage = true */
            this.isValueInvalid = true
            let startDateHours = new Date(this.startDate).getHours()
            let startDateMinutes =  new Date(this.startDate).getMinutes()
            
            this.endDate.setHours(startDateHours + 1)
            this.endDate.setMinutes(startDateMinutes)
          }
          else{
            this.errorMessage = ''
            this.invalidMessage = false
            this.isValueInvalid = false
          }
          this.allDayNotHidden = true
        }
      },
      validateValues(){
        if (this.title && !this.isValueInvalid && this.startDate != null && this.endDate != null){
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
