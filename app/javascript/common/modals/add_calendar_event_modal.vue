<template>
  <sweet-modal ref="AddCalendarEventModal" class="of_v">
    <div class="sweet_model_icon_div">
      <div class="radius_circle bg-warning center_flex mlr_a">
        <i class="material-icons text-white">add</i>
      </div>
    </div>

    <!-- <div v-if="isSprint == true">
      <h3 v-if="actionType == 'update'" class="f_smooth_auto">Edit Sprint</h3>
      <h3 v-else class="f_smooth_auto">Add Sprint</h3>
    </div> -->

    <div>
      <h3 v-if="actionType == 'update'" class="f_smooth_auto">Edit Activity</h3>
      <h3 v-else class="f_smooth_auto">Add Activity</h3>
    </div>

    <!-- <div class="row">
      <div class="col-12 pr-0 pl-2 d-flex justify-content-center align-items-center">
        <div>
          <input type="radio" v-model="isSprint" :value="true" />
          <label class="form-label mt-2" for="checkbox">&nbsp;&nbsp;Sprint&nbsp;&nbsp;</label>
          <input type="radio" v-model="isSprint" :value="false" />
          <label class="form-label mt-2" for="checkbox">&nbsp;&nbsp;Event&nbsp;&nbsp;</label>
        </div>
        <div v-if="!isSprint" class="ml-4">
          <input type="checkbox" class="mr-2" v-model="standalone" style="transform: scale(0.8);" />
          <label class="form-label mt-2" for="checkbox" style="font-size: 0.8rem;">Don't include in sprints</label>
        </div>
      </div>
    </div> -->

    <div class="row">
      <div class="col-6 d-flex content-justified-start px-0" v-if="isSprint == false && multipleSprints.length > 0">
        <label class="form-label mt-2" for="checkbox">Related to:&nbsp;&nbsp;</label>
        <select v-if="actionType == 'update'" class="w-50 form-control" v-model="parentNode">
          <option v-for="sprint in multipleSprints.filter(s => s.id !== showEvent.id)" :value="sprint.id">
            {{ sprint.title }}
          </option>
          <option value="none">
            None
          </option>
        </select>
        <select v-else class="w-50 form-control" v-model="parentNode">
          <option v-for="sprint in multipleSprints" :value="sprint.id">
            {{ sprint.title }}
          </option>
          <option value="none">
            None
          </option>
        </select>
      </div>
    </div>

    <div class="w-100">
      <div class="row my-2">
        <input class="inputBox col-12" type="text" placeholder="Enter Title" v-model="title"
          :validateValues="validateValues" />
      </div>
      <div class="row my-2">
        <input class="inputBox col-12" type="text" placeholder="Enter Description" v-model="description" />
      </div>

      <div class="row mt-4">
        <div class="col-10 d-flex content-justified-start px-0" v-if="allDay">
          <label class="form-label mt-1">Start:</label>
          <DatePicker class="mx-2" type="date" format="MM/DD/YYYY" v-model="startDate"></DatePicker>
          <label class="form-label ml-4 mt-1">End:</label>
          <DatePicker class="mx-2" type="date" format="MM/DD/YYYY" v-model="endDate"></DatePicker>
        </div>
        <!-- <div class="col-10 d-flex content-justified-start px-0" v-else>
          <label class="form-label mt-1">Start</label>
          <DatePicker class="mx-1" format="MM/DD/YYYY HH:mm" type="datetime" :minute-options="datePickerMinutes" v-model="startDate"></DatePicker>
          <label class="form-label mt-1">End</label>
          <DatePicker class="mx-1" format="MM/DD/YYYY HH:mm" :minute-options="datePickerMinutes" type="datetime" v-model="endDate"></DatePicker>
        </div> -->
        <span v-else>
          <div class="col-10 d-flex content-justified-start px-0">
            <strong class="mt-1">Start: </strong>
            <div>
              <DatePicker class="mx-1" format="MM/DD/YYYY" type="date" v-model="startDate"></DatePicker>
            </div>
            <div>
              <DatePicker class="mx-2" format="HH:mm" :minute-options="datePickerMinutes" type="time" v-model="startDate">
              </DatePicker>
            </div>
          </div>

          <div class="col-10 d-flex content-justified-start px-0 mt-4">
            <strong class="mt-1">End: </strong>
            <div class="end-date-picker">
              <DatePicker class="mx-1" format="MM/DD/YYYY" type="date" v-model="endDate"></DatePicker>
            </div>
            <div>
              <DatePicker class="mx-2" format="HH:mm" :minute-options="datePickerMinutes" type="time" v-model="endDate">
              </DatePicker>
            </div>
          </div>
        </span>
        <div class="col-4 d-flex content-justified-start mt-2" v-if="allDayNotHidden">
          <input type="checkbox" v-model="allDay" v-if="!isSprint">
          <label class="form-label ml-2 mt-2" for="checkbox" style="white-space: nowrap;" v-if="!isSprint">All Day</label>
        </div>
      </div>



      <div class="row">
        <span class="text-danger">{{ errorMessage }}</span>
      </div>
    </div>
    <div class="center_flex mt_2">
      <a disabled href="javascript:;" class="calendar_btn btn_2 bg-success text-white mr_1" @click.stop="createEvent"
        v-if="actionType == 'create'">
        <i class="material-icons mr-1">done</i>
        Add
      </a>
      <a href="javascript:;" class="calendar_btn btn_2 bg-success text-white mr_1" @click.stop="updateEvent"
        v-if="actionType == 'update'">
        <i class="material-icons mr-1">update</i>
        Update
      </a>
      <a href="javascript:;" class="calendar_btn btn_2 bg-primary text-white mr_1" @click.stop="openRecurringEventModal">
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
  props: ['eventDates', 'showEvent', 'allEvents'],
  mixins: [Common],
  data() {
    return {
      multipleSprints: [],
      title: '',
      description: '',
      startDate: null,
      endDate: null,
      allDay: true,
      parentNode: null,
      actionType: '',
      allDayNotHidden: true,
      isValueInvalid: false,
      isSprint: false,
      standalone: false,
      errorMessage: '',
      invalidMessage: false,
      datePickerMinutes: [0, 15, 30, 45]

    }
  },
  components: { DatePicker },
  watch: {
    eventDates(newValue, oldValue) {
      //console.log("eventDates", newValue, oldValue)
      this.setDefaultValues()
      this.updateSelectedDate()
      this.allDay = true
      let selectedStart = new Date(newValue.start)
      let selectedEnd = new Date(newValue.end)
      if (selectedEnd - selectedStart > 86400000 && this.actionType == 'create') {
        let potentialChildren = this.allEvents.filter(event => new Date(event.startdate) >= selectedStart.setHours(0, 0, 0, 0) && new Date(event.duedate) <= selectedEnd.setHours(23, 59, 59, 999))
        if (potentialChildren.length > 0) {
          let sprints = potentialChildren.filter(c => c.is_sprint)
          if (sprints.length == 0) this.isSprint = true
        }
      }
      this.checkForParentNode()
    },
    showEvent: {
      handler(newValue, oldValue) {
        //console.log("showEvent", newValue, oldValue)
        this.setDefaultValues()
        this.showSelectedEvent('update')
        if (!newValue.raw.parentNode || newValue.raw.standalone) this.parentNode = 'none'
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
    allDay() {
      this.toggleAllDay
    },
    multipleSprints() {
      //console.log('multipleSprints',this.multipleSprints)
    },
    parentNode() {
      //console.log(this.parentNode)
    },
  },
  methods: {
    checkForParentNode() {
      if (!this.parentNode && this.multipleSprints && this.multipleSprints.length > 0) {
        if (!this.isSprint) this.parentNode = this.multipleSprints[0].id
        else this.isSprint = false
      } 
    },
    closeMapModal() {
      this.$refs.AddCalendarEventModal.close()
    },
    updateSelectedDate() {
      this.startDate = this.eventDates.start
      this.endDate = this.eventDates.end
      this.allDay = this.eventDates.isAllday
      this.actionType = 'create'
      let midnight = '12:00 am'
      if (midnight == moment(this.startDate).format("hh:mm a") && midnight == moment(this.endDate).format("hh:mm a") && this.eventDates.isAllday == false) {
        let hours = new Date().getHours()
        let minutes = new Date().getMinutes()
        this.startDate.setHours(hours)
        this.startDate.setMinutes(minutes)
        this.endDate.setHours(hours + 1)
        this.endDate.setMinutes(minutes)
      }
      this.disableEventCreation()
      this.checkForMultipleSprints(this.allEvents, this.startDate, this.endDate, this.allDay)
    },
    showSelectedEvent(actType) {
      this.title = this.showEvent.title
      this.description = this.showEvent.body
      this.startDate = this.showEvent.start.d.d
      this.endDate = this.showEvent.end.d.d
      this.allDay = this.showEvent.isAllday
      //console.log("showSelectedEvent", this.showEvent)
      this.standalone = this.showEvent.raw.standalone
      this.isSprint = this.showEvent.raw.isSprint
      this.parentNode = this.showEvent.raw.parentNode
      this.actionType = actType
      this.checkForMultipleSprints(this.allEvents, this.startDate, this.endDate, this.allDay)
    },
    generateDataObj() {
      let _this = this;
      let data = {
        title: _this.title,
        body: _this.description,
        start: _this.startDate,
        end: _this.endDate,
        isAllday: _this.allDay,
        raw: {
          isSprint: _this.isSprint,
          standalone: _this.standalone,
          parentNode: _this.parentNode,
        },
        //backgroundColor: _this.isSprint ? this.getRandomColor() : '#363636',
        id: null
      };

      if (this.actionType == 'update') {
        data.id = this.showEvent.id;
        //data.backgroundColor = this.showEvent.backgroundColor;
        if (data.raw.isSprint) {
          data.raw.parentNode = null
          data.raw.standalone = false
          if ((this.allEvents.filter(sprint => sprint.id !== data.id).map(x => x.line_color).includes(data.backgroundColor)) || data.backgroundColor === "#363636") {
            data.backgroundColor = this.getRandomColor()
          }
        }
      }
      if (data.isAllday) {
        data.start.setHours(0, 0, 0, 0)
        data.end.setHours(23, 59, 59, 999)
      }

      if (data.raw.parentNode) {
        data.raw.standalone = false
      }
      return data;
    },
    checkForMultipleSprints(nodeList, eventStart, eventEnd, allDay) {
      let eventList = []

      for (let i = 0; i < nodeList.length; i++) {
        const node = nodeList[i];
        const nodeStart = new Date(node.startdate);
        const nodeEnd = new Date(node.duedate);

        if (allDay) {
          nodeStart.setHours(0, 0, 0, 0)
          nodeEnd.setHours(23, 59, 59, 999)
        }

        // Check if the event falls within the date range of the node
        if (eventStart >= nodeStart && eventEnd <= nodeEnd) {
          eventList.push(node)
        }

        let sprintList = eventList.filter(e => e.is_sprint)

        if (sprintList && sprintList.length > 0) {
          this.multipleSprints = sprintList
        } else {
          this.multipleSprints = eventList
        }
      }

    },
    createEvent() {
      if (this.title && !this.isValueInvalid) {
        let data = this.generateDataObj()
        data.backgroundColor = data.raw.isSprint ? this.getRandomColor() : '#363636'
        this.$emit('createEvent', data)
        this.closeMapModal()
      }
    },
    updateEvent() {
      if (this.title && !this.isValueInvalid) {
        let data = this.generateDataObj()
        this.$emit('updateEvent', data, this.parentNode)
        this.closeMapModal()
      }
    },
    setDefaultValues() {
      this.title = ''
      this.description = ''
      this.startDate = null
      this.endDate = null
      this.allDay = false
      this.actionType = ''
      this.allDayNotHidden = true
      this.isSprint = false
      this.standalone = false
      this.parentNode = null
      this.multipleSprints = []
    },
    openRecurringEventModal() {
      if (this.title && !this.isValueInvalid) {
        let data = {
          start: this.startDate,
          end: this.endDate
        }
        this.$emit('openRecurringModal', data)
      }
    },
    disableEventCreation() {
      $(".calendar_btn").attr('disabled', 'disabled')
    },
    enableEventCreation() {
      $(".calendar_btn").removeAttr('disabled')
      if (!this.title && !this.description) {
        this.disableEventCreation()
      }
    }
  },
  computed: {
    toggleAllDay() {
      // Reset flags and variables
      this.isValueInvalid = false;
      let difference = this.getDateDifference(this.startDate, this.endDate);

      if (difference >= 0) {
        // Valid date range
        this.invalidMessage = false;
        this.allDayNotHidden = false;
        this.errorMessage = '';
      } else {
        // Invalid date range
        this.isValueInvalid = true;
        let startDateMonth = new Date(this.startDate).getMonth();
        let startDateDate = new Date(this.startDate).getDate();
        let startDateYear = new Date(this.startDate).getFullYear();
        let endDateMonth = new Date(this.endDate).getMonth();
        let endDateDate = new Date(this.endDate).getDate();
        let endDateYear = new Date(this.endDate).getFullYear();

        // Adjust end date to match start date if necessary
        if (endDateYear < startDateYear) {
          this.endDate.setFullYear(startDateYear);
        } else if (endDateMonth < startDateMonth) {
          this.endDate.setMonth(startDateMonth);
        } else if (endDateDate < startDateDate) {
          this.endDate.setDate(startDateDate);
        }
      }

      if (this.endDate <= this.startDate && !this.allDay) {
        // Invalid end time for same-day event
        this.isValueInvalid = true;
        let startDateHours = new Date(this.startDate).getHours();
        let startDateMinutes = new Date(this.startDate).getMinutes();

        // Set end time to start time + 1 hour
        this.endDate.setHours(startDateHours + 1);
        this.endDate.setMinutes(startDateMinutes);
        if (this.endDate > this.startDate) {
          this.isValueInvalid = false
        }
      } else {
        // Valid end time or multiple-day event
        this.errorMessage = '';
        this.invalidMessage = false;
        this.isValueInvalid = false;
      }

      // Show allDayNotHidden field
      this.allDayNotHidden = true;
    },
    toggleAllDays() {
      this.isValueInvalid = false
      let difference = this.getDateDifference(this.startDate, this.endDate)
      if (difference > 0) {
        this.invalidMessage = false
        this.allDayNotHidden = false
        this.errorMessage = ''
      }
      else if (difference < 0) {
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
      else {
        if ((this.endDate - this.startDate) <= 0 && this.allDay == false) {
          this.isValueInvalid = true
          let startDateHours = new Date(this.startDate).getHours()
          let startDateMinutes = new Date(this.startDate).getMinutes()

          this.endDate.setHours(startDateHours + 1)
          this.endDate.setMinutes(startDateMinutes)
        }
        else {
          this.errorMessage = ''
          this.invalidMessage = false
          this.isValueInvalid = false
        }
        this.allDayNotHidden = true
      }
    },
    validateValues() {
      if (this.title && !this.isValueInvalid && this.startDate != null && this.endDate != null) {
        this.enableEventCreation()
      }
      else {
        this.disableEventCreation()
      }
    }
  }
}
</script>
<style>
.inputBox {
  border: none;
  border-bottom: 1px solid;
  margin-bottom: 5px;
  padding: 2px;
  width: 100%;
}

input:focus {
  outline: none;
}

.end-date-picker {
  margin-left: 6px;
}
</style>
