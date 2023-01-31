<template>
  <component v-if="element == 'ul'" :is="element" v-bind="$attrs" v-on="$listeners">
    <li>
      <slot/>
    </li>
  </component>
  <component v-else :is="element" v-bind="$attrs" v-on="$listeners">
    <slot/>
  </component>
</template>

<script>
export default {
  props: {
    element: {
      type: String,
      default: 'span',
    },
  },
  mounted() {
    if(this.element == 'ul'){}
  }
}
</script>
