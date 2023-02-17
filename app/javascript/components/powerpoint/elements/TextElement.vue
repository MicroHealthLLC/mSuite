<template>
  <div @click="id = element.id"
    class="position-relative"
    :style="selectedElement && selectedElement.id == id ? `
      border: 2px dotted ${element.line_color};
      ` : ''">
    <DynamicElement
      v-if="!editable"
      @click="editable = true"
      :element="element"
      :style="`
        color:${element.line_color};
        width:${element.element_width}px;
        z-index:${element.id};
        `"
    >
      {{element.description}}
    </DynamicElement>
    <textarea
      v-focus
      ref="textarea"
      v-else
      class="input-editor text-field resizing-area"
      v-model="element.description" @blur="updateElement"
      :style="`
        width:${element.element_width}px;
        color:${element.line_color};
        background: ${parentColor};
        font-size: ${fontSize};
        `">
    </textarea>
    <div
      v-if="selectedElement && selectedElement.id == id"
      class="position-absolute icon"
      :style="`
        left:50%;
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
import DynamicElement from "./DynamicElement.vue"
import Rotate from "./ppt-mixins/rotate.js"

export default {

  name: 'TextElement',
  props: ['element','parentColor', 'selectedElement'],
  mixins:[Rotate],
  components: {
    DynamicElement
  },
  data () {
    return {
      editable: this.element.description != 'Tap and Type' ? false : true,
      oldTitle: this.element.description,
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
    }
  },
  methods: {
    updateElement(){
      this.editable = this.element.description != 'Tap and Type' ? false : true
      this.element.node_width    = this.rotation
      this.element.element_width = this.$refs.textarea ? this.$refs.textarea.scrollWidth : this.$refs.inputField.scrollWidth
      if (this.element.description == '') {
        this.element.description = this.oldTitle
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
<style lang="scss" scoped>
  @import "../style/styles.scss"
</style>
