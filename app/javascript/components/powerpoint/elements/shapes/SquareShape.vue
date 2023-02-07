<template>
  <div
    ref="rectangle"
    id="rectangle"
    :style="`
      width: ${width}px;
      height: ${height}px;
      --line_color: ${element.line_color};
      `"
    :class="element.hide_self ? 'transparent_border' : 'apply_color'"
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
  .transparent_border{
    border: 1px dotted var(--line_color);
  }
  .apply_color{
    background-color: var(--line_color);
  }
</style>
