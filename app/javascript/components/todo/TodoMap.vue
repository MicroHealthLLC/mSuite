<template>
  <div>
    <b-list-group-item :id="'todo' + node.id" tabindex="0" @click="myTodo(node)" class="mb-0">
      <div class="flex" v-if="selectedTodo.id != node.id">
        <div class="col-8 d-flex flex-row">
          <div class="flex-auto">
            <input type="checkbox" class="mr-4" :checked="node.is_disabled" @input="checkCheckedAns($event)"
              @click="updateTodo(node, node.name, !node.is_disabled)" />
          </div>
          <label v-if="selectedTodo.id != node.id" @click="showInputFieldToggle(node)" class="mb-0 text-wrap"
            :for="'todo-' + node.id" :class="{ 'line-through': node.is_disabled }">{{ node.name }}</label>
        </div>
        <span v-if="selectedTodo.id != node.id" @click="showInputFieldToggle(node)" class="dueDate col-3"
          :class="{ 'line-through': node.is_disabled }">
          {{ formatDate(node.duedate) }}
        </span>
        <div class="col-1 d-flex flex-row align-items-end">
          <i v-b-tooltip.hover title="Add Subtask" class='ml-lg-3 fa fa-plus addTodo'
            @click="toggleChildModal(node)"></i>
          <i v-b-tooltip.hover title="Delete Todo" class="ml-lg-3 ml-xs-1 fa fa-times deleteTodo"
            @click="toggleDeleteTodo(node)"></i>
        </div>
      </div>
      <div class="ml-3" v-else-if="selectedTodo.id == node.id">
        <div class="relative flex h-full">
          <div class="container relative z-20 max-w-xl mt-20 h-min">
            <b-form @submit.prevent="updateTodo(selectedTodo, selectedTodo.name, selectedTodo.is_disabled)">
              <b-row>
                <b-col cols="5" sm="5">
                  <b-form-input v-model="selectedTodo.name" ref="title" type="text" placeholder="Your Todo">
                  </b-form-input>
                </b-col>
                <b-col cols="5" sm="5" class="w-50 d-flex flex-row">
                  <div @mouseenter="hideCalendar('task-date')" @mouseover="hideClear('task-date')"
                    @mouseleave="showCalendar('task-date')" class="dateInput">
                    <date-picker id="task-date" v-model='selectedTodo.duedate'
                      :placeholder="formatDate(selectedTodo.duedate)" :format="format" ref="datePicker"
                      @close="closeDatePicker('task-date')"></date-picker>
                    <i @click="selectedTodo.duedate = ''" class="fa fa-remove iconClear"></i>
                  </div>
                </b-col>
                <b-col sm="2" cols="2" class="d-flex flex-row">
                  <b-button v-b-tooltip.hover title="Save" type="submit" variant="success"> <i
                      class="fas fa-save"></i></b-button>
                  <b-button class="ml-1" v-b-tooltip.hover title="Cancel" variant="secondary"
                    @click="clearTodoEditObj"><i class="fa fa-ban"></i></b-button>
                </b-col>
              </b-row>
            </b-form>
          </div>
          <div @click="updateTodo(selectedTodo, selectedTodo.name, selectedTodo.is_disabled)"
            class="absolute top-0 z-10 w-full h-full"></div>
        </div>
      </div>
    </b-list-group-item>
    <div v-if="node.children && node.children.length">
      <draggable class="list-group" :disabled="dragLocked" :list="sortedChildTodos"
        @change="(e) => handleEnd(e, sortedChildTodos)" group="people" @start="drag = true" @end="drag = false"
        v-bind="dragOptions">
        <transition-group type="transition" :name="!drag ? 'list' : null">
          <b-list-group-item class="pl-5 mb-0" v-for="child in sortedChildTodos" :node="child" :key="child.id">
            <div class="flex" v-if="selectedTodo.id != child.id">
              <!-- <div class="flex" v-if="selectedTodo.id != child.id"> -->
              <div class="col-8 d-flex flex-row">
                <div class="flex-auto">
                  <input type="checkbox" class="mr-4" :checked="child.is_disabled"
                    @click="updateTodo(child, child.name, !child.is_disabled)" />
                </div>
                <label @click="showInputFieldToggle(child)" class="mb-0 text-wrap" :for="'child-' + child.id"
                  :class="{ 'line-through': child.is_disabled }">{{ child.name }}</label>
              </div>
              <span @click="showInputFieldToggle(child)" class="col-3 dueDate pl-1"
                :class="{ 'line-through': child.is_disabled }">
                {{ formatDate(child.duedate) }}
              </span>
              <div class="col-1 ml-xl-5 ml-lg-5 ml-md-4 ml-sm-4 ml-4 pl-xl-1 pl-lg-0 pl-md-1 pl-sm-1 pl-1">
                <i class="d-none ml-2 fa fa-times"></i>
                <i v-b-tooltip.hover placement="top" title="Delete Todo" class="mt-1 ml-2 fa fa-times deleteTodo"
                  @click="toggleDeleteTodo(child)"></i>
              </div>
            </div>
            <div v-else-if="selectedTodo.id == child.id">
              <div class="relative flex h-full">
                <div class="container relative z-20 max-w-xl mt-20 h-min">
                  <b-form @submit.prevent="updateTodo(selectedTodo, selectedTodo.name, selectedTodo.is_disabled)">
                    <b-row>
                      <b-col sm="5" cols="5">
                        <b-form-input v-model="selectedTodo.name" ref="title" type="text" placeholder="Your Todo">
                        </b-form-input>
                      </b-col>
                      <b-col cols="5" sm="5" class="w-50 d-flex flex-row">
                        <div @mouseenter="hideCalendar('task-date-2')" @mouseover="hideClear('task-date-2')"
                          @mouseleave="showCalendar('task-date-2')" class="dateInput">
                          <date-picker id="task-date-2" v-model='selectedTodo.duedate'
                            :placeholder="formatDate(selectedTodo.duedate)" :format="format"
                            @close="closeDatePicker('task-date-2')" ref="date"></date-picker>
                          <i @click="selectedTodo.duedate = ''" class="fa fa-remove iconClear"></i>
                        </div>
                      </b-col>
                      <b-col sm="2" cols="2" class="d-flex flex-row">
                        <b-button v-b-tooltip.hover title="Save" type="submit" variant="success"> <i
                            class="fas fa-save"></i> </b-button>
                        <b-button v-b-tooltip.hover title="Cancel" class="ml-1" variant="secondary"
                          @click="clearTodoEditObj"><i class="fa fa-ban"></i></b-button>
                      </b-col>
                    </b-row>
                  </b-form>
                </div>
                <div @click="updateTodo(selectedTodo, selectedTodo.name, selectedTodo.is_disabled)"
                  class="absolute top-0 z-10 w-full h-full"></div>
              </div>
            </div>
          </b-list-group-item>
        </transition-group>
      </draggable>
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
    editInProgress: Boolean,
    dragLocked: Boolean,
    currentMindMap: null
  },
  data() {
    return {
      parentIndex: null,
      index: null,
      format: 'MM/DD/YYYY',
      fieldDisabled: false,
      editStatus: false,
      prevElement: null,
      dropElement: null,
      drag: false
    }
  },
  methods: {
    /* dragStart(event,nodeId){
      event.dataTransfer.setData("Text", nodeId);
    },
    dragDrop(event,nodeId){
      this.prevElement = parseInt(event.dataTransfer.getData("Text"))
      this.prevElement = this.currentMindMap.nodes.find((node) => node.id == this.prevElement)
      this.dropElement = this.currentMindMap.nodes.find((node) => node.id == nodeId)
      this.prevElement.parent_node = this.dropElement.id
      this.updateTodo(this.prevElement, this.prevElement.title, this.prevElement.completed)
    }, */
    async handleEnd(e, list) {
      let newIdList = list.map(i => i.id)
      let nodes = this.$store.getters.getMsuite.nodes
      let sortedTodoArr = this.relativeSortArray(nodes, newIdList)
      if (e.moved) {
        this.reorderTodo(sortedTodoArr)
      } else if (e.added) {
        let otherNode = sortedTodoArr.find(n => n.id != e.added.element.id)
        sortedTodoArr.forEach((n, idx) => {
          if (n.id == e.added.element.id) {
            let oldId = n.id
            n.parent_node = otherNode.parent_node
            nodes.forEach(c => {
              if (c.parent_node == oldId) {
                c.parent_node = n.parent_node
                sortedTodoArr.push(c)
              }
            })
          }
        })
        this.reorderTodo(sortedTodoArr)
      }
    },
    relativeSortArray(arr1, arr2) {
      let sortedArr = [];
      let auxArr = [];
      let arrSet = this.newSet(arr2);
      if (arr1 && arr2) {
        for (let i = 0; i < arr2.length; i++) {
          for (let j = 0; j < arr1.length; j++) {
            if (arr1[j].id === arr2[i]) {
              arr1[j].position = i + 1
              sortedArr.push(arr1[j]);
            }
          }
        }
        return sortedArr
      }
    },
    newSet(arr) {
      let arrSet = new Set();
      for (let i = 0; i < arr.length; i++) {
        arrSet.add(arr[i]);
      }
      return arrSet;
    },
    async reorderTodo(list) {
      let data = {
        mindmap: {
          nodes: list
        }
      }
      await this.$store.dispatch('updateMSuite', data)
        .then((result) => {
          console.log(result)
          this.$parent.$parent.$parent.fetchToDos()
        }).catch((err) => {
          console.error(err);
        });
    },
    closeDatePicker(objId) {
      this.hideCalendar(objId)
    },
    hideCalendar(objId) {
      const elem = document.getElementById(objId);
      const calendarIcon = elem.getElementsByClassName('mx-icon-calendar')[0];
      calendarIcon.style.display = 'none';
    },
    showCalendar(objId) {
      const elem = document.getElementById(objId);
      const calendarIcon = elem.getElementsByClassName('mx-icon-calendar')[0];
      calendarIcon.style.display = 'block';
    },
    hideClear(objId) {
      const eleme = document.getElementById(objId);
      const calendarClear = eleme.getElementsByClassName('mx-icon-calendar')[0];
      calendarClear.style.display = 'none';
    },
    updateTodo(todo, title, completed) {
      if (this.selectedTodo.duedate != undefined && this.selectedTodo.duedate !== '' && this.selectedTodo.duedate.getTime != undefined) this.selectedTodo.duedate = new Date(this.selectedTodo.duedate.getTime() - (this.selectedTodo.duedate.getTimezoneOffset() * 60000)).toISOString().split("T")[0]
      this.$emit("updateTodo", todo, title, completed)
    },
    myTodo(todo) {
      if (this.selectedTodo.id && todo.id != this.selectedTodo.id) {
        this.updateTodo(this.selectedTodo, this.selectedTodo.name, this.selectedTodo.completed)
        setTimeout(() => {
          this.showInputFieldToggle(todo)
        }, 300)
      }
    },
    toggleChildModal(todo) {
      console.log(todo)
      this.$emit("toggleChildModal", todo)
    },
    toggleDeleteTodo(todo) {
      this.$emit("toggleDeleteTodo", todo)
    },
    showInputFieldToggle(todo) {
      if (this.editStatus) {
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
      if (this.selectedTodo && this.selectedTodo.duedate != undefined && this.selectedTodo.duedate !== '' && this.selectedTodo.duedate.getTime != undefined) this.selectedTodo.duedate = new Date(this.selectedTodo.duedate.getTime() - (this.selectedTodo.duedate.getTimezoneOffset() * 60000)).toISOString().split("T")[0]

      this.$emit("showInputField", todo)
    },
    blurEvent(val, e) {
      this.$emit("blurEvent", val, e)
    },
    clearTodoEditObj() {
      this.$emit("clearTodoEditObj")
    },
    formatDate(date) {
      return date ? moment(date).format("MM/DD/YYYY") : ""
    },
    checkCheckedAns(event) {
      if (event.target.checked) event.target.setAttribute("checked", "checked")
      else event.target.removeAttribute("checked")
    },
  },
  computed: {
    sortedChildTodos() {
      if (this.completedTasks) {
        return this.node.children
          .filter(task => (!task.is_disabled) ? task : '')
      } else {
        return this.node.children
      }
    },
    dragOptions() {
      return {
        animation: 200,
        disabled: false,
        ghostClass: "ghost"
      };
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
<style lang="scss" scoped>
@import "./todo_style.scss";

.iconClear {
  position: absolute;
  left: 204px;
  top: 12px;
  display: none;
  color: #bfbfbf;
  font-weight: 100;
}

.dateInput:hover .iconClear {
  display: inline-block;
}
</style>
