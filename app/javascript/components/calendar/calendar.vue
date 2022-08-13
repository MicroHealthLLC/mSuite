<template>
  <div>
    <navigation-bar
      @mSuiteTitleUpdate="mSuiteTitleUpdate"
      @openPrivacy="openPrivacy"
      @deleteMindmap="deleteMap"
      @resetMindmap="resetMindmap"
      :current-mind-map="currentMindMap"
      :defaultDeleteDays="defaultDeleteDays"
      :expDays="expDays"
      :deleteAfter="deleteAfter"
      :exportId="'calendar'"
      :isEditing="isEditing"
      :saveElement="saveElement"
      ref="calendarNavigation">
    </navigation-bar>
    <div id="cal">
      <div>
        <button @click="toggleCalendarView('month')">Month</button>
        <button @click="toggleCalendarView('week')">Week</button>
        <button @click="toggleCalendarView('day')">Day</button>
      </div>
      <div>
        <button @click="moveCalendar(-1)">Previous</button>
        <span>{{this.calendarTitle}}</span>
        <button @click="moveCalendar(1)">Next</button>
      </div>
      <div class="editPopup" v-if="showEditEvent">
        <div>
          <button @click="editEventModal">edit</button>
          <button @click="deleteEvents">delete</button>
          <button @click="showEditEvent = false">cross</button>
        </div>
        <div>{{this.showEvent.title}}</div>
        <div>{{this.showEvent.start.d.d}}</div>
        <div>{{this.showEvent.body}}</div>
        <div>{{this.showEvent.state}}</div>
      </div>
      <div id="calendar"></div>
    </div>
    <make-private-modal ref="make-private-modal" @password-apply="passwordProtect" @password_mismatched="$refs['passwordMismatched'].open()" :password="currentMindMap.password" :isSaveMSuite="isSaveMSuite"></make-private-modal>
    <delete-map-modal ref="delete-map-modal" @delete-mindmap="confirmDeleteMindmap"></delete-map-modal>
    <delete-password-modal ref="delete-password-modal" @deletePasswordCheck="deleteMindmapProtected"></delete-password-modal>
    <confirm-save-key-modal ref="confirm-save-key-modal" :current-mind-map="currentMindMap"></confirm-save-key-modal>
    <add-calendar-event-modal :eventDates="eventDates" :showEvent="showEvent" @createEvent="beforeCreateEvent" @updateEvent="updateEvent" @openRecurringModal="openRecurringEventsModal" ref="add-calendar-event-modal"></add-calendar-event-modal>
    <recurring-calendar-event-modal  :recurringEventsDate="recurringEventsDate" @continue="getRecurringEventsDate" ref="recurring-calendar-event-modal"></recurring-calendar-event-modal>
    <sweet-modal ref="passwordMismatched" class="of_v" icon="error" title="Password Mismatch">
      Your Password and Confirm Password are Mismatched, Please Try Again!
      <button slot="button" @click="passwordAgain" class="btn btn-warning mr-2">Try Again</button>
      <button slot="button" @click="$refs['passwordMismatched'].close()" class="btn btn-secondary">Cancel</button>
    </sweet-modal>
    <sweet-modal ref="errorModal" class="of_v" icon="error" title="Password Error">
      Incorrect Password, Please Try Again!
    </sweet-modal>
    <sweet-modal ref="successModal" class="of_v" icon="success">
      Password updated successfully!
    </sweet-modal>
  </div>
</template>
<script>
  import http from "../../common/http"
  import domtoimage from "dom-to-image-more"
  import DeleteMapModal from '../../common/modals/delete_modal';
  import MakePrivateModal from "../../common/modals/make_private_modal"
  import DeletePasswordModal from '../../common/modals/delete_password_modal';
  import RecurringCalendarEventModal from '../../common/modals/recurring_calendar_event_modal';
  import AddCalendarEventModal from '../../common/modals/add_calendar_event_modal';
  import Calendar from '@toast-ui/calendar';
  import '@toast-ui/calendar/dist/toastui-calendar.min.css';
  import 'tui-date-picker/dist/tui-date-picker.css';
  import 'tui-time-picker/dist/tui-time-picker.css';
  import { uuid } from 'vue-uuid';
  import Chance from 'chance'

  export default {
    props: ['currentMindMap','defaultDeleteDays','deleteAfter','expDays'],
    data() {
      return {
        isReset: false,
        isEditing: false,
        saveElement: true,
        calendar: null,
        calendarTitle: null,
        recurringEvents: null,
        recurringEventsDate: null,
        fetchedEvents:[],
        eventDates: null,
        showEvent: null,
        showEditEvent: false,
        counter: 0
      }
    },
    components: {
      DeleteMapModal,
      DeletePasswordModal,
      MakePrivateModal,
      RecurringCalendarEventModal,
      AddCalendarEventModal

    },
    channels: {
      WebNotificationsChannel: {
        received(data) {
          if (data.message === "Mindmap Deleted" && this.currentMindMap.id === data.mindmap.id)
          {
            window.open('/','_self')
          } else if (data.message === "Password Updated" && this.currentMindMap.id === data.mindmap.id) {
            setTimeout(() => {
              location.reload()
            }, 500)
          }
          else if(data.message === "Reset mindmap" && this.currentMindMap.id === data.mindmap.id){
            
          }
          else if(data.message === "Mindmap Updated" && this.currentMindMap.id === data.mindmap.id){
          }
          else {
            if (this.counter < 1){
              this.calendar.store.getState().calendar.events.internalMap.clear()
              this.fetchEvents()
            }
          }
        }
      }
    },
    methods: {
      openPrivacy(val) {
        this.isSaveMSuite = val
        this.$refs['make-private-modal'].$refs['makePrivateModal'].open()
      },
      deleteMap() {
        this.$refs['delete-map-modal'].$refs['deleteMapModal'].open()
      },
      confirmDeleteMindmap() {
        if (this.currentMindMap.password){
          this.$refs['delete-password-modal'].$refs['DeletePasswordModal'].open()
        } else {
          this.deleteMindmap()
        }
      },
      deleteMindmapProtected(password) {
        http
        .delete(`/msuite/${this.currentMindMap.unique_key}.json?password_check=${password}`)
        .then(res=>{
          if (!res.data.success && this.currentMindMap.password)
            this.$refs['errorModal'].open()
        })
        .catch(error => {
          console.log(error)
        })
      },
      deleteMindmap() {
        http
        .delete(`/msuite/${this.currentMindMap.unique_key}.json`)
        .then(res => {
          window.open("/", "_self")
        })
        .catch(error => {
          console.log(error)
        })
      },
      passwordProtect(new_password, old_password, is_mSuite) {
        http
        .patch(`/msuite/${this.currentMindMap.unique_key}.json`,{mindmap:{password: new_password, old_password: old_password}})
        .then(res => {
          if (res.data.mindmap) {
            this.currentMindMap.password = res.data.mindmap.password
            if(!is_mSuite) window.open("/", "_self")
            else location.reload()
            this.$refs['successModal'].open()
          } else {
            if (res.data.error) this.$refs['errorModal'].open()
          }
        })
      },
      passwordAgain() {
        this.$refs['passwordMismatched'].close()
        this.openPrivacy()
      },
      resetMindmap() {
        this.isReset = true
        http.get(`/msuite/${this.currentMindMap.unique_key}/reset_mindmap.json`)
      },
      getUuid(){
        let id = uuid.v1()
        return id
      },
      createCalendar(){
        const container = document.getElementById('calendar');
        this.calendar = new Calendar('#calendar', {
          usageStatistics: false,
          defaultView: 'month',
          useFormPopup: false,
          useDetailPopup: false,
          gridSelection: {
            enableDblClick: true,
            enableClick: false,
          },
          week: {
            taskView: false,
          },
          })
        this.calendar.on('selectDateTime', (eventObj) => {
          this.showEditEvent = false
          this.eventDates = eventObj
          this.$refs['add-calendar-event-modal'].$refs['AddCalendarEventModal'].open()
          this.recurringEvents = null
          this.calendar.clearGridSelections()
        })
        this.calendar.on('clickEvent', (eventObj) => {
          
          this.showEvent = eventObj.event
          this.showEditEvent = true
        })
      },
      toggleCalendarView(value){
        this.calendar.changeView(value);
      },
      moveCalendar(value){
        this.calendar.move(value)
        this.getCalendarTitle()
      },
      getCalendarTitle(){
        var calendarDate = new Date(this.calendar.getDate())
        var getMonthName =  new Intl.DateTimeFormat("en-US", { month: "long" }).format
        this.calendarTitle = getMonthName(calendarDate)+ ' ' + calendarDate.getFullYear()
      },
      openRecurringEventsModal(){
          this.recurringEventsDate = this.eventDates.end
          this.$refs['recurring-calendar-event-modal'].$refs['RecurringCalendarEventModal'].open()
      },
      getRecurringEventsDate(events){
        
        this.recurringEvents = events
      },
      generateRecurringEvents(eventObj){
        this.recurringEvents.forEach((currentValue, index, rEvents)=> {
          eventObj.start = currentValue
          eventObj.end = currentValue
          this.saveEvents(eventObj)
        })
        
        this.recurringEvents = null 
      },
      beforeCreateEvent(data){
        this.counter = 0
        this.saveEvents(data)
          if (this.recurringEvents){
            this.generateRecurringEvents(data)
          }
      },
      editEventModal(){
        this.counter = 0
        this.$refs['add-calendar-event-modal'].$refs['AddCalendarEventModal'].open()
      },
      saveEvents(eventObj){
        let data = {
          title: eventObj.title,
          description: eventObj.body,
          startdate: eventObj.start,
          duedate: eventObj.end,
          is_disabled: eventObj.isAllday,
          line_color: eventObj.state,
          mindmap_id: this.currentMindMap.id
          }
        http.post(`/nodes.json`, data)
      },
      updateEvent(eventObj){
        this.showEditEvent = false
        this.eventDates = eventObj.end
        let data = {
          title: eventObj.title,
          description: eventObj.body,
          startdate: eventObj.start,
          duedate: eventObj.end,
          is_disabled: eventObj.isAllday,
          line_color: eventObj.state,
          }
        http.put(`/nodes/${eventObj.id}`, data);
      },
      deleteEvents(){
        this.showEditEvent = false
        http.delete(`/nodes/${this.showEvent.id}.json`)
      },
      async fetchEvents(){
        this.counter = this.counter + 1
        let mindmap_key = window.location.pathname.split('/')[2]
        let response = await http.get(`/msuite/${mindmap_key}.json`)
        this.defaultDeleteDays = response.data.defaultDeleteDays
        this.deleteAfter = response.data.deleteAfter
        this.expDays = response.data.expDays
        this.currentMindMap = response.data.mindmap
        this.fetchedEvents = response.data.mindmap.nodes
        this.renderEvents()
      },
      renderEvents(){
        this.fetchedEvents.forEach((currentValue, index, rEvents)=> {
          this.calendar.createEvents([
            {
              id: currentValue.id,
              title: currentValue.title,
              start: currentValue.startdate,
              end: currentValue.duedate,
              body: currentValue.description,
              state: currentValue.line_color,
            }
          ])
        })
        this.fetchedEvents = []
      }

    },
    mounted() {
      this.$cable.subscribe({ channel:"WebNotificationsChannel", room: this.currentMindMap.id })
      this.createCalendar()
      this.getCalendarTitle()
      this.fetchEvents()
    }
  }
</script>
<style>
  #calendar{
    height:70vh;
  }
  #options{
    padding: 6px 1px 1px 1px;
    background-color:MediumSeaGreen;
    float: left;
  }
</style>
