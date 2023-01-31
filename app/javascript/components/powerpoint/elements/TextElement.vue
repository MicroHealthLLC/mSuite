<template>
  <div :style="`transform: rotate(${this.rotation}deg)`">
  <DynamicElement
    v-if="!editable"
    @click="editable = true"
    :element="element.element_type"
    :style="`color:${element.line_color};`"
  >
    {{element.title}}
  </DynamicElement>
  <textarea
    v-focus
    v-else-if="element.element_type == 'p' || element.element_type == 'ul'"
    class="input-editor text-field"
    v-model="element.title" @blur="updateElement"
    :style="`
      color:${element.line_color};
      background: ${parentColor};
      `">
  </textarea>
  <div v-else>
    <input
      v-focus
      class="input-editor"
      type="text"
      name="text"
      v-model="element.title"
      @blur="updateElement"
      :style="`
        color:${element.line_color};
        background: ${parentColor};
        font-size: ${fontSize};
        `">
  </div>
  </div>
</template>

<script>
import DynamicElement from "./DynamicElement.vue"
import Rotate from "./ppt-mixins/rotate.js"

export default {

  name: 'TextElement',
  props: ['element','parentColor'],
  mixins:[Rotate],
  components: {
    DynamicElement
  },
  data () {
    return {
      editable: this.element.title != 'Tap and Type' ? false : true,
      oldTitle: this.element.title,
      rotation: this.element.node_width,
    }
  },
  computed: {
    fontSize(){
      switch (this.element.element_type) {
        case "h1":
          return '2.5rem'
        case "h2":
          return '2rem'
        case "h3":
          return '1.75rem'
        case "h4":
          return '1.5rem'
        case "h5":
          return '1.25rem'
        default:
          return '1rem'
      }
    },
  },
  methods: {
    updateElement(){
      this.editable = this.element.title != 'Tap and Type' ? false : true
      this.element.node_width = this.rotation

      if (this.element.title == '') {
        this.element.title = this.oldTitle
        this.$emit('deleteElement', this.element)
      } else this.$emit('updateElement', this.element)
    },
  }
}
</script>

<style lang="css" scoped>
  .input-editor{
    border: dotted;
  }
</style>
