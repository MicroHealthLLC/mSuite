<template>
  <div class="poll-app">
    <div id="poll">
      <create-poll
        v-if="pollEdit"
        :pollEdit="pollEdit"
        :pollData = "pollData"
        :current-mind-map="currentMindMap"
        :undo-canvas="undoCanvas"
        @pollEditData="pollEditData"
        @updateVote="updateVote"
        @updateUndoCanvas="updateUndoCanvas">
      </create-poll>
      <poll-view
        class="mt-5"
        v-else
        :pollData="pollData"
        :graph_array="graph_array"
        :current-mind-map="currentMindMap"
        :child-mindmap="childMindmap"
        @pollEditData="pollEditData"
        @updateVote="updateVote">
      </poll-view>
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
    props: {
      exportDef : Function,
      undoMap: Function,
      redoMap: Function
    },
    data() {
      return {
        currentMindMap: this.$store.getters.getMsuite,
        dataLoaded: false,
        isReset: false,
        pollEdit: true,
        undoCanvas: [],
        redoCanvas: []
      }
    },
    components: {
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
            this.resetPoll()
          }
          else if (data.message === "Mindmap Updated" && this.currentMindMap.id === data.mindmap.id){
            this.$store.commit('setMSuite', data.mindmap)
            this.pollData = JSON.parse(data.mindmap.canvas).pollData
          }
          else if (data.message === "storage updated" && this.currentMindMap.id === data.content.mindmap_id){
            this.$store.dispatch('setUserEdit'     , data.content.userEdit)
            this.$store.dispatch('setTemporaryUser', data.content.userEdit)
            this.$store.dispatch('setUserList'     , data.content.userEdit)
          }
        }
      }
    },
    computed: {
      pollData() {
        if (JSON.parse(this.$store.getters.getMsuite.canvas) && this.$store.getters.getMsuite.canvas != '{"version":"4.6.0","columns":[], "data":[], "style":{}, "width": []}')
          return JSON.parse(this.$store.getters.getMsuite.canvas).pollData
        else return null
      },
      childMindmap() {
        return this.pollData.Questions[0].voters.length > 0
      }
    },
    mounted: async function(){
      if(this.currentMindMap){
        this.subscribeCable(this.currentMindMap.id)
        this.$store.dispatch('setExportId', 'poll')
        this.getData()
        if(this.dataLoaded) this.exportXLS(0)
      }
      if (this.currentMindMap.canvas == null ){
        this.$store.dispatch('setUserEdit', this.currentMindMap.canvas)
        this.$store.dispatch('setTemporaryUser', this.currentMindMap.canvas)
      }
      this.sendLocals(false)
      this.setUserOnMountC()
      this.getUserOnMount()
      this.undoMap(this.undoObj)
      this.redoMap(this.redoObj)
      this.exportDef(this.exportXLS)
      console.log(this.pollEdit)
    },
    methods: {
      updateVote(data){
        let _this = this
        let id = this.currentMindMap.unique_key
        http.patch(`/msuite/${id}.json`,data).then( res =>{
          //_this.pollEditData(false)
          _this.dataLoaded = true
        })
      },
      pollEditData(val) {
        if (val == false) this.pollEdit = false
        else this.pollEdit = true
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
          })
          const xls = new xlsExport(graph_array, 'title');
          if (option == 1) xls.exportToXLS(`${this.currentMindMap.unique_key}.xls`)
          else if (option == 2) xls.exportToCSV(`${this.currentMindMap.unique_key}.csv`)
        } else {
          if ( option == 1 || option == 2 ) this.$refs['dataErrorModal'].open()
        }
      },
      async getData(){
        if (this.pollData){
          if (this.pollData.Questions){
            let ques = this.pollData.Questions[0]
            if(ques.question != '' && ques.answerField && ques.answerField[0].text != '' && ques.answerField[1].text != '') this.dataLoaded = true
          }
        }
      },
      resetPoll(){
        this.pollEditData(true)
        let data = {
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
            checked: [],
          }],
          showResult: false,
          url: ''
        }
        let mindmap = this.createMindmapCanvas(data)
        this.$store.dispatch('updateMSuite', mindmap)
      },
      createMindmapCanvas(polling){
        let mycanvas = {
          pollData  : polling,
          user      : this.$store.getters.getUser
        }
        mycanvas = JSON.stringify(mycanvas)
        let mindmap = { mindmap: { canvas: mycanvas } }
        return mindmap
      },
      updateUndoCanvas(mindmap){
        this.undoCanvas.push(mindmap)
      },
      undoObj(){
        this.undoDone = true
        http
          .post(`/msuite/${this.$store.getters.getMsuite.unique_key}/undo_mindmap.json`, { undoCanvas: this.undoCanvas })
          .then((res) => {
            let canvas = this.undoCanvas.pop()
            if (typeof(canvas) == 'string') this.redoCanvas.push(canvas)
            else this.redoCanvas.push(canvas.mindmap.canvas)
          })
          .catch((err) => {
            console.log(err)
          })
      },
      redoObj(){
        http
          .put(`/msuite/${this.$store.getters.getMsuite.unique_key}/redo_mindmap.json`, { redoCanvas: this.redoCanvas })
          .then((res) => {
            let canvas = this.redoCanvas.pop()
            this.undoCanvas.push(canvas)
          })
          .catch((err) => {
            console.log(err)
          })
      },
    },
  }
</script>
