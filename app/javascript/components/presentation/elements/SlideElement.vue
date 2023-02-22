<template>
  <DynamicElement
    :element="element.element_type"
    :style="`color:${element.line_color}; font-size: ${fontSize}`"
  >
    {{element.title}}
  </DynamicElement>
</template>

<script>
import DynamicElement from "./DynamicElement.vue"
export default {

  name: 'TextElement',
  props: ['element','parentColor'],
  components: {
    DynamicElement
  },
  data () {
    return {
      editable: this.element.title != '' ? false : true
    }
  },
  computed: {
    fontSize(){
      switch (this.element.element_type) {
        case "h1":
          return '0.4rem'
        case "h2":
          return '0.3rem'
        case "h3":
          return '0.2rem'
        case "h4":
          return '0.1rem'
        case "h5":
          return '0.05rem'
        default:
          return '0.01rem'
      }
    }
  },
  methods: {
    updateElement(){
      this.editable = false
      this.$emit('updateElement', this.element)
    },
  }
}
</script>

<style lang="css" scoped>
  .input-editor{
    border: dotted;
  }
</style>
