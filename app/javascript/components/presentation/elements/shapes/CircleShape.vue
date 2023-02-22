<template>
  <div
    class="resizable-circle"
    :style="`width: ${width}px; height: ${height}px; background-color: ${element.line_color};`"
    v-on:dblclick="startResizing"
    @mousemove.stop="resize"
    @mouseup.stop="stopResizing"
  ></div>
</template>

<script>
import Resize from "../ppt-mixins/resize.js"
export default {
  props: ["element"],
  mixins: [Resize],
  data() {
    return {
      width: this.element.element_width,
      height: this.element.element_height,
      color: this.element.line_color,
    }
  },
}
</script>

<style>
.resizable-circle {
  border-radius: 50%;
}
</style>
