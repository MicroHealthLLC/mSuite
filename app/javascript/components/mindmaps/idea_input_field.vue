<template>
  <div @mousedown.stop="startDragIdea" @touchstart.stop="startDragIdea" class="main">
    <span v-if="editable" @mousedown.stop="startDrag" @touchstart.stop="startDrag" class="start_dot" :class="C_startDotPositionClass"></span>
    <span
      v-if="hasChild"
      class="collapse_child"
      :class="C_expandCollapseIconPositionClass">
      <span
        v-show="hideChildren"
        class="collapse_icon"
        @click.stop="expandChildren"
      ><i class="fa fa-plus-square"></i></span>
      <span
        v-show="!hideChildren"
        class="collapse_icon"
        @click.stop="unexpandChildren"
      ><i class="fa fa-minus-square"></i></span>
    </span>
    <textarea v-if="isEdited" type="text" ref="new_idea" @input="updateIdea" v-model="tempLocalValue" class="shadow-lg new_idea_selected pt-2" :class="{'blue_border': isEdited}" :style="C_newIdeaStyle"/>
    <div v-else class="new_idea row">
      <div class="col-12 px-0">
        <span v-if="isSelected" class="mr-2 clickable float-right" :class="hasDescription ? 'text-info':''" @click.stop="addAttachModal" data-tab="description-tab"><i class="fa fa-comment"></i></span>
      </div>
      <div class="node_attachment text-secondary px-2 col-12 px-0">
        <span class="notes_bar" :class="{'top_bar': !isSelected}">
        </span>
      </div>
      <div class="col-12 px-0">
        <p v-if="isSelected" @dblclick.prevent="editNode" class="node_selected shadow-lg py-2">{{tempLocalValue}}</p>
        <p v-else class="new_idea_pg">{{tempLocalValue}}</p>
      </div>
    </div>
  </div>
</template>

<script>
  import {debounce} from 'lodash'

  export default {
    props: [
      'value',
      'isSelected',
      'quadrant',
      'hasChild',
      'hideChildren',
      'isEdited',
      'nodeAttr',
      'editable',
      'isEditing'
    ],

    data() {
      return {
        localValue     : this.value,
        tempLocalValue : this.value,
        DV_collapse    : this.hideChildren,
        newIdeaWidth   : '11em',
        newIdeaHeight  : '3em',
        isEditing      : false,
        hasDescription : !!this.nodeAttr.description
      }
    },

    computed: {
      C_expandCollapseIconPositionClass() {
        if (this.quadrant == "UL" || this.quadrant == "LL") {
          return "left_position_icon"
        }
        return "right_position_icon"
      },
      C_startDotPositionClass() {
        if (this.quadrant == "UL" || this.quadrant == "LL") {
          return "start_dot_left"
        }
        return "start_dot_right"
      },
      C_newIdeaStyle() {
        return {
          width    : this.newIdeaWidth,
          height   : this.newIdeaHeight,
          minHeight: "3em"
        }
      }
    },

    methods: {
      startDrag(event) {
        this.$emit('start-drag', event)
      },
      updateIdea: function(input) {
        this.localValue     = this.$refs.new_idea.value
        this.tempLocalValue = this.$refs.new_idea.value
        this.isEditing = true
        this.$emit('sendLocals', event)
      },
      startDragIdea(event) {
        this.$emit('mousedown-event', event)
        if (event.target.classList.contains("clickable")) {
          this.addAttachModal(event)
        }
      },
      expandChildren() {
        this.DV_collapse = false
        this.$emit('switch-expand-children', this.DV_collapse)
      },
      unexpandChildren() {
        this.DV_collapse = true
        this.$emit('switch-expand-children', this.DV_collapse)
      },
      editNode(event) {
        if (!this.editable) return false
        this.$emit('edit-node', event)
      },
      addAttachModal(event) {
        this.$emit('open-attachment', event.target.dataset.tab)
      }
    },
    watch: {
      nodeAttr: {
        handler() {
          this.hasDescription = !!this.nodeAttr.description
        }, deep: true
      },
      value() {
        this.tempLocalValue = this.value
      },
      localValue() {
        this.$emit("input", this.localValue)
        this.$emit("node-updated")
      },
      tempLocalValue(value) {
        let dheight        = Math.ceil(value.length / 15)
        dheight            = dheight > 1 ? dheight * 2 : 3
        this.newIdeaHeight = dheight > 8 ? "8em" : dheight + "em"
      },
      isSelected() {
        let dheight        = Math.ceil(this.value.length / 15)
        dheight            = dheight > 1 ? dheight * 2 : 3
        this.newIdeaHeight = dheight > 8 ? "8em" : dheight + "em"
      }
    }
  }
</script>

<style scoped lang="scss">
  @import "./styles/idea_input_field.scss";
</style>
