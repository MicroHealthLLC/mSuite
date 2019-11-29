<template>
  <ol class="text-left">
    <li v-for="l in list" :style="listColor(l)">
      <div class="li-data ml-2">
        {{l.title}}
        <div class="ml-4" v-html="l.description"></div>
      </div>
      <nested-list :list="l.children" />
    </li>
  </ol>
</template>

<script>
export default {
  name: 'nested-list',
  props: [
    'list'
  ],
  methods: {
    listColor(node) {
      return {
        color: node.line_color
      }
    }
  }
}
</script>

<style lang="scss" scoped>
.li-data {
  display: contents;
}
ol {
  padding-left: 1em;
  counter-reset: item;
}
li {
  display: block;
}
li:before {
  content: counters(item, ".") ".";
  counter-increment: item;
}
</style>
