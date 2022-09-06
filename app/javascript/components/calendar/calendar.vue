<template>
  <div>
    <navigation-bar
      @mSuiteTitleUpdate="mSuiteTitleUpdate"
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
    <div id="cal" class="row">
      <div class="col-9 d-flex px-5" @click="showEditEvent = false">
        <span class="py-2 pl-2">
          <a
            href="javascript:;"
            role="button"
            class="d-flex text-info pointer mr-3"
            @click.prevent="moveCalendar(-1)"
          >
            <i class="fa fa-solid fa-less-than d-flex"></i>
          </a>
        </span>
        <span class="p-1 text-info">{{this.calendarTitle}}</span>
        <span class="p-2">
          <a
            href="javascript:;"
            role="button"
            class="d-flex text-info pointer mr-3"
            @click.prevent="moveCalendar(1)"
          >
            <i class="fa fa-solid fa-greater-than d-flex"></i>
          </a>
        </span>
      </div>
      <div class="col-3 text-info d-flex justify-content-end pr-5" @click="showEditEvent = false">
        <select id="calendarFormat" class="form-control w-50" @change="toggleCalendarView()">
          <option selected value="month">Month</option>
          <option value="week"> Week </option>
          <option value="day"> Day </option>
        </select>
      </div>
      <div class="col-12 px-5" id="calendar"></div>
    </div>
    <b-popover target="calendar" :show.sync="showEditEvent" class="editPopup" v-if="showEditEvent">
      <div class="w-100 mr-4">
        <div class="row d-flex flex-row-reverse my-3">
          <span
            @click="showEditEvent = false"
            role="button"
            class="material-icons col-1 px-0 text-danger"
            >
            close</span>
          <span
            @click="editEventModal"
            role="button"
            class="material-icons col-2 pl-0 text-secondary"
            >
            edit</span>
          <span
            @click="deleteEvents"
            role="button"
            class="material-icons col-2"
            >
            delete</span>
        </div>
        <div class="row mb-1 font-weight-medium h5">{{showEvent.title}}</div>
        <div class="row mb-4">{{formatshowEventDate()}}</div>
        <div class="row my-2">{{showEvent.body}}</div>
      </div>
    </b-popover>
    <add-calendar-event-modal 
      :eventDates="eventDates"
      :showEvent="showEvent" 
      @createEvent="beforeEventCreate" 
      @updateEvent="beforeEventUpdate" 
      @openRecurringModal="openRecurringEventsModal" 
      ref="add-calendar-event-modal">
    </add-calendar-event-modal>
    <recurring-calendar-event-modal 
      :recurringEvents="recurringEvents"  
      :recurringEventsDate="recurringEventsDate" 
      @continue="getRecurringEventsDate" 
      ref="recurring-calendar-event-modal">
    </recurring-calendar-event-modal>
  </div>
</template>
<script>
  import http from "../../common/http"
  import domtoimage from "dom-to-image-more"
  import RecurringCalendarEventModal from '../../common/modals/recurring_calendar_event_modal';
  import AddCalendarEventModal from '../../common/modals/add_calendar_event_modal';
  import Calendar from '@toast-ui/calendar';
  import '@toast-ui/calendar/dist/toastui-calendar.min.css';
  import 'tui-date-picker/dist/tui-date-picker.css';
  import 'tui-time-picker/dist/tui-time-picker.css';
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
        counter: 0,
        createEventDate: null
      }
    },
    components: {
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
            this.currentMindMap = data.mindmap
            this.calendar.destroy()
            this.createCalendar()
          }
          else if(data.message === "Mindmap Updated" && this.currentMindMap.id === data.mindmap.id){
            this.currentMindMap = data.mindmap
          }
          else if(data.message === "Node is updated" && this.currentMindMap.id === data.node.mindmap_id){
              this.calendar.store.getState().calendar.events.internalMap.clear()
              this.fetchEvents()
          }
          else if( data.message === "Event Trigger" ) {
            this.eventNotifications(data.node.title)
          }
          else {
            this.calendar.store.getState().calendar.events.internalMap.clear()
            this.fetchEvents()
          }
        }
      }
    },
    methods: {
      resetMindmap() {
        this.isReset = true
        http.get(`/msuite/${this.currentMindMap.unique_key}/reset_mindmap.json`)
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
            eventView: true
          },
          })
        this.calendar.on('selectDateTime', (eventObj) => {
          this.showEditEvent = false
          eventObj.end.setSeconds(1)
          this.eventDates = eventObj
          this.createEventDate = eventObj.end
          this.$refs['add-calendar-event-modal'].$refs['AddCalendarEventModal'].open()
          this.recurringEvents = null
          this.calendar.clearGridSelections()
        })
        this.calendar.on('clickEvent', (eventObj) => {
          this.showEvent = eventObj.event
          this.showEditEvent = true
        })
        this.calendar.on('beforeUpdateEvent', (eventObj) => {
          let data = eventObj.event
          if (eventObj.changes.start){
            data.start = eventObj.changes.start.d.d
          }
          data.end = eventObj.changes.end.d.d
            if (this.counter == 0){
              this.updateEvent(data)
            }
            this.counter = this.counter + 1
        });
      },

      toggleCalendarView(){
        let value = document.getElementById("calendarFormat").value;
        this.calendar.changeView(value);
      },
      moveCalendar(value){
        this.showEditEvent = false
        this.calendar.move(value)
        this.getCalendarTitle()
      },
      getCalendarTitle(){
        var calendarDate = new Date(this.calendar.getDate())
        var getMonthName =  new Intl.DateTimeFormat("en-US", { month: "long" }).format
        this.calendarTitle = getMonthName(calendarDate)+ ' ' + calendarDate.getFullYear()
      },
      openRecurringEventsModal(data){
        this.recurringEvents = null
        this.recurringEventsDate = data.end
        this.$refs['recurring-calendar-event-modal'].$refs['RecurringCalendarEventModal'].open()
      },
      getRecurringEventsDate(events){
        this.recurringEvents = events
      },
      generateRecurringEvents(eventObj){
        let time = {
          startHours: eventObj.start.getHours(),
          startMinutes: eventObj.start.getMinutes(),
          startSeconds: eventObj.start.getSeconds(),
          endHours: eventObj.end.getHours(),
          endMinutes: eventObj.end.getMinutes(),
          endSeconds: eventObj.end.getSeconds(),
          }
        this.recurringEvents.forEach((currentValue, index, rEvents)=> {
          currentValue.setHours(time.startHours)
          currentValue.setMinutes(time.startMinutes)
          currentValue.setSeconds(time.startSeconds)
          eventObj.start = new Date(currentValue)
          currentValue.setHours(time.endHours)
          currentValue.setMinutes(time.endMinutes)
          currentValue.setSeconds(time.endSeconds)
          eventObj.end = new Date(currentValue)
          this.saveEvents(eventObj)
        })
        this.recurringEvents = null
      },
      beforeEventCreate(data){
        this.counter = 0
        this.saveEvents(data)
        if(this.recurringEvents) this.generateRecurringEvents(data)
      },
      beforeEventUpdate(data){
        this.updateEvent(data)
        if(this.recurringEvents) this.generateRecurringEvents(data)
      },
      editEventModal(){
        this.counter = 0
        this.$refs['add-calendar-event-modal'].$refs['AddCalendarEventModal'].open()
      },
      saveEvents(eventObj){
        eventObj.start = new Date(eventObj.start)
        eventObj.end = new Date(eventObj.end)

        let data = {
          title: eventObj.title,
          description: eventObj.body,
          startdate: eventObj.start,
          duedate: eventObj.end,
          is_disabled: eventObj.isAllday,
          line_color: eventObj.state,
          mindmap_id: this.currentMindMap.id
          }
        http.post('/nodes.json', data)
      },
      updateEvent(eventObj){
        eventObj.start = new Date(eventObj.start)
        eventObj.end = new Date(eventObj.end)
        let dateTwoUTC = Date.UTC(
          eventObj.end.getFullYear(),
          eventObj.end.getMonth(),
          eventObj.end.getDate()
        )
        let dateOneUTC = Date.UTC(
          eventObj.start.getFullYear(),
          eventObj.start.getMonth(),
          eventObj.start.getDate()
        )
        let diffrence = dateTwoUTC - dateOneUTC
        diffrence = diffrence/(1000 * 60 * 60 * 24)

        if (diffrence > 0) eventObj.isAllday = true
        this.showEditEvent = false
        let data = {
          title: eventObj.title,
          description: eventObj.body,
          startdate: eventObj.start,
          duedate: eventObj.end,
          is_disabled: eventObj.isAllday,
          line_color: eventObj.state,
          }
        http.put(`/nodes/${eventObj.id}`, data)
      },
      deleteEvents(){
        this.showEditEvent = false
        http.delete(`/nodes/${this.showEvent.id}.json`)
      },
      async fetchEvents(){
        this.counter = 0
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
        if(this.fetchedEvents.length == 0){
          this.calendar.destroy()
          this.createCalendar()
        }
        this.calendar.store.getState().calendar.events.internalMap.clear()
        this.counter = 0
        this.fetchedEvents.forEach((currentValue, index, rEvents)=> {
          if (currentValue.is_disabled){
            currentValue.startdate = new Date(currentValue.startdate)
            currentValue.duedate = new Date(currentValue.duedate)
          }
          this.calendar.createEvents([
            {
              id: currentValue.id,
              title: currentValue.title,
              start: currentValue.startdate,
              end: currentValue.duedate,
              body: currentValue.description,
              state: currentValue.line_color,
              isAllday: currentValue.is_disabled
            }
          ])
        })
        this.fetchedEvents = []
      },
      formatshowEventDate(){
        var showDate = new Date(this.showEvent.start.d.d)
        var getMonthName =  new Intl.DateTimeFormat("en-US", { month: "long" }).format
        showDate = showDate.toLocaleDateString('en-us', { weekday: 'long' }) + ' ' + getMonthName(showDate)+ ' ' + showDate.getDate() + ' ' + showDate.getFullYear()
        return showDate
      },
      async eventNotifications(title){
        const reg = await navigator.serviceWorker.getRegistration();
        Notification.requestPermission().then(permission => {
          if (permission !== 'granted') {
            alert('you need to allow push notifications');
          } else {
            reg.showNotification(
              'mSuite Calendar',
              {
                tag: title,
                body: title,
                data: {
                  url: window.location.href,
                },
                badge: '/assets/msuite.png',
                icon: '/favicon.ico',
              }
            );
          }
        });
      }
    },
    mounted() {
      this.$cable.subscribe({ channel:"WebNotificationsChannel", room: this.currentMindMap.id })
      this.createCalendar()
      this.getCalendarTitle()
      this.fetchEvents()
      var el = document.querySelector('#calendar');
        el.addEventListener("mouseleave", function( event ) {
          this.showEditEvent = false
        });
    }
  }
</script>
<style>
  @import "./calendar.scss";
</style>
