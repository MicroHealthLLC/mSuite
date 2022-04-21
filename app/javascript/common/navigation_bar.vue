<template>
  <div class="buttons_area">
    <div class="buttons_container p-2">
      <span class="flex">
        <a
          href="javascript:;"
          role="button"
          class="navbar-brand"
          @click.stop="goHome"
        >
          <img src="/assets/microhealthllc.png"/>
        </a>
    
      </span>
      <span v-show="!editable" @click="makeEditable" class="my-1 py-1 pointer text-sapphire text-wrapper" data-toggle="tooltip" :title="mSuiteTitle">{{ mSuiteTitle | truncate(30) }}</span>
      <textarea
        v-show="editable"
        :rows="1"
        id="mSuiteTitle"
        @keydown.enter.prevent="mSuiteTitleUpdate"
        type="text"
        v-debounce:3000ms="blurEvent"
        v-model="mSuiteName"
        class="border-0 mindmap-title w-25 text-sapphire font-weight-bold align-items-center pt-2 mt-1"
        @blur="mSuiteTitleUpdate"
        placeholder="Enter mSuite Map Title"
      >
      </textarea>

      <span v-if="currentMindMap.editable && currentMindMap.mm_type === 'simple'">
        <a
          href="javascript:;"
          role="button"
          :disabled="!selectedNode"
          :class="{button_disabled: !selectedNode}"
          class="d-flex text-info edit_delete_btn mr-3 center_flex"
          @click.stop="deleteSelectedNode"
        >
          <i class="material-icons delete_icon icons d-flex center_flex"></i>
        </a>
        <a
          href="javascript:;"
          role="button"
          :disabled="!selectedNode"
          :class="{button_disabled: !copiedNode}"
          class="fa-icon d-flex text-info edit_delete_btn mr-3 center_flex"
          @click.stop="pasteCopiedNode"
        >
          <i class="fa fa-paste paste_icon icons d-flex center_flex"></i>
          <span class="fa-icon-text">Paste</span>
        </a>
        <a
          href="javascript:;"
          role="button"
          :disabled="!selectedNode"
          :class="{button_disabled: !selectedNode}"
          class="fa-icon d-flex text-info edit_delete_btn mr-3 center_flex"
          @click.stop="cutSelectedNode"
        >
          <i class="fa fa-cut cut_icon icons d-flex center_flex"></i>
          <span class="fa-icon-text">Cut</span>
        </a>
        <a
          href="javascript:;"
          role="button"
          :disabled="!selectedNode"
          :class="{button_disabled: !selectedNode}"
          class="d-flex text-info edit_delete_btn mr-3 center_flex"
          @click.stop="copySelectedNode"
        >
          <i class="material-icons copy_icon icons d-flex center_flex"></i>
        </a>
      </span>

      <span>
        <a
          v-if="isDeleteMindMap"
          href="javascript:;"
          role="button"
          class="fa-icon d-flex text-info pointer edit_delete_btn mr-3 center_flex"
          @click.prevent="deleteMindmap"
        >
          <i class="fas fa-trash-alt icons d-flex center_flex"></i>
          <span class="fa-icon-text">Delete Map</span>
        </a>
        <a
          href="javascript:;"
          role="button"
          class="d-flex text-info edit_delete_btn mr-3 center_flex"
          @click.stop="resetMap"
        >
          <i class="material-icons restore_icon icons d-flex center_flex"></i>
        </a>
        <a
          v-if="currentMindMap.mm_type==='simple'"
          ref="exportWordBtn"
          role="button"
          class="fa-icon d-flex text-info pointer edit_delete_btn mr-3 center_flex"
          @click.stop="exportToWord"
        >
          <i class="fas fa-file-word icons d-flex center_flex"></i>
          <span class="fa-icon-text">Export Word</span>
        </a>
        <a
          ref="exportBtn"
          role="button"
          href="javascript:;"
          class="d-flex text-info pointer edit_delete_btn mr-3 center_flex"
          @click.prevent.stop="$refs['exportOption'].open()"
        >
          <i class="material-icons export_icon icons d-flex center_flex"></i>
            <!-- <font-awesome-icon icon="fa-solid fa-file-export d-flex center_flex" /> -->
        </a>
        <a
          role="button"
          href="javascript:;"
          class="d-flex text-info pointer edit_delete_btn mr-3 center_flex"
          @click.prevent.stop="saveMSuite"
        >
          <i class="material-icons save_btn icons d-flex center_flex"></i>
        </a>
        <span class="scaling_area" v-if="currentMindMap.mm_type === 'simple' || currentMindMap.mm_type === 'tree_chart' || currentMindMap.mm_type === 'flowmap'">
          <a
            v-if="scaleFactor != 1"
            href="javascript:;"
            role="button"
            class="fa-icon zoom_btn text-info edit_delete_btn center_flex mr-3"
            @click.prevent="resetZoomScale"
          >
            <i class="fas fa-history icons d-flex center_flex"></i>
            <span class="fa-icon-text">100%</span>
          </a>
          <a
            href="javascript:;"
            role="button"
            class="zoom_btn text-info edit_delete_btn center_flex mr-3"
            @click.prevent="zoomInScale"
          >
            <i class="material-icons zoom_in_icon icons d-flex center_flex"></i>
          </a>
          <a
            href="javascript:;"
            role="button"
            class="zoom_btn text-info edit_delete_btn mr-3 center_flex"
            @click.prevent="zoomOutScale"
          >
            <i class="material-icons zoom_out_icon icons d-flex center_flex"></i>
          </a>
        </span>
      </span>
    </div>
    <confirm-save-key-modal @openPrivacy="openPrivacy" @deleteMindmap="deleteMindmap" ref="confirm-save-key-modal" :current-mind-map="currentMindMap" :isSaveMSuite="isSaveMSuite" :defaultDeleteDays="defaultDeleteDays" :deleteAfter="deleteAfter"></confirm-save-key-modal>
    <sweet-modal ref="exportOption" class="of_v" icon="info" title="Export Format">
      Kindly Choose the Format of Export
      <button slot="button" @click="exportImage(1)" class="btn btn-warning float-left mr-2">Export to Image</button>
      <button slot="button" @click="exportImage(2)" class="btn btn-info float-left">Export to Pdf</button>
      <button slot="button" @click="$refs['exportOption'].close()" class="btn btn-secondary">Cancel</button>
    </sweet-modal>
    <reset-map-modal
      ref="reset-map-modal"
      @reset-mindmap="resetMindmap"
    ></reset-map-modal>
  </div>
</template>

<script>
  import ConfirmSaveKeyModal from "./modals/confirm_save_key_modal"
  import { jsPDF } from "jspdf";
  import html2canvas from "html2canvas"
  import domtoimage from "dom-to-image-more"
  import http from "./http"
  import ResetMapModal from '../components/mindmaps/modals/reset_map_modal'

  export default{
    name:"NavigationBar",
    props:["scaleFactor", "currentMindMap", "selectedNode", "copiedNode", "exportId", "defaultDeleteDays","deleteAfter"],
    data() {
      return{
        mSuiteName: this.currentMindMap.title,
        deleteableMSuite: ['simple', 'kanban', 'whiteboard'],
        editable: false,
        isSaveMSuite: false
      }
    },
    components:{
      ConfirmSaveKeyModal,
      ResetMapModal
    },
    computed: {
      isDeleteMindMap () {
        return (this.deleteableMSuite.includes(this.currentMindMap.mm_type))
      },
      mSuiteTitle () {
        return this.mSuiteName
      }
    },
    filters: {
      truncate: function(data,num){
        if(data === undefined) return
        let reqdString = data.split("").slice(0, num).join("");
        if (reqdString.length < data.length) {
          reqdString = reqdString.concat('.....')
        }
        return reqdString;
      }
    },
    methods:{
      putMSuite (value) {
        let _this = this
        http.patch(`/msuite/${ this.currentMindMap.unique_key }.json`,{ mindmap: { title: value }})
        .then((res) => {
          _this.currentMindMap = res.data.mindmap
          _this.mSuiteName = res.data.mindmap.title
          _this.defaultDeleteDays = res.data.defaultDeleteDays
          _this.deleteAfter = res.data.deleteAfter
        })
      },
      saveMSuite () {
        this.isSaveMSuite = true
        this.$refs['confirm-save-key-modal'].$refs['confirmSaveKeyModal'].open()
      },
      goHome () {
        this.isSaveMSuite = false
        this.$refs['confirm-save-key-modal'].$refs['confirmSaveKeyModal'].open()
      },
      openPrivacy () {
        this.$emit("openPrivacy", this.isSaveMSuite)
      },
      deleteMindmap () {
        this.$emit("deleteMindmap")
      },
      resetMindmap () {
        this.$emit("resetMindmap")
      },
      exportToWord () {
        this.$emit("exportToWord")
      },
      resetZoomScale () {
        this.$emit("resetZoomScale")
      },
      zoomInScale () {
        this.$emit("zoomInScale")
      },
      zoomOutScale () {
        this.$emit("zoomOutScale")
      },
      copySelectedNode () {
        this.$emit("copySelectedNode")
      },
      deleteSelectedNode () {
        this.$emit("deleteSelectedNode")
      },
      pasteCopiedNode () {
        this.$emit("pasteCopiedNode")
      },
      cutSelectedNode () {
        this.$emit("cutSelectedNode")
      },
      resetMap(){
        this.$refs['reset-map-modal'].$refs['resetMapModal'].open()
      },
      makeEditable () {
        this.editable = true
        setTimeout(() => {
          document.getElementById('mSuiteTitle').focus()
        }, 300)
      },
      mSuiteTitleUpdate () {
        this.editable = false
        this.mSuiteName = this.mSuiteName.trim()
        if(this.mSuiteName) this.putMSuite(this.mSuiteName)
        else this.mSuiteName = this.currentMindMap.title
      },
      blurEvent (val, e) {
        if (e.target) {
          e.target.blur()
        };
      },
      exportImage(option) {
        if (this.currentMindMap.mm_type === 'simple')
        {
          this.$emit('exportToImage',option)
        }
        else {
          const _this = this
          let elm = document.getElementById(this.exportId)
          if (this.currentMindMap.mm_type === 'kanban')
          {
            let inner_list = document.getElementsByClassName('drag-inner-list')
            inner_list.forEach(i=>i.classList.add('mh-100'))
          }
          elm.style.transform = "scale(1)"
          let map_key = _this.currentMindMap.unique_key || "image"
          domtoimage.toPng(elm, {height: elm.scrollHeight, width: elm.scrollWidth})
          .then((url) => {
            if (option === 1){
              let downloadLink = document.createElement("a")
              document.body.appendChild(downloadLink)
              downloadLink.href = url
              downloadLink.download = map_key + ".png"
              downloadLink.click()
              document.body.removeChild(downloadLink)
            }
            else {
              var pdf = new jsPDF('l', 'px',[elm.scrollWidth,elm.scrollHeight],true);
              var width = pdf.internal.pageSize.getWidth();
              var height = pdf.internal.pageSize.getHeight();
              html2canvas(elm).then(canvas => {
                pdf.addImage(url, 'JPEG', 0, 0, width, height);
                pdf.save(map_key + '.pdf');
              });
            }
            _this.currentMindMap.mm_type === 'kanban' ? document.getElementsByClassName('drag-inner-list').forEach(i => i.classList.remove('mh-100')) : false
            _this.$refs['exportOption'].close()
          })
          .catch((err) => {
            console.error('oops, something went wrong!', err)
          })
        }
      },
    },
    watch: {
      currentMindMap: {
        handler(value) {
          this.mSuiteName = value.title
        }, deep: true
      }
    }
  }
</script>

<style>
  @import "../components/mindmaps/styles/mindmap_new.scss";
</style>
