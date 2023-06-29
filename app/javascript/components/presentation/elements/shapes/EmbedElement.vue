<template>
  <div
    :style="`
      display:block;
      width:${width}px;
      height:${height}px;
    `"
    v-on:dblclick="startResizing"
    @mousemove.stop="resize"
    @mouseup.stop="stopResizing"
  >
    <div v-if = "element.element_type == 'image'">
      <img :src="element.description" :width="width" :height="height" />
    </div>
    <div v-else>
      <div class="w-100">
        <iframe
          :id="`frame-${element.id}`"
          :style="`
            width:${width}px;
            height:${height}px;
          `"
          :src="`${element.description}?autoplay=1`"
          style="position:absolute; display:block; top:0; left: 0"
        ></iframe>
      </div>
    </div>
  </div>
</template>

<script>
import Resize from "../ppt-mixins/resize.js"
export default {

  name: 'VideoElement',
  props: ["element"],
  mixins: [Resize],

  data () {
    return {
      width: this.element.element_width,
      height: this.element.element_height,
    }
  }
}
</script>

<style lang="css" scoped>
</style>
