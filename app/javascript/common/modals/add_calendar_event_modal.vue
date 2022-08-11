<template>
  <sweet-modal ref="AddCalendarEventModal" class="of_v">
    <div class="sweet_model_icon_div">
      <div class="radius_circle bg-warning center_flex mlr_a">
        <i class="material-icons text-white">delete</i>
      </div>
    </div>
    <h3 class="f_smooth_auto">Add Event</h3>
    <div>
      <div>
        Title 
        <input class="title" type="text" v-model="title"/>
      </div>
      <div>
        Description 
        <input class="title" type="text" v-model="description"/>
      </div>
      <div>
        Start
        <DatePicker v-model="startDate"></DatePicker>
        End
        <DatePicker v-model="endDate"></DatePicker>
      </div>
      <div>
        <input type="checkbox" value="true">
        <label for="vehicle1"> All Day</label>
      </div>
    </div>    
    <div class="center_flex mt_2">
      <a
        href="javascript:;"
        class="btn_2 bg-danger text-white mr_1"
        @click.stop=""
      >
        <i class="material-icons mr-1">done</i>
        Add
      </a>
      <a
        href="javascript:;"
        class="btn_2 bg-primary text-white mr_1"
      >
        <i class="material-icons mr-1">cancel</i>
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
    props:['eventDates'],
    data () {
      return{
        title: '',
        description: '',
        startDate: null,
        endDate: null,
        allDay: false,
        state: 'busy'
        
      }
    },
    components: { DatePicker },
    watch:{
      eventDates(newVal, oldVal){
        this.updateSelectedDate();
      }
    },
    methods: {
      closeMapModal() {
        this.$refs.AddCalendarEventModal.close()
      },
      updateSelectedDate(){
        this.startDate = this.eventDates.start
        this.endDate = this.eventDates.end
      }
    },
  }
</script>
<style>
.title{
  border: none;
  border-bottom: 1px solid;
  margin-bottom: 5px;
  padding: 2px;
}
</style>
