<template>
  <div>
    <navigation-bar
      ref="navigationBar"
      @resetMindmap="resetMindmap"
      @sendLocals="sendLocals"
      @undoMindmap="undoEvent"
      @redoMindmap="redoEvent"
      :current-mind-map="currentMindMap"
      :exportId="'cal'"
      :isEditing="isEditing"
      :saveElement="saveElement"
      :temporaryUser="temporaryUser"
      :userList="userList">
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
            <i class="fas fa-less-than d-flex"></i>
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
            <i class="fas fa-greater-than d-flex"></i>
          </a>
        </span>
      </div>
      <div class="col-3 text-info d-flex justify-content-end pr-5" @click="showEditEvent = false">
        <select id="calendarFormat" v-model="currentView" class="form-control w-50" @change="toggleCalendarView()">
          <option value="month">Month</option>
          <option value="week"> Week </option>
          <option value="day"> Day </option>
        </select>
      </div>
      <div class="col-12 px-5" id="calendar" ></div>
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
  import Common from "../../mixins/common.js"
  import TemporaryUser from "../../mixins/temporary_user.js"
  import moment from 'moment';

  export default {
    mixins: [Common, TemporaryUser],
    data() {
      return {
        currentMindMap: this.$store.state.mSuite,
        isReset:             false,
        isEditing:           false,
        saveElement:         true,
        calendar:            null,
        calendarTitle:       null,
        recurringEvents:     null,
        recurringEventsDate: null,
        fetchedEvents:       [],
        eventDates:          null,
        showEvent:           null,
        showEditEvent:       false,
        createEventDate:     null,
        userList:            [],
        temporaryUser:       '',
        currentView:         'month',
        undoNodes:           [],
        redoNodes:           [],
        undoDone:            false
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
          else if ( data.message === "storage updated" && this.currentMindMap.id == data.content.mindmap_id) {
            this.temporaryUser = data.content.userEdit
            this.userList.push(data.content.userEdit)
            localStorage.userList = JSON.stringify(this.userList);
            this.isEditing = data.isEditing
            if (!this.isEditing) {
              this.saveElement = true
              setTimeout(()=>{
                this.saveElement = false
              },1200)
            }
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
        this.undoNodes = []
        this.redoNodes = []
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
          template: {
            monthMoreClose(){
              return '<i class="material-icons text-danger">close</i>';
            },
            monthMoreTitleDate(moreTitle) {
              let {ymd} = moreTitle
              ymd = moment(ymd).format("MMM D");
              return `<span>${ymd}</span>`;
            },
          }
          })
        this.calendar.on('selectDateTime', (eventObj) => {
          this.showEditEvent = false
          if(this.currentView =='month') eventObj.isAllday = false
          else if(this.findDateTimeMinutes(eventObj.start, eventObj.end) == 30){
            eventObj.end.setMinutes(eventObj.end.getMinutes() + 30)
          }
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
          let difference = this.getDateDifference(data.start,eventObj.changes.end.d.d)
          if (difference == 0){
            if ((eventObj.changes.end.d.d - data.start) <= 0 && data.isAllday == false ){
              eventObj.changes.end.d.d.setHours(0)
              eventObj.changes.end.d.d.setMinutes(0)
              data.start.setHours(0)
              data.start.setMinutes(0)
              data.isAllday = true
            }
          }
          data.end = eventObj.changes.end.d.d
          this.updateEvent(data)
        })
      },
      findDateTimeMinutes(start, end){
        var startTime = moment(start, 'DD-MM-YYYY hh:mm:ss');
        var endTime = moment(end, 'DD-MM-YYYY hh:mm:ss');
        return endTime.diff(startTime, 'minutes');
      },
      toggleCalendarView(){
        let selectElement = document.getElementById('calendarFormat')
        selectElement.forEach((currentValue)=>{
          currentValue.removeAttribute('selected')
        })
        this.currentView = $("#calendarFormat").val();
        $('#calendarFormat option:selected').attr("selected","true")
        this.calendar.changeView(this.currentView);
        let calendarStore = this.calendar.store.getState().calendar.events.internalMap
        if ((this.currentView == 'week' || this.currentView == 'day') && calendarStore.size !=0 ){
          calendarStore.clear()
          this.fetchEvents()
        }
      },
      moveCalendar(value){
        this.showEditEvent = false
        this.calendar.move(value)
        this.getCalendarTitle()
      },
      getCalendarTitle(){
        var calendarDate = new Date(this.calendar.getDate())
        this.calendarTitle = moment(calendarDate).format("MMMM YYYY");
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
        this.saveEvents(data)
        if(this.recurringEvents) this.generateRecurringEvents(data)
      },
      beforeEventUpdate(data){
        this.updateEvent(data)
        if(this.recurringEvents) this.generateRecurringEvents(data)
      },
      editEventModal(){
        this.$refs['add-calendar-event-modal'].$refs['AddCalendarEventModal'].open()
      },
      async updateCalendarUser(){
        await http.put(`/msuite/${this.currentMindMap.unique_key}`, {
           canvas: localStorage.userEdit
          });
      },
      saveEvents(eventObj){
        this.sendLocals(true)
        eventObj.start = new Date(eventObj.start)
        eventObj.end = new Date(eventObj.end)
        let data = {
          title: eventObj.title,
          description: eventObj.body,
          startdate: eventObj.start,
          duedate: eventObj.end,
          is_disabled: eventObj.isAllday,
          mindmap_id: this.currentMindMap.id
          }
        this.updateCalendarUser()
        http.post('/nodes.json', data).then((result) => {
          this.undoNodes.push({req: 'addNode', receivedData: result.data.node})
        })
        this.sendLocals(false)
      },
      updateEvent(eventObj){
        this.sendLocals(true)
        eventObj.start = new Date(eventObj.start)
        eventObj.end = new Date(eventObj.end)
        this.showEditEvent = false
        let data = {
          title: eventObj.title,
          description: eventObj.body,
          startdate: eventObj.start,
          duedate: eventObj.end,
          is_disabled: eventObj.isAllday,
          }
          if(this.undoNodes.length > 0) {
            this.undoNodes.forEach((element, index) => {
            if(element['receivedData']){
              if(element['receivedData'].id === eventObj.id) {
                this.undoNodes[index]['receivedData'].title = data.title
                this.undoNodes[index]['receivedData'].description = data.description
                this.undoNodes[index]['receivedData'].startdate = data.startdate
                this.undoNodes[index]['receivedData'].duedate = data.duedate
                this.undoNodes[index]['receivedData'].is_disabled = data.is_disabled
              }
            } 
            else {
                if(element['node'].id === eventObj.id) {
                  this.undoNodes[index]['node'].title = data.title
                  this.undoNodes[index]['node'].description = data.description
                  this.undoNodes[index]['node'].startdate = data.startdate
                  this.undoNodes[index]['node'].duedate = data.duedate
                  this.undoNodes[index]['node'].is_disabled = data.isAllday
                }
            }
          });
        }
        else {
          let dataObj = {
            id:eventObj.id,
            ...data
          }
          this.undoNodes.push({'req': 'addNode', node: dataObj})
        }
        this.updateCalendarUser()
        http.put(`/nodes/${eventObj.id}`, data)
        this.sendLocals(false)

      },
      deleteEvents(){
        this.undoDone = false
        this.sendLocals(true)
        this.showEditEvent = false
        this.updateCalendarUser()
        http.delete(`/nodes/${this.showEvent.id}.json`).then((res)=>{
          let receivedNodes = res.data.node
          if(receivedNodes && receivedNodes.length > 0){
            this.undoNodes.push({'req': 'deleteNode', 'node' : receivedNodes})
          }
          if (!this.undoDone){
            let data = {
              title: this.showEvent.title,
              description: this.showEvent.body,
              startdate: this.showEvent.start.d.d,
              duedate: this.showEvent.end.d.d,
              is_disabled: this.showEvent.isAllday,
              mindmap_id: this.currentMindMap.id
            }
            this.undoNodes.push({'req': 'deleteNode', node: data})
          }
          }).catch((err) => {
            console.error(err);
          });
        this.sendLocals(false)
      },
      async fetchEvents(){
        let mindmap_key = window.location.pathname.split('/')[2]
        let response = await http.get(`/msuite/${mindmap_key}.json`)
        this.defaultDeleteDays = response.data.defaultDeleteDays
        this.deleteAfter = response.data.deleteAfter
        this.expDays = response.data.expDays
        this.currentMindMap = response.data.mindmap
        this.fetchedEvents = response.data.mindmap.nodes
        localStorage.userEdit = this.currentMindMap.canvas
        this.renderEvents()
      },
      renderEvents(){
        if(this.fetchedEvents.length == 0){
          this.calendar.destroy()
          this.createCalendar()
        }
        this.calendar.store.getState().calendar.events.internalMap.clear()
        this.fetchedEvents.forEach((currentValue, index, rEvents)=> {
          currentValue.duedate = new Date(currentValue.duedate)
          currentValue.startdate = new Date(currentValue.startdate)
          this.calendar.createEvents([
            {
              id: currentValue.id,
              title: currentValue.title,
              start: currentValue.startdate,
              end: currentValue.duedate,
              body: currentValue.description,
              isAllday: currentValue.is_disabled
            }
          ])
        })
        this.fetchedEvents = []
      },
      formatshowEventDate(){
        var showDate = new Date(this.showEvent.start.d.d)
        showDate = moment(showDate).format("dddd MMMM Do YYYY");
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
      },
      undoEvent(){
        this.undoDone = true
        http
          .post(`/msuite/${this.currentMindMap.unique_key}/undo_mindmap.json`, { undoNode: this.undoNodes })
          .then((res) => {
            this.toggleCalendarView()
            this.undoNodes.pop()
            let node = res.data.node.node
            let req = res.data.node.req
            this.redoNodes.push({req, node})
          })
          .catch((err) => {
            console.log(err)
          })
      },
      redoEvent(){
        http
          .put(`/msuite/${this.currentMindMap.unique_key}/redo_mindmap.json`, { redoNode: this.redoNodes })
          .then((res) => {
            this.redoNodes.pop()
            let receivedData = res.data.node.node
            let req = res.data.node.req
            this.undoNodes.push({req, receivedData})
          })
          .catch((err) => {
            console.log(err)
          })
      }
    },
    mounted: async function() {
      this.subscribeCable(this.currentMindMap.id)
      this.sendLocals(false)
      this.createCalendar()
      this.getCalendarTitle()
      await this.fetchEvents()
      this.getUserOnMount()
      var el = document.querySelector('#calendar');
        el.addEventListener("mouseleave", function( event ) {
          this.showEditEvent = false
        })
    }
  }
</script>
<style>
  @import "./calendar.scss";
</style>
