<template>
  <div>
    <navigation-bar
      v-if="isMounted"
      @mSuiteTitleUpdate="mSuiteTitleUpdate"
      @openPrivacy="openPrivacy"
      @graphOrientationVertical="graphOrientationVertical"
      @graphOrientationHorizontal="graphOrientationHorizontal"
      @deleteMindmap="deleteMap"
      :current-mind-map="currentMindMap"
      :defaultDeleteDays="defaultDeleteDays"
      :deleteAfter="deleteAfter"
      :exportId="'mermaid'"
      ref="flowmapNavigation">
    </navigation-bar>
    <div class="row">
      <div class="col-1 px-0 sidebar">
        <div class="rounded-0 pl-1 btn whiteboard-btns border pointer d-flex px-0" @click="linkType = '-->'" :class="linkType === '-->' ? 'active':''">
          <span class="material-icons">
            arrow_right_alt
          </span>
          <span class="ml-1">Links To</span>
        </div>
        <div class="rounded-0 pl-1 btn whiteboard-btns border pointer d-flex px-0" @click="linkType = '---'" :class="linkType === '---' ? 'active':''">
          <span class="material-icons">
            horizontal_rule
          </span>
          <span class="ml-1">Sub Child</span>
        </div>
        <div class="rounded-0 pl-1 btn whiteboard-btns border pointer d-flex px-0" @click="linkType = '-.-'" :class="linkType === '-.-' ? 'active':''">
          <span class="material-icons">
            more_horiz
          </span>
          <span class="ml-1">Dotted</span>
        </div>
        <div class="rounded-0 pl-1 btn whiteboard-btns border pointer d-flex px-0" @click="linkType = '-.->'" :class="linkType === '-.->' ? 'active':''">
          <span class="dottedArrow">
            &#8674;
          </span>
          <span class="ml-3 mt-1">Dotted Link</span>
        </div>
        <div class="rounded-0 pl-1 btn btn-danger border pointer d-flex px-0" @click="isDeleteAble = !isDeleteAble" :class = "isDeleteAble ? 'active':''">
          <span class="material-icons">
            delete_forever
          </span>
          <span class="ml-1">DELETE</span>
        </div>
      </div>
        <div id="mermaid" class="mermaid flowmap border mx-0 mt-0 d-flex justify-content-center">
            {{computedDiagramData}}
        </div>
    </div>
    <make-private-modal ref="make-private-modal" @password-apply="passwordProtect" @password_mismatched="$refs['passwordMismatched'].open()" :password="currentMindMap.password"></make-private-modal>
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
    <sweet-modal ref="errorNodeModal" class="of_v" icon="error" title="Node Title Error">
      Nodes Title Cannot Be Empty
    </sweet-modal>
    <sweet-modal ref="deleteNodeConfirm" class="of_v" icon="warning" title="Delete node">
      Do you want to delete this node? All of the child Nodes will also be Deleted
      <button slot="button" @click="this.deleteNode" class="btn btn-warning mr-2">Delete</button>
      <button slot="button" @click="$refs['deleteNodeConfirm'].close()" class="btn btn-secondary">Cancel</button>
    </sweet-modal>
  </div>
</template>
<script>
  import http from "../../common/http"
  import domtoimage from "dom-to-image-more"
  import DeleteMapModal from '../../common/modals/delete_modal';
  import MakePrivateModal from "../../common/modals/make_private_modal"
  import DeletePasswordModal from '../../common/modals/delete_password_modal';
  import mermaid from 'mermaid'

  export default {
    props: ['currentMindMap'],
    data() {
      return {
        isMounted: false,
        image: "",
        defaultDeleteDays: '',
        colorPicker: "#000000",
        currentMindMap: {},
        initialImage: [],
        keyUpTimeOut: null,
        deleteAfter: '',
        oldTitle: '',
        nodeId: null,
        startnode: '',
        endnode: 'Title_Here',
        diagramData: '',
        graphNodes: [],
        parent_node: false,
        submitChild: false,
        child_node: { id: '', title: '', parent_node: '',parent: '', mindmap_id: '', link_type: ''},
        previous_node: {},
        node_title:'',
        nodes: [],
        node:{},
        newTitle: '',
        linkType: '-->',
        graphOrientation: 'graph LR;',
        isDeleteAble: false,
        duplicate: '',
        duplicateCounter: 0,
        elementLength: 0,
      }
    },
    components: {
      DeleteMapModal,
      DeletePasswordModal,
      MakePrivateModal,
      mermaid
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
          } else {
            http
            .get(`/msuite/${this.$route.params.key}.json`)
            .then((res) => {
              this.nodes = res.data.mindmap.nodes
              this.createNode()
            })
          }
        }
      }
    },
    computed: {
      computedDiagramData() {
        return this.diagramData
      }
    },
    methods: {
      getMindmap(id) {
        http
        .get(`/msuite/${id}.json`)
        .then((res) => {
          this.defaultDeleteDays = res.data.defaultDeleteDays
          this.deleteAfter = res.data.deleteAfter
          this.currentMindMap = res.data.mindmap
          this.isMounted = true
          this.$cable.subscribe({ channel:"WebNotificationsChannel", room: this.currentMindMap.id })
        })
      },
      openPrivacy() {
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
        .catch(error => {
          console.log(error)
        })
      },
      passwordProtect(new_password, old_password) {
        http
        .patch(`/msuite/${this.currentMindMap.unique_key}.json`,{mindmap:{password: new_password, old_password: old_password}})
        .then(res => {
          if (res.data.mindmap) {
            this.currentMindMap.password = res.data.mindmap.password
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
      postNode: async function (obj) {
        let data = {
          node: {title: obj.title, parent_node: obj.parent_node, mindmap_id: obj.mindmap_id, line_color: obj.link_type}
        }
        http.post(`/nodes.json`, data).then((res) => {
          this.submitChild = false
          this.createNode()
        }).catch(err => {
        })
      },
      updateFlowMap: async function (obj) {
        let data = {
          name: obj.name,
          mm_type: 'flowmap',
          line_color: obj.line_color
        }
        await http.put(`/msuite/${this.currentMindMap.unique_key}`, data);
        this.parent_node = false
        mermaid.render(undefined, $("#mermaid"));
      },
      updateSelectedNode: async function(obj){
        await http.put(`/nodes/${obj.id}`, obj).then((res) => {
          this.createNode()
        });
        mermaid.render(undefined, $("#mermaid"));
      },
      deleteSelectedNode: async function(obj){
        await http.delete(`/nodes/${obj.id}.json`).then((res) => {
          this.child_node.id = ''
          this.node = null
          this.createNode();
        });
        this.$refs['deleteNodeConfirm'].close()
      },
      setNodeSelected(event){
        let nodeTitle = event.currentTarget.children[0].children[0].children[0].innerText.replace(/\s/g, '_')
        nodeTitle = nodeTitle.split('_').join(' ')
        this.node = this.nodes.find(n => n.title === nodeTitle)
        if(this.node) this.node.title = this.node.title.split('_').join(' ')
        if(this.node && this.node.title != "Title_Here"){
          this.parent_node = (this.node.title == this.currentMindMap.name) ? true : null
          this.child_node.title = (this.node.title != this.currentMindMap.name) ? this.node.label : null
        }else if(nodeTitle == this.currentMindMap.name) {
          this.parent_node = true
          this.submitChild = false
          this.child_node.title = null
        }else if(this.endnode == "Title_Here") {
          this.parent_node = this.currentMindMap.name ? true : null
          this.submitChild = true
        }
      },
      createNode(){
        this.diagramData = this.graphOrientation
        this.startnode = this.currentMindMap.name.replace(/\s/g, '_')
        this.diagramData = this.diagramData.concat(this.startnode + ';\n')
        this.startnode = this.endnode;
        this.nodes.forEach((node, index) => {
          this.diagramData = this.diagramData.concat(node.parent.replace(/[\s]/g, '_') + node.line_color + node.title.replace(/[\s]/g, '_') + ';\n')
        });
        $('#mermaid').html(this.diagramData).removeAttr('data-processed');
        mermaid.init(undefined, $("#mermaid"));
      },
      addNode(eventElement){
        this.duplicateCounter = 0
        this.child_node.link_type = this.linkType
        if (this.parent_node) {
          this.previous_node = this.currentMindMap.name.replace(/\s/g, '_')
          this.child_node.parent_node = null
        } else {
          this.child_node.parent_node = this.node.id
          this.previous_node = this.node.title.replace(/\s/g, '_')
        }
        this.diagramData = this.diagramData.concat(' ' + this.previous_node + this.linkType + this.endnode + ';\n') 
        this.node_title = this.endnode
        this.startnode = this.endnode
        $('#mermaid').html(this.diagramData).removeAttr('data-processed');
        mermaid.init(undefined, $("#mermaid"));
      },
      putData(){
        if (!this.submitChild && this.parent_node) {
          this.currentMindMap.name = this.node_title.replace(/\s/g, '_')
          this.updateFlowMap(this.currentMindMap)
        } else if (this.oldTitle == "Title_Here"){
          if(this.child_node.id != ''){
            alert("Some thing went Wrong, We are really Sorry.")
            this.node_title = ''
            this.child_node.id = ''
            this.submitChild = false
            this.createNode();
          } else {
            this.child_node.title = this.node_title.replace(/[@^\[\];|&\/\\#,+()$~%.'":*?<>{}]/g,'_')
            this.duplicate = this.child_node.title
            if (this.duplicate == this.child_node.title) {
              this.duplicateCounter = this.duplicateCounter + 1
            }
            if (this.duplicateCounter == 1) {
              this.child_node.mindmap_id = this.currentMindMap.id
              this.child_node.link_type = this.linkType
              this.postNode(this.child_node)
            }
          }
        } else {
          this.nodes.forEach((node, index) => {
            if(this.node && this.node.title.replace(/\s/g, '_') === node.title.replace(/\s/g, '_')){
              this.child_node.id = node.id
              this.child_node.mindmap_id = this.currentMindMap.id
              this.child_node.parent_node = node.parent_node
              this.child_node.parent = node.parent
            }
          });
          this.child_node.title = this.node_title.replace(/[@^\[\];|&\/\\#,+()$~%.'":*?<>{}]/g,'_')
          this.updateSelectedNode(this.child_node)
        }
      },
      textEdit(eventElement){
        let _this = this
        var keyUpTimeOut
        eventElement.target.childNodes[1].style.display = "none"
        eventElement.target.childNodes[2].style.display = "none"
        this.oldTitle = eventElement.target.innerText
        if(eventElement.target.innerText == "Title_Here"){
          eventElement.target.innerText = ""
        }
        eventElement.target.contentEditable = true
        eventElement.target.focus();
        eventElement.target.addEventListener('blur',function(){
          if(eventElement.target.innerText == "" || _this.newTitle == ''){
            _this.node_title = ""
            _this.submitChild = false
            _this.createNode()
          }
        })
        eventElement.target.addEventListener('keyup', function(){
          clearTimeout(keyUpTimeOut)
          _this.newTitle = event.target.innerText.split('\n').join('')
          if (event.keyCode === 13 && this.oldTitle != "Title_Here") {
            if (_this.newTitle && _this.newTitle != '') {
              _this.node_title = _this.newTitle
              _this.putData()
            }
            else {
              _this.$refs['errorNodeModal'].open()
              eventElement.target.innerText = _this.oldTitle
            }
          }
          else if (_this.newTitle && _this.newTitle !== _this.oldTitle) {
            keyUpTimeOut = setTimeout(() => {
              _this.node_title = _this.newTitle
              _this.putData()
            }, 2000)
          }
        })
      },
      toggleNode(eventElement){
        this.setNodeSelected(eventElement)
        if(this.isDeleteAble){
          if(this.currentMindMap.name.replace(/\s/g, '_') == this.node.label) this.deleteMap()
          else this.$refs['deleteNodeConfirm'].open()
        }else {
          if(eventElement.target.classList[1] == 'fa-plus'){
            if(!this.submitChild && this.node_title !== "Title_Here") this.addNode(eventElement)
          } else if (eventElement.target.classList[1] == 'fa-times' && !this.submitChild && this.node_title !== "Title_Here") {
            if(!this.submitChild && this.parent_node) this.deleteMap()
            else this.$refs['deleteNodeConfirm'].open()
          }else if(eventElement.target.classList[0] == 'obj-holder') this.textEdit(eventElement)
        }
      },
      deleteNode(eventElement){
        this.deleteSelectedNode(this.node)
      },
      graphOrientationVertical(){
        this.graphOrientation = 'graph TD;'
        this.createNode();
      },
      graphOrientationHorizontal(){
        this.graphOrientation = 'graph LR;'
        this.createNode();
      },
    },
    updated() {
      setTimeout(() => {
        let nodes = document.getElementsByClassName("node default")
        nodes.forEach((element, index) => {
          let foreignObject = element.children[1].children[0].children[0];
          if (foreignObject.clientWidth < 50)
          {
            foreignObject.setAttribute("width", "50px");
            element.children[0].setAttribute("width", "70px");
          }
          element.children[0].setAttribute("height", "52px")
          foreignObject.children[0].style.whiteSpace = 'pre-line'
          foreignObject.children[0].style.display = 'flex'
          foreignObject.children[0].style.wordBreak = 'break-all';
          foreignObject.innerHTML = foreignObject.innerHTML = foreignObject.innerHTML.replace(/(<div)/igm, '<div class="obj-holder"')
          let deleteEl =  document.createElement("span");
          deleteEl.innerHTML =  "<i class='fa fa-times' aria-hidden='true'></i>"
          deleteEl.setAttribute("class", "delete-el");
          let plusEl =  document.createElement("span");
          plusEl.innerHTML = "<i class='fa fa-plus' aria-hidden='true'></i>"
          plusEl.setAttribute("class", "plus-el");
          foreignObject.querySelector(".obj-holder .delete-el") ? null : foreignObject.querySelector(".obj-holder").appendChild(deleteEl);
          foreignObject.querySelector(".obj-holder .plus-el") ? null : foreignObject.querySelector(".obj-holder").appendChild(plusEl);
          element.children[1].addEventListener('click', this.toggleNode)
          foreignObject.style.height = "50px"
          foreignObject.children[0].style.marginTop = "20px"
          if (this.isDeleteAble) { element.children[1].style.cursor = "not-allowed"; } 
          else { element.children[1].children[0].style.cursor = "text"; }
        });
      }, 500)
    },
    mounted() {
      mermaid.initialize({startOnLoad:true});
      if(mermaid){
      this.nodes = this.currentMindMap.nodes
      this.createNode()
      }
      if (this.$route.params.key) {
        this.getMindmap(this.$route.params.key)
        this.isMounted = true
      }
    }
  }
</script>
<style>
  .flowmap{
    width: calc(100vw - 150px);
    height: calc(100vh - 70px);
    margin: 10px auto;
    margin-bottom: 100px;
    overflow: scroll;
  }
  .active{
    background: #eee;
  }
  .node .default {
    width: 110px !important;
  }
  .obj-holder{
    position: relative;
  }
  .delete-el,
  .plus-el{
    position: absolute;
    top: -25px;
  }
  .delete-el{
    right: 0px;
  }
  .plus-el{
    right: 15px;
    color: red;
  }
  .fa-plus{
    color: #3CA556;
    cursor: pointer;
  }
  .fa-times{
    color: #D1727F;
    cursor: pointer;
  }
  .dottedArrow{
    transform: scale(1.8) translate(10%, 10%);
  }
</style>
