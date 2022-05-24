<template>
  <div class="todo-app">
    <navigation-bar
      v-if="isMounted"
      @mSuiteTitleUpdate="mSuiteTitleUpdate"
      @openPrivacy="openPrivacy"
      @deleteMindmap="deleteMap"
      @addTodo="toggleModal"
      @resetMindmap="resetMindmap"
      :current-mind-map="currentMindMap"
      :defaultDeleteDays="defaultDeleteDays"
      :deleteAfter="deleteAfter"
      :exportId="'todo'"
      ref="todoNavigation">
    </navigation-bar>
    <div id="todo">
      <div>
        <div class="h-75">
          <div class="">
            <div class="container max-w-lg mx-auto">
                <h1 class=" font-bold text-center text-blue-600">ToDo App</h1>
            </div>
          </div>
          <div class="container relative max-w-lg pt-6 mx-auto">
            <p class="text-slate-600 text-center">Your Todos</p>
            <toggle-button 
              class="toggleButton mb-3"
              :value="true" 
              color="#82C7EB" 
              :sync="true" 
              :labels="{checked: 'Actionable', unchecked: 'All tasks'}" 
              v-model="completedTasks" 
              width = "90"
              height = "28"/>
            <div class="parentGroup">
              <b-list-group class="mr-0" v-if="sortedTodos.length > 0">
                <div v-for="(todo) in sortedTodos" :key="todo.id">
                  <todo-map 
                    :node="todo" 
                    :selectedTodo="selectedTodo" 
                    :completedTasks="completedTasks"
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
                                  :placeholder="'Add Child ToDo for ' + todo.name"
                                >
                                </b-form-input>
                              </b-col>
                              <b-col cols="5" sm="5">
                                  <date-picker
                                    id="input" 
                                    class="w-75"
                                    v-model='todoChildData.date'
                                    placeholder="Due Date"
                                    :disabled-date="disabledStartDate"
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
                              :disabled-date="disabledStartDate"
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
                  <div @click="toggleModal(todo)" class="absolute top-0 z-10 w-full h-full"></div>
                </div>
              </b-list-group-item>
            </div>
          </div>
        </div>
      </div>
    </div>
    <make-private-modal ref="make-private-modal" @password-apply="passwordProtect" @password_mismatched="$refs['passwordMismatched'].open()" :password="currentMindMap.password" :isSaveMSuite="isSaveMSuite"></make-private-modal>
    <delete-map-modal ref="delete-map-modal" @delete-mindmap="confirmDeleteMindmap"></delete-map-modal>
    <delete-password-modal ref="delete-password-modal" @deletePasswordCheck="deleteMindmapProtected"></delete-password-modal>
    <confirm-save-key-modal ref="confirm-save-key-modal" :current-mind-map="currentMindMap"></confirm-save-key-modal>
    <sweet-modal ref="passwordMismatched" class="of_v" icon="error" title="Password Mismatch">
      Your Password and Confirm Password are Mismatched, Please Try Again!
      <button slot="button" @click="passwordAgain" class="btn btn-warning mr-2">Try Again</button>
      <button slot="button" @click="$refs['passwordMismatched'].close()" class="btn btn-secondary">Cancel</button>
    </sweet-modal>
    <sweet-modal ref="errorModal" class="of_v" icon="error" title="Password Error">
      Incorrect Password, Please Try Again!
    </sweet-modal>
    <sweet-modal ref="successModal" class="of_v" icon="success">
      Password updated successfully!
    </sweet-modal>
    <sweet-modal ref="deleteTodoConfirm" class="of_v" icon="warning" title="Delete ToDo">
      Do you want to delete this ToDo?
      <button slot="button" @click="deleteTodo" class="btn btn-warning mr-2">Delete</button>
      <button slot="button" @click="$refs['deleteTodoConfirm'].close()" class="btn btn-secondary">Cancel</button>
    </sweet-modal>
    <sweet-modal ref="errTitle" class="of_v" icon="error">
      Node Title Can't be empty!
    </sweet-modal>
  </div>
</template>
<script>
  import http from "../../common/http"
  import domtoimage from "dom-to-image-more"
  import DeleteMapModal from '../../common/modals/delete_modal';
  import MakePrivateModal from "../../common/modals/make_private_modal"
  import DeletePasswordModal from '../../common/modals/delete_password_modal';
  import { ToggleButton } from 'vue-js-toggle-button'
  import DatePicker from 'vue2-datepicker';
  import './datepicker.css';
  import TodoMap from "./TodoMap";

  export default {
    props: ['currentMindMap'],
    data() {
      return {
        isMounted: false,
        todos: [],
        todo: {},
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
        format: 'YYYY-MM-DD'
      }
    },
    components: {
      DeleteMapModal,
      DeletePasswordModal,
      MakePrivateModal,
      TodoMap,
      ToggleButton,
      DatePicker
    },
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
          } else if (data.message === "Reset mindmap" && this.currentMindMap.id === data.mindmap.id) {
            this.currentMindMap = data.mindmap
            this.fetchToDos()
          }
          else {
            this.fetchToDos()
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
          this.defaultDeleteDays = res.data.defaultDeleteDays
          this.deleteAfter = res.data.deleteAfter
          this.currentMindMap = res.data.mindmap
          this.isMounted = true
          this.$cable.subscribe({ channel:"WebNotificationsChannel", room: this.currentMindMap.id })
        })
      },
      openPrivacy(val) {
        this.isSaveMSuite = val
        this.$refs['make-private-modal'].$refs['makePrivateModal'].open()
      },
      deleteMap() {
        this.$refs['delete-map-modal'].$refs['deleteMapModal'].open()
      },
      confirmDeleteMindmap() {
        if (this.currentMindMap.password){
          this.$refs['delete-password-modal'].$refs['DeletePasswordModal'].open()
        } else {
          this.deleteMindmap()
        } 
      },
      deleteMindmapProtected(password) {
        http
        .delete(`/msuite/${this.currentMindMap.unique_key}.json?password_check=${password}`)
        .then(res=>{
          if (!res.data.success && this.currentMindMap.password)
            this.$refs['errorModal'].open()
        })
        .catch(error => {
          console.log(error)
        })
      },
      deleteMindmap() {
        http
        .delete(`/msuite/${this.currentMindMap.unique_key}.json`)
        .then(res => {
          window.open("/", "_self")
        })
        .catch(error => {
          console.log(error)
        })
      },
      passwordProtect(new_password, old_password, is_mSuite) {
        http
        .patch(`/msuite/${this.currentMindMap.unique_key}.json`,{mindmap:{password: new_password, old_password: old_password}})
        .then(res => {
          if (res.data.mindmap) {
            this.currentMindMap.password = res.data.mindmap.password
            if(!is_mSuite) window.open("/", "_self")
            else location.reload()
            this.$refs['successModal'].open()
          } else {
            if (res.data.error) this.$refs['errorModal'].open()
          }
        })
      },
      passwordAgain() {
        this.$refs['passwordMismatched'].close()
        this.openPrivacy()
      },
      toggleModal() {
        this.todo = {}
        this.showChildModalTodo = false
        this.showModalTodo = !this.showModalTodo
        this.$nextTick(() => this.$refs.title.focus())
        this.$refs['addTodo'].open()
      },
      toggleChildModal(todo) {
        this.todo = todo
        this.todo_parent = todo.id
        this.showChildModalTodo = true
      },
      clearTodoEditObj() {
        this.selectedTodo = {id: ''}
        this.fetchToDos()
      },
      async fetchToDos(){
        let mindmap_key = window.location.pathname.split('/')[2]
        let response = await http.get(`/msuite/${mindmap_key}.json`)
        this.defaultDeleteDays = response.data.defaultDeleteDays
        this.deleteAfter= response.data.deleteAfter
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
          this.showModalTodo = false
          this.clearTodoObj()
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
          this.showChildModalTodo = false
          this.clearTodoObj()
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
        let obj = {
          node: {
            id: todo.id,
            title: title,
            is_disabled: completed,
            duedate: this.selectedTodo.duedate
          }
        }
        http.put(`/nodes/${todo.id}`, obj)
        this.selectedTodo = {id: ''}
      },
      async deleteTodo() {
        let todo = this.selectedTodoDelete
        this.index = this.myTodos.findIndex(e => e.id == todo.id)
        await  http.delete(`/nodes/${todo.id}`)
          .then((result) => {
          }).catch((err) => {
            console.error(err);
          });
        this.$refs['deleteTodoConfirm'].close()
      },
      toggleDeleteTodo(todo){
        this.selectedTodoDelete = todo
        this.clearTodoObj()
        this.$refs['deleteTodoConfirm'].open()
      },
      showInputField(todo){
        let _this = this
        _this.selectedTodo = todo
        if(document.getElementById('textArea'+ _this.selectedTodo.id) != null){
          setTimeout(() => {
            document.getElementById('textArea'+ _this.selectedTodo.id).focus()
          }, 300)
        }
      },
      blurEvent(val, e){
        this.selectedTodo = {id: null}
        if (e.target) e.target.blur()
      },
      resetMindmap() {
        http
          .get(`/msuite/${this.currentMindMap.unique_key}/reset_mindmap.json`)
          .then((res) => {
            this.currentMindMap.nodes = []
          })
          .catch((err) => {
            console.log(err)
          })
      },
      disabledStartDate(date) {
        if(this.todo.duedate !== null) return date < new Date() || date > new Date(this.todo.duedate)
        else return date < new Date()
      },
    },
    computed: {
      sortedTodos() {
        if(this.completedTasks){
          return this.myTodos
            .sort((a,b) => {
              if (a.duedate > b.duedate) { return  1 }
              if (b.duedate > a.duedate) { return -1 }
              return 0
            })
            .filter(task => (!task.is_disabled) ? task : '')
        } else {
          return this.myTodos
            .sort((a,b) => {
              if (a.duedate > b.duedate) { return  1 }
              if (b.duedate > a.duedate) { return -1 }
              return 0
            })
        }
      }
    },
    mounted() {
      if (this.$route.params.key) {
        this.getMindmap(this.$route.params.key)
        this.todos = this.currentMindMap.nodes
        this.renderTodos()
      }
    },
  }
</script>
<style scoped>
  @import "./todo_style.css";
</style>
