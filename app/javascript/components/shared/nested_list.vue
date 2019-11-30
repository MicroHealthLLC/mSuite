<template>
  <draggable
    :list="children"
    ghost-class="ghost"
    tag="ol"
    :group="C_group"
  >
    <li v-for="elem in children" :style="listElementStyle(elem)" :key="elem.id">
      <div class="li-data ml-2">
        {{elem.title}}
        <div class="ml-4" v-html="elem.description"></div>
      </div>
      <nested-list 
        v-if="elem.children.length > 0" 
        :children="elem.children" 
        :group="elem.parent_node.toString()" 
      />
    </li>
  </draggable>
</template>

<script>
  import draggable from "vuedraggable"
  
  export default {
    name: 'nested-list',
    components: {
      draggable
    },
    props: {
      children: {
        required: true,
        type: Array
      },
      group: {
        required: false,
        type: String
      }
    },
    methods: {
      listElementStyle(node) {
        return {
          border: "1px dashed "+ node.line_color,
          padding: "5px",
          margin: "10px"
        }
      }
    },
    computed: {
      C_group() {
        return {
          name: this.group.toString(),
          put: false
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
  .ghost {
    opacity: 0.5;
    background: #ddd;
  }
</style>
