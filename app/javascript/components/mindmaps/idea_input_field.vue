<template>
  <div @mousedown.stop="startDragIdea" class="main">
    <span @mousedown.stop="startDrag" class="start_dot" :class="C_startDotPositionClass"></span>
    <span 
      v-if="hasChild"
      class="collapse_child" 
      :class="C_expandCollapseIconPositionClass">
      <i 
        v-if="hideChildren == false" 
        class="material-icons collapse_icon"
        @click.stop="switchExpandChildren"
      >remove</i>
      <i 
        v-else 
        class="material-icons collapse_icon"
        @click.stop="switchExpandChildren"
      >add</i>
    </span>
    <textarea v-if="isEdited" type="text" ref="new_idea" @input="updateIdea" v-model="tempLocalValue" class="shadow-lg new_idea_selected pt-2" :class="{'blue_border': isEdited}" :style="newIdeaStyle"/>
    <div v-else class="new_idea">
      <div class="node_attachment text-secondary px-2">
        <i v-if="isSelected" @click.stop="addAttachModal" class="material-icons">post_add</i>
        <span class="notes_bar">
          <i v-if="hasDescription" class="material-icons mr-2">message</i>
          <span v-if="fileCount > 0"><i class="far fa-file-alt"></i> <sup style="color: black;">{{fileCount}} </sup></span>
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
        isEditing      : false
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
      newIdeaStyle() {
        return {
          width : this.newIdeaWidth,
          height: this.newIdeaHeight
        }
      },
      fileCount() {
        return this.nodeAttr.attach_files.length
      },
      hasDescription() {
        return !!this.nodeAttr.description
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
      },
      switchExpandChildren() {
        this.DV_collapse = !this.DV_collapse
        this.$emit('switch-expand-children', this.DV_collapse)
      },
      editNode() {
        this.$emit('edit-node', event)
      },
      addAttachModal() {
        this.$emit('open-attachment', event)
      }
    },

    watch: {
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
  .blue_border {
    border: 2px solid blue !important;
  }
  .new_idea_selected {
    text-align   : center;
    border       : none;
    border       : 2px solid;
    border-radius: 10px;
    font-weight  : 700;
    font-size    : 80%;
    line-height  : 1.2;
    word-wrap    : break-word;
    position     : absolute;
    bottom       : -3em;
  }
  .new_idea {
    cursor     : pointer;
    text-align : center;
    font-weight: normal;
    resize     : none;
    background : none;
    word-wrap  : break-word;
    width      : 11em;
    font-size  : 80%;
    line-height: 1.2;
    margin-top : 0.5em;
    position   : absolute;
    bottom     : -4em;
    padding    : 2px;
  }
  .node_selected {
    border-radius: 10px;
    border       : 2px solid red !important;
    cursor       : move !important;
  }
  .new_idea_pg:hover {
    padding      : unset;
    border       : 2px dotted #ccc;
    border-radius: 10px;
    box-shadow   : 0 0.3em 0.8em rgba(0, 0, 0, 0.15);
  }
  .main:hover .start_dot{
    display: inline-block;
  }
  .start_dot {
    cursor          : grab;
    height          : 15px;
    width           : 15px;
    background-color: #f00;
    border-radius   : 50%;
    display         : none;
    position        : absolute;
    top             : 33px;
    z-index         : 100;
  }
  .start_dot_left {
    left: 10px;
  }
  .start_dot_right {
    left: 110px;
  }
  .start_dot:hover {
    border: 3px solid cornflowerblue;
  }
  .collapse_child {
    color   : darkgray;
    position: absolute;
    top     : 30px;
    z-index : 199;
  }
  .left_position_icon {
    left: 25px;
  }
  .right_position_icon {
    left: 85px;
  }
  .node_attachment {
    z-index: 99;
    display: flex;
    i {
      font-size: 1.2em;
    }
  }
  .collapse_icon {
    font-size       : 1em;
    color           : black;
    background-color: #ccc;
    border-radius   : 22%;
    font-weight     : bold;
  }
  .notes_bar {
    display    : inline-flex;
    align-items: center;
    margin-left: 4em;
  }
</style>
