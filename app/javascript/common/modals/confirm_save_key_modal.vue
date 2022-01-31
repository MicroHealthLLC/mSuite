<template>
  <div>
    <sweet-modal ref="confirmSaveKeyModal" class="of_v">
      <div class="sweet_model_icon_div">
        <div class="radius_circle bg-warning center_flex mlr_a text-white">
          <i class="material-icons">notification_important</i>
        </div>
      </div>
      <h3 class="f_smooth_auto">Did you save the map key?</h3>
      <div class="row">
        <div class="col-12">
          <p class="mb-0 text-left text-center"> If not oppend, this MSuite will automatically delete after
            <code class="pointer">
              <input
                v-model="currentMindMap.will_delete_at"
                type="number"
                class="w-10"
                @keydown.enter.prevent.native
                v-debounce:3000ms="expireDate"
                id="willDeleteAt"
              />
            </code>
             days.
          </p>
        </div>
        <div class="col-12">
          <span class="text-muted fs_18">You will need this key <code> {{ currentMindMap.unique_key }} </code> to view the map again!</span>
        </div>
      </div>
      <div class="center_flex mt_2">
        <a
          href="javascript:;"
          class="btn_2 bg-primary text-white mr_1"
          @click.stop="goHome"
          :title="'Anyone with above Unique Key: ' + currentMindMap.unique_key + ' can access Public Map.'"
        >
          Save Public
        </a>
        <a
          href="javascript:;"
          class="btn_2 bg-info text-white mr_1"
          @click.stop="openPrivacy"
          :title="'Private Map only accessable to those who had Unique key: '+ currentMindMap.unique_key + 'and Password().'"
        >
          Save Private
        </a>
        <a
          href="javascript:;"
          class="btn_2 bg-danger text-white mr_1"
          @click.prevent="deleteMSuite"
          title="Delete Permanently"
        >
          Delete
        </a>
      </div>
    </sweet-modal>
    <sweet-modal ref="Error" class="of_v">
      <p>Number of days not greater then {{ defaultDeleteDays }}</p>
    </sweet-modal>
  </div>
</template>

<script>
  import http from '../http'
  export default {
    name: "ConfirmSaveKeyModal",
    data () {
      return {
        showDays: JSON.stringify(JSON.parse(this.currentMindMap.will_delete_at)),
        deletedAtMSuite: JSON.stringify(JSON.parse(this.currentMindMap.will_delete_at))
      }
    },
    props: ['currentMindMap', 'defaultDeleteDays'],
    computed: {
      getBaseUrl () {
        return window.location.href
      }
    },
    methods: {
      expireDate (event) {
        const value = event
        if (value <= this.defaultDeleteDays && value > 0) {
          var day = new Date();
          var nextDay = new Date(day);
          nextDay.setDate(day.getDate() + parseInt(value));
          this.currentMindMap.will_delete_at = nextDay
          if(this.currentMindMap.will_delete_at) this.updateInActiveDate()
        }else {
          this.$refs.Error.open()
          this.currentMindMap.will_delete_at = this.deletedAtMSuite
        }
      },
      updateInActiveDate () {
        let _this = this
        http.put(`/mindmaps/${this.currentMindMap.unique_key}.json`, this.currentMindMap)
        .then((res) => {
          _this.currentMindMap = res.data.mindmap
        })
      },
      goHome () {
        window.open("/", "_self")
      },
      openPrivacy () {
        this.$emit("openPrivacy")
      },
      closeModal() {
        this.$refs.confirmSaveKeyModal.close()
      },
      deleteMSuite () {
        this.$emit("deleteMindmap")
      }
    }
  }
</script>
<style>
  .w-10{
    width: 10%;
  }
</style>
