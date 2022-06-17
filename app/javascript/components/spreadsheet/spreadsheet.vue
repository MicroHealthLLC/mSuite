<template>
  <div>
    <navigation-bar
      v-if="isMounted"
      @mSuiteTitleUpdate="mSuiteTitleUpdate"
      @openPrivacy="openPrivacy"
      @deleteMindmap="deleteMap"
      @resetMindmap="resetMindmap"
      :current-mind-map="currentMindMap"
      :defaultDeleteDays="defaultDeleteDays"
      :deleteAfter="deleteAfter"
      :exportId="'spreadsheet'"
      :isEditing="isEditing"
      :saveElement="saveElement"
      ref="spreadSheetNavigation">
    </navigation-bar>
    <div id="spreadSheet" class="overflow-auto">
      <div id="mytable"></div>
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
  </div>
</template>
<script>
  import http from "../../common/http"
  import domtoimage from "dom-to-image-more"
  import DeleteMapModal from '../../common/modals/delete_modal';
  import MakePrivateModal from "../../common/modals/make_private_modal"
  import DeletePasswordModal from '../../common/modals/delete_password_modal';
  import jexcel from 'jspreadsheet-ce'

  export default {
    props: ['currentMindMap'],
    data() {
      return {
        isMounted: false,
        formula: '',
        sheetData: {
          data: [[]],
          style: {},
        },
        isReset: false,
        isEditing: false,
        saveElement: true
      }
    },
    components: {
      DeleteMapModal,
      DeletePasswordModal,
      MakePrivateModal
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


          }
          else {
            this.currentMindMap = data.mindmap
            this.sheetData = JSON.parse(data.mindmap.canvas)
          }
        }
      }
    },
    methods: {
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
      resetMindmap() {
        http
          .get(`/msuite/${this.currentMindMap.unique_key}/reset_mindmap.json`)
          .then((res) => {

          })
          .catch((err) => {
            console.log(err)
          })
      },
      dataChange(){
        this.sheetData.data = this.table.getData()
        let mindmap = { mindmap: { canvas: JSON.stringify(this.sheetData) } }
        let id = this.currentMindMap.unique_key
        if(!this.isReset){
          http.patch(`/msuite/${id}.json`,mindmap)
          this.isEditing = false
          this.saveElement = true
        }
        else this.isReset = false
      },
      editStart(){
        this.isEditing = true
      },
      editEnd(){
        this.sheetData.data = JSON.stringify(this.table.getData())
      },
      changeStyle(){
        setTimeout(()=>{
          this.sheetData.style = this.table.getStyle()
          let mindmap = { mindmap: { canvas: JSON.stringify(this.sheetData) } }
          let id = this.currentMindMap.unique_key
          if(!this.isReset){
            http.patch(`/msuite/${id}.json`,mindmap)
            this.isEditing = false
            this.saveElement = true
          }
          else this.isReset = false
        },500)
      },
    },
    beforeUpdate(){
      let icons = document.querySelectorAll('.jexcel_toolbar i.jexcel_toolbar_item');
      [].forEach.call(icons, function(icon){
        icon.classList.add('mr-3')
      })
      let toolbar = document.querySelectorAll('.jexcel_toolbar')[0]
      toolbar.classList.add('pb-2')
    },
    created() {
      setTimeout(() => this.saveElement = false, 1200)
    },
    updated() {
      setTimeout(() => this.saveElement = false, 1200)
    },
    mounted() {
      if (this.$route.params.key) {
        this.getMindmap(this.$route.params.key)
      }
      if(this.currentMindMap.canvas != null) this.sheetData = JSON.parse(this.currentMindMap.canvas)
      let table = jexcel(document.getElementById('mytable'), {
        data:this.sheetData.data,
        style: this.sheetData.style,
        formula: true,
        tableOverflow: true,
        tableHeight: '78vh',
        minDimensions:[30,30],
        onchange: this.dataChange,
        onchangestyle: this.changeStyle,
        onselection: this.selectionCreated,
        oneditionstart: this.editStart,
        oneditionend: this.editEnd,
        toolbar:[
          {
            type: 'i',
            content: 'undo',
            onclick: function() {
                table.undo();
            }
          },
          {
            type: 'i',
            content: 'redo',
            onclick: function() {
                table.redo();
            }
          },
          {
            type: 'i',
            content: 'save',
            onclick: function () {
                table.download(true);
            }
          },
          {
            type: 'select',
            k: 'font-family',
            v: ['Arial','Verdana']
          },
          {
            type: 'select',
            k: 'font-size',
            v: ['9px','10px','11px','12px','13px','14px','15px','16px','17px','18px','19px','20px','40px','60px']
          },
          {
            type: 'i',
            content: 'format_align_left',
            k: 'text-align',
            v: 'left'
          },
          {
            type:'i',
            content:'format_align_center',
            k:'text-align',
            v:'center'
          },
          {
            type: 'i',
            content: 'format_align_right',
            k: 'text-align',
            v: 'right'
          },
          {
            type: 'i',
            content: 'format_bold',
            k: 'font-weight',
            v: 'bold'
          },
           {
              type: 'color',
              content: 'format_color_text',
              k: 'color'
          },
          {
              type: 'color',
              content: 'format_color_fill',
              k: 'background-color'
          },
        ],
      });
      this.table = table
    },
  }
</script>
<style scoped>
  @import 'https://bossanova.uk/jspreadsheet/v4/jexcel.css';
  @import 'https://jsuites.net/v4/jsuites.css';

  .jexcel_toolbar i.jexcel_toolbar_item {
    margin-right: 2% !important;
  }
</style>
