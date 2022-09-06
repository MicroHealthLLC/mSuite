<template>
  <div class="todo-app">
    <navigation-bar
      v-if="isMounted"
      @mSuiteTitleUpdate="mSuiteTitleUpdate"
      @deleteMindmap="deleteMap"
      @resetMindmap="resetMindmap"
      @undoMindmap="undoObj"
      @redoMindmap="redoObj"
      @sendLocals="sendLocals"
      :current-mind-map="currentMindMap"
      :defaultDeleteDays="defaultDeleteDays"
      :expDays="expDays"
      :deleteAfter="deleteAfter"
      :exportId="'todo'"
      :isEditing="isEditing"
      :temporaryUser="temporaryUser"
      :userList="userList"
      :saveElement="saveElement"
      ref="todoNavigation">
    </navigation-bar>
    <div id="todo">
      <div>
        <div class="h-75">
          <div class="">
            <div class="container max-w-lg mx-auto">
                <h1 class=" font-bold text-center text-blue-600">ToDo</h1>
            </div>
          </div>
          <div class="container relative max-w-lg pt-6 mx-auto">
            <p class="text-slate-600 text-center">Your Todos</p>
            <toggle-button 
              class="toggleButton mb-3"
              :value="true" 
              color="#82C7EB" 
              :sync="true" 
              :labels="{checked: 'Actionable', unchecked: 'All Tasks'}" 
              v-model="completedTasks" 
              width = "115"
              height = "28"/>
            <div class="parentGroup">
              <b-list-group class="mr-0" v-if="sortedTodos.length > 0">
                <div v-for="(todo) in sortedTodos" :key="todo.id">
                  <todo-map 
                    :node="todo" 
                    :selectedTodo="selectedTodo" 
                    :completedTasks="completedTasks"
                    :editInProgress="editInProgress"
                    :current-mind-map="currentMindMap"
                    @updateTodo="updateTodo"
                    @toggleChildModal="toggleChildModal"
                    @toggleDeleteTodo="toggleDeleteTodo"
                    @showInputField="showInputField"
                    @blurEvent="blurEvent"
                    @clearTodoEditObj="clearTodoEditObj"></todo-map>
                  <b-list-group-item v-if="showChildModalTodo && todo_parent === todo.id" class="child-field">
                    <div class="ml-1">
                      <div class="relative flex h-full">
                        <div class="container relative z-20 max-w-xl mt-20 h-min">
                          <b-form @submit.prevent="addChildTodo()">
                            <b-row>
                              <b-col cols="5" sm="5">
                                <b-form-input
                                  :class="fieldDisabled ? 'shake': ''"
                                  v-model="todoChildData.title"
                                  ref="title"
                                  type="text"
                                  :placeholder="'Add subtask for ' + todo.name"
                                >
                                </b-form-input>
                              </b-col>
                              <b-col cols="5" sm="5">
                                  <date-picker
                                    id="input"
                                    class="w-75"
                                    v-model='todoChildData.date'
                                    placeholder="Due Date"
                                    :format="format"
                                    ref="datePicker"
                                    ></date-picker>
                              </b-col>
                              <b-col cols="2" sm="2" class="d-flex flex-row">
                                <b-button v-b-tooltip.hover title="Save" type="submit" variant="success"> <i class="fas fa-save"></i> </b-button>
                                <b-button class="ml-1" v-b-tooltip.hover title="Cancel" variant="secondary" @click="cancelChildObj"><i class="fas fa-eject"></i></b-button>
                              </b-col>
                            </b-row>
                          </b-form>
                        </div>
                        <div @click="toggleChildModal(todo)" class="absolute top-0 z-10 w-full h-full"></div>
                      </div>
                    </div>
                  </b-list-group-item>
                </div>
              </b-list-group>
              <b-list-group-item v-if="!showChildModalTodo" class="mb-5">
                <div class="relative flex h-full">
                  <div class="container relative max-w-xl mt-20 h-min">
                    <b-form @submit.prevent="addTodo()">
                      <b-row>
                        <b-col cols="5" class="todo-field">
                          <b-form-input
                            :class="fieldDisabled ? 'shake': ''"
                            v-model="todoData.title"
                            ref="title"
                            type="text"
                            :placeholder="placeHolderText"
                          >
                          </b-form-input>
                        </b-col>
                        <b-col cols="5">
                            <date-picker
                              id="input"
                              class="w-75"
                              v-model='todoData.date'
                              placeholder="Due Date"
                              :format="format"
                              ref="datePicker"
                              ></date-picker>
                        </b-col>
                        <b-col sm="2" cols="2" class="d-flex flex-row">
                          <b-button v-b-tooltip.hover title="Save" type="submit" variant="success"> <i class="fas fa-save"></i> </b-button>
                          <b-button class="ml-1" v-b-tooltip.hover variant="warning" @click="clearTodoObj" title="Reset"> <i class="fas fa-undo-alt"></i> </b-button>
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
      Node Title Can't be empty!
    </sweet-modal>
  </div>
</template>
<script>
  import http from "../../common/http"
  import domtoimage from "dom-to-image-more"
  import { ToggleButton } from 'vue-js-toggle-button'
  import DatePicker from 'vue2-datepicker';
  import './datepicker.css';
  import TodoMap from "./TodoMap";
  import TemporaryUser from "../../mixins/temporary_user.js"

  export default {
    props: ['currentMindMap'],
    data() {
      return {
        isMounted: false,
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
        format: 'YYYY-MM-DD',
        editInProgress: false,
        undoNodes: [],
        redoNodes: [],
        undoDone: false,
        isEditing: false,
        saveElement: false
      }
    },
    components: {
      TodoMap,
      ToggleButton,
      DatePicker
    },
    mixins: [TemporaryUser],
    channels: {
      WebNotificationsChannel: {
        received(data) {
          if (data.message === "Mindmap Deleted" && this.currentMindMap.id === data.mindmap.id)
          {
            window.open('/','_self')
          } else if (data.message === "Password Updated" && this.currentMindMap.id === data.mindmap.id) {
            setTimeout(() => {
              location.reload()
            }, 500)
          } else if (data.message === "storage updated" && this.currentMindMap.id == data.content.mindmap_id)
          {
            localStorage.nodeNumber = data.content.nodeNumber
            localStorage.userNumber = data.content.userNumber
            this.userList.push(data.content.userEdit)
            localStorage.userList = JSON.stringify(this.userList);
            this.temporaryUser = data.content.userEdit
            this.isEditing = data.isEditing
            if (!this.isEditing) {
              this.saveElement = true
              setTimeout(()=>{
                this.saveElement = false
              },1200)
            }
          } else if (data.message === "Reset mindmap" && this.currentMindMap.id === data.mindmap.id) {
            this.currentMindMap = data.mindmap
            this.fetchToDos()
          }
          else {
            this.fetchToDos()
            this.saveElement = true
            setTimeout(()=>{
              this.saveElement = false
            },1200)
          }
        }
      }
    },
    methods: {
      clearTodoObj() {
        this.todo = {}
        this.todoData = { title: null, date: null }
        this.todoChildData = { title: null, date: null }
      },
      cancelChildObj() {
        this.showChildModalTodo = false
        this.clearTodoObj()
      },
      async getMindmap(id) {
        await http
        .get(`/msuite/${id}.json`)
        .then((res) => {
          this.expDays = res.data.expDays
          this.defaultDeleteDays = res.data.defaultDeleteDays
          this.deleteAfter = res.data.deleteAfter
          this.currentMindMap = res.data.mindmap
          this.isMounted = true
          this.subscribeCable(this.currentMindMap.id)
        })
      },
      toggleChildModal(todo) {
        this.todo = todo
        this.todo_parent = todo.id
        this.showChildModalTodo = true
        this.sendLocals(true)
      },
      clearTodoEditObj() {
        this.selectedTodo = {id: ''}
        this.editInProgress = false
        this.fetchToDos()
        this.sendLocals(false)
      },
      async fetchToDos(){
        let mindmap_key = window.location.pathname.split('/')[2]
        let response = await http.get(`/msuite/${mindmap_key}.json`)
        this.defaultDeleteDays = response.data.defaultDeleteDays
        this.deleteAfter = response.data.deleteAfter
        this.expDays = response.data.expDays
        this.currentMindMap = response.data.mindmap
        this.todos = response.data.mindmap.nodes
        this.renderTodos()
      },
      renderTodos(){
        let parent_nodes = []
        let date = ''
        this.todos.forEach((node) => {
          if(node.parent_node == null){
            parent_nodes.push(node)
          }
        })
        parent_nodes = parent_nodes.map((node, index) => {
          if(node.duedate != null){
            date = node.duedate.slice(0, 10)
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
      getChildNode(parent_nodes){
        let childNodes = []
        let date = ''
        this.todos.forEach((node) => {
          if(node.duedate != null){
            date = node.duedate.slice(0, 10)
          } else {
            date = node.duedate
          }
          parent_nodes.forEach((p, index)=> {
            if(p.id == node.parent_node){
              let obj = { name: node.title,
                          id: node.id ,
                          is_disabled: node.is_disabled,
                          parent: p.id,
                          duedate: date,
                          children: []}
              parent_nodes[index].children.push(obj)
            }
          })
        })
        if(childNodes.length > 0){
          this.getChildNode(_.uniq(childNodes))
        }
        this.myTodos = parent_nodes
      },
      async addTodo() {
        if(this.todoData.title == null || this.todoData.title.trim().length === 0){
          this.$refs['errTitle'].open()
          this.fieldDisabled = true
          setTimeout(() => {
            this.fieldDisabled = false
          }, 1500)
          return
        }
        if(this.todoData.date) this.todoData.date = new Date(this.todoData.date.getTime() - this.todoData.date.getTimezoneOffset() * 60 * 1000)
        let data = {
          node: {title: this.todoData.title, mindmap_id: this.currentMindMap.id, duedate: this.todoData.date, is_disabled: false}
        }
        http.post(`/nodes.json`, data).then((result) => {
          this.myTodos.push(result.data.node)
          this.undoNodes.push({req: 'addNode', receivedData: result.data.node})
          this.showModalTodo = false
          this.clearTodoObj()
          this.sendLocals(false)
        }).catch((err) => {
          console.error(err);
        });
      },
      async addChildTodo() {
        if(this.todoChildData.title == null || this.todoChildData.title.trim().length === 0){
          this.$refs['errTitle'].open()
          this.fieldDisabled = true
          setTimeout(() => {
            this.fieldDisabled = false
          }, 1500)
          return
        }
        if(this.todoChildData.date) this.todoChildData.date = new Date(this.todoChildData.date.getTime() - this.todoChildData.date.getTimezoneOffset() * 60 * 1000)
        let data = {
          node: {title: this.todoChildData.title, duedate: this.todoChildData.date, mindmap_id: this.currentMindMap.id, parent_node: this.todo_parent, is_disabled: false}
        }
        http.post(`/nodes.json`, data).then((result) => {
          this.undoNodes.push({req: 'addNode', receivedData: result.data.node})
          this.showChildModalTodo = false
          this.clearTodoObj()
          this.sendLocals(false)
        }).catch((err) => {
          console.error(err);
        });
      },
      updateTodo(todo, title, completed) {
        if(title == null || title.trim().length === 0){
          this.$refs['errTitle'].open()
          this.fieldDisabled = true
          setTimeout(() => {
            this.fieldDisabled = false
          }, 1500)
          return
        }
        if(this.selectedTodo.duedate && typeof this.selectedTodo.duedate !== 'string') {
          this.selectedTodo.duedate = new Date(this.selectedTodo.duedate.getTime() - this.selectedTodo.duedate.getTimezoneOffset() * 60 * 1000)
        }
        todo.title = title
        todo.is_disabled = completed
        todo.duedate = this.selectedTodo.duedate

        if(this.undoNodes.length > 0) {
          this.undoNodes.forEach((element, index) => {
            if(element['receivedData']){
              if(element['receivedData'].id === todo.id) {
              this.undoNodes[index]['receivedData'].title = todo.title
              this.undoNodes[index]['receivedData'].duedate = todo.duedate
              this.undoNodes[index]['receivedData'].is_disabled = completed
              }
            } else {
              if(element['node'].id === todo.id) {
              this.undoNodes[index]['node'].title = todo.title
              this.undoNodes[index]['node'].duedate = todo.duedate
              this.undoNodes[index]['node'].is_disabled = completed
              }
            }
          });
        } else {
          this.undoNodes.push({'req': 'addNode', node: todo})
        }

        http.put(`/nodes/${todo.id}`, todo)
        this.selectedTodo = {id: ''}
        this.editInProgress = false
        this.sendLocals(false)
      },
      async deleteTodo() {
        let todo = this.selectedTodoDelete
        this.index = this.myTodos.findIndex(e => e.id == todo.id)
        await  http.delete(`/nodes/${todo.id}.json`)
          .then((res) => {
            let receivedNodes = res.data.node
            if(receivedNodes && receivedNodes.length > 0){
              this.undoNodes.push({'req': 'deleteNode', 'node' : receivedNodes})
            }
            if (!this.undoDone) {
              let myNode = {
                id: todo.id,
                title: todo.name,
                duedate: todo.duedate,
                mindmap_id: this.currentMindMap.id,
                parent_node: todo.parent,
                is_disabled: todo.is_disabled
              }
              this.undoNodes.push({'req': 'deleteNode', node: myNode})
            }
          }).catch((err) => {
            console.error(err);
          });
      },
      toggleDeleteTodo(todo){
        this.selectedTodoDelete = todo
        this.undoDone = false
        this.clearTodoObj()
        this.deleteTodo()
        this.sendLocals(false)
      },
      showInputField(todo){
        let _this = this
        _this.editInProgress = true
        _this.selectedTodo = todo
        if(document.getElementById('textArea'+ _this.selectedTodo.id) != null){
          setTimeout(() => {
            document.getElementById('textArea'+ _this.selectedTodo.id).focus()
          }, 300)
        }
        this.sendLocals(true)
      },
      blurEvent(val, e){
        this.selectedTodo = {id: null}
        if (e.target) {
          e.target.blur()
          this.sendLocals(false)
        }
      },
      resetMindmap() {
        http
          .get(`/msuite/${this.currentMindMap.unique_key}/reset_mindmap.json`)
          .then((res) => {
            this.currentMindMap.nodes = []
            this.undoNodes = []
            this.redoNodes = []
            this.cancelChildObj()
            this.completedTasks = false
          })
          .catch((err) => {
            console.log(err)
          })
      },
      undoObj(){
        this.undoDone = true
        http
          .post(`/msuite/${this.currentMindMap.unique_key}/undo_mindmap.json`, { undoNode: this.undoNodes })
          .then((res) => {
            this.undoNodes.pop()
            let node = res.data.node.node
            let req = res.data.node.req
            this.redoNodes.push({req, node})
          })
          .catch((err) => {
            console.log(err)
          })
      },
      redoObj(){
        http
          .put(`/msuite/${this.currentMindMap.unique_key}/redo_mindmap.json`, { redoNode: this.redoNodes })
          .then((res) => {
            this.redoNodes.pop()
            let receivedData = res.data.node.node
            let req = res.data.node.req
            this.undoNodes.push({req, receivedData})
          })
          .catch((err) => {
            console.log(err)
          })
      },
    },
    computed: {
      sortedTodos() {
        if(this.completedTasks){
          return this.myTodos
            .filter(task => (!task.is_disabled) ? task : '')
        } else {
          return this.myTodos
        }
      }
    },
    mounted() {
      if (this.$route.params.key) {
        this.getMindmap(this.$route.params.key)
        this.todos = this.currentMindMap.nodes
        this.renderTodos()
      }
      $(".vue-js-switch .v-switch-label, .v-right").css({"color": "#212529"})

      $(".v-switch-label, .v-right").css({"color": "#212529"})
      if(localStorage.mindmap_id == this.currentMindMap.id){
        this.userList = JSON.parse(localStorage.userList)
        this.temporaryUser = localStorage.userEdit
      }
    },
  }
</script>
<style scoped>
  @import "./todo_style.css";
</style>
