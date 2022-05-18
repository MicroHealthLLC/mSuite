<template>
  <div>
    <b-list-group-item class="mb-0">
      <div class="flex" v-if="selectedTodo.id != node.id">
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
        <span v-if="selectedTodo.id != node.id" @click="showInputField(node)"
          class="ml-4 dueDate"
          :class="{ 'line-through': node.is_disabled }"> 
            {{node.duedate}}
        </span>
        <i class='ml-4 mt-1 fa fa-plus addTodo'  @click="toggleChildModal(node)"></i>
        <i class="ml-1 mt-1 fa fa-times deleteTodo"  @click="toggleDeleteTodo(node)" ></i>
      </div>
      <div class="ml-3" v-else-if="selectedTodo.id == node.id">
        <div class="relative flex h-full">
          <div class="container relative z-20 max-w-xl mt-20 h-min">
            <b-form @submit.prevent="updateTodo(selectedTodo, selectedTodo.name, selectedTodo.is_disabled)">
              <b-row>
                <b-col sm="5">
                  <b-form-input 
                    v-model="selectedTodo.name"
                    ref="title"
                    type="text"
                    placeholder="Your Todo"
                  >
                  </b-form-input>
                </b-col>
                <b-col sm="5">
                  <date-picker
                    id="input" 
                    v-model='selectedTodo.duedate'
                    :placeholder="selectedTodo.duedate"
                    :disabled-date="disabledStartDate"
                    ref="date"
                    ></date-picker>
                </b-col>
                <b-col sm="2">
                  <b-button type="submit" variant="success"> <i class="fas fa-check"></i> </b-button>
                  <b-button variant="danger" @click="clearTodoEditObj"><i class="fa fa-times"></i></b-button>
                </b-col>
              </b-row>
            </b-form>
          </div>
          <div @click="updateTodo(selectedTodo, selectedTodo.name, selectedTodo.is_disabled)" class="absolute top-0 z-10 w-full h-full"></div>
        </div>
      </div>
    </b-list-group-item>
    <div  v-if="node.children && node.children.length">
      <b-list-group-item class="pl-5 mb-0" v-for="child in sortedChildTodos" :node="child" :key="child.id">
        <div class="flex" v-if="selectedTodo.id != child.id">
          <div class="flex-auto">
            <input
                type="checkbox"
                class="mr-4"
                :checked="child.is_disabled"
                @click="updateTodo(child, child.name, !child.is_disabled)"
            />
          </div>
          <label @click="showInputField(child)" class="mb-0"
            :for="'child-' + child.id"
              :class="{ 'line-through': child.is_disabled }"
          >{{ child.name }}</label>
          <span @click="showInputField(child)"
            class="ml-4 dueDate"
            :class="{ 'line-through': child.is_disabled }"> 
              {{child.duedate}}
          </span>
          <i class="ml-1 mt-1 fa fa-times deleteTodo" @click="toggleDeleteTodo(child)"></i>
        </div>
        <div class="ml-3" v-else-if="selectedTodo.id == child.id">
          <div class="relative flex h-full">
            <div class="container relative z-20 max-w-xl mt-20 h-min">
              <b-form @submit.prevent="updateTodo(selectedTodo, selectedTodo.name, selectedTodo.is_disabled)">
                <b-row>
                  <b-col sm="5">
                    <b-form-input 
                      v-model="selectedTodo.name"
                      ref="title"
                      type="text"
                      placeholder="Your Todo"
                    >
                    </b-form-input>
                  </b-col>
                  <b-col sm="5">
                    <date-picker
                      id="input" 
                      v-model='selectedTodo.duedate'
                      :placeholder="selectedTodo.duedate"
                      :disabled-date="disabledStartDate"
                      ref="date"
                      ></date-picker>
                  </b-col>
                  <b-col sm="2">
                    <b-button type="submit" variant="success"> <i class="fas fa-check"></i> </b-button>
                    <b-button variant="danger" @click="clearTodoEditObj"><i class="fa fa-times"></i></b-button>
                  </b-col>
                </b-row>
              </b-form>
            </div>
            <div @click="updateTodo(selectedTodo, selectedTodo.name, selectedTodo.is_disabled)" class="absolute top-0 z-10 w-full h-full"></div>
          </div>
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
      completedTasks: Boolean
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
      },
      clearTodoEditObj(){
        this.$emit("clearTodoEditObj")
      },
      disabledStartDate(date) {
        if(this.selectedTodo.id != this.node.id) return date < new Date() || date > new Date(this.node.duedate)
        else return date < new Date()
      },
    },
    computed: {
      sortedChildTodos() {
        if(this.completedTasks){
          return this.node.children
            .sort((a,b) => {
              if (a.duedate > b.duedate) { return  1 }
              if (b.duedate > a.duedate) { return -1 }
              return 0
            })
            .filter(task => (!task.is_disabled) ? task : '')
        } else {
          return this.node.children
            .sort((a,b) => {
              if (a.duedate > b.duedate) { return  1 }
              if (b.duedate > a.duedate) { return -1 }
              return 0
            })
        }
      }
    },
  };
</script>
<style scoped>
  @import "./todo_style.css";
</style>
