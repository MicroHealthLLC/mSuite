<template>
  <draggable
    :disabled="!editable"
    :list="children"
    ghost-class="ghost"
    tag="p"
    :style="orderListSyle"
    :group="C_group"
    @change="onChange"
  >
    <span :style="listItemStyle" class="list-item m-2" v-for="(elem, index) in children" :key="elem.id">
      <p :style="liDataStyle" class="li-data ml-2">
        <span :style="liNumberStyle">
          <span>{{getlistIndex(index)}}</span>
          <span :style="elemTitleStyle">{{elem.title}}</span>
        </span>
        <span :style="liDataDesStyle" class="ml-4" v-html="elem.description"></span>
      </p>
      <nested-list
        :editable="editable"
        v-if="elem.children.length > 0"
        :children="elem.children"
        :group="elem.parent_node.toString()"
        :prefix-index="getlistIndex(index)"
      />
    </span>
  </draggable>
</template>

<script>
  import draggable from "vuedraggable"
  import http from "../../common/http"

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
      },
      editable: {
        required: false,
        type: Boolean
      }
    },
    computed: {
      C_group() {
        return {
          name: this.group.toString(),
          put: false
        }
      },
      orderListSyle() {
        return {
          paddingLeft: "15px",
          margin: "0 !important"
        }
      },
      listItemStyle() {
        return {
          display: "block",
          padding: "6px",
          marginLeft: "25px"
        }
      },
      liDataStyle() {
        return {
          margin: "0 !important",
          wordBreak: "break-all"
        }
      },
      liDataDesStyle() {
        return {
          display: "block",
          marginLeft: "20px !important"
        }
      },
      liNumberStyle() {
        return {
          display: "flex",
          justifyContent: "left"
        }
      },
      elemTitleStyle() {
        return {
          marginLeft: "5px"
        }
      }
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

<style lang="css" scoped>
  .list-item:hover {
    padding: 5px !important;
    border: 1px dashed #ccc;
  }
  .ghost {
    opacity: 0.5;
    background: #ddd;
  }
</style>
