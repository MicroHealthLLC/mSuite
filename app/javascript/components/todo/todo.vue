<template>
  <div class="todo-app">
    <div id="todo">
      <div>
        <div class="parentGroup overflow-auto">
          <div class="">
            <div class="container max-w-lg mx-auto">
              <h1 class="font-bold text-center text-blue-600">Todo</h1>
            </div>
          </div>
          <div class="container relative max-w-lg pt-6 mx-auto">
            <p class="text-slate-600 text-center">Your Todo</p>
            <toggle-button class="toggleButton mb-3" :value="true" color="#82C7EB" :sync="true"
              :labels="{ checked: 'Actionable', unchecked: 'All Tasks' }" v-model="completedTasks" width="115"
              height="28" />
            <toggle-button v-if="!isMobile" @click="handleDrag" class="toggleButton mb-3" :value="true" color="#82C7EB"
              :sync="true" :labels="{ checked: 'Drag Row', unchecked: 'Make Child' }" v-model="isDraggable" width="115"
              height="28" />
            <div class="lock-container">
              <toggle-button v-if="isMobile" :value="true" color="#82C7EB" :sync="true"
                :labels="{ checked: 'Actionable', unchecked: 'All Tasks' }" v-model="completedTasks" width="100" />
              <toggle-button class="toggle-drag" v-if="isMobile" v-model="dragLocked"
                :labels="{ checked: 'Drag Locked', unchecked: 'Drag Unlocked' }" width="100" />
            </div>

            <div>
              <b-list-group class="mr-0" v-if="sortedTodos.length > 0">
                <draggable class="list-group" group="people" :list="sortedTodos"
                  @change="(e) => handleEndParent(e, sortedTodos)" @start="drag = true" @end="drag = false"
                  v-bind="dragOptions">
                  <transition-group type="transition" :name="!drag ? 'list' : null">
                    <div v-for="todo in sortedTodos" :key="todo.id">
                      <todo-map :node="todo" :selectedTodo="selectedTodo" :dragLocked="dragLocked"
                        :completedTasks="completedTasks" :editInProgress="editInProgress"
                        :current-mind-map="currentMindMap" :isDraggable="isDraggable" :myTodos="myTodos"
                        @stopChild="isDraggable = true" @updateTodo="updateTodo" @toggleChildModal="toggleChildModal"
                        @toggleDeleteTodo="toggleDeleteTodo" @showInputField="showInputField" @blurEvent="blurEvent"
                        @clearTodoEditObj="clearTodoEditObj" @HandleTodo="HandleChild"
                        @handleStartDate="handleStartDate"></todo-map>
                      <b-list-group-item v-if="showChildModalTodo && todo_parent === todo.id" class="child-field">
                        <div class="ml-1">
                          <div class="relative flex h-full">
                            <div class="container relative z-20 max-w-xl mt-20 h-min">
                              <b-form @submit.prevent="addChildTodo()">
                                <b-row>
                                  <b-col cols="6" sm="6">
                                    <b-form-input :class="fieldDisabled ? 'shake' : ''" v-model="todoChildData.title"
                                      ref="title" type="text" :placeholder="'Add subtask for ' + todo.name
              ">
                                    </b-form-input>
                                  </b-col>
                                  <b-col cols="4">
                                    <date-picker id="input" class="w-100" v-model="childRange" :format="format" range
                                      range-separator=" - "></date-picker>
                                  </b-col>
                                  <b-col cols="2" sm="2" class="d-flex flex-row justify-content-end">
                                    <b-button v-b-tooltip.hover title="Save" type="submit" variant="success">
                                      <i class="fas fa-save"></i>
                                    </b-button>
                                    <b-button class="ml-1" v-b-tooltip.hover title="Cancel" variant="secondary"
                                      @click="cancelChildObj">
                                      <i class="fas fa-ban"></i></b-button>
                                  </b-col>
                                </b-row>
                              </b-form>
                            </div>
                            <div @click="toggleChildModal(todo)" class="absolute top-0 z-10 w-full h-full"></div>
                          </div>
                        </div>
                      </b-list-group-item>
                    </div>
                  </transition-group>
                </draggable>
              </b-list-group>
              <b-list-group-item v-if="!showChildModalTodo" class="mb-2">
                <div class="relative flex h-full">
                  <div class="container relative max-w-xl mt-20 h-min">
                    <b-form @submit.prevent="addTodo()">
                      <b-row>
                        <b-col cols="6" class="todo-field">
                          <b-form-input :class="fieldDisabled ? 'shake' : ''" v-model="todoData.title" ref="title"
                            type="text" :placeholder="placeHolderText">
                          </b-form-input>
                        </b-col>
                        <b-col cols="4">
                          <date-picker id="input" class="w-100" v-model="parentRange" :format="format" range
                            range-separator=" - "></date-picker>
                        </b-col>
                        <b-col sm="2" cols="2" class="d-flex flex-row justify-content-end">
                          <b-button v-b-tooltip.hover title="Save" type="submit" variant="success">
                            <i class="fas fa-save"></i>
                          </b-button>
                          <b-button class="ml-1" v-b-tooltip.hover variant="warning" @click="clearTodoObj"
                            title="Reset">
                            <i class="fas fa-undo-alt"></i>
                          </b-button>
                        </b-col>
                      </b-row>
                    </b-form>
                  </div>
                </div>
              </b-list-group-item>
            </div>
          </div>
        </div>
      </div>
    </div>
    <sweet-modal ref="errTitle" class="of_v" icon="error">
      Node title can't be empty!
    </sweet-modal>
    <sweet-modal ref="errDates" class="of_v" icon="error">
      {{
              todoData.startDate == null
                ? "Start date required when using due date"
                : todoData.dueDate == null
                  ? "Due date required when using start date"
                  : "Not a valid date range"
            }}
    </sweet-modal>
    <sweet-modal ref="errDatesUpdate" class="of_v" icon="error">
      {{
                selectedTodo.startdate == ""
                  ? "Start date required when using due date"
                  : selectedTodo.duedate == ""
                    ? "Due date required when using start date"
                    : "Not a valid date range"
              }}
    </sweet-modal>
  </div>
</template>
<script>
import http from "../../common/http";
import domtoimage from "dom-to-image-more";
import draggable from "vuedraggable";
import { ToggleButton } from "vue-js-toggle-button";
import DatePicker from "vue2-datepicker";
import "./datepicker.css";
import TodoMap from "./TodoMap";
import TemporaryUser from "../../mixins/temporary_user.js";
import Common from "../../mixins/common.js";
import History from "../../mixins/history.js";
import { isMobile } from "mobile-device-detect";

export default {
  props: {
    undoMap: Function,
    redoMap: Function,
  },
  data() {
    return {
      currentMindMap: this.$store.getters.getMsuite,
      todos: [],
      todo: {},
      userList: [],
      selectedTodo: { id: null },
      myTodos: [
        {
          name: "",
          counter: 0,
        },
      ],
      todo_parent: null,
      showModalTodo: false,
      showChildModalTodo: false,
      todoData: { title: null, date: "" },
      todoChildData: { title: null, date: "" },
      uniqueChild: new Set(),
      childCompleted: false,
      parentIndex: null,
      index: null,
      completedTasks: null,
      selectedTodoDelete: null,
      disabledBefore: new Date(),
      placeHolderText: "Add Todo",
      fieldDisabled: false,
      format: "MM/DD/YYYY",
      editInProgress: false,
      undoNodes: [],
      redoNodes: [],
      undoDone: false,
      drag: false,
      dragLocked: isMobile ? true : false,
      parentRange: [],
      childRange: [],
      isDraggable: true,
      targetItem: [],
    };
  },
  components: {
    TodoMap,
    ToggleButton,
    DatePicker,
    draggable,
  },
  mixins: [Common, TemporaryUser, History],
  channels: {
    WebNotificationsChannel: {
      received(data) {
        if (
          data.message === "Mindmap Deleted" &&
          this.currentMindMap.id === data.mindmap.id
        ) {
          window.open("/", "_self");
        } else if (
          data.message === "Mindmap Updated" &&
          this.currentMindMap.id === data.mindmap.id
        ) {
          this.$store.commit("setMSuite", data.mindmap);
          this.fetchToDos();
        } else if (
          data.message === "Password Updated" &&
          this.currentMindMap.id === data.mindmap.id
        ) {
          setTimeout(() => {
            location.reload();
          }, 500);
        } else if (
          data.message === "storage updated" &&
          this.currentMindMap.id == data.content.mindmap_id
        ) {
          this.$store.dispatch("setUserEdit", data.content.userEdit);
          this.$store.dispatch("setNodeNumber", data.content.nodeNumber);
          this.$store.dispatch("setTemporaryUser", data.content.userEdit);
          this.$store.dispatch("setUserList", data.content.userEdit);
        } else if (
          data.message === "Reset mindmap" &&
          this.currentMindMap.id === data.mindmap.id
        ) {
          this.$store.commit("setMSuite", data.mindmap);
          this.currentMindMap = data.mindmap;
          this.resetMindmap();
          this.fetchToDos();
        } else {
          this.fetchToDos();
        }
      },
    },
  },
  methods: {
    async HandleChild(obj, pNode) {
      let indexToAdd = this.myTodos.findIndex((n) => n.id == pNode.id);
      this.myTodos.splice(indexToAdd + 1, 0, obj);
      await http
        .put(`/nodes/${obj.id}.json`, {
          node: { parent_node: obj.parent, line_color: this.getRandomColor() },
        })
        .then((res) => {
          this.fetchToDos();
        })
    },
    handleDrag() {
      this.isDraggable = !this.isDraggable;
    },
    async handleDragPosition(list) {
      let data = [];
      list.forEach((n, idx) => {
        data.push({ id: n.id, position: idx });
      });
      await http
        .put(`/nodes/update_all_positions`, { nodes: data })
        .then((res) => {
          this.fetchToDos();
        });
    },
    handleEndParent(e, list) {
      if (!e.removed) {
        if (e.moved) {
          if (!this.isDraggable) {
            this.handleChildParent(e, list);
          } else {
            this.handleDragPosition(list);
          }
        }
      }
    },
    async handleChildParent(e, list) {
      if (e.moved.oldIndex < e.moved.newIndex) {
        this.targetItem = list[e.moved.newIndex - 1];
      } else {
        this.targetItem = list[e.moved.newIndex + 1];
      }
      const movedItem = list[e.moved.newIndex];
      const movedItemChildren = movedItem.children;
      let addedNode = list.find((n) => n.id == movedItem.id);
      addedNode.parent_node = this.targetItem.id;
      if (this.targetItem.children.length > 0 && movedItemChildren.length > 0) {
        this.targetItem.children.push(...movedItemChildren);
      } else if (
        this.targetItem.children.length === 0 &&
        movedItemChildren.length > 0
      ) {
        this.targetItem.children = movedItemChildren;
      }
      this.targetItem.children.push(movedItem);
      await http
        .put(`/nodes/${addedNode.id}.json`, {
          node: {
            parent_node: addedNode.parent_node,
            position: e.moved.newIndex,
            is_sprint: true,
          },
        })
        .then((res) => {
          this.fetchToDos();
        });
      list.splice(e.moved.newIndex, 1);
    },
    async reorderTodo(list) {
      let data = {
        mindmap: {
          nodes: list,
        },
      };
      await this.$store.dispatch("updateMSuite", data).then((result) => {
        this.fetchToDos();
      });
    },
    clearTodoObj() {
      this.todo = {};
      this.todoData = { title: null, date: null };
      this.todoChildData = { title: null, date: null };
      this.parentRange = [];
      this.childRange = [];
    },
    cancelChildObj() {
      this.showChildModalTodo = false;
      this.clearTodoObj();
    },
    toggleChildModal(todo) {
      this.todo = todo;
      this.todo_parent = todo.id;
      this.showChildModalTodo = true;
      this.sendLocals(true);
    },
    clearTodoEditObj() {
      this.selectedTodo = { id: "" };
      this.editInProgress = false;
      this.fetchToDos();
      this.sendLocals(false);
    },
    async fetchToDos() {
      let res = await this.$store.dispatch("getMSuite");
      let response = this.$store.getters.getMsuite;
      this.$store.dispatch("setMindMapId", response.id);
      this.defaultDeleteDays = response.defaultDeleteDays;
      this.deleteAfter = response.deleteAfter;
      this.expDays = response.expDays;
      this.$store.commit("SET_MSUITE", response);
      this.todos = response.nodes;
      this.renderTodos();
    },
    renderTodos() {
      let parent_nodes = [];
      this.todos.forEach((node) => {
        if (node.parent_node == null || node.parent_node == 0) {
          parent_nodes.push(node);
        }
      });
      parent_nodes = parent_nodes.map((node, index) => {
        let obj = {
          name: node.title,
          id: node.id,
          is_disabled: node.is_disabled,
          counter: 0,
          duedate: node.duedate,
          startdate: node.startdate,
          children: [],
        };
        if (obj["duedate"]) {
          obj["duedate"] = new Date(node.duedate).toLocaleDateString("en-US");
        }
        if (obj["startdate"]) {
          obj["startdate"] = new Date(node.startdate).toLocaleDateString(
            "en-US"
          );
        }
        return obj;
      });
      this.getChildNode(parent_nodes);
    },
    getChildNode(parent_nodes) {
      let childNodes = [];
      this.todos.forEach((node) => {
        parent_nodes.forEach((p, index) => {
          if (p.id == node.parent_node) {
            let obj = {
              name: node.title,
              id: node.id,
              is_disabled: node.is_disabled,
              parent: p.id,
              duedate: node.duedate,
              startdate: node.startdate,
              children: [],
            };

            if (obj["duedate"]) {
              obj["duedate"] = new Date(node.duedate).toLocaleDateString(
                "en-US"
              );
            }
            if (obj["startdate"]) {
              obj["startdate"] = new Date(node.startdate).toLocaleDateString(
                "en-US"
              );
            }
            parent_nodes[index].children.push(obj);
          }
        });
      });
      if (childNodes.length > 0) {
        this.getChildNode(_.uniq(childNodes));
      }
      this.myTodos = parent_nodes;
    },
    async updateTodoUser() {
      await this.$store.dispatch("updateMSuite", {
        canvas: this.$store.getters.getUser,
      });
    },
    async addTodo() {
      if (
        this.todoData.title == null ||
        this.todoData.title.trim().length === 0
      ) {
        this.$refs["errTitle"].open();
        this.fieldDisabled = true;
        setTimeout(() => {
          this.fieldDisabled = false;
        }, 1500);
        return;
      }
      if (
        (this.todoData.startDate == null && this.todoData.dueDate) ||
        (this.todoData.startDate && this.todoData.dueDate == null) ||
        moment(this.todoData.dueDate)._d < moment(this.todoData.startDate)._d
      ) {
        this.$refs["errDates"].open();
        return;
      }
      if (this.todoData.startDate)
        this.todoData.startDate = moment(this.todoData.startDate)._d;
      if (this.todoData.dueDate)
        this.todoData.dueDate = moment(this.todoData.dueDate)._d;
      let data = {
        node: {
          title: this.todoData.title,
          description: "",
          mindmap_id: this.currentMindMap.id,
          startdate: this.todoData.startDate,
          duedate: this.todoData.dueDate,
          is_disabled: false,
          hide_children: true,
          line_color: this.getRandomColor(),
          is_sprint: true,
        },
      };
      this.updateTodoUser();
      http.post(`/nodes.json`, data).then((result) => {
        this.myTodos.push(result.data.node);
        this.undoNodes.push({ req: "addNode", node: result.data.node });
        this.showModalTodo = false;
        this.clearTodoObj();
        this.sendLocals(false);
      });
    },
    async addChildTodo() {
      if (
        this.todoChildData.title == null ||
        this.todoChildData.title.trim().length === 0
      ) {
        this.$refs["errTitle"].open();
        this.fieldDisabled = true;
        setTimeout(() => {
          this.fieldDisabled = false;
        }, 1500);
        return;
      }
      if (this.todoChildData.startDate)
        this.todoChildData.startDate = moment(this.todoChildData.startDate)._d;
      if (this.todoChildData.dueDate)
        this.todoChildData.dueDate = moment(this.todoChildData.dueDate)._d;

      let data = {
        node: {
          title: this.todoChildData.title,
          description: "",
          mindmap_id: this.currentMindMap.id,
          parent_node: this.todo_parent,
          startdate: this.todoChildData.startDate,
          duedate: this.todoChildData.dueDate,
          line_color: "#58A2B8",
          is_disabled: false,
          hide_children: true,
        },
      };
      this.updateTodoUser();
      http.post(`/nodes.json`, data).then((result) => {
        this.undoNodes.push({ req: "addNode", node: result.data.node });
        this.showChildModalTodo = false;
        this.clearTodoObj();
        this.sendLocals(false);
      });
    },
    updateTodo(todo, title, completed) {
      if (title == null || title.trim().length === 0) {
        this.$refs["errTitle"].open();
        this.fieldDisabled = true;
        setTimeout(() => {
          this.fieldDisabled = false;
        }, 1500);
        return;
      }
      if (
        ((todo.startdate == null || todo.startdate == "") && todo.duedate) ||
        (todo.startdate && (todo.duedate == null || todo.duedate == "")) ||
        moment(todo.duedate)._d < moment(todo.startdate)._d
      ) {
        this.$refs["errDatesUpdate"].open();
        return;
      }
      if (
        this.selectedTodo.duedate &&
        typeof this.selectedTodo.duedate !== "string"
      ) {
        this.selectedTodo.duedate = moment(this.selectedTodo.duedate)._d;
      }
      if (
        this.selectedTodo.startdate &&
        typeof this.selectedTodo.startdate !== "string"
      ) {
        this.selectedTodo.startdate = moment(this.selectedTodo.startdate)._d;
      }
      todo.title = title;
      todo.is_disabled = completed;
      todo.duedate = this.selectedTodo.duedate
        ? this.selectedTodo.duedate
        : todo.duedate;
      todo.duedate = moment(todo.duedate)._d;
      todo.startdate = this.selectedTodo.startdate
        ? this.selectedTodo.startdate
        : todo.startdate;
      todo.startdate = moment(todo.startdate)._d;
      const dueDateMoment = moment(todo.duedate);
      const startDateMoment = this.selectedTodo.startdate
        ? moment(this.selectedTodo.startdate)
        : moment(todo.startdate);
      this.myTodos.forEach((myTodo) => {
        if (myTodo.id == todo.id) {
          myTodo.showstartdate = dueDateMoment.isSame(startDateMoment, "day");
        } else {
          myTodo.showstartdate = false;
        }
      });
      // todo.hide_children = true;
      if (this.undoNodes.length > 0) {
        this.undoNodes.forEach((element, index) => {
          if (element["node"].id === todo.id) {
            this.undoNodes[index]["node"].title = todo.title;
            this.undoNodes[index]["node"].startdate = todo.startdate;
            this.undoNodes[index]["node"].duedate = todo.duedate;
            this.undoNodes[index]["node"].is_disabled = completed;
            // this.myTodos = todo;
          }
        });
      } else {
        this.undoNodes.push({ req: "addNode", node: todo });
      }
      this.updateTodoUser();
      http.put(`/nodes/${todo.id}`, todo);
      this.selectedTodo = { id: "" };
      this.editInProgress = false;
      this.sendLocals(false);
    },
    async deleteTodo() {
      let todo = this.selectedTodoDelete;
      this.index = this.myTodos.findIndex((e) => e.id == todo.id);
      this.updateTodoUser();
      await http.delete(`/nodes/${todo.id}.json`).then((res) => {
        let receivedNodes = res.data.node;
        if (receivedNodes && receivedNodes.length > 0) {
          this.undoNodes.push({ req: "deleteNode", node: receivedNodes });
        }
        if (!this.undoDone) {
          let duedate = moment(todo.duedate)._d;
          let startdate = moment(todo.startdate)._d;
          let myNode = {
            id: todo.id,
            title: todo.name,
            startdate: startdate,
            duedate: duedate,
            mindmap_id: this.currentMindMap.id,
            parent_node: todo.parent,
            is_disabled: todo.is_disabled,
          };
          this.undoNodes.push({ req: "deleteNode", node: myNode });
        }
      });
    },
    toggleDeleteTodo(todo) {
      this.selectedTodoDelete = todo;
      this.undoDone = false;
      this.clearTodoObj();
      this.deleteTodo();
      this.sendLocals(false);
    },
    showInputField(todo) {
      let _this = this;
      _this.editInProgress = true;
      _this.selectedTodo = todo;
      if (document.getElementById("textArea" + _this.selectedTodo.id) != null) {
        setTimeout(() => {
          document.getElementById("textArea" + _this.selectedTodo.id).focus();
        }, 300);
      }
      this.sendLocals(true);
    },
    blurEvent(val, e) {
      this.selectedTodo = { id: null };
      if (e.target) {
        e.target.blur();
        this.sendLocals(false);
      }
    },
    resetMindmap() {
      this.undoNodes = [];
      this.redoNodes = [];
      this.cancelChildObj();
      this.completedTasks = false;
    },
    async undoObj() {
      this.undoDone = true;
      let undoObj = await this.undoNode(this.undoNodes);
      if (undoObj) {
        this.undoNodes.pop();
        this.redoNodes.push({ req: undoObj.req, node: undoObj.node });
      }
    },
    async redoObj() {
      let redoObj = await this.redoNode(this.redoNodes);
      if (redoObj) {
        this.redoNodes.pop();
        this.undoNodes.push({ req: redoObj.req, node: redoObj.node });
      }
    },
  },
  computed: {
    mSuite() {
      return this.$store.getters.getMsuite;
    },
    buttonText() {
      return this.isDraggable ? "Click to Drag Row" : "Click to Make Child";
    },
    sortedTodos() {
      if (this.completedTasks) {
        return this.myTodos.filter((task) => (!task.is_disabled ? task : ""));
      } else {
        return this.myTodos;
      }
    },
    dragOptions() {
      return {
        animation: 200,
        disabled: false,
        ghostClass: "ghost",
      };
    },
  },
  mounted() {
    this.currentMindMap = this.$store.state.mSuite;
    this.$store.dispatch("setExportId", "todo");
    this.subscribeCable(this.currentMindMap.id);
    this.todos = this.currentMindMap.nodes;
    this.setUserOnMount();
    this.renderTodos();

    $(".vue-js-switch .v-switch-label, .v-right").css({ color: "#212529" });
    $(".v-switch-label, .v-right").css({ color: "#212529" });

    this.getUserOnMount();

    this.undoMap(this.undoObj);
    this.redoMap(this.redoObj);
  },
  watch: {
    mSuite: {
      handler(value) {
        this.currentMindMap = value;
        this.todos = value.nodes;
        //this.fetchToDos()
      },
      deep: true,
    },
    parentRange() {
      if (this.parentRange) {
        this.todoData.startDate = this.parentRange[0];
        this.todoData.dueDate = this.parentRange[1];
      }
    },
    childRange() {
      if (this.childRange) {
        this.todoChildData.startDate = this.childRange[0];
        this.todoChildData.dueDate = this.childRange[1];
      }
    },
  },
};
</script>
<style lang="scss" scoped>
@import "./todo_style.scss";
</style>
