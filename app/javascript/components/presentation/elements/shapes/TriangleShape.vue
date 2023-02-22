<template>
  <div
    id="triangle-container"
    v-on:dblclick="startResizing"
    @mousemove.stop="resize"
    @mouseup.stop="stopResizing">
    <div
      id="triangle"
      :style="`
        border-bottom: ${height}px solid ${element.line_color};
        border-left: ${width/2}px solid transparent;
        border-right: ${width/2}px solid transparent;
        height: 0;
        width: ${width}px;
      `">
    </div>
  </div>
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
    }
  },
};
</script>
<style scoped>
  .rotate-90{
    transform: rotate(90deg);
  }
  #triangle-container {
    position: relative;
    height: 100%;
    width: 100%;
  }
</style>
