<template>
  <div>
    <div v-if="loaded && expirationDate">
      <div>
        <h3 class="d-inline-block"><strong>Poll Results</strong></h3>
        <button
          class="float-right btn btn-warning text-white py-0 px-3 rounded-0"
          @click="$emit('showPoll')">Go Back
        </button>
      </div>
      <span>Poll Expiration Date: {{ expirationDate }}</span>
      <div class="graphs overflow-auto">
        <div v-for="(results,index) in pollData.Questions">
          <h4><strong>{{ results.question }}</strong></h4>
          <div
            v-if="createResultData(index)"
            :id="'results' + index" >
          </div>
        </div>
      </div>
    </div>
    <div v-else class="container loader"></div>
    <sweet-modal ref="errorModal" class="of_v" icon="error">
      No results found
    </sweet-modal>
  </div>
</template>
<script>
  import http from "../../../../common/http"
  import { convertArrayToCSV } from 'convert-array-to-csv'
  import moment from 'moment'

  import 'pivottable'
  import 'pivottable/dist/pivot.min.js'
  import 'pivottable/dist/pivot.min.css'
  import $ from 'jquery'
  import 'jquery-ui-bundle'
  import 'jquery-ui-bundle/jquery-ui.css'

  import '../../../../common/plotly.js'
  import '../../../../common/plotly_renderers.min.js'

  export default {
    name: 'Poll Results',
    props: ["pollData"],
    data() {
      return {
        dataLoaded: false,
        pollData_questions: [],
        dataUpdated: false,
        graph_data: null,
        graph_array: [],
        expirationDate: null,
        loaded: false
      }
    },
    mounted: async function(){
      await this.getVoteData()
      this.expirationDate = moment(new Date(this.pollData.duedate)).format('DD MMM YYYY')
    },
    methods:{
      async getVoteData() {
        let _this = this
        let response = await http.get(`/msuite/${this.pollData.url}.json`)
        if(response && response.data.mindmap && response.data.mindmap.canvas){
          _this.pollData = JSON.parse(response.data.mindmap.canvas)
          _this.loaded = true
        } else {
          _this.$refs['errorModal'].open()
          setTimeout(()=>{
            _this.$refs['errorModal'].close()
            _this.$emit('showPoll')
          },3000)
        }
      },
      createResultData(q_index){
        let _this = this
        var json = this.pollData.Questions[q_index].answerField
        var fields = Object.keys(json[0])
        var replacer = function(key, value) { return value === null ? '' : value }
        var csv = json.map(function(row){
          if (typeof(row['votes']) == 'object' && row['votes'] != null ){
            row['votes'].map(function(fieldValue,index){
              _this.graph_data = {
                answer: row['text'],
                voter: fieldValue
              }
              _this.graph_array.push(_this.graph_data)
            })
          } else {
            _this.graph_data = {
                answer: row['text'],
                voter: row['votes']
              }
            _this.graph_array.push(_this.graph_data)
          }
        })
        csv.unshift(fields.join(','))
        csv = csv.join('\r\n');

        const csvFromArrayOfObjects = convertArrayToCSV(this.graph_array);

        let pivotData = this.graph_array
        var renderers = $.extend($.pivotUtilities.renderers,$.pivotUtilities.plotly_renderers)

        $(`#results${q_index}`).pivotUI(pivotData,{
          renderers: renderers,
        });
        this.graph_array = []
        return true
      },
    }
  }
</script>
<style scoped>
  @import '../poll.css'
</style>
