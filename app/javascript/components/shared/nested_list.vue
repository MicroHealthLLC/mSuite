<template>
  <draggable
    :list="children"
    ghost-class="ghost"
    tag="p"
    class="order-list"
    :group="C_group"
    @change="onChange"
  >
    <div class="list-item" v-for="(elem, index) in children" :key="elem.id">
      <p class="li-data ml-2">
        <span>{{getlistIndex(index)}}</span> {{elem.title}}
        <div class="ml-4" v-html="elem.description"></div>
      </p>
      <nested-list 
        v-if="elem.children.length > 0" 
        :children="elem.children" 
        :group="elem.parent_node.toString()" 
        :prefix-index="getlistIndex(index)"
      />
    </div>
  </draggable>
</template>

<script>
  import draggable from "vuedraggable"
  import http      from "../../common/http"
  
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
      },
      prefixIndex: {
        required: false,
        type: String
      }
    },
    computed: {
      C_group() {
        return {
          name: this.group.toString(),
          put: false
        }
      },
    },
    methods: {
      getlistIndex(index) {
        return this.prefixIndex == "0" ? ++index +"." : this.prefixIndex +""+ ++index + "."
      },
      onChange(move) {
        if (move == undefined || move == null) return;
        let node = move.moved.element
        let data = {old_index: move.moved.oldIndex, new_index: move.moved.newIndex}

        http.put(`/nodes/${node.id}/update_export_order.json`, data)
          .then((res) => {
            console.log('export order updated!')
          }).catch((err) => {
            console.log(err)
          })
      }
    }
  }
</script>

<style lang="scss" scoped>
  .li-data {
    display: contents;
  }
  p {
    margin: 0 !important;
  }
  .order-list {
    padding-left: 1em;
  }
  .list-item {
    padding: 6px;
    margin: 10px;
    display: block;
    &:hover {
      padding: 5px;
      border: 1px dashed #ccc;
    }
  }
  .ghost {
    opacity: 0.5;
    background: #ddd;
  }
</style>
