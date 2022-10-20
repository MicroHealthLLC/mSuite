<template>
  <div>
    <sweet-modal ref="confirmSaveKeyModal" class="of_v">
      <div class="sweet_model_icon_div">
        <div class="radius_circle bg-warning center_flex mlr_a text-white">
          <i class="material-icons">notification_important</i>
        </div>
      </div>
      <h3 class="f_smooth_auto">Did you save the document key?</h3>
      <div class="row">
        <div class="col-12">
          <p class="mb-0 text-left text-center"> This will automatically delete if inactive for
            <code class="pointer">
              <input
                v-model="expDaysInput"
                type="number"
                class="w-10"
                min="1"
                :max="defaultDeleteDays"
                @click.prevent="onClick"
                @keydown.enter.prevent.native
                v-debounce:500ms="expireDate"
                id="willDeleteAt"
              />
            </code>
              days.
          </p>
        </div>
        <div class="col-12">
          <span class="text-muted fs_18">You will need this key <code> {{ unique_key }} </code> to view the document again!</span>
        </div>
      </div>
      <div class="center_flex mt_2 row">
        <a
          href="javascript:;"
          class="btn_2 col-3 bg-primary text-white mr_1"
          @click.stop="goHome"
          :title="'Anyone with above Unique Key: ' + unique_key + ' can access Public Map.'"
        >
          Save Public
        </a>
        <a
          href="javascript:;"
          class="btn_2 col-3 bg-info text-white mr_1"
          @click.stop="openPrivacy"
          :title="'Private Map only accessable to those who had Unique key: '+ unique_key + 'and Password().'"
        >
          Save Private
        </a>
        <a
          v-if="isSaveMap == 'is_private'"
          href="javascript:;"
          class="btn_2 col-3 bg-warning text-white mr_1"
          @click.stop="changePrivacy"
        >
          Change Password
        </a>
        <a
          href="javascript:;"
          class="btn_2 col-2 bg-danger text-white mr_1"
          @click.prevent="deleteMap"
          title="Delete Permanently"
        >
          Delete
        </a>
      </div>
    </sweet-modal>
    <sweet-modal ref="Error" class="of_v">
      <p>Number of days cannot be greater than {{ defaultDeleteDays }}</p>
    </sweet-modal>
  </div>
</template>

<script>
  import http from '../http'
  export default {
    name: "ConfirmSaveKeyModal",
    data () {
      return {
        expDaysInput: this.findTotalDaysBetweenDates(),
        expDays: '',
        deleteAfter: this.$store.getters.getDataMsuite.deleteAfter,
        currentMindMap: this.$store.getters.getMsuite,
        unique_key: this.$store.getters.getMsuite.unique_key,
        deletedAtMSuite: JSON.parse(JSON.stringify(this.$store.getters.getMsuite.will_delete_at))
      }
    },
    props: ['currentMindMap', 'defaultDeleteDays', 'isSaveMap', 'deleteAfter', 'isSaveMSuite'],
    computed: {
      getBaseUrl () {
        return window.location.href
      },
      expDeleteDays () {
        /* if(this.currentMindMap && this.isSaveMap == null ) return this.deleteAfter
        else  */return this.findTotalDaysBetweenDates()
      }
    },
    watch: {
      currentMindMap: {
        handler(value){
          this.isSaveMap = value.is_save
          this.expDaysInput = this.findTotalDaysBetweenDates()
        }, deep: true
      }
    },
    methods: {
      expireDate (val) {
        const value = val
        if (value <= this.defaultDeleteDays && value > 0) {
          var day = new Date();
          var nextDay = new Date(day);
          nextDay.setDate(day.getDate() + parseInt(value));
          this.currentMindMap.will_delete_at = nextDay
          if(this.currentMindMap.will_delete_at) this.updateInActiveDate()
        }else {
          this.$refs.Error.open()
          if (this.expDaysInput < 1) {
            this.expDaysInput = 1
          } else this.expDaysInput = this.defaultDeleteDays
          
          this.currentMindMap.will_delete_at = this.deletedAtMSuite
        }
      },
      onClick() {
        this.expireDate(this.expDaysInput)
      },
      updateInActiveDate () {
        this.$emit("updateInActiveDate", this.currentMindMap)
      },
      is_save () {
        this.$emit("isSave")
      },
      goHome () {
        //console.log(this.expDays)
        this.is_save()
        //if(this.findTotalDaysBetweenDates() == this.expDays) this.expireDate(this.deleteAfter)
        this.$emit("changeIsMsuitSaved")
        if(this.isSaveMSuite) this.closeModal()
        else window.open("/", "_self")
      },
      changePrivacy () {
        this.$emit("openPrivacy", this.isSaveMSuite)
      },
      openPrivacy () {
        this.$emit("changeIsMsuitSaved")
        if(this.isSaveMap == null || this.isSaveMap == 'is_public') this.$emit("openPrivacy", this.isSaveMSuite)
        else if(this.isSaveMSuite) this.closeModal()
        else window.open("/", "_self")
      },
      closeModal() {
        this.$refs.confirmSaveKeyModal.close()
      },
      deleteMap () {
        this.$emit("deleteMap")
      },
      findTotalDaysBetweenDates() {
        let currentDate = new Date();
        let comingDate = new Date(this.$store.getters.getMsuite.will_delete_at);
        return this.totalDays(comingDate,currentDate)
      },
      totalDays (date_1, date_2) {
        let difference = date_1.getTime() - date_2.getTime();
        let TotalDays = Math.ceil(difference / (1000 * 3600 * 24));
        return TotalDays;
      }
    },
  }
</script>
<style>
  .w-10{
    width: 10%;
  }
</style>
