<template>
  <div
    ref="rectangle"
    id="rectangle"
    :style="`
      width: ${width}px;
      height: ${height}px;
      background-color: ${element.line_color};`"
    class="border"
    v-on:dblclick="startResizing"
    @mousemove.stop="resize"
    @mouseup.stop="stopResizing"
  >
  </div>
</template>

<script>
import Resize from "../ppt-mixins/resize.js"
export default {
  name: "RectangleShape",
  props: ["element"],
  mixins: [Resize],
  data() {
    return {
      width: this.element.element_width,
      height: this.element.element_height,
    };
  },
};
</script>
<style type="text/css" scoped>
</style>
