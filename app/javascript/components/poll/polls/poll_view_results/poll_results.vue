<template>
  <div>
    <div>
      <div>
        <h3 class="d-inline-block"><strong>Poll Results</strong></h3>
        <el-button
          round
          type="warning"
          class="float-right text-white py-2 px-3"
          @click="$emit('showPoll')">GO BACK
        </el-button>
      </div>
      <span>Poll Expiration Date: {{ expirationDate }}</span>
      <div class="graphs overflow-auto">
        <div class="mt-4" v-for="(results,index) in pollResults.Questions" :key="index">
          <h4>
            <strong>{{ index + 1 }}.&nbsp;</strong>
            <strong>{{ results.question }}</strong>
          </h4>
          <div :id="'results' + index" ></div>
        </div>
      </div>
    </div>
    <sweet-modal ref="errorModal" class="of_v" icon="error">
      No results found
    </sweet-modal>
  </div>
</template>
<script>
  import http from "../../../../common/http"
  import { convertArrayToCSV } from 'convert-array-to-csv'
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
        currentMindMap: this.$store.getters.getMsuite,
        dataLoaded: false,
        pollData_questions: [],
        dataUpdated: false,
        graph_data: null,
        graph_array: [],
        expirationDate: null,
        loaded: false,
        resultsLoaded: [],
      }
    },
    mounted: async function(){
      await this.getVoteData()
      if(this.pollResults.duedate) this.expirationDate = moment(new Date(this.pollResults.duedate)).format('DD MMM YYYY')
      else this.expirationDate = 'None'
      setTimeout(()=>{
        this.createResultData()
      },500)
    },
    computed: {
      pollResults() {
        if (this.pollData.Questions) return this.pollData
        else return this.pollData.pollData
      }
    },
    methods:{
      async getVoteData() {
        let _this = this
        let response = await http.get(`/msuite/${this.currentMindMap.unique_key}.json`)
        if(response && response.data.mindmap && response.data.mindmap.canvas){
          _this.pollData = JSON.parse(response.data.mindmap.canvas)
          _this.loaded = true
        } else {
          _this.$refs['errorModal'].open()
          setTimeout(()=>{
            _this.$refs['errorModal'].close()
            _this.$emit('showPoll')
          },1200)
        }
      },
      createResultData(){
        let _this = this
        this.pollResults.Questions.forEach( (poll_question, index) => {
          var json = poll_question.answerField
          var fields = Object.keys(json[0])
          var replacer = function(key, value) { return value === null ? '' : value }
          var csv = json.map(function(row){
            if (typeof(row['votes']) == 'object' && row['votes'] != null ){
              if(row['votes'].length == 0){
                _this.graph_data = {
                  answer: row['text'],
                  voter: 'None'
                }
                _this.graph_array.push(_this.graph_data)
              } else {
                row['votes'].map(function(fieldValue,index){
                  if(fieldValue == null){
                    fieldValue = 'None'
                  }
                  _this.graph_data = {
                    answer: row['text'],
                    voter: fieldValue
                  }
                  _this.graph_array.push(_this.graph_data)
                })
              }
            } else {
              if ( row['votes'] == null ){
                row['votes'] = 'None'
              }
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
          $(`#results${index}`).pivotUI(pivotData,{
            renderers: renderers,
            rendererOptions: {
              plotly: {width: 550, height: 350} }
          });
          this.graph_array = []
        })
        return true
      },
    }
  }
</script>
<style lang="scss" scoped>
  @import '../poll.scss';
</style>
