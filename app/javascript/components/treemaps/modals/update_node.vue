<template>
  <div>
    <sweet-modal ref="updateNodeToTreeMap" id="update_node" class="of_v" title="Update Node" @click="resetValue">
      <b-row>
        <b-col cols="12">
          <b-row class="align-items-center">
            <b-col cols="3">
              <label class="align-items-center float-left font-weight-bold" for="">Select Node</label>
            </b-col>
            <b-col cols="9" class="mb-2">
              <select v-model="selectNodeId" class="form-control" @change="selectedNode()">
                <option value="" disabled selected>Select your option</option>
                <option v-for="option in nodes" v-bind:value="option.id">
                  {{ option.title }}
                </option>
              </select>
            </b-col>
          </b-row>
          <div v-if="showFormNode">
            <b-row class="align-items-center">
              <b-col cols="3">
                <label class="align-items-center float-left font-weight-bold">Title</label>
              </b-col>
              <b-col cols="9" class="mb-2">
                <input type="email" v-model="enteredTitle" class="form-control" id="" placeholder="Node title here...">
              </b-col>
            </b-row>
            <b-row class="align-items-center d-none">
              <b-col cols="3">
                <label class="align-items-center float-left font-weight-bold">Add Sized</label>
              </b-col>
              <b-col cols="9" class="mb-2">
                <input type="number" v-model="selectNode.node_width" placeholder="Enter 0 to 100" min="0" max="100" class="form-control">
              </b-col>
            </b-row>
            <b-row>
              <b-col cols="3">
                <p class="align-self-start text-left mb-2 text-left col-12 px-0 float-left font-weight-bold">Color</p>
              </b-col>
              <b-col cols="9" class="mb-2">
                <ColorPicker />
              </b-col>
            </b-row>
            <hr/>
            <b-row class="float-left">
              <button @click="updatedNode" class="btn btn-info mx-2 px-4">Update</button>
              <button @click="deleteNode" class="btn btn-danger mx-2 px-4">Delete</button>
            </b-row>
          </div>
        </b-col>
      </b-row>
    </sweet-modal>
  </div>
</template>

<script>
  import ColorPicker from './color_picker'
  import { mapGetters, mapActions } from 'vuex'

  export default {
    name:"UpdateNode",
    components:{
      ColorPicker
    },
    props: [
      'nodes'
    ],
    data(){
      return{
        selectNodeId: null,
        enteredTitle: '',
        colors: {
          hex: ''
        },
        selectNode: {},
        showFormNode: false,
        node: {
          label: "",
          parent_label: 0,
          color: '#B3FAFF'
        }
      }
    },
    computed: {
      getColor(){
        return this.getColorCode
      },
      ...mapGetters([
          'getColorCode'
        ])
    },
    methods:{
      ...mapActions([
          'addColor'
        ]),
      resetValue(){
        this.enteredTitle = ''
        this.node.label = ''
        this.node.parent_label = ''
        this.node.color = ''
        this.selectNode = {}
        this.showFormNode = false
      },
      closeModal(){
        this.$refs.updateNodeToTreeMap.close()
      },
      updatedNode() {
        this.selectNodeId = ''
        this.showFormNode = false
        this.selectNode.line_color = this.getColorCode
        this.selectNode.title = this.enteredTitle
        this.$emit('updatedNode', this.selectNode)
        this.$refs.updateNodeToTreeMap.close()
        this.selectNode = {}
      },
      deleteNode(){
      this.selectNodeId = ''
       this.showFormNode = false
       this.$emit('deleteNode', this.selectNode)
       this.selectNode = {}
       this.$refs.updateNodeToTreeMap.close()
      },
      selectedNode(){
        let id  = this.selectNodeId
        this.selectNode  = this.nodes.find( x => x.id == id )
        this.addColor({hex: this.selectNode.line_color})
        this.showFormNode = true
      }
    },
    watch: {
      "selectNode.title": function (val) {
        this.enteredTitle = val
      }
    }
  }
</script>
<style>
</style>
