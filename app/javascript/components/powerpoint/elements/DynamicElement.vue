<template>
  <component v-if="element.element_type == 'ul' || element.element_type == 'ol'" :is="element.element_type" v-bind="$attrs" v-on="$listeners">
    <li  v-for="li in getList" :key="li">
      {{li}}
    </li>
  </component>
  <component v-else :is="element.element_type" v-bind="$attrs" v-on="$listeners">
    <slot/>
  </component>
</template>

<script>
export default {
  props: {
    element: {
      type: Object,
      default: null,
    },
  },
  computed: {
    getList(){
      return (this.element.element_type == 'ul' || this.element.element_type == 'ol') ? this.element.description.split('\n') : []
      }
  }
}
</script>
