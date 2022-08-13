<template>
  <sweet-modal ref="AddCalendarEventModal" class="of_v">
    <div class="sweet_model_icon_div">
      <div class="radius_circle bg-warning center_flex mlr_a">
        <i class="material-icons text-white">add</i>
      </div>
    </div>
    <h3 class="f_smooth_auto">Add Event</h3>
    <div>
      <div>
        <input class="inputBox" type="text" placeholder="Enter Title" v-model="title"/>
      </div>
      <div>
        <input class="inputBox" type="text" placeholder="Enter Description" v-model="description"/>
      </div>
      <div>
        Start
        <DatePicker type="datetime" v-model="startDate"></DatePicker>
        End
        <DatePicker type="datetime" v-model="endDate"></DatePicker>
      </div>
      <div>
        <input type="checkbox" v-model="allDay">
        <label for="checkbox"> All Day</label>
      </div>
      <div>
        <select name="state" v-model="state">
            <option disabled value="">Select option</option>
            <option value="Busy">Busy</option>
            <option value="Free">Free</option>
          </select>
      </div>
    </div>    
    <div class="center_flex mt_2">
      <a
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
        state: '',
        actionType:''
        
      }
    },
    components: { DatePicker },
    watch:{
      eventDates(newVal, oldVal){
        this.setDefaultValues()
        this.updateSelectedDate()
      },
      "showEvent.id"(newVal, oldVal){
        this.setDefaultValues()
        this.showSelectedEvent()
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
      },
      showSelectedEvent(){
        this.title = this.showEvent.title
        this.description = this.showEvent.body
        this.startDate = this.showEvent.start.d.d
        this.endDate = this.showEvent.end.d.d
        this.allDay = this.showEvent.isAllday
        this.state = this.showEvent.state
        this.actionType = 'update'
      },
      generateDataObj(){
        if (this.title && this.description && this.state){
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
        }
      },
      createEvent(){
          this.$emit('createEvent', this.generateDataObj())
          this.closeMapModal()
      },
      updateEvent(){
        this.$emit('updateEvent', this.generateDataObj())
        this.closeMapModal()
      },
      setDefaultValues(){
        this.title = '',
        this.description = '',
        this.startDate = null,
        this.endDate = null,
        this.allDay = false,
        this.state = ''
        this.actionType = ''
      },
      openRecurringEventModal(){
        if (this.title && this.description && this.state){
          this.$emit('openRecurringModal')
        }
      }
    },
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
