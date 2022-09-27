<template>
  <div class="poll-app">
    <navigation-bar
      ref="navigationBar"
      @mSuiteTitleUpdate="mSuiteTitleUpdate"
      @deleteMindmap="deleteMap"
      @resetMindmap="resetMindmap"
      @exportToDocument="exportToDocument"
      @pollEditData="pollEditData"
      @exportXLS="exportXLS"
      :current-mind-map="currentMindMap"
      :defaultDeleteDays="defaultDeleteDays"
      :expDays="expDays"
      :deleteAfter="deleteAfter"
      :pollPin="pollData"
      :pollEdit="pollEdit"
      :exportId="'poll'">
    </navigation-bar>

    <div id="poll">
      <poll-view
        class="mt-5"
        v-if="!pollEdit && dataLoaded && pollData"
        :pollData="pollData"
        :graph_array="graph_array"
        :current-mind-map="currentMindMap"
        :child_mindmap="child_mindmap"
        @pollEditData="pollEditData"
        @updateVote="updateVote"></poll-view>

      <create-poll
        v-else
        :pollData = "pollData"
        :current-mind-map="currentMindMap"
        @updateVote="updateVote">
      </create-poll>
      <sweet-modal ref="dataErrorModal" class="of_v" icon="error">
        Sorry, No Data Found
      </sweet-modal>
    </div>

  </div>
</template>
<script>
  import http from "../../common/http"
  import DeleteMapModal from '../../common/modals/delete_modal'
  import MakePrivateModal from "../../common/modals/make_private_modal"
  import DeletePasswordModal from '../../common/modals/delete_password_modal'
  import createPoll from './polls/create_poll'
  import pollView from './polls/poll_view'
  import TemporaryUser from "../../mixins/temporary_user.js"
  import xlsExport from 'xlsexport'
  export default {
    props: ['currentMindMap'],
    data() {
      return {
        dataLoaded: false,
        isReset: false,
        pollData: null,
        pollEdit: false,
        child_mindmap: false
      }
    },
    components: {
      DeleteMapModal,
      MakePrivateModal,
      DeletePasswordModal,
      createPoll,
      pollView
    },
    mixins: [TemporaryUser],
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
          } else if (data.message === "Reset mindmap" && this.currentMindMap.id === data.mindmap.id) {
            this.currentMindMap = data.mindmap
          }
          else if (data.message === "Mindmap Updated" && this.currentMindMap.id === data.mindmap.id){
            this.currentMindMap = data.mindmap
            this.pollData = JSON.parse(data.mindmap.canvas)
          }
        }
      }
    },
    mounted(){
      if(this.currentMindMap){
        this.subscribeCable(this.currentMindMap.id)
        this.pollData = JSON.parse(this.currentMindMap.canvas)
        if (this.pollData){
          if (this.pollData.Questions[0].question != '') this.dataLoaded = true
          if (this.pollData.url) this.getPollData()
          if (this.pollData.child_id) this.child_mindmap = true
        }
        this.exportXLS(0)
      }
    },
    methods: {
      updateVote(data){
        let mindmap = {
          name: data.url,
          mindmap: { canvas: JSON.stringify(data) }
        }
        let id = this.currentMindMap.unique_key
        http.patch(`/msuite/${id}.json`,mindmap).then( res =>{
          this.pollEdit = false
          this.dataLoaded = true
          if (JSON.parse(res.data.mindmap.canvas).child_id) this.child_mindmap = true
        })
      },
      pollEditData() {
        this.pollEdit = true
      },
      async getPollData(){
        let _this = this
        let response = await http.get(`/msuite/${this.pollData.url}.json`)
        if(response && response.data.mindmap && response.data.mindmap.canvas){
          _this.pollData = JSON.parse(response.data.mindmap.canvas)
          _this.child_mindmap = true
        }
      },
      exportXLS(option){
        if(this.pollData){
          let _this = this
          let graph_data = {}
          let graph_array = []
          this.pollData.Questions.forEach( (q, q_index) => {
            graph_array.push({ question : q.question })
            var json = this.pollData.Questions[q_index].answerField
            var fields = Object.keys(json[0])
            var replacer = function(key, value) { return value === null ? '' : value }
            var csv = json.map(function(row){
              if (typeof(row['votes']) == 'object' && row['votes'] != null ){
                row['votes'].map(function(fieldValue,index){
                  graph_data = {
                    vote: fieldValue,
                    text: row['text']
                  }
                  graph_array.push(graph_data)
                })
              } else {
                graph_data = {
                    vote: row['votes'],
                    text: row['text']
                  }
                graph_array.push(graph_data)
              }
            })
            csv.unshift(fields.join(','))
            csv = csv.join('\r\n');
          } )
          const xls = new xlsExport(graph_array, 'title');

          if (option == 1) xls.exportToXLS(`${this.currentMindMap.unique_key}.xls`)
          else if (option == 2) xls.exportToCSV(`${this.currentMindMap.unique_key}.csv`)
        } else {
          if ( option == 1 || option == 2 ) this.$refs['dataErrorModal'].open()
        }
      },
      resetMindmap() {
        let canvasData = {
          title: '',
          description: '',
          Questions: [{
            question: '',
            answerField: [
              { value: 1, text: '', votes: [] },
              { value: 2, text: '', votes: [] }
            ],
            allowedAnswers: 0,
            voters: [],
          }],
          showResult: false,
          url: ''
        }
        let mindmap = { mindmap: {
          canvas: JSON.stringify(canvasData),
          title: 'Title' }
        }
        let id = this.currentMindMap.unique_key
        http.patch(`/msuite/${id}.json`,mindmap)
        this.pollEdit = false
        this.dataLoaded = false
      },
    },
  }
</script>
<style lang="scss">
</style>
