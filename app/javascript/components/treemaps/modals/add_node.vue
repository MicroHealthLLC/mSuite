<template>
  <div>
    <sweet-modal ref="addNodeToTreeMap" id="add_node" class="of_v" title="Add Node TreeMap" @close="resetValue">
      <div class="row my-2">
        <label class="align-self-center mb-0 text-left col-3 px-0 float-left font-weight-bold" for="">Select Parent</label>
        <select v-model="node.parent_label" class="form-control col-9">
          <option value="" disabled selected>Select your option</option>
          <option v-bind:value="treeMap" v-if="treeMap"> {{treeMap.name}} </option>
          <option v-for="option in nodes" v-bind:value="option.id">
            {{ option.title }}
          </option>
        </select>
      </div>
      <div class="row my-2">
        <label for="" class="align-self-center mb-0 text-left col-3 px-0 float-left font-weight-bold">Title</label>
        <input type="email" v-model="node.label" class="col-9 form-control" id="" placeholder="Node title here...">
      </div>
      <div class="row my-2 d-none">
        <label for="" class="align-self-center mb-0 text-left col-3 px-0 float-left font-weight-bold">Add Size</label>
        <input type="number" v-model="node.node_width" placeholder="Enter 0 to 100" min="0" max="100" class="form-control col-9">
      </div>


      <div class="row my-2">
        <p class="align-self-start mb-0 text-left mb-0 text-left col-3 px-0 float-left font-weight-bold">Color</p>
        <div class="col-9 px-0">
          <ColorPicker />
        </div>
      </div>
      <hr/>
      <b-row>
        <b-col cols="12">
          <button @click="saveNode" class="btn btn-success float-left" color="light-grey" :disabled="disableAddNode">Add Node</button>
        </b-col>
      </b-row>
    </sweet-modal>
  </div>
</template>

<script>
  import ColorPicker from './color_picker'
  import { mapGetters, mapActions } from 'vuex'

  export default {
    name:"AddNode",
    components: {
      ColorPicker
    },
    props: [
      'nodes',
      'treeMap'
    ],
    data(){
      return{
        colors: { h: 150, s: 0.66, v: 0.30 },
        node: {
          label: '',
          parent_label: '',
          node_width: '',
          color: '#000000'
        }
      }
    },
    methods:{
      resetValue(){
        this.node.label = ''
        this.node.parent_label = ''
      },
      closeModal(){
        this.$refs.addNodeToTreeMap.close()
      },
      saveNode() {
        this.node.color = this.getColorCode
        this.node.label = this.node.label.trim();
        if (this.node.parent_label == 'treeMap'){
          this.node.parent_label = ''
        }
        this.$emit('saveNode', this.node)
        this.node.label = ''
        this.$refs.addNodeToTreeMap.close()
      },
      setColor(value){
        this.colors.hex = value
        this.node.color = value
      }
    },
    computed: {
      disableAddNode() {
        return this.node.label.length > 0 ? false : true;
      },
      ...mapGetters([
          'getColorCode'
        ])
    }
  }
</script>
