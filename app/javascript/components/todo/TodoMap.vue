<template>
  <div>
    <b-list-group-item :id="'todo' + node.id" tabindex="0" @click="myTodo(node)" class="mb-0">
      <div class="flex" v-if="selectedTodo.id != node.id">
        <div class="col-6 d-flex flex-row">
          <div class="flex-auto">
            <input type="checkbox" class="mr-4" :checked="node.is_disabled" @input="checkCheckedAns($event)"
              @click="updateTodo(node, node.name, !node.is_disabled)" />
          </div>
          <label v-if="selectedTodo.id != node.id" @click="showInputFieldToggle(node)" class="mb-0 text-wrap"
            :for="'todo-' + node.id" :class="{ 'line-through': node.is_disabled }">{{ node.name }}</label>
        </div>
        <span @click="showInputFieldToggle(node)" class="dueDate col-3" :class="{ 'line-through': node.is_disabled }">
          {{ showStartDate }}
        </span>
        <span v-if="selectedTodo.id != node.id && node" @click="showInputFieldToggle(node)" class="dueDate col-2"
          :class="{ 'line-through': node.is_disabled }">
          {{
      node.duedate
        ? `Due: ${new Date(node.duedate).toLocaleDateString("en-US")}`
        : ""
    }}
        </span>
        <div class="col-1 d-flex flex-row align-items-end">
          <i v-b-tooltip.hover title="Add Subtask" class="ml-lg-3 fa fa-plus addTodo"
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
                <b-col cols="6" sm="6">
                  <b-form-input v-model="selectedTodo.name" ref="title" type="text" placeholder="Your Todo">
                  </b-form-input>
                </b-col>
                <b-col cols="4" sm="4" class="w-50 d-flex flex-row">
                  <date-picker id="input" class="w-100" v-model="selectedTodoRange" :format="format" range disabled-time
                    range-separator=" - "></date-picker>
                </b-col>
                <b-col sm="2" cols="2" class="d-flex flex-row">
                  <b-button v-b-tooltip.hover title="Save" type="submit" variant="success">
                    <i class="fas fa-save"></i></b-button>
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
    <!-- Black background color added to see draggable field for debugging -->
    <div style="background-color: black">
      <draggable class="list-group" group="child" :disabled="dragLocked" :list="sortedChildTodos" :move="checkMove"
        @change="(e) => handleEndChild(e, sortedChildTodos, node)" @start="drag = true"
        @end="(e) => onDragEnd(e, sortedChildTodos, node)" v-bind="dragOptions">
        <transition-group type="transition" :name="!drag ? 'list' : null"
          v-if="sortedChildTodos && sortedChildTodos.length > 0">
          <b-list-group-item class="pl-5 mb-0" v-for="child in sortedChildTodos" :node="child" :key="child.id">
            <div class="flex" v-if="selectedTodo.id != child.id">
              <div class="col-6 d-flex flex-row">
                <div class="flex-auto">
                  <input type="checkbox" class="mr-4" :checked="child.is_disabled"
                    @click="updateTodo(child, child.name, !child.is_disabled)" />
                </div>
                <label @click="showInputFieldToggle(child)" class="mb-0 text-wrap" :for="'child-' + child.id"
                  :class="{ 'line-through': child.is_disabled }">{{ child.name }}</label>
              </div>
              <span v-if="selectedTodo.id != child.id" @click="showInputFieldToggle(child)" class="col-3 dueDate pl-1"
                :class="{ 'line-through': child.is_disabled }">
                {{
      child.startdate &&
        child.startdate != "" &&
        child.startdate != child.duedate
        ? `Start: ${new Date(child.startdate).toLocaleDateString(
          "en-US"
        )}`
        : ""
    }}
              </span>
              <span v-else class="col-3"></span>
              <span @click="showInputFieldToggle(child)" class="col-2 dueDate pl-1"
                :class="{ 'line-through': child.is_disabled }">
                {{
      child.duedate
        ? `Due: ${new Date(child.duedate).toLocaleDateString(
          "en-US"
        )}`
        : ""
    }}
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
                      <b-col sm="6" cols="6">
                        <b-form-input v-model="selectedTodo.name" ref="title" type="text" placeholder="Your Todo">
                        </b-form-input>
                      </b-col>
                      <b-col cols="4" sm="4" class="w-50 d-flex flex-row">
                        <date-picker id="input" class="w-100" v-model="selectedChildTodoRange" :format="format" range
                          disabled-time range-separator=" - "></date-picker>
                      </b-col>
                      <b-col sm="2" cols="2" class="d-flex flex-row">
                        <b-button v-b-tooltip.hover title="Save" type="submit" variant="success">
                          <i class="fas fa-save"></i>
                        </b-button>
                        <b-button v-b-tooltip.hover title="Cancel" class="ml-1" variant="secondary"
                          @click="clearTodoEditObj"><i class="fa fa-ban"></i></b-button>
                      </b-col>
                    </b-row>
                  </b-form>
                </div>
                <div @click="updateTodo(selectedTodo, selectedTodo.name, selectedTodo.is_disabled)"
                  class="absolute top-0 z-10 w-full h-full">
                </div>
              </div>
            </div>
          </b-list-group-item>
        </transition-group>
      </draggable>
    </div>
  </div>
</template>

<script>
import http from "../../common/http";

export default {
  name: "node",
  props: {
    node: Object,
    selectedTodo: Object,
    completedTasks: Boolean,
    editInProgress: Boolean,
    dragLocked: Boolean,
    currentMindMap: null,
    isDraggable: Boolean,
    myTodos: Array,
  },
  data() {
    return {
      parentIndex: null,
      index: null,
      format: "MM/DD/YYYY",
      fieldDisabled: false,
      editStatus: false,
      prevElement: null,
      dropElement: null,
      drag: false,
      selectedTodoRange: [],
      selectedChildTodoRange: [],
    };
  },
  methods: {
    onDragEnd(e, list, pNode) {
      if (e.added || e.moved) return;
      if (e.newIndex == 0) {
        this.handleEndChild(e, list, pNode);
      }
    },
    async handleEndChild(e, list, pNode) {
      if (e.moved) {
        let data = [];
        list.forEach((n, idx) => {
          data.push({ id: n.id, position: idx });
        });
        await http
          .put(`/nodes/update_all_positions`, { nodes: data })
          .then((res) => {
            this.$parent.$parent.$parent.fetchToDos();
          })
      }
      if (!e.isTrusted && !e.added && !e.removed && !e.pullMode) {
        this.handleSingleParent(e, list, pNode);
      }
      if (e.added) {
        const movedItem = list[e.added.newIndex];
        if (movedItem.parent !== pNode.id) {
          if (this.isDraggable) {
            let movedElementNodeId = e.added.element.id;
            let indexToRemove = pNode.children.findIndex(
              (n) => n.id == movedElementNodeId
            );
            pNode.children.splice(indexToRemove, 1);
            if (e.added.element.parent) e.added.element.parent = null;
            this.$emit("HandleTodo", e.added.element, pNode);
          }
        }
      }
    },
    handleSingleParent(e, list, pNode) {
      const movedItem = list[e.newIndex];
      if (this.isDraggable && movedItem) {
        let movedElementNode = pNode.children.find((n) => n.id == movedItem.id);
        let indexToRemove = pNode.children.findIndex(
          (n) => n.id == movedElementNode.id
        );
        pNode.children.splice(indexToRemove, 1);
        if (movedElementNode.parent) movedElementNode.parent = null;
        this.$emit("HandleTodo", movedElementNode, pNode);
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
              arr1[j].position = i + 1;
              sortedArr.push(arr1[j]);
            }
          }
        }
        return sortedArr;
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
          nodes: list,
        },
      };
      await this.$store
        .dispatch("updateMSuite", data)
        .then((result) => {
          this.$parent.$parent.$parent.fetchToDos();
        })
    },
    closeDatePicker(objId) {
      this.hideCalendar(objId);
    },
    hideCalendar(objId) {
      const elem = document.getElementById(objId);
      const calendarIcon = elem.getElementsByClassName("mx-icon-calendar")[0];
      calendarIcon.style.display = "none";
    },
    showCalendar(objId) {
      const elem = document.getElementById(objId);
      const calendarIcon = elem.getElementsByClassName("mx-icon-calendar")[0];
      calendarIcon.style.display = "block";
    },
    hideClear(objId) {
      const eleme = document.getElementById(objId);
      const calendarClear = eleme.getElementsByClassName("mx-icon-calendar")[0];
      calendarClear.style.display = "none";
    },
    updateTodo(todo, title, completed) {
      let prevStartDate, prevDueDate
      prevStartDate = todo.startdate
      prevDueDate = todo.duedate

      if (
        todo.duedate != undefined &&
        todo.duedate !== "" &&
        todo.duedate.getTime != undefined
      ) {
        const prevDueDateTime = new Date(prevDueDate);
        const newDueDateTime = new Date(todo.duedate);

        // Set new date's time to previous date's time
        newDueDateTime.setHours(prevDueDateTime.getHours());
        newDueDateTime.setMinutes(prevDueDateTime.getMinutes());
        newDueDateTime.setSeconds(prevDueDateTime.getSeconds());

        todo.duedate = newDueDateTime;
      }

      if (
        todo.startdate != undefined &&
        todo.startdate !== "" &&
        todo.startdate.getTime != undefined
      ) {
        const prevStartDateTime = new Date(prevStartDate);
        const newStartDateTime = new Date(todo.startdate);

        // Set new date's time to previous date's time
        newStartDateTime.setHours(prevStartDateTime.getHours());
        newStartDateTime.setMinutes(prevStartDateTime.getMinutes());
        newStartDateTime.setSeconds(prevStartDateTime.getSeconds());

        todo.startdate = newStartDateTime;
      }

      this.$emit("updateTodo", todo, title, completed, prevDueDate, prevStartDate);
    },
    myTodo(todo) {
      if (this.selectedTodo.id && todo.id != this.selectedTodo.id) {
        this.updateTodo(
          this.selectedTodo,
          this.selectedTodo.name,
          this.selectedTodo.completed
        );
        setTimeout(() => {
          this.showInputFieldToggle(todo);
        }, 300);
      }
    },
    toggleChildModal(todo) {
      this.$emit("toggleChildModal", todo);
    },
    toggleDeleteTodo(todo) {
      this.$emit("toggleDeleteTodo", todo);
    },
    showInputFieldToggle(todo) {
      if (this.editStatus) {
        this.fieldDisabled = true;
        setTimeout(() => {
          this.fieldDisabled = false;
        }, 1500);
        return;
      } else {
        this.showInputField(todo);
      }
    },
    showInputField(todo) {

      let nod = this.currentMindMap.nodes.find((n) => n.id == todo.id);
      const sta = new Date(nod.startdate);
      const due = new Date(nod.duedate);

      if (due > new Date(2020)) {
        this.selectedTodo.duedate = new Date(due.getTime());
      }
      if (sta > new Date(2020)) {
        this.selectedTodo.startdate = new Date(sta.getTime());
      }
      this.selectedTodoRange = [
        this.selectedTodo.startdate,
        this.selectedTodo.duedate,
      ];
      this.selectedChildTodoRange = [
        this.selectedTodo.startdate,
        this.selectedTodo.duedate,
      ];

      this.$emit("showInputField", todo);
    },
    blurEvent(val, e) {
      this.$emit("blurEvent", val, e);
    },
    clearTodoEditObj() {
      this.$emit("clearTodoEditObj");
    },

    checkCheckedAns(event) {
      if (event.target.checked) event.target.setAttribute("checked", "checked");
      else event.target.removeAttribute("checked");
    },
    setPreviousTime(dateRange) {

      const originalStartTime = this.selectedTodo.startdate;
      const originalEndTime = this.selectedTodo.duedate;
      const startDate = new Date(dateRange[0]);
      const endDate = new Date(dateRange[1]);
      if (typeof originalStartTime !== 'string') {
        startDate.setHours(originalStartTime.getHours());
        startDate.setMinutes(originalStartTime.getMinutes());
        startDate.setSeconds(originalStartTime.getSeconds());
        endDate.setHours(originalEndTime.getHours());
        endDate.setMinutes(originalEndTime.getMinutes());
        endDate.setSeconds(originalEndTime.getSeconds());
      }
      this.selectedTodo.startdate = startDate;
      this.selectedTodo.duedate = endDate;
    },
  },
  computed: {
    sortedChildTodos() {
      if (this.completedTasks) {
        return this.node.children.filter((task) =>
          !task.is_disabled ? task : ""
        );
      } else {
        return this.node.children;
      }
    },
    dragOptions() {
      return {
        animation: 200,
        disabled: false,
        ghostClass: "ghost",
      };
    },
    showStartDate() {
      if (!this.node.showstartdate) {
        const startDate = moment(this.node.startdate);
        const dueDate = moment(this.node.duedate);
        return this.node.startdate && !startDate.isSame(dueDate)
          ? `Start: ${new Date(this.node.startdate).toLocaleDateString(
            "en-US"
          )}`
          : "";
      }
    },
  },
  watch: {
    editInProgress: {
      handler(value) {
        this.editStatus = value;
      },
      deep: true,
    },
    selectedTodo() { },
    selectedTodoRange() {
      if (this.selectedTodoRange) {

        this.setPreviousTime(this.selectedTodoRange)
        // this.selectedTodo.startdate = this.selectedTodoRange[0];
        // this.selectedTodo.duedate = this.selectedTodoRange[1];
      }
    },
    selectedChildTodoRange() {
      if (this.selectedChildTodoRange) {
        this.setPreviousTime(this.selectedChildTodoRange)
        // this.selectedTodo.startdate = this.selectedChildTodoRange[0];
        // this.selectedTodo.duedate = this.selectedChildTodoRange[1];
      }
    },
  },
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
