<template>
  <div @mousedown.stop="startDragIdea" class="main">
    <span @mousedown.stop="startDrag" class="start_dot" :class="C_startDotPositionClass"></span>
    <span 
      v-if="hasChild"
      class="collapse_child" 
      :class="C_expandCollapseIconPositionClass">
      <i 
        v-if="hideChildren" 
        class="material-icons collapse_icon"
        @click.stop="expandChildren"
      >add</i>
      <i 
        v-else 
        class="material-icons collapse_icon"
        @click.stop="unexpandChildren"
      >remove</i>
    </span>
    <textarea v-if="isEdited" type="text" ref="new_idea" @input="updateIdea" v-model="tempLocalValue" class="shadow-lg new_idea_selected pt-2" :class="{'blue_border': isEdited}" :style="C_newIdeaStyle"/>
    <div v-else class="new_idea">
      <div class="node_attachment text-secondary px-2">
        <i v-if="isSelected" @click.stop="addAttachModal" class="material-icons">post_add</i>
        <span class="notes_bar" :class="{'top_bar': !isSelected}">
          <i v-if="hasDescription" class="material-icons mr-2 clickable" @click.stop="addAttachModal" data-tab="description-tab">message</i>
          <span v-if="fileCount > 0" data-tab="files-tab" @click.stop="addAttachModal" class="clickable"><i data-tab="files-tab" class="far fa-file-alt"></i> <sup data-tab="files-tab" style="color: black;">{{fileCount}} </sup></span>
        </span>
      </div>
      <p v-if="isSelected" @dblclick.prevent="editNode" class="node_selected shadow-lg py-2">{{tempLocalValue}}</p>
      <p v-else class="new_idea_pg py-2">{{tempLocalValue}}</p>
    </div>
  </div>
</template>

<script>
  import _ from 'lodash'

  export default {
    props: [
      'value', 
      'isSelected', 
      'quadrant', 
      'hasChild', 
      'hideChildren', 
      'isEdited',
      'nodeAttr'
    ],

    data() {
      return {
        localValue     : this.value,
        tempLocalValue : this.value,
        DV_collapse    : this.hideChildren,
        newIdeaWidth   : '11em',
        newIdeaHeight  : '3em',
        isEditing      : false,
        fileCount      : this.nodeAttr.attach_files.length,
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
      updateIdea: _.debounce(
        function(input) {
          this.localValue     = this.$refs.new_idea.value
          this.tempLocalValue = this.$refs.new_idea.value
        },
        500
      ),
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
        this.$emit('edit-node', event)
      },
      addAttachModal(event) {
        this.$emit('open-attachment', event.target.dataset.tab)
      }
    },

    watch: {
      nodeAttr: {
        handler: function() {
          this.fileCount      = this.nodeAttr.attach_files.length
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
