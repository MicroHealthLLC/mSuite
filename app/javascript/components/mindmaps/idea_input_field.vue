<template>
  <div @mousedown="startDragIdea" class="main">
    <span @mousedown="startDrag" class="start_dot"></span>
    <input v-if="isSelected" type="text" ref="new_idea" @input="updateIdea" v-model="tempLocalValue" class="new_idea_selected" :class="{'blue_border': isSelected}"/>
    <p v-else class="new_idea">{{tempLocalValue}}</p>
  </div>
</template>

<script>
  import _ from 'lodash';

  export default {
    props: ['value', 'isSelected'],
    data() {
      return {
        localValue: this.value,
        tempLocalValue: this.value
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
      }
    },
    watch: {
      value() {
        this.tempLocalValue = this.value;
      },
      localValue() {
        this.$emit("input", this.localValue)
        this.$emit("node-updated");
      }
    }
  }
  
</script>

<style scoped lang="scss">
  .blue_border {
    border: 8px solid blue !important;
  }
  .new_idea_selected {
    text-align: center;
    padding: 5% 5%;
    border: none;
    border: 8px solid;
    border-radius: 15px;
    font-weight: 700;
    font-size: 80%;
    word-wrap: break-word;
    max-width: 165px;
  }
  .new_idea {
    cursor: pointer;
    text-align: center;
    padding: 5% 5%;
    font-weight: normal;
    border: none;
    text-decoration: underline;
    resize: none;
    background: none;
    word-wrap: break-word;
    max-width: 165px;
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
    left: 80px;
    top: 25px;
  }
  .start_dot:hover {
    border: 10px solid cornflowerblue;
  }
</style>