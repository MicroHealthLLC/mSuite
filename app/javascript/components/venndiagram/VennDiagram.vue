<template>
  <div class="container">
    <div class="w-100">
      <highcharts id="venndiagram" :options="chartOptions" :key="componentKey"/>
    </div>
    <div class="d-flex flex-row justify-content-end position-relative z-index-inherit bottom-4 right-1">
      <b-button v-b-tooltip.hover title="Add" type="submit" variant="success" @click="addValue"> <i class="fas fa-plus"></i> </b-button>
    </div>
    <venn-form v-if="addBar" @addNewValue="addNewValue"></venn-form>
    <venn-popup
      id="edit"
      v-if="openEditBox"
      :selectedSet="selectedSet"
      @updateSet="updateSet"
      @deleteSet="deleteSet"
      @closeEditBox="closeEditBox"
      class="position-fixed editBox rounded p-1">
    </venn-popup>
    <sweet-modal ref="dataErrorModal" class="of_v" icon="error">
      This Data set is already declared. Try another!
    </sweet-modal>
  </div>
</template>
<script>
  import http from "../../common/http"
  import TemporaryUser from "../../mixins/temporary_user.js"
  import History from "../../mixins/history.js"
  import vennForm from "./utils/vennForm"
  import vennPopup from "./utils/vennPopup"
  export default {
    props: {
      undoMap: Function,
      redoMap: Function
    },
    mixins: [TemporaryUser, History],
    components: {
      vennForm,
      vennPopup
    },
    channels: {
      WebNotificationsChannel: {
        received(data) {
          if (data.message === "Mindmap Deleted" && this.currentMindMap.id === data.mindmap.id)
          {
            window.open('/','_self')
          } else if (data.message === "Mindmap Updated" && this.currentMindMap.id === data.mindmap.id ) {
            this.$store.commit('setMSuite', data.mindmap)
            this.fetchSets()
          }else if (data.message === "Password Updated" && this.currentMindMap.id === data.mindmap.id) {
            setTimeout(() => {
              location.reload()
            }, 500)
          } else if (data.message === "storage updated" && this.currentMindMap.id == data.content.mindmap_id)
          {
            this.$store.dispatch('setUserEdit'     , data.content.userEdit)
            this.$store.dispatch('setNodeNumber' , data.content.nodeNumber)
            this.$store.dispatch('setTemporaryUser', data.content.userEdit)
            this.$store.dispatch('setUserList'     , data.content.userEdit)
          } else if (data.message === "Reset mindmap" && this.currentMindMap.id === data.mindmap.id) {
            this.$store.commit('setMSuite', data.mindmap)
            this.currentMindMap = data.mindmap
            this.fetchSets()
          }
          else {
            this.fetchSets()
          }
        }
      }
    },
    data(){
      return {
        currentMindMap: this.$store.getters.getMsuite,
        data: [],
        addBar: false,
        savedSets: [],
        selectedSet: null,
        openEditBox: false,
        undoNodes: [],
        redoNodes: [],
        componentKey: 0
      }
    },
    computed: {
      chartOptions() {
        return {
          series: [this.vennData],
          title: {
            text: "",
            style: {
              fontSize: 14,
            },
          },
          chart: {
            height: 500,
            borderWidth: 1,
            borderColor: "#ccc",
          },
          credits: {
            enabled: false,
          },
          tooltip: {
            formatter() {
              if(typeof(this.point.sets) == 'string') this.point.sets = this.point.sets.split(",").map(String)
              return `<strong>${this.point.sets.join(
                ","
              )}</strong><br /><span>values: ${this.point.value}</span>`;
            },
          },
          legend: {
            align: "left",
          },
        };
      },
      vennData() {
        let data = this.data
        return {
          type: "venn",
          data,
          point: {
            events: {
              click: (event) => {
                this.pointClick(event)
              }
            }
          }
        };
      },
    },
    mounted(){
      this.subscribeCable(this.currentMindMap.id)
      this.$store.dispatch('setExportId', 'venndiagram')
      this.sendLocals()
      this.fetchSets()
      this.undoMap(this.undoObj)
      this.redoMap(this.redoObj)
    },
    methods: {
      addValue(){
        this.addBar = true
      },
      addNewValue(dataSet){
        let dataArray  = dataSet.sets.split(",").map(String);
        let dataValue  = parseFloat(dataSet.value)
        let createData = {
          sets : dataArray,
          value: dataValue
        }
        if (dataSet.name != '') createData.name = dataSet.name
        this.addBar = false
        this.addNewSet(createData, dataSet)
      },
      addNewSet(createData, dataSet) {
        let nodeName = ''
        if (createData.name) nodeName = createData.name
        let data = {
          node: {
            title: nodeName,
            description: dataSet.sets,
            mindmap_id: this.currentMindMap.id,
            position: createData.value,
            line_color: "#B3FAFF"
          }
        }
        http.post(`/nodes.json`, data).then((res) => {
          if(res.data.node.id){
            this.updateVennUser()
            this.sendLocals()
            this.undoNodes.push({req: 'addNode', receivedData: res.data.node})
          } else {
            this.$refs["dataErrorModal"].open()
          }
        }).catch((err) => {
          console.log(err);
        });
      },
      async updateSet(){
        let mySet = {
          title: this.selectedSet.name,
          position: this.selectedSet.value,
          description: this.selectedSet.sets.toString(),
          line_color: this.selectedSet.color
        }
        if(this.undoNodes.length > 0) {
          this.undoNodes.forEach((element, index) => {
            if(element['receivedData']){
              if(element['receivedData'].id === this.selectedSet.nodeId) {
                this.undoNodes[index]['receivedData'].title = mySet.title
                this.undoNodes[index]['receivedData'].position = mySet.position
                this.undoNodes[index]['receivedData'].description = mySet.description
                this.undoNodes[index]['receivedData'].line_color = mySet.line_color
              }
            } else {
              if(element['node'].id === this.selectedSet.nodeId) {
                this.undoNodes[index]['node'].title = mySet.title
                this.undoNodes[index]['node'].position = mySet.position
                this.undoNodes[index]['node'].description = mySet.description
                this.undoNodes[index]['node'].line_color = mySet.line_color
              }
            }
          });
        } else {
          this.undoNodes.push({'req': 'addNode', node: mySet})
        }
        this.openEditBox = false
        var _this = this
        await http.put(`/nodes/${this.selectedSet.nodeId}`, mySet).then( async (res) => {
          this.updateVennUser()
          this.sendLocals()
        }).catch( err => {
          console.log(err);
        })
      },
      deleteSet(){
        http.delete(`/nodes/${this.selectedSet.nodeId}.json`).then((res)=>{
          this.openEditBox = false
          this.updateVennUser()
          this.sendLocals()
          let myNode = {
            id: this.selectedSet.nodeId,
            title: this.selectedSet.name,
            mindmap_id: this.currentMindMap.id,
            position: this.selectedSet.value,
            description: this.selectedSet.sets.toString(),
            line_color: this.selectedSet.color
          }
          this.undoNodes.push({'req': 'deleteNode', node: myNode})
        })
      },
      async fetchSets() {
        let res = await this.$store.dispatch('getMSuite')
        let response = this.$store.getters.getMsuite
        this.$store.dispatch('setMindMapId', response.id)
        this.defaultDeleteDays = response.defaultDeleteDays
        this.deleteAfter = response.deleteAfter
        this.expDays = response.expDays
        this.$store.commit('SET_MSUITE', response)
        this.savedSets = response.nodes
        this.renderSets()
      },
      renderSets(){
        let dataReceived = []
        this.data = []
        this.savedSets.forEach((node) => {
          let dataArray  = node.description.split(",").map(String)
          let createData = {
            sets : dataArray,
            value: node.position,
            color: node.line_color
          }
          if (node.title != '') createData.name = node.title
          dataReceived.push(createData)
        })
        var uniqueData = dataReceived.filter((v, i, a) => a.indexOf(v) === i);
        this.data = uniqueData
        this.forceRerender()
      },
      async updateVennUser(){
        await this.$store.dispatch('updateMSuite',  {
          canvas: this.$store.getters.getUser
        })
      },
      pointClick(event) {
        this.selectedSet = event.point
        let getNode = this.savedSets.find( n => {
          let title = n.description
          if (n.title != '') title = n.title
          if (title === this.selectedSet.name) return n
        })
        this.selectedSet.nodeId = getNode.id
        this.openEditBox = true
        setTimeout(()=>{
          let element = document.getElementById('edit')
          element.style.top  = this.selectedSet.plotY + 'px'
          element.style.left = this.selectedSet.plotX + 'px'
        },10)
      },
      forceRerender() {
        this.componentKey += 1
      },
      closeEditBox(){
        this.openEditBox = false
      },
      async undoObj(){
        this.undoDone = true
        let undoObj = await this.undoNode(this.undoNodes)
        if(undoObj){
          this.undoNodes.pop()
          this.redoNodes.push({req: undoObj.req, node: undoObj.node})
        }
      },
      async redoObj(){
        let redoObj = await this.redoNode(this.redoNodes)
        if(redoObj){
          this.redoNodes.pop()
          this.undoNodes.push({req: redoObj.req, receivedData: redoObj.node})
        }
      },
    }
  };
</script>
<style>
  .z-index-inherit{
    z-index: inherit;
  }
  .bottom-4{
    bottom: 40px;
  }
  .right-1{
    right: 10px;
  }
  .editBox{
    background: #fff;
    border: 2px solid #ccc;
    transition: all 0.6s ease;
  }
</style>