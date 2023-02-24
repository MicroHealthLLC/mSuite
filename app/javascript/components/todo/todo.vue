<template>
  <div class="todo-app">
    <div id="todo">
      <div>
        <div class="parentGroup overflow-auto">
          <div class="">
            <div class="container max-w-lg mx-auto">
              <h1 class=" font-bold text-center text-blue-600">Todo</h1>
            </div>
          </div>
          <div class="container relative max-w-lg pt-6 mx-auto">
            <p class="text-slate-600 text-center">Your Todo</p>
            <toggle-button v-if="!isMobile" class="toggleButton mb-3" :value="true" color="#82C7EB" :sync="true"
              :labels="{ checked: 'Actionable', unchecked: 'All Tasks' }" v-model="completedTasks" width="115"
              height="28" />
            <div class="lock-container">
              <toggle-button v-if="isMobile" :value="true" color="#82C7EB" :sync="true"
                :labels="{ checked: 'Actionable', unchecked: 'All Tasks' }" v-model="completedTasks" width="100" />
              <toggle-button class="toggle-drag" v-if="isMobile" v-model="dragLocked"
                :labels="{ checked: 'Drag Locked', unchecked: 'Drag Unlocked' }" width="100" />
            </div>
            <div>
              <b-list-group class="mr-0" v-if="sortedTodos.length > 0">
                <draggable class="list-group" :disabled="dragLocked" group="people" :list="sortedTodos"
                  :move="checkMove" @change="(e) => handleEnd(e, sortedTodos)" @start="drag = true" @end="drag = false"
                  v-bind="dragOptions">
                  <transition-group type="transition" :name="!drag ? 'list' : null">
                    <div v-for="(todo) in sortedTodos" :key="todo.id">
                      <todo-map :node="todo" :selectedTodo="selectedTodo" :dragLocked="dragLocked"
                        :completedTasks="completedTasks" :editInProgress="editInProgress"
                        :current-mind-map="currentMindMap" @updateTodo="updateTodo" @toggleChildModal="toggleChildModal"
                        @toggleDeleteTodo="toggleDeleteTodo" @showInputField="showInputField" @blurEvent="blurEvent"
                        @clearTodoEditObj="clearTodoEditObj"></todo-map>
                      <b-list-group-item v-if="showChildModalTodo && todo_parent === todo.id" class="child-field">
                        <div class="ml-1">
                          <div class="relative flex h-full">
                            <div class="container relative z-20 max-w-xl mt-20 h-min">
                              <b-form @submit.prevent="addChildTodo()">
                                <b-row>
                                  <b-col cols="5" sm="5">
                                    <b-form-input :class="fieldDisabled ? 'shake' : ''" v-model="todoChildData.title"
                                      ref="title" type="text" :placeholder="'Add subtask for ' + todo.name">
                                    </b-form-input>
                                  </b-col>
                                  <b-col cols="5" sm="5">
                                    <date-picker id="input" class="w-75" v-model='todoChildData.date'
                                      placeholder="Due Date" :format="format" ref="datePicker"></date-picker>
                                  </b-col>
                                  <b-col cols="2" sm="2" class="d-flex flex-row">
                                    <b-button v-b-tooltip.hover title="Save" type="submit" variant="success"> <i
                                        class="fas fa-save"></i> </b-button>
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
                        <b-col cols="5" class="todo-field">
                          <b-form-input :class="fieldDisabled ? 'shake' : ''" v-model="todoData.title" ref="title"
                            type="text" :placeholder="placeHolderText">
                          </b-form-input>
                        </b-col>
                        <b-col cols="5">
                          <date-picker id="input" class="w-75" v-model='todoData.date' placeholder="Due Date"
                            :format="format" ref="datePicker"></date-picker>
                        </b-col>
                        <b-col sm="2" cols="2" class="d-flex flex-row justify-content-end">
                          <b-button v-b-tooltip.hover title="Save" type="submit" variant="success"> <i
                              class="fas fa-save"></i> </b-button>
                          <b-button class="ml-1" v-b-tooltip.hover variant="warning" @click="clearTodoObj"
                            title="Reset"> <i class="fas fa-undo-alt"></i> </b-button>
                        </b-col>
                      </b-row>
                    </b-form>
                  </div>
                </div>
              </b-list-group-item>
            </div>
            <!-- <div class="lock-container">
                <toggle-button class="toggle-drag" v-if="!isMobile" v-model="dragLocked" :labels="{checked: 'Drag Locked', unchecked: 'Drag Unlocked'}" width="100"/>
              </div> -->
          </div>
        </div>
      </div>
    </div>
    <sweet-modal ref="errTitle" class="of_v" icon="error">
      Node Title Can't be empty!
    </sweet-modal>
  </div>
</template>
<script>
import http from "../../common/http"
import domtoimage from "dom-to-image-more"
import draggable from 'vuedraggable'
import { ToggleButton } from 'vue-js-toggle-button'
import DatePicker from 'vue2-datepicker';
import './datepicker.css';
import TodoMap from "./TodoMap";
import TemporaryUser from "../../mixins/temporary_user.js"
import Common from "../../mixins/common.js"
import History from "../../mixins/history.js"
import { isMobile } from 'mobile-device-detect'

export default {
  props: {
    undoMap: Function,
    redoMap: Function
  },
  data() {
    return {
      currentMindMap: this.$store.getters.getMsuite,
      todos: [],
      todo: {},
      userList: [],
      selectedTodo: { id: null },
      myTodos: [{
        name: '',
        counter: 0,
      }],
      todo_parent: null,
      showModalTodo: false,
      showChildModalTodo: false,
      todoData: { title: null, date: '' },
      todoChildData: { title: null, date: '' },
      uniqueChild: new Set(),
      childCompleted: false,
      parentIndex: null,
      index: null,
      completedTasks: null,
      selectedTodoDelete: null,
      disabledBefore: new Date(),
      placeHolderText: 'Your Todo',
      fieldDisabled: false,
      format: 'MM/DD/YYYY',
      editInProgress: false,
      undoNodes: [],
      redoNodes: [],
      undoDone: false,
      drag: false,
      dragLocked: isMobile ? true : false,
    }
  },
  components: {
    TodoMap,
    ToggleButton,
    DatePicker,
    draggable
  },
  mixins: [Common, TemporaryUser, History],
  channels: {
    WebNotificationsChannel: {
      received(data) {
        //console.log(data)
        if (data.message === "Mindmap Deleted" && this.currentMindMap.id === data.mindmap.id) {
          window.open('/', '_self')
        } else if (data.message === "Mindmap Updated" && this.currentMindMap.id === data.mindmap.id) {
          this.$store.commit('setMSuite', data.mindmap)
          this.fetchToDos()
        } else if (data.message === "Password Updated" && this.currentMindMap.id === data.mindmap.id) {
          setTimeout(() => {
            location.reload()
          }, 500)
        } else if (data.message === "storage updated" && this.currentMindMap.id == data.content.mindmap_id) {
          this.$store.dispatch('setUserEdit', data.content.userEdit)
          this.$store.dispatch('setNodeNumber', data.content.nodeNumber)
          this.$store.dispatch('setTemporaryUser', data.content.userEdit)
          this.$store.dispatch('setUserList', data.content.userEdit)
        } else if (data.message === "Reset mindmap" && this.currentMindMap.id === data.mindmap.id) {
          this.$store.commit('setMSuite', data.mindmap)
          this.currentMindMap = data.mindmap
          this.resetMindmap()
          this.fetchToDos()
        }
        else {
          this.fetchToDos()
        }
      }
    }
  },
  methods: {
    async handleEnd(e, list) {
      if (!e.removed) {
        let newIdList = list.map(i => i.id)
        let nodes = this.$store.getters.getMsuite.nodes
        let sortedTodoArr = this.relativeSortArray(nodes, newIdList)
        if (e.moved) {
          this.reorderTodo(sortedTodoArr)
        } else if (e.added) {
          let otherNode = sortedTodoArr.find(n => n.id != e.added.element.id)
          sortedTodoArr.forEach(n => {
            if (n.id == e.added.element.id)
              n.parent_node = otherNode.parent_node
          })
          this.reorderTodo(sortedTodoArr)
        }
      }
    },
    checkMove(e) {
      /* console.log(e)
      console.log(e.draggedContext.element.name)
      console.log(e.relatedContext.element.name) */
    },
    relativeSortArray(arr1, arr2) {
      let sortedArr = [];
      let auxArr = [];
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
    async reorderTodo(list) {
      let data = {
        mindmap: {
          nodes: list
        }
      }
      await this.$store.dispatch('updateMSuite', data)
        .then((result) => {
          this.fetchToDos()
        }).catch((err) => {
          console.error(err);
        });
    },
    clearTodoObj() {
      this.todo = {}
      this.todoData = { title: null, date: null }
      this.todoChildData = { title: null, date: null }
    },
    cancelChildObj() {
      this.showChildModalTodo = false
      this.clearTodoObj()
    },
    toggleChildModal(todo) {
      this.todo = todo
      this.todo_parent = todo.id
      this.showChildModalTodo = true
      this.sendLocals(true)
    },
    clearTodoEditObj() {
      this.selectedTodo = { id: '' }
      this.editInProgress = false
      this.fetchToDos()
      this.sendLocals(false)
    },
    async fetchToDos() {
      let res = await this.$store.dispatch('getMSuite')
      let response = this.$store.getters.getMsuite
      this.$store.dispatch('setMindMapId', response.id)
      this.defaultDeleteDays = response.defaultDeleteDays
      this.deleteAfter = response.deleteAfter
      this.expDays = response.expDays
      this.$store.commit('SET_MSUITE', response)
      this.todos = response.nodes
      this.renderTodos()
    },
    renderTodos() {
      let parent_nodes = []
      let date = ''
      this.todos.forEach((node) => {
        if (node.parent_node == null) {
          parent_nodes.push(node)
        }
      })
      parent_nodes = parent_nodes.map((node, index) => {
        if (node.duedate != null) {
          date = new Date(node.duedate).toLocaleDateString("en-US")
        } else {
          date = node.duedate
        }
        return {
          name: node.title,
          id: node.id,
          is_disabled: node.is_disabled,
          counter: 0,
          duedate: date,
          children: []
        }
      })
      this.getChildNode(parent_nodes)
    },
    getChildNode(parent_nodes) {
      let childNodes = []
      let date = ''
      this.todos.forEach((node) => {
        if (node.duedate != null) {
          date = new Date(node.duedate).toLocaleDateString("en-US")
        } else {
          date = node.duedate
        }
        parent_nodes.forEach((p, index) => {
          if (p.id == node.parent_node) {
            let obj = {
              name: node.title,
              id: node.id,
              is_disabled: node.is_disabled,
              parent: p.id,
              duedate: date,
              children: []
            }
            parent_nodes[index].children.push(obj)
          }
        })
      })
      if (childNodes.length > 0) {
        this.getChildNode(_.uniq(childNodes))
      }
      this.myTodos = parent_nodes
    },
    async updateTodoUser() {
      await this.$store.dispatch('updateMSuite', {
        canvas: this.$store.getters.getUser
      })
    },
    async addTodo() {
      if (this.todoData.title == null || this.todoData.title.trim().length === 0) {
        this.$refs['errTitle'].open()
        this.fieldDisabled = true
        setTimeout(() => {
          this.fieldDisabled = false
        }, 1500)
        return
      }
      if (this.todoData.date) this.todoData.date = moment(this.todoData.date)._d
      let data = {
        node: {
          title: this.todoData.title,
          description: '',
          mindmap_id: this.currentMindMap.id,
          startdate: this.todoData.date,
          duedate: this.todoData.date,
          is_disabled: false,
          hide_children: true,
          line_color: '#18A2B8'
        }
      }
      this.updateTodoUser()
      http.post(`/nodes.json`, data).then((result) => {
        this.myTodos.push(result.data.node)
        this.undoNodes.push({ req: 'addNode', 'node': result.data.node })
        this.showModalTodo = false
        this.clearTodoObj()
        this.sendLocals(false)
      }).catch((err) => {
        console.error(err);
      });
    },
    async addChildTodo() {
      if (this.todoChildData.title == null || this.todoChildData.title.trim().length === 0) {
        this.$refs['errTitle'].open()
        this.fieldDisabled = true
        setTimeout(() => {
          this.fieldDisabled = false
        }, 1500)
        return
      }
      if (this.todoChildData.date) this.todoChildData.date = moment(this.todoChildData.date)._d

      let data = {
        node: {
          title: this.todoChildData.title,
          description: '',
          mindmap_id: this.currentMindMap.id,
          parent_node: this.todo_parent,
          startdate: this.todoChildData.date,
          duedate: this.todoChildData.date,
          line_color: '#58A2B8',
          is_disabled: false,
          hide_children: true
        }
      }
      this.updateTodoUser()
      http.post(`/nodes.json`, data).then((result) => {
        this.undoNodes.push({ req: 'addNode', 'node': result.data.node })
        this.showChildModalTodo = false
        this.clearTodoObj()
        this.sendLocals(false)
      }).catch((err) => {
        console.error(err);
      });
    },
    updateTodo(todo, title, completed) {
      if (title == null || title.trim().length === 0) {
        this.$refs['errTitle'].open()
        this.fieldDisabled = true
        setTimeout(() => {
          this.fieldDisabled = false
        }, 1500)
        return
      }
      if (this.selectedTodo.duedate && typeof this.selectedTodo.duedate !== 'string') {
        this.selectedTodo.duedate = moment(this.selectedTodo.duedate)._d
      }
      todo.title = title
      todo.is_disabled = completed
      todo.duedate = this.selectedTodo.duedate ? this.selectedTodo.duedate : todo.duedate
      todo.duedate = moment(todo.duedate)._d
      todo.startdate = todo.duedate
      todo.hide_children = true

      if (this.undoNodes.length > 0) {
        this.undoNodes.forEach((element, index) => {
          if (element['node'].id === todo.id) {
            this.undoNodes[index]['node'].title = todo.title
            this.undoNodes[index]['node'].startdate = todo.duedate
            this.undoNodes[index]['node'].duedate = todo.duedate
            this.undoNodes[index]['node'].is_disabled = completed
          }
        });
      } else {
        this.undoNodes.push({ 'req': 'addNode', node: todo })
      }
      this.updateTodoUser()
      http.put(`/nodes/${todo.id}`, todo)
      this.selectedTodo = { id: '' }
      this.editInProgress = false
      this.sendLocals(false)
    },
    async deleteTodo() {
      let todo = this.selectedTodoDelete
      this.index = this.myTodos.findIndex(e => e.id == todo.id)
      this.updateTodoUser()
      await http.delete(`/nodes/${todo.id}.json`)
        .then((res) => {
          let receivedNodes = res.data.node
          if (receivedNodes && receivedNodes.length > 0) {
            this.undoNodes.push({ 'req': 'deleteNode', 'node': receivedNodes })
          }
          if (!this.undoDone) {
            let duedate = moment(todo.duedate)._d
            let myNode = {
              id: todo.id,
              title: todo.name,
              startdate: duedate,
              duedate: duedate,
              mindmap_id: this.currentMindMap.id,
              parent_node: todo.parent,
              is_disabled: todo.is_disabled
            }
            this.undoNodes.push({ 'req': 'deleteNode', node: myNode })
          }
        }).catch((err) => {
          console.error(err);
        });
    },
    toggleDeleteTodo(todo) {
      this.selectedTodoDelete = todo
      this.undoDone = false
      this.clearTodoObj()
      this.deleteTodo()
      this.sendLocals(false)
    },
    showInputField(todo) {
      let _this = this
      _this.editInProgress = true
      _this.selectedTodo = todo
      if (document.getElementById('textArea' + _this.selectedTodo.id) != null) {
        setTimeout(() => {
          document.getElementById('textArea' + _this.selectedTodo.id).focus()
        }, 300)
      }
      this.sendLocals(true)
    },
    blurEvent(val, e) {
      this.selectedTodo = { id: null }
      if (e.target) {
        e.target.blur()
        this.sendLocals(false)
      }
    },
    resetMindmap() {
      this.undoNodes = []
      this.redoNodes = []
      this.cancelChildObj()
      this.completedTasks = false
    },
    async undoObj() {
      this.undoDone = true
      let undoObj = await this.undoNode(this.undoNodes)
      if (undoObj) {
        this.undoNodes.pop()
        this.redoNodes.push({ req: undoObj.req, node: undoObj.node })
      }
    },
    async redoObj() {
      let redoObj = await this.redoNode(this.redoNodes)
      if (redoObj) {
        this.redoNodes.pop()
        this.undoNodes.push({ req: redoObj.req, 'node': redoObj.node })
      }
    },
  },
  computed: {
    mSuite() {
      return this.$store.getters.getMsuite
    },
    sortedTodos() {
      if (this.completedTasks) {
        return this.myTodos
          .filter(task => (!task.is_disabled) ? task : '')
      } else {
        return this.myTodos
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
  mounted() {
    this.currentMindMap = this.$store.state.mSuite
    this.$store.dispatch('setExportId', 'todo')
    this.subscribeCable(this.currentMindMap.id)
    this.todos = this.currentMindMap.nodes
    this.setUserOnMount()
    this.renderTodos()

    $(".vue-js-switch .v-switch-label, .v-right").css({ "color": "#212529" })
    $(".v-switch-label, .v-right").css({ "color": "#212529" })

    this.getUserOnMount()

    this.undoMap(this.undoObj)
    this.redoMap(this.redoObj)

  },
  watch: {
    mSuite: {
      handler(value) {
        this.currentMindMap = value
        this.todos = value.nodes
        //this.fetchToDos()
      }, deep: true
    },
  }
}
</script>
<style  lang="scss" scoped>
@import "./todo_style.scss";
</style>
