<template id="mytmp">
  <div>
    <div id="mynetwork"></div>
  </div>
</template>

<script>
  import vis from 'vis-network'
  export default {
    mounted() {
      this.container = document.getElementById('mynetwork');
      this.network = new vis.Network(this.container, this.graph_data, this.options);
    },
    computed: {
      graph_data() {
        return {
          nodes: this.nodes,
          edges: this.edges
        }
      }
    },
    data() {
      return {
        nodes: [
          { id: 0, label: "0", x: -147, y: -77 },
          { id: 1, label: "1", x: -186, y: 88 },
          { id: 2, label: "2", x: 8, y: 160 },
          { id: 3, label: "3", x: 159, y: 28 },
          { id: 4, label: "4", x: 45, y: -111 },
          { id: 5, label: "4", x: 65, y: -125 }
        ],
        edges: [
          { from: 0, to: 1 },
          { from: 0, to: 1 },
          { from: 0, to: 2 },
          { from: 0, to: 3 },
          { from: 0, to: 4 },
          { from: 0, to: 4 },
          { from: 1, to: 2 },
          { from: 1, to: 3 },
          { from: 1, to: 3 },
          { from: 2, to: 3 },
          { from: 2, to: 4 },
          { from: 3, to: 4 }
        ],
        options: {
          manipulation: {
            enabled: true,
            initiallyActive: true,
            addEdge: function(edgeData, callback) {
              callback(edgeData);
            },
            dragStart: function(data, callback) {
              alert("sceded");
            }
          },
          physics: {
            enabled: false
          },
          nodes: {
            physics: false
          }
        },
        container: '',
        network: null
      }
    },
  }
</script>

<style>
#mynetwork {
  width: 100%;
  height: 80vh;
  border: 1px solid lightgray;
}
</style>