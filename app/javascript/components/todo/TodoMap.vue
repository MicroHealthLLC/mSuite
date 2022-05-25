<template>
  <div>
    <b-list-group-item class="mb-0">
      <div class="flex" v-if="selectedTodo.id != node.id">
        <div class="col-8 d-flex flex-row">
          <div class="flex-auto">
            <input
                type="checkbox"
                class="mr-4"
                :checked="node.is_disabled"

                @click="updateTodo(node, node.name, !node.is_disabled)"
            />
          </div>
          <label v-if="selectedTodo.id != node.id" @click="showInputFieldToggle(node)" class="mb-0 text-wrap"
            :for="'todo-' + node.id"
            :class="{ 'line-through': node.is_disabled }"
          >{{ node.name }}</label>
        </div>
        <span v-if="selectedTodo.id != node.id" @click="showInputFieldToggle(node)"
          class="dueDate col-3"
          :class="{ 'line-through': node.is_disabled }"> 
            {{node.duedate}}
        </span>
        <div class="col-1 d-flex flex-row align-items-end">
          <i v-b-tooltip.hover title="Add Todo" class='ml-lg-3 fa fa-plus addTodo'  @click="toggleChildModal(node)"></i>
          <i v-b-tooltip.hover title="Delete Todo" class="ml-lg-1 ml-xs-1 fa fa-times deleteTodo"  @click="toggleDeleteTodo(node)" ></i>
        </div>
      </div>
      <div class="ml-3" v-else-if="selectedTodo.id == node.id">
        <div class="relative flex h-full">
          <div class="container relative z-20 max-w-xl mt-20 h-min">
            <b-form @submit.prevent="updateTodo(selectedTodo, selectedTodo.name, selectedTodo.is_disabled)">
              <b-row>
                <b-col cols="5" sm="5">
                  <b-form-input 
                    v-model="selectedTodo.name"
                    :class="fieldDisabled ? 'shake': ''"
                    ref="title"
                    type="text"
                    placeholder="Your Todo"
                  >
                  </b-form-input>
                </b-col>
                <b-col cols="5" sm="5" class="w-50 d-flex flex-row">
                  <date-picker
                    id="input" 
                    v-model='selectedTodo.duedate'
                    :placeholder="selectedTodo.duedate"
                    :disabled-date="disabledStartDate"
                    :format="format"
                    ref="datePicker"
                    ></date-picker>
                    <b-button class="ml-1" @click="selectedTodo.duedate=''" variant="warning"> <i class="fas fa-backspace"></i> </b-button>
                </b-col>
                <b-col sm="2" cols="2" class="d-flex flex-row">
                  <b-button v-b-tooltip.hover title="Save" type="submit" variant="success"> <i class="fas fa-save"></i> </b-button>
                  <b-button class="ml-1" v-b-tooltip.hover title="Cancel" variant="secondary" @click="clearTodoEditObj"><i class="fa fa-ban"></i></b-button>
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
          <div class="col-8 d-flex flex-row">
            <div class="flex-auto">
              <input
                  type="checkbox"
                  class="mr-4"
                  :checked="child.is_disabled"
                  @click="updateTodo(child, child.name, !child.is_disabled)"
              />
            </div>
            <label @click="showInputFieldToggle(child)" class="mb-0 text-wrap"
              :for="'child-' + child.id"
                :class="{ 'line-through': child.is_disabled }"
            >{{ child.name }}</label>
          </div>
          <span @click="showInputFieldToggle(child)"
            class="col-3 dueDate pl-1"
            :class="{ 'line-through': child.is_disabled }"> 
              {{child.duedate}}
          </span>
          <div class="col-1 ml-xl-5 ml-lg-5 ml-md-4 ml-sm-4 ml-4 pl-xl-1 pl-lg-0 pl-md-1 pl-sm-1 pl-1">
            <i class="d-none fa fa-times"></i>
            <i v-b-tooltip.hover placement="top" title="Delete Todo" class="mt-1 fa fa-times deleteTodo" @click="toggleDeleteTodo(child)"></i>
          </div>
        </div>
        <div v-else-if="selectedTodo.id == child.id">
          <div class="relative flex h-full">
            <div class="container relative z-20 max-w-xl mt-20 h-min">
              <b-form @submit.prevent="updateTodo(selectedTodo, selectedTodo.name, selectedTodo.is_disabled)">
                <b-row>
                  <b-col sm="5" cols="5">
                    <b-form-input 
                      v-model="selectedTodo.name"
                      :class="fieldDisabled ? 'shake': ''"
                      ref="title"
                      type="text"
                      placeholder="Your Todo"
                    >
                    </b-form-input>
                  </b-col>
                  <b-col sm="5" cols="5" class="d-flex flex-row">
                    <date-picker
                      id="input" 
                      class="w-50"
                      v-model='selectedTodo.duedate'
                      :placeholder="selectedTodo.duedate"
                      :disabled-date="disabledStartDate"
                      :format="format"
                      ref="date"
                      ></date-picker>
                      <b-button class="ml-1" @click="selectedTodo.duedate=''" variant="warning"> <i class="fas fa-backspace"></i> </b-button>
                  </b-col>
                  <b-col sm="2" cols="2" class="d-flex flex-row">
                    <b-button v-b-tooltip.hover title="Save" type="submit" variant="success"> <i class="fas fa-save"></i> </b-button>
                    <b-button v-b-tooltip.hover title="Cancel" class="ml-1" variant="secondary" @click="clearTodoEditObj"><i class="fa fa-ban"></i></b-button>
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
      completedTasks: Boolean,
      editInProgress: Boolean
    },
    data() {
      return {
        parentIndex: null,
        index: null,
        format: 'YYYY-MM-DD',
        fieldDisabled: false,
        editStatus: false
      }
    },
    methods:{
      updateTodo(todo, title, completed) {
        if(this.selectedTodo.duedate != undefined && this.selectedTodo.duedate !== '' && this.selectedTodo.duedate.getTime != undefined) this.selectedTodo.duedate = new Date(this.selectedTodo.duedate.getTime() - (this.selectedTodo.duedate.getTimezoneOffset() * 60000 )).toISOString().split("T")[0]
        this.$emit("updateTodo",todo,title,completed)
      },
      toggleChildModal(todo) {
        this.$emit("toggleChildModal",todo)
      },
      toggleDeleteTodo(todo) {
        this.$emit("toggleDeleteTodo",todo)
      },
      showInputFieldToggle(todo){
        if(this.editStatus){
          this.fieldDisabled = true
          setTimeout(() => {
            this.fieldDisabled = false
          }, 1500)
          return
        } else {
          this.showInputField(todo)
        }
      },
      showInputField(todo) {
        if(this.selectedTodo && this.selectedTodo.duedate != undefined && this.selectedTodo.duedate !== '' && this.selectedTodo.duedate.getTime != undefined) this.selectedTodo.duedate = new Date(this.selectedTodo.duedate.getTime() - (this.selectedTodo.duedate.getTimezoneOffset() * 60000 )).toISOString().split("T")[0]

        this.$emit("showInputField",todo)
      },
      blurEvent(val, e) {
        this.$emit("blurEvent", val, e)
      },
      clearTodoEditObj(){
        this.$emit("clearTodoEditObj")
      },
      disabledStartDate(date) {
        if(this.selectedTodo.id != this.node.id && this.node.duedate !== null) return date < new Date() || date > new Date(this.node.duedate)
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
    watch: {
      editInProgress: {
        handler(value) {
          this.editStatus = value
        }, deep: true
      }
    }
  };
</script>
<style scoped>
  @import "./todo_style.css";
</style>
