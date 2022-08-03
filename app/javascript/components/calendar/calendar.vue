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
      <div>
        <button @click="addRecurringEvents"> Check</button>
      </div>
      <div id="calendar"></div>
    </div>
    <make-private-modal ref="make-private-modal" @password-apply="passwordProtect" @password_mismatched="$refs['passwordMismatched'].open()" :password="currentMindMap.password" :isSaveMSuite="isSaveMSuite"></make-private-modal>
    <delete-map-modal ref="delete-map-modal" @delete-mindmap="confirmDeleteMindmap"></delete-map-modal>
    <delete-password-modal ref="delete-password-modal" @deletePasswordCheck="deleteMindmapProtected"></delete-password-modal>
    <confirm-save-key-modal ref="confirm-save-key-modal" :current-mind-map="currentMindMap"></confirm-save-key-modal>
    <recurring-calendar-event-modal ref="recurring-calendar-event-modal"></recurring-calendar-event-modal>
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
        calendarTitle: null
      }
    },
    components: {
      DeleteMapModal,
      DeletePasswordModal,
      MakePrivateModal,
      RecurringCalendarEventModal
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
        return uuid.v1()
      },
      createCalendar(){
        const container = document.getElementById('calendar');
        const options = {
          defaultView: 'week',
          timezone: {
            zones: [
              {
                timezoneName: 'Asia/Seoul',
                displayLabel: 'Seoul',
              },
              {
                timezoneName: 'Europe/London',
                displayLabel: 'London',
              },
            ],
        },
      };
      this.calendar = new Calendar('#calendar', {
        usageStatistics: false,
        defaultView: 'month',
        gridSelection: {
          enableDblClick: true,
          enableClick: false,
        },
      });
      this.calendar.setOptions({
        useFormPopup: true,
        useDetailPopup: true
      });
      this.calendar.setOptions({
        week: {
          taskView: false,
        },
      });
      this.calendar.setOptions({
        template: {
          locationPlaceholder() {
            return 'Description';
          },
          popupDetailRecurrenceRule({ recurrenceRule }) {
            return recurrenceRule;
          },
        },
      });
      let _this = this
      this.calendar.on('beforeCreateEvent', (eventObj) => {
        // eventObj.recurrenceRule = 'FREQ=DAILY;INTERVAL=1'
        // eventObj.recurrenceRule = (new Date(new Date() + 2)).toString()
        this.calendar.createEvents([
          {
            ...eventObj,
            id: _this.getUuid(),
            }
          ]);
        });
        this.calendar.on('beforeUpdateEvent', (eventObj) => {
          this.calendar.updateEvent(eventObj.event.id, eventObj.event.calendarId, eventObj.changes);
        });  
        this.calendar.on('beforeDeleteEvent', (eventObj) => {
          this.calendar.deleteEvent(eventObj.id, eventObj.calendarId);
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
      addRecurringEvents(){
        this.$refs['recurring-calendar-event-modal'].$refs['RecurringCalendarEventModal'].open()
      }

    },
    mounted() {
      this.$cable.subscribe({ channel:"WebNotificationsChannel", room: this.currentMindMap.id })
      this.createCalendar()
      this.getCalendarTitle()
    },
    
  }
</script>
<style>
#calendar{
  height:70vh;
}

</style>
