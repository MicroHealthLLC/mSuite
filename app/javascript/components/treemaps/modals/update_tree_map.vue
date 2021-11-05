<template>
  <sweet-modal ref="updateTreeMapRef" id="update_tree_map" class="of_v" title="TreeMap Update">
    <b-row class="align-items-center" v-if="treeMaps">
      <b-col cols="1">
        <label for="" class="align-items-center float-left font-weight-bold">Title</label>
      </b-col>
      <b-col cols="11" class="mb-2">
        <input type="email" v-model="treeMaps.name" class="form-control" id="" placeholder="Node title here...">
      </b-col>
    </b-row>
    <hr/>
    <b-row>
      <b-col cols="12">
        <button @click="updateTreeMap" class="btn btn-success float-right" color="light-grey">Update TreeMap</button>
      </b-col>
    </b-row>
  </sweet-modal>
</template>

<script>

  export default {
    name:"UpdateTreeMap",
    props: [
      'treeMaps'
    ],
    data(){
      return{
      }
    },
    methods:{
      closeModal(){
        this.$refs.updateTreeMapRef.close()
      },
      updateTreeMap(){
        this.$emit('updateTreeMap', this.treeMaps)
        this.$refs.updateTreeMapRef.close()
        this.treeMaps = {}
      }
    }
  }
</script>
