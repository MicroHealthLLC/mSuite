<template>
  <div @mousedown.stop="startDragIdea" class="main">
    <span @mousedown.stop="startDrag" class="start_dot" :class="C_startDotPositionClass"></span>
    <span 
      v-if="hasChild"
      class="collapse_child" 
      :class="C_expandCollapseIconPositionClass">
      <i 
        v-if="hideChildren == false" 
        class="material-icons"
        @click.stop="switchExpandChildren"
      >remove_circle</i>
      <i 
        v-else 
        class="material-icons"
        @click.stop="switchExpandChildren"
      >add_circle</i>
    </span>
    <textarea v-if="isSelected" type="text" ref="new_idea" @input="updateIdea" v-model="tempLocalValue" class="new_idea_selected pt-2" :class="{'blue_border': isSelected}" :style="newIdeaStyle"/>
    <p v-else class="new_idea py-2">{{tempLocalValue}}</p>
  </div>
</template>

<script>
  import _ from 'lodash';

  export default {
    props: ['value', 'isSelected', 'quadrant', 'hasChild', 'hideChildren'],
    data() {
      return {
        localValue: this.value,
        tempLocalValue: this.value,
        DV_collapse: this.hideChildren,
        newIdeaWidth: '10em',
        newIdeaHeight: '3em'
      }
    },
    computed: {
      C_expandCollapseIconPositionClass() {
        if (this.quadrant == "UL" || this.quadrant == "LL") {
          return "left_position_icon";
        }
        return "right_position_icon";
      },
      C_startDotPositionClass() {
        if (this.quadrant == "UL" || this.quadrant == "LL") {
          return "start_dot_left";
        }
        return "start_dot_right";
      },
      newIdeaStyle() {
        return {
          width: this.newIdeaWidth,
          height: this.newIdeaHeight
        }
      }
    },
    methods: {
      startDrag(event) {
        this.$emit('start-drag', event);
      },
      updateIdea: _.debounce(
        function(input) {
          this.localValue = this.$refs.new_idea.value;
          this.tempLocalValue = this.$refs.new_idea.value;
        },
        500
      ),
      startDragIdea(event) {
        this.$emit('mousedown-event', event);
      },
      switchExpandChildren() {
        this.DV_collapse = !this.DV_collapse;
        this.$emit('switch-expand-children', this.DV_collapse);
      }
    },
    watch: {
      value() {
        this.tempLocalValue = this.value;
      },
      localValue() {
        this.$emit("input", this.localValue)
        this.$emit("node-updated");
      },
      tempLocalValue(value) {
        let dheight = Math.ceil(value.length / 15)
        dheight = dheight > 1 ? dheight*2 : 3
        this.newIdeaHeight = dheight > 8 ? "8em" : dheight + "em" 
      },
      isSelected() {
        let dheight = Math.ceil(this.value.length / 15)
        dheight = dheight > 1 ? dheight*2 : 3
        this.newIdeaHeight = dheight > 8 ? "8em" : dheight + "em" 
      }
    }
  }
  
</script>

<style scoped lang="scss">
  .blue_border {
    border: 3px solid blue !important;
  }
  .new_idea_selected {
    text-align: center;
    border: none;
    border: 2px solid;
    border-radius: 15px;
    font-weight: 700;
    font-size: 80%;
    word-wrap: break-word;
  }
  .new_idea {
    cursor: pointer;
    text-align: center;
    font-weight: normal;
    border: none;
    resize: none;
    background: none;
    word-wrap: break-word;
    width: 10em;
    font-size: 80%;
    line-height: 1;
    margin-top: 0.5em;
  }
  .new_idea:hover {
    border: 3px dotted;
    border-radius: 15px
  }
  .main:hover .start_dot{
    display: inline-block;
  }
  .start_dot {
    cursor: grab;
    height: 15px;
    width: 15px;
    background-color: #f00;
    border-radius: 50%;
    display: none;
    position: absolute;
    top: 33px;
  }
  .start_dot_left {
    left: 10px;
  }
  .start_dot_right {
    left: 110px;
  }
  .start_dot:hover {
    border: 10px solid cornflowerblue;
  }
  .collapse_child {
    color: darkgray;
    position: absolute;
    top: 30px;
  }
  .left_position_icon {
    left: 25px;
  }
  .right_position_icon {
    left: 85px;
  }
</style>