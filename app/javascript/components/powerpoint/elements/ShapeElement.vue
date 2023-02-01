<template>
  <div @click="id = element.id"
    class="position-relative"
    :style="selectedElement && selectedElement.id == id ? `
      border: 2px dotted ${element.line_color};
      ` : ''">
    <div v-if="element.element_type == 'square'">
      <SquareShape :element="element" @updateElement="updateElement"/>
    </div>
    <div v-else-if="element.element_type == 'circle'">
      <CircleShape :element="element" @updateElement="updateElement"/>
    </div>
    <div v-else>
      <TriangleShape :element="element" @updateElement="updateElement"/>
    </div>
    <div
      v-if="selectedElement && selectedElement.id == id"
      class="position-absolute icon"
      :style="`
        left:${(element.element_width - 12) / 2}px;
        top: -20px;
      `"
      @mousedown="$emit('dragStart',$event)"
    >
      <i class="fas fa-arrows-alt position-absolute"></i>
    </div>
    <div
      v-if="selectedElement && selectedElement.id == id"
      class="position-absolute delete-icon-pos"
    >
      <i @click.stop="$emit('deleteElement', element)" class="fas fa-times bg-danger rounded-circle text-white px-1"></i>
    </div>
  </div>
</template>

<script>
  import SquareShape from "./shapes/SquareShape.vue"
  import CircleShape from "./shapes/CircleShape.vue"
  import TriangleShape from "./shapes/TriangleShape.vue"

  export default {
    props: ['element','parentColor','selectedElement'],
    components: {
      SquareShape,
      CircleShape,
      TriangleShape
    },
    data () {
      return {
        id: 0,
      }
    },
    methods: {
      updateElement(element){
        this.$emit("updateElement", element)
      }
    }
  }
</script>
<style lang="scss" scoped>
  @import "../style/styles.scss"
</style>
