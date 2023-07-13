<template>
  <div>
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
            class="material-icons col-2 pl-2"
            >
            delete</span>
          <span v-if="showEvent.raw.isSprint || (!showEvent.raw.parentNode && !showEvent.raw.isSprint)"
            class="fas fa-eye-dropper color-picker mt-1 icon-opacity"
            @click="colorSelected = true"
            >
          </span>
        </div>
        <div class="row mb-1 font-weight-medium h5">{{showEvent.title}}</div>
        <div class="row mb-4">{{formatshowEventDate()}}</div>
        <div class="row my-2">{{showEvent.body}}</div>
        <div class="row my-2">{{showEvent.raw.standalone ? 'Relationship: None' : showEvent.raw.parentNode && currentMindMap.nodes.find(n => n.id === showEvent.raw.parentNode) ? 'Related to: ' + currentMindMap.nodes.find(n => n.id === showEvent.raw.parentNode).title : ''}}</div>
      </div>
    </b-popover>
    <add-calendar-event-modal 
      :eventDates="eventDates"
      :showEvent="showEvent" 
      :allEvents="allEvents"
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
    <div v-if="colorSelected">
      <div class="card card-position p-0 border-none mt-5">
        <color-palette
          :selected-node="eventNode"
          :uniqueColors="uniqueColors"
          @updateColorNode="updateColorNode"
          @saveNodeColor="saveNodeColor"
          @closeModelPicker="closeModelPicker"
          >
        </color-palette>
      </div>
    </div>
  </div>
</template>
<script>
  import http from "../../common/http"
  import domtoimage from "dom-to-image-more"
  import RecurringCalendarEventModal from '../../common/modals/recurring_calendar_event_modal';
  import AddCalendarEventModal from '../../common/modals/add_calendar_event_modal';
  import ColorPalette from '../../common/modals/color_palette_modal'
  import Calendar from '@toast-ui/calendar';
  import '@toast-ui/calendar/dist/toastui-calendar.min.css';
  import 'tui-date-picker/dist/tui-date-picker.css';
  import 'tui-time-picker/dist/tui-time-picker.css';
  import Chance from 'chance'
  import Common from "../../mixins/common.js"
  import TemporaryUser from "../../mixins/temporary_user.js"
  import History from "../../mixins/history.js"
  import "./calendar.css";

  export default {
    mixins: [Common, TemporaryUser, History],
    data() {
      return {
        currentMindMap      : this.$store.getters.getMsuite,
        isReset             : false,
        isEditing           : false,
        saveElement         : true,
        calendar            : null,
        calendarTitle       : null,
        recurringEvents     : null,
        recurringEventsDate : null,
        fetchedEvents       : [],
        eventDates          : null,
        showEvent           : null,
        showEditEvent       : false,
        createEventDate     : null,
        userList            : [],
        temporaryUser       : '',
        currentView         : 'month',
        undoNodes           : [],
        redoNodes           : [],
        undoDone            : false,
        colorSelected       : false,
        uniqueColors        : [],
        selectedEvent       : null,
        allEvents          : []
      }
    },
    props: {
      undoMap: Function,
      redoMap: Function,
    },
    components: {
      RecurringCalendarEventModal,
      AddCalendarEventModal,
      ColorPalette
    },
    channels: {
      WebNotificationsChannel: {
        received(data) {
          if (data.message === "Mindmap Updated" && this.currentMindMap.id === data.mindmap.id){
            this.calendar.store.getState().calendar.events.internalMap.clear()
            this.fetchEvents()
          } else if (data.message === "Mindmap Deleted" && this.currentMindMap.id === data.mindmap.id) {
            window.open('/','_self')
          } else if (data.message === "Password Updated" && this.currentMindMap.id === data.mindmap.id) {
            setTimeout(() => {
              location.reload()
            }, 500)
          } else if(data.message === "Reset mindmap" && this.currentMindMap.id === data.mindmap.id){
            this.$store.dispatch('updateMSuite', data.mindmap)
            this.currentMindMap = data.mindmap
            this.calendar.destroy()
            this.createCalendar()
            this.calendar.today()
            this.getCalendarTitle()
          } else if(data.message === "Node is updated" && this.currentMindMap.id === data.node.mindmap_id){
              this.calendar.store.getState().calendar.events.internalMap.clear()
              this.fetchEvents()
          } else if( data.message === "Event Trigger" ) {
            this.eventNotifications(data.node.title)
          } else if ( data.message === "storage updated" && this.currentMindMap.id == data.content.mindmap_id) {
            this.$store.dispatch('setUserEdit'     , data.content.userEdit)
            this.$store.dispatch('setTemporaryUser', data.content.userEdit)
            this.$store.dispatch('setUserList'     , data.content.userEdit)
          } else {
            this.calendar.store.getState().calendar.events.internalMap.clear()
            this.fetchEvents()
          }
        }
      }
    },
    computed: {
      mSuite () {
        return this.$store.getters.getMsuite
      },
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
          this.eventNode = this.currentMindMap.nodes.find(o => o.id === eventObj.event.id)
          this.showEvent = eventObj.event
          console.log('clickEvent', this.eventNode, this.showEvent)
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
          if (data.isAllday) {
            eventObj.changes.end.d.d.setHours(23)
            eventObj.changes.end.d.d.setMinutes(59)
            eventObj.changes.end.d.d.setSeconds(59)
          }
          data.end = eventObj.changes.end.d.d
          this.updateEvent(data)
        })
        this.calendar.on('clickMoreEventsBtn',(eventObj)=>{
          let pos = $(eventObj.target).position()
          if(pos.top > 500){
            $(eventObj.target).css({top: 300, left: pos.left});
          }
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
        if (calendarStore.size !=0 ){
          calendarStore.clear()
          this.fetchEvents()
        }
      },
      moveCalendar(value){
        this.showEditEvent = false
        this.calendar.move(value)
        if (this.currentMindMap.nodes && this.currentMindMap.nodes.length > 0) this.updateEventHeights(this.currentMindMap)
        this.getCalendarTitle()
        this.bindEventToClick()
      },
      getCalendarTitle(){
        var calendarDate = new Date(this.calendar.getDate())
        this.calendarTitle = moment(calendarDate).format("MMMM YYYY");
      },
      openRecurringEventsModal(data){
        this.recurringEvents = null
        this.recurringEventsDate = data
        this.$refs['recurring-calendar-event-modal'].$refs['RecurringCalendarEventModal'].open()
      },
      getRecurringEventsDate(events){
        this.recurringEvents = events
      },
      generateRecurringEvents(eventObj){
        let time = {
          startHours: eventObj.start.getHours(),
          startMinutes: eventObj.start.getMinutes(),
          endHours: eventObj.end.getHours(),
          endMinutes: eventObj.end.getMinutes(),
          }
        let difference = this.getDateDifference(eventObj.start,eventObj.end)
        if(difference == 0){
          this.recurringEvents.forEach((currentValue, index, rEvents)=> {
            currentValue.setHours(time.startHours)
            currentValue.setMinutes(time.startMinutes)
            eventObj.start = new Date(currentValue)
            currentValue.setHours(time.endHours)
            currentValue.setMinutes(time.endMinutes)
            eventObj.end = new Date(currentValue)
            this.saveEvents(eventObj)
          })
        }
        else{
          this.recurringEvents.forEach((currentValue, index, rEvents)=> {
            currentValue[0].setHours(time.startHours)
            currentValue[0].setMinutes(time.startMinutes)
            eventObj.start = new Date(currentValue[0])
            currentValue[1].setHours(time.endHours)
            currentValue[1].setMinutes(time.endMinutes)
            eventObj.end = new Date(currentValue[1])
            this.saveEvents(eventObj)
          })
        }
        this.recurringEvents = null
      },
      async beforeEventCreate(data){
        console.log('beforeEventCreate', data)
        this.sendLocals(true)
        await this.saveEvents(data)
        if(this.recurringEvents) await this.generateRecurringEvents(data)
        this.sendLocals(false)
        this.updateCalendarUser()
      },
      beforeEventUpdate(data){
        console.log('beforeEventUpdate', data)
        this.updateEvent(data)
        if(this.recurringEvents) this.generateRecurringEvents(data)
      },
      editEventModal(){
        console.log("editEventModal", this.showEvent, this.allEvents)
        this.$refs['add-calendar-event-modal'].$refs['AddCalendarEventModal'].open()
      },
      async updateCalendarUser(){
        await this.$store.dispatch('updateMSuite', {
          canvas: this.$store.getters.getUser
          });
      },
      async saveEvents(eventObj){
        eventObj.start = new Date(eventObj.start)
        eventObj.end = new Date(eventObj.end)
        let data = {
          title: eventObj.title,
          description: eventObj.body,
          startdate: eventObj.start,
          duedate: eventObj.end,
          hide_children: eventObj.isAllday,
          line_color: eventObj.raw.isSprint ? eventObj.backgroundColor : '#363636',
          mindmap_id: this.currentMindMap.id,
          is_sprint: eventObj.raw.isSprint,
          parent_node: eventObj.raw.parentNode,
          standalone: eventObj.raw.standalone
          }
          console.log("saveEvents", eventObj)
        let _this = this
        await http.post('/nodes.json', data).then((result) => {
          _this.undoNodes.push({req: 'addNode', 'node': result.data.node})
          _this.currentNodeId = result.data.node.id
        })
        if (data.parent_node && this.allEvents.length > 0 && this.currentMindMap.nodes) {
          let parent = this.currentMindMap.nodes.find(n => n.id == data.parent_node)
          if (parent && !parent.is_sprint) this.updateNewParent(parent)
        }
      },
      async updateEvent(eventObj, par) {
        this.sendLocals(true)
        eventObj.start = new Date(eventObj.start)
        eventObj.end = new Date(eventObj.end)
        console.log(eventObj, par)
        this.checkEventStatus(eventObj, this.currentMindMap.nodes)
        //this.currentMindmap = this.updateEventColors(this.currentMindMap)
        this.showEditEvent = false
        let data = {
          title: eventObj.title,
          description: eventObj.body,
          startdate: eventObj.start,
          duedate: eventObj.end,
          hide_children: eventObj.isAllday,
          line_color: eventObj.backgroundColor,
          is_sprint: eventObj.raw.isSprint,
          parent_node: eventObj.raw.parentNode,
          standalone: eventObj.raw.standalone
        }
        console.log('updateEvent1', eventObj, data)
        /* if (eventObj.raw) {
          data.is_sprint = eventObj.raw.isSprint
          data.parent_node = eventObj.raw.parentNode
          data.standalone = eventObj.raw.standalone
        } */
        //console.log('updateEvent2',eventObj, data)
        //data.line_color = data.is_sprint ? data.line_color : this.getParentColor(data.parent_node)
        if (this.undoNodes.length > 0) {
          this.undoNodes.forEach((element, index) => {
          if (element['node'].id === eventObj.id) {
            this.undoNodes[index]['node'].title = data.title
            this.undoNodes[index]['node'].description = data.description
            this.undoNodes[index]['node'].startdate = data.startdate
            this.undoNodes[index]['node'].duedate = data.duedate
            this.undoNodes[index]['node'].hide_children = data.isAllday
            this.undoNodes[index]['node'].is_sprint = data.is_sprint
            this.undoNodes[index]['node'].parent_node = data.parent_node
            this.undoNodes[index]['node'].standalone = data.standalone
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
        const toastElement = document.querySelector('.toastui-calendar-see-more-container');
        if (toastElement) toastElement.style.display = 'none';

        this.sendLocals(false)
        this.updateCalendarUser()
        console.log(data)
        /* if (data.parent_node == null) {
          this.setChildsParent(eventObj)
        } */
        await http.put(`/nodes/${eventObj.id}`, data)
        if (data.parent_node && this.allEvents.length > 0 && this.currentMindMap.nodes) {
          let parent = this.currentMindMap.nodes.find(n => n.id == data.parent_node)
          if (parent && !parent.is_sprint) this.updateNewParent(parent)
        }
      },
      deleteEvents(){
        this.undoDone = false
        this.sendLocals(true)
        this.showEditEvent = false
        /* let selectedNode = this.fetchedEvents.find(n => n.id == this.showEvent.id)
        let childsParent = this.fetchedEvents.find(n => n.id == selectedNode.parent_node)
        console.log(childsParent)
        let isParent = selectedNode.children.length > 0 */
        http.delete(`/nodes/${this.showEvent.id}.json`).then((res)=>{
          console.log(res)
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
              hide_children: this.showEvent.isAllday,
              line_color: this.showEvent.backgroundColor,
              mindmap_id: this.currentMindMap.id,
              is_sprint: this.showEvent.raw.isSprint,
              parent_node: this.showEvent.raw.parentNode,
              standalone: this.showEvent.raw.standalone
            }
            this.undoNodes.push({'req': 'deleteNode', node: data}) 
          }
          }).catch((err) => {
            console.error(err);
          });
          if (this.showEvent) {
          let selectedNode = this.fetchedEvents.find(n => n.id == this.showEvent.id)
          if (selectedNode) {
            let childsParent = this.fetchedEvents.find(n => n.id == selectedNode.parent_node)
            console.log(childsParent)
            if (childsParent) {
              console.log(childsParent)
              this.checkForChildren(childsParent, selectedNode)
            }
          }
        }  
          /* if (childsParent) {
            console.log(childsParent)
            this.checkForChildren(childsParent, selectedNode)
          } */
          this.calendar.today()
          this.getCalendarTitle()
          this.sendLocals(false)
          this.updateCalendarUser()
          const toastElement = document.querySelector('.toastui-calendar-see-more-container');
          if (toastElement) toastElement.style.display = 'none';
      },
      async setChildsParent(obj) {
        await http.patch(`/nodes/${obj.id}`, { parent_node: null })
      },
      async checkForChildren(parent, child) {
        console.log(parent)
        if (parent.children.length == 1 && parent.children[0].id == child.id) {
          await http.patch(`/nodes/${parent.id}`, { is_sprint: false, line_color: '#363636' })
        }
      },
      async fetchEvents(){
        let res = await this.$store.dispatch('getMSuite')
        this.currentMindMap = this.$store.getters.getMsuite
        this.$store.dispatch('setMindMapId', this.currentMindMap.id)
        this.fetchedEvents = this.currentMindMap.nodes
        this.allEvents = []
        this.fetchedEvents.forEach((currentValue, index, rEvents)=> {
          /* if(currentValue.is_sprint){ */
            this.allEvents.push(currentValue)
          /* } */          
        })
        /* if (this.showEvent) {
          let selectedNode = this.fetchedEvents.find(n => n.id == this.showEvent.id)
          if (selectedNode) {
            let childsParent = this.fetchedEvents.find(n => n.id == selectedNode.parent_node)
            console.log(childsParent)
            if (childsParent) {
              console.log(childsParent)
              this.checkForChildren(childsParent, selectedNode)
            }
          }
        } */
        console.log("fetchEvents",  this.allEvents)
        this.renderEvents()
      },
      renderEvents(){
        if(this.fetchedEvents.length == 0){
          this.calendar.destroy()
          this.createCalendar()
        }
        this.mapColors = []
        this.uniqueColors = []
        this.calendar.store.getState().calendar.events.internalMap.clear()
        let _this = this
        this.fetchedEvents.forEach((currentValue, index, rEvents)=> {
          currentValue.duedate   = new Date(currentValue.duedate)
          currentValue.startdate = new Date(currentValue.startdate)
          // currentValue.duedate = moment(new Date(currentValue.duedate))
          // currentValue.startdate = moment(new Date(currentValue.startdate))
          let colorType = this.lightOrDark(currentValue.line_color)
          let textColor = colorType != 'dark' ? '#020101' : '#F8F8F8'
          this.mapColors.push(currentValue.line_color)
          //console.log("renderEvents", currentValue.title, currentValue)
          /* if (currentValue.parent_node == null && currentValue.is_sprint == false) {
            currentValue.is_sprint = true
            this.afterParentDelete(currentValue)
          } */ 
          console.log(currentValue)
          // if (currentValue.children.length == 0 && currentValue.is_sprint) {
          //   currentValue.is_sprint = false
          //   currentValue.line_color = "#363636"
          // }
          this.calendar.createEvents([
            {
              id: currentValue.id,
              title: currentValue.title,
              start: currentValue.startdate,
              end: currentValue.duedate,
              body: currentValue.description,
              category: currentValue.is_sprint || currentValue.hide_children ? 'allday' : 'time',
              isAllday: currentValue.hide_children,
              backgroundColor: currentValue.line_color,
              dragBackgroundColor:currentValue.line_color,
              color:textColor,
              raw: {isSprint: currentValue.is_sprint, parentNode: currentValue.parent_node, standalone: currentValue.standalone }
            }
          ])
        })
        this.uniqueColors = this.getUniqueColors(this.mapColors);
        this.bindEventToClick()

        /* if (this.showEvent) {
          let selectedNode = this.fetchedEvents.find(n => n.id == this.showEvent.id)
          if (selectedNode) {
            let childsParent = this.fetchedEvents.find(n => n.id == selectedNode.parent_node)
            console.log(childsParent)
            if (childsParent) {
              console.log(childsParent)
              this.checkForChildren(childsParent, selectedNode)
            }
          }
        }   */

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
      async undoEvent(){
        this.undoDone = true
        let undoObj = await this.undoNode(this.undoNodes)
        if(undoObj){
          this.toggleCalendarView()
          this.undoNodes.pop()
          this.redoNodes.push({req: undoObj.req, node: undoObj.node})
        }
      },
      async redoEvent(){
        let redoObj = await this.redoNode(this.redoNodes)
        if(redoObj){
          this.toggleCalendarView()
          this.redoNodes.pop()
          this.undoNodes.push({req: redoObj.req, 'node': redoObj.node})
        }
      },
      closeModelPicker(){
        this.colorSelected = false
        if (this.selectedEvent.style.backgroundColor) {
          this.selectedEvent.style.backgroundColor = this.showEvent.backgroundColor
        }
        this.selectedEvent.style.color = this.showEvent.color
      },
      saveNodeColor(){
        let data = {
          id:this.showEvent.id,
          title:this.showEvent.title,
          body: this.showEvent.body,
          start:this.showEvent.start.d.d,
          end:this.showEvent.end.d.d,
          isAllday:this.showEvent.isAllday,
          backgroundColor:this.eventNode.line_color.hex,
          raw: {
            standalone: this.showEvent.raw.standalone,
            isSprint: this.showEvent.raw.isSprint,
            parentNode: this.showEvent.raw.parentNode
          }
        }
        this.updateEvent(data)
        this.colorSelected = false
      },
      updateColorNode(){
        if (this.selectedEvent.children.length == 3) this.selectedEvent = this.selectedEvent.children[0]
        let colorType = this.lightOrDark(this.eventNode.line_color.hex)
        let textColor = '#F8F8F8'
        if (colorType != 'dark') textColor = '#020101'
        this.selectedEvent.style.backgroundColor = this.eventNode.line_color.hex
        this.selectedEvent.style.color = textColor
      },
      lightOrDark(color) {
        if(color){
          color = +("0x" + color.slice(1).replace(color.length < 5 && /./g, '$&$&'));
          let r = color >> 16;
          let g = color >> 8 & 255;
          let b = color & 255;
          let hsp = Math.sqrt(0.299 * (r * r) + 0.587 * (g * g) + 0.114 * (b * b));
          if (hsp>127.5) {
            return 'light';
          }
          else {
            return 'dark';
          }
        }
      },
      afterParentDelete(node) {
        let data = {
          id: node.id,
          title: node.title,
          body: node.body,
          start: node.startdate,
          end: node.duedate,
          isAllday: node.hide_children,
          backgroundColor: node.line_color,
          raw: {
            standalone: node.standalone,
            isSprint: node.is_sprint,
            parentNode: node.parent_node
          }
        }
        console.log(data)
        this.updateEvent(data)
      },
      updateNewParent(parent) {
        console.log(parent)
        http.put(`/nodes/${parent.id}`, { is_sprint: true, line_color: this.getRandomColor() })
      },
      checkEventStatus(eventObj, nodeList) {
        console.log(eventObj)
        const eventStart = new Date(eventObj.start);
        const eventEnd = new Date(eventObj.end);

        const eventObjColor = eventObj.backgroundColor  

        if (eventObj.raw) {
          if (!eventObj.raw.isSprint) {
            
            let multiNodes = []
            nodeList.forEach(n => {
              const node = n;
              const nodeStart = new Date(node.startdate);
              const nodeEnd = new Date(node.duedate);

              if (eventStart >= nodeStart && eventEnd <= nodeEnd.setSeconds(nodeEnd.getSeconds() + 1)) {
                multiNodes.push(node)
              }
            })
            nodeList.forEach(n => {
              const node = n;
              const nodeStart = new Date(node.startdate);
              const nodeEnd = new Date(node.duedate);

              if (eventStart >= nodeStart && eventEnd <= nodeEnd.setSeconds(nodeEnd.getSeconds() + 1) && node.is_sprint && !eventObj.raw.standalone) {
                if (eventObj.raw.parentNode == null) {
                  eventObj.raw.standalone = false
                  eventObj.raw.parentNode = node.id
                } else {
                  if (multiNodes.length == 1) {
                    if (eventObj.raw.parentNode != node.id) {
                      eventObj.raw.standalone = false
                      eventObj.raw.parentNode = node.id
                    }
                  } else {
                    if (eventObj.raw.parentNode != node.id && !multiNodes.map(n => n.id).includes(eventObj.raw.parentNode)) {
                      /* console.log(eventObj)
                      return; */
                      if (eventObj.raw.parentNode == 'none') {
                        eventObj.raw.parentNode = null
                        eventObj.raw.standalone = true
                      } else {
                        eventObj.raw.standalone = false
                        eventObj.raw.parentNode = node.id
                      } 
                    } else {
                      eventObj.raw.parentNode = eventObj.raw.parentNode
                    }
                  } 
                }
                return eventObj;
              }
              if (eventStart >= nodeStart && eventEnd <= nodeEnd && node.is_sprint && eventObj.raw.standalone) {
                if (eventObj.backgroundColor == node.line_color) {
                  eventObj.backgroundColor = '#363636'
                }
              }
            })
            
            if (eventObj.id === eventObj.raw.parentNode) {
              //eventObj.raw.standalone = true
              eventObj.raw.parentNode = null
            } 

            if (multiNodes.length === 0) {
              if (eventObj.raw.parentNode) eventObj.backgroundColor = '#363636'
              eventObj.raw.parentNode = null;
              //eventObj.raw.standalone = true
              console.log(eventObj)
              /* if (eventEnd - eventStart > 86400000) {
                eventObj.raw.isSprint = true
                if (nodeList.filter(n => n.id != eventObj.id).map(n => n.line_color).includes(eventObjColor) && !eventObj.raw.standalone) {
                  eventObj.backgroundColor = this.getRandomColor()
                }
              } */
              /* if (!eventObj.raw.isSprint) { 
                eventObj.backgroundColor = '#363636'
              } */
            }
            console.log(eventObj)
            return eventObj;
          }
        } 
      },
      updateEventColors(mindmap) {
        const parentNodes = mindmap.nodes.filter(n => n.is_sprint);

        mindmap.nodes.filter(node => !parentNodes.includes(node)).forEach(n => {
          parentNodes.forEach(p => {
            if (p.id === n.parent_node && n.line_color !== p.line_color) {
              n.line_color = p.line_color;
            }

            if (n.id === p.id) {
              n.children.forEach(c => {
                if (c.line_color !== p.line_color) {
                  c.line_color = p.line_color;
                }
              });
            }
          });
        });

        return mindmap;
      },
      updateEventHeights(mindmap) {
        // Filter the events to get the long events
        let longEvents = mindmap.nodes.filter(n => {
          if (!n.is_sprint) { // Exclude sprints
            const startDate = new Date(n.startdate);
            const dueDate = new Date(n.duedate);

            // Check if the event is either on the next day or longer duration
            let isNextDayOrLonger = (
              startDate.getFullYear() < dueDate.getFullYear() ||
              startDate.getMonth() < dueDate.getMonth() ||
              startDate.getDate() < dueDate.getDate()
            );
            if (n.hide_children) isNextDayOrLonger = true
            return isNextDayOrLonger;
          } else {
            return false;
          }
        });

        // Wait for a short duration and update the heights of long events
        setTimeout(() => {
          longEvents.forEach(e => {
            // Find the event elements to be updated based on their test id
            let elements = document.querySelectorAll(`[data-testid="${e.id}-${e.title}"]`);
            elements.forEach(event => {
              // Update the height, line height, and font size of the event element's children
              let child = event.children[0]
              if (child && child.style) {
                child.style.height = "13px";
                child.style.lineHeight = "13px";
                child.style.marginTop = '6px'
              }
              if (child.querySelector('.toastui-calendar-weekday-event-title')) {
                child.querySelector('.toastui-calendar-weekday-event-title').style.fontSize = '10px';
                child.querySelector('.toastui-calendar-weekday-event-title').style.fontWeight = '400';
              }
              if (child.querySelector('.toastui-calendar-weekday-resize-handle')) {
                child.querySelector('.toastui-calendar-weekday-resize-handle').style.transform = 'scale(0.9)'
                child.querySelector('.toastui-calendar-weekday-resize-handle').style.marginTop = '5px'
              }
              
            });
          });
        }, 50);
      },
      bindEventToClick(){
        let _this = this
        setTimeout(()=>{
          $(".toastui-calendar-weekday-event-title").click(function () {
            _this.selectedEvent = this.parentElement
          })
          $(".toastui-calendar-event-time-content").click(function () {
            _this.selectedEvent = this.parentElement
          })
          $(".toastui-calendar-weekday-event-dot").click(function () {
            _this.selectedEvent = this
          })
        },50)
      },
      hidePopover() {
        this.showEditEvent = false;
        //this.colorSelected = false // Set the variable to hide the popover
      }
    },
    mounted: async function() {
      this.subscribeCable(this.currentMindMap.id)
      this.$store.dispatch('setExportId', 'cal')
      this.sendLocals(false)
      this.createCalendar()
      this.getCalendarTitle()
      this.setUserOnMount()
      await this.fetchEvents()
      this.getUserOnMount()
      var el = document.querySelector('#calendar');
        el.addEventListener("mouseleave", function( event ){
          this.showEditEvent = false
        })
      setTimeout(()=>{
        let height = document.getElementById('nav').offsetHeight
        document.getElementById('calendar').style.height = `calc(96vh - ${height}px)`
      }, 100)
      this.undoMap(this.undoEvent)
      this.redoMap(this.redoEvent)
    },
    watch: {
      mSuite: {
        handler(value) {
          this.currentMindMap = value.nodes && value.nodes.length > 0 ? this.updateEventColors(value) : value
          if (value.nodes && value.nodes.length > 0) this.updateEventHeights(this.currentMindMap)
          this.fetchedEvents = value.nodes
        }, deep: true
      },
      showEvent() {
         console.log(this.showEvent)
      }
    }
  }
</script>
