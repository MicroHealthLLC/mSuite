<template>
  <div @click="id = element.id"
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
