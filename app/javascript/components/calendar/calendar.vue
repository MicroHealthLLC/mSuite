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
      <div id="calendar"></div>
    </div>
    <make-private-modal ref="make-private-modal" @password-apply="passwordProtect" @password_mismatched="$refs['passwordMismatched'].open()" :password="currentMindMap.password" :isSaveMSuite="isSaveMSuite"></make-private-modal>
    <delete-map-modal ref="delete-map-modal" @delete-mindmap="confirmDeleteMindmap"></delete-map-modal>
    <delete-password-modal ref="delete-password-modal" @deletePasswordCheck="deleteMindmapProtected"></delete-password-modal>
    <confirm-save-key-modal ref="confirm-save-key-modal" :current-mind-map="currentMindMap"></confirm-save-key-modal>
    <recurring-calendar-event-modal  :recurringEventsDate="recurringEventsDate" @continue="calendarRecurringEvents" ref="recurring-calendar-event-modal"></recurring-calendar-event-modal>
    <add-calendar-event-modal :eventDates="eventDates" ref="add-calendar-event-modal"></add-calendar-event-modal>
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
        eventDates: null
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
          else {}
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
          template: {
            locationPlaceholder() {
              return 'Description';
            }
          },
        })
        this.calendar.on('beforeCreateEvent', (eventObj) => {
          this.saveEvents(eventObj)
          this.calendar.createEvents([
            {
              ...eventObj
              }
            ])
          if (this.recurringEvents){
            this.generateRecurringEvents(eventObj)
          }
        })
        this.calendar.on('beforeUpdateEvent', (eventObj) => {
          this.calendar.updateEvent(eventObj.event.id, eventObj.event.calendarId, eventObj.changes);
        })
        this.calendar.on('beforeDeleteEvent', (eventObj) => {
          this.calendar.deleteEvent(eventObj.id, eventObj.calendarId);
        })
        this.calendar.on('selectDateTime', (eventObj) => {
          this.eventDates = eventObj
          this.$refs['add-calendar-event-modal'].$refs['AddCalendarEventModal'].open()
          this.calendar.clearGridSelections();
        });
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
      calculateRecurringEvents(){
        let val = document.getElementsByClassName("toastui-calendar-content")
        if (val[0].value && val[1].value){
          this.recurringEventsDate = val[3].value
          this.$refs['recurring-calendar-event-modal'].$refs['RecurringCalendarEventModal'].open()
        }
      },
      calendarRecurringEvents(events){
        this.recurringEvents = events
      },
      generateRecurringEvents(eventObj){
        let _this = this
        this.recurringEvents.forEach((currentValue, index, rEvents)=> {
          eventObj.start.d.d = currentValue
          eventObj.end.d.d = currentValue
          this.saveEvents(eventObj)
          this.calendar.createEvents([
            {
              ...eventObj
            }
          ])
        })
        this.recurringEvents = null 
      },
      addButton(){
        // this.$refs['add-calendar-event-modal'].$refs['AddCalendarEventModal'].open()
        // this.calendar.clearGridSelections();
        // setTimeout(()=>{
        //   const popupSec = document.getElementsByClassName("toastui-calendar-popup-section")[5]
        //   let moreOption = document.createElement("span")
        //   moreOption.id ="options"
        //   moreOption.innerText = "More options"
        //   moreOption.classList.add("toastui-calendar-popup-button")
        //   moreOption.classList.add("toastui-calendar-popup-confirm")
        //   moreOption.onclick = this.calculateRecurringEvents
        //   popupSec.appendChild(moreOption)
        // }, 400)
      },
      saveEvents(eventObj){
        let data = {
          title: eventObj.title,
          description: eventObj.location,
          startdate: eventObj.start.d.d,
          duedate: eventObj.end.d.d,
          is_disabled: eventObj.isAllday,
          line_color: eventObj.state,
          mindmap_id: this.currentMindMap.id
          }
        http.post(`/nodes.json`, data)
      },
      async fetchEvents(){
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
              calendarId: '',
              title: currentValue.title,
              start: currentValue.startdate,
              end: currentValue.duedate,
              location: currentValue.description,
              state: currentValue.line_color,
            }
          ])
        })
      }

    },
    mounted() {
      this.$cable.subscribe({ channel:"WebNotificationsChannel", room: this.currentMindMap.id })
      this.createCalendar()
      this.getCalendarTitle()
      if(this.calendar){
        setTimeout(()=>{
          if($(".toastui-calendar-daygrid-cell").length > 0){
            $(".toastui-calendar-daygrid-cell").each( (cellId, cell) => {
              cell.addEventListener("dblclick", this.addButton)
            } )
          }
        },10)
      }
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
