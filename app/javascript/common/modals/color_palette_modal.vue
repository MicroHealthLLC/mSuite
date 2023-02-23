<template>
  <div class="card-body p-0 border rounded">
    <sketch-picker v-if="selectedNode && mm_type == 'kanban'" class="rounded-0 size-color-picker" v-model="selectedNode.stage_color" :preset-colors="uniqueColors" @input="updateColorNode()"/>
    <sketch-picker v-else v-model="node.line_color" :preset-colors="uniqueColors" @input="updateColorNode()" class=" h-25 overflow-auto size-color-picker rounded-0"/>
    <div v-if="showRandomPl" class="pallete d-flex flex-row w-50">
      <div class="row w-100 bg-white">
        <div v-for="colorPalette in customPallete" class="col-2">
          <div
            class="color-pallete mt-2"
            :style="'background-color:' + colorPalette"
            @click="paletteUpdateColor">
          </div>
        </div>
      </div>
    </div>
    <div class="card-button d-flex mt-1">
      <button class="btn btn-success w-50 border-none" @click="saveNodeColor">Update</button>
      <button
        class="btn btn-info border-none"
        :class="showRandomPl && this.mm_type != 'presentation' ? 'w-25':'w-50'"
        @click="closeModelPicker">
        Cancel
      </button>
      <button
        v-if="showRandomPl && this.mm_type != 'presentation'"
        class="btn btn-warning border-none w-25"
        @click="createPalette">
          <i class="fas fa-sync cursor-pointer mt-2"></i>
      </button>
      <button
        v-else-if="presentationSlide"
        class="btn btn-warning border-none w-50"
        @click="applyColorOnAllNodes"
      >
        Apply All
      </button>
    </div>
  </div>
</template>

<script>
  import Palette from "@color-palette/color-palette"
  import TemporaryUser from "../../mixins/temporary_user.js"


  export default {
    data(){
      return{
        randomColor: Palette.random(5),
        customPallete: [],
        node_color: '',
        currentMindMap: this.$store.getters.getMsuite,
        mm_type: this.$store.getters.getmmType
      }
    },
    props:['selectedNode', 'selectedBlock', 'nodes', 'uniqueColors'],
    mixins: [TemporaryUser],
    computed: {
      node(){
        return this.selectedNode ? this.selectedNode : this.selectedBlock
      },
      showRandomPl() {
        return (this.mm_type != 'calendar') && ((this.selectedNode && this.mm_type == 'kanban') || this.mm_type != 'kanban')
      },
      presentationSlide(){
        return this.mm_type == 'presentation' && !this.node.parent_nod
      }
    },
    mounted() {
      if(this.mm_type != 'calendar' && this.mm_type != 'presentation') this.createPalette()
    },
    methods: {
      saveNodeColor(){
        if (this.palette) this.paletteSaveColor()
        else this.$emit("saveNodeColor")
      },
      closeModelPicker(){
        if (this.mm_type == 'tree_map'){
          let myClass = 'jqx-treemap-rectangle'
          let element = document.getElementsByClassName(myClass)[0]
          element.style.backgroundColor = this.currentMindMap.line_color
          Object.values(this.nodes).forEach((node, index) => {
            let element = document.getElementsByClassName(myClass)[index + 1]
            element.style.backgroundColor = node.line_color
          });
        }
        else if (this.mm_type == 'kanban') {
          if(this.selectedNode){
            Object.values(this.nodes).forEach((stage, index) => {
              let element = document.getElementsByClassName('drag-column')[index]
              element.style.backgroundColor = stage.stage_color
            });
          }
        } else if (this.mm_type == 'calendar' || this.mm_type == 'presentation'){
          this.$emit("closeModelPicker")
          return
        }
        else {
          let parentElement = document.getElementById('treeChart'+undefined)
          parentElement.style.backgroundColor = this.currentMindMap.line_color

          Object.values(this.nodes).forEach((node, index) => {
            var objNode = {id: '', line_color: ''}
            objNode.id = node.id
            let element = document.getElementById('treeChart'+ node.id)
            element.style.backgroundColor = node.line_color
            objNode.line_color = node.line_color
          });
        }

        this.$emit("closeModelPicker")
      },
      updateColorNode(){
         this.mm_type == 'kanban' ? this.$emit("updateColorNode") : this.$emit("updateColorNode", this.node.line_color)
      },
      applyColorOnAllNodes(){
        this.$emit("updateAllColorNode", this.node.line_color)
      },
      paletteUpdateColor(){
        if (this.mm_type == 'tree_map' || this.mm_type == 'kanban'){
          let myClass = ''
          if (this.mm_type == 'tree_map') myClass = 'jqx-treemap-rectangle'
          else myClass = 'drag-column'
          Object.values(this.nodes).forEach((node, index) => {
            var objNode = {id: '', line_color: ''}
            objNode.id = node.id
            let element = document.getElementsByClassName(myClass)[index]
            element.style.backgroundColor = this.customPallete[index]
            objNode.line_color = this.customPallete[index]
          });
          if(this.mm_type == 'tree_map'){
            let element = document.getElementsByClassName('jqx-treemap-rectangle')[this.nodes.length]
            element.style.backgroundColor = this.customPallete[this.nodes.length]
          }
        }
        else {
          let element = document.getElementById('treeChart' + undefined)
          element.style.backgroundColor = this.customPallete[0]
          Object.values(this.nodes).forEach((node, index) => {
            var objNode = {id: '', line_color: ''}
            objNode.id = node.id
            let element = document.getElementById('treeChart'+ node.id)
            element.style.backgroundColor = this.customPallete[index + 1]
            objNode.line_color = this.customPallete[index + 1]
          });
        }
        this.palette = true
      },
      paletteSaveColor(){
        this.currentMindMap.line_color = this.customPallete[0]
        this.$store.dispatch('updateMSuite', this.currentMindMap)
        // this.$emit("updatedTreeChart" , this.currentMindMap)
        Object.values(this.nodes).forEach((node, index) => {
          var objNode = {id: '', line_color: '', stage_color: ''}
          objNode.id = node.id
          objNode.line_color = this.customPallete[index + 1]
          objNode.stage_color = this.customPallete[index]
          this.$emit("updateTreeChartNode", objNode)
        });
        if(this.mm_type == 'tree_map') this.sendLocals(false)
      },
      createPalette(){
        this.customPallete = []
        if (this.mm_type == "kanban") this.randomColor = Palette.random(this.nodes.length)
        else this.randomColor = Palette.random(this.nodes.length + 1)
        this.randomColor.forEach((x, i) => {
          let h = parseInt(x.substring(4,7))
          let s = parseInt(x.substring(8,11))
          let l = parseInt(x.substring(12,15))
          this.customPallete.push(this.hslToHex(h, s, l))
        });
      },
      hslToHex(h, s, l) {
        l /= 100;
        const a = s * Math.min(l, 1 - l) / 100;
        const f = n => {
          const k = (n + h / 30) % 12;
          const color = l - a * Math.max(Math.min(k - 3, 9 - k, 1), -1);
          return Math.round(255 * color).toString(16).padStart(2, '0');
        };
        return `#${f(0)}${f(8)}${f(4)}`;
      },
    }
  }
</script>

<style>
  .presentation{

  }
</style>
