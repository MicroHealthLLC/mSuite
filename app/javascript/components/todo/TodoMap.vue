<template>
  <div>
    <b-list-group-item class="mb-0">
      <div class="flex">
        <div class="flex-auto">
          <input
              type="checkbox"
              class="mr-4"
              :checked="node.is_disabled"
              @click="updateTodo(node, node.name, !node.is_disabled)"
          />
        </div>
        <label v-if="selectedTodo.id != node.id" @click="showInputField(node)" class="mb-0"
          :for="'todo-' + node.id"
            :class="{ 'line-through': node.is_disabled }"
        >{{ node.name }}</label>
        <span v-else-if="selectedTodo.id == node.id">
          <textarea-autosize 
            type="text" 
            v-model="selectedTodo.name"  
            v-debounce:3000ms="blurEvent" 
            @blur.native="updateTodo(selectedTodo, selectedTodo.name, selectedTodo.is_disabled)" :rows="1"
            class="w-100 rounded my-2" 
            placeholder="Enter title here" 
            :id="'textArea' + node.id"/>
        </span>
        <span
          class="ml-4 dueDate"
          :class="{ 'line-through': node.is_disabled }"> 
            {{node.duedate}}
        </span>
        <i class='ml-4 mt-1 fa fa-plus addTodo'  @click="toggleChildModal(node)"></i>
        <i class="ml-1 mt-1 fa fa-times deleteTodo"  @click="toggleDeleteTodo(node)" ></i>
      </div>
    </b-list-group-item>
    <div  v-if="node.children && node.children.length">
      <b-list-group-item class="pl-5 mb-0" v-for="child in sortedChildTodos" :node="child" :key="child.id">
        <div class="flex" >
          <div class="flex-auto">
            <input
                type="checkbox"
                class="mr-4"
                :checked="child.is_disabled"
                @click="updateTodo(child, child.name, !child.is_disabled)"
            />
          </div>
          <label v-if="selectedTodo.id != child.id" @click="showInputField(child)" class="mb-0"
            :for="'child-' + child.id"
              :class="{ 'line-through': child.is_disabled }"
          >{{ child.name }}</label>
          <span v-else-if="selectedTodo.id == child.id">
          <textarea-autosize 
            type="text" 
            v-model="selectedTodo.name"  
            v-debounce:3000ms="blurEvent" 
            @blur.native="updateTodo(selectedTodo, selectedTodo.name, selectedTodo.is_disabled)" :rows="1"
            class="w-100 rounded my-2" 
            placeholder="Enter title here" 
            :id="'textArea' + child.id"/>
        </span>
          <span
            class="ml-4 dueDate"
            :class="{ 'line-through': child.is_disabled }"> 
              {{child.duedate}}
          </span>
          <i class="ml-1 mt-1 fa fa-times deleteTodo" @click="toggleDeleteTodo(child)"></i>
        </div>
      </b-list-group-item>
    </div>
  </div>
</template>

<script>
  import http from "../../common/http"

  export default {
    name: "node",
    props: {
      node: Object,
      selectedTodo: Object,
    },
    data() {
      return {
        parentIndex: null,
        index: null,
      }
    },
    methods:{
      updateTodo(todo, title, completed) {
        this.$emit("updateTodo",todo,title,completed)
      },
      toggleChildModal(todo) {
        this.$emit("toggleChildModal",todo)
      },
      toggleDeleteTodo(todo) {
        this.$emit("toggleDeleteTodo",todo)
      },
      showInputField(todo) {
        this.$emit("showInputField",todo)
      },
      blurEvent(val, e) {
        this.$emit("blurEvent", val, e)
      }
    },
    computed: {
      sortedChildTodos() {
        return this.node.children
          .sort((a,b) => {
            if (a.duedate > b.duedate) { return  1 }
            if (b.duedate > a.duedate) { return -1 }
            return 0
          })
      }
    },
  };
</script>
<style scoped>
  @import "./todo_style.css";
</style>
