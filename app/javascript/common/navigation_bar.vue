<template>
  <div class="buttons_area">
    <div class="buttons_container p-2">
      <span class="flex ml-5">
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
      <span v-if = "currentMindMap.mm_type === 'spreadsheet'" class="mt-3">
        <a
          href="javascript:;"
          role="button"
          class="d-flex text-info pointer mr-3 center_flex"
          v-b-tooltip.hover title="Status"
        >
          <div v-if="isEditing">
            <span>Editing</span>
            <span class="dots-cont" v-if="isEditing">
              <span class="dot dot-1"></span>
              <span class="dot dot-2"></span>
              <span class="dot dot-3"></span>
            </span>
          </div>
          <div v-else v-show="saveElement">
            <span class="save">Saved</span>
          </div>
        </a>
      </span>
      <span>
        <a
          href="javascript:;"
          role="button"
          class="fa-icon d-flex text-info pointer edit_delete_btn mr-3 center_flex"
          @click.prevent="deleteMindmap"
        >
          <i class="fas fa-trash-alt icons d-flex center_flex"></i>
          <span class="fa-icon-text">Delete</span>
        </a>
        <a
          href="javascript:;"
          role="button"
          class="d-flex text-info pointer edit_delete_btn mr-3 center_flex"
          v-b-tooltip.hover title="Comments"
          @click.prevent="openCommentModal"
        >
          <i id="comment" class="fa fa-comment d-flex center_flex"></i>
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
          v-if="currentMindMap.mm_type==='spreadsheet'"
          ref="exportBtn"
          role="button"
          href="javascript:;"
          class="fa-icon zoom_btn text-info edit_delete_btn center_flex mr-3"
          @click.prevent.stop="$refs['exportOptionCsv'].open()"
        >
          <i class="fas fa-file-excel icons d-flex center_flex"></i>
          <span class="fa-icon-text">Export</span>
        </a>
        <a
          role="button"
          href="javascript:;"
          class="d-flex text-info pointer edit_delete_btn mr-3 center_flex"
          @click.prevent.stop="saveMSuite"
          v-b-tooltip.hover :title="currentMindMap.will_delete_at"
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
    <comment-map-modal :mind-map='currentMindMap' ref="comment-box-modal"></comment-map-modal>
    <confirm-save-key-modal @openPrivacy="openPrivacy" @deleteMindmap="deleteMindmap" ref="confirm-save-key-modal" :current-mind-map="currentMindMap" :isSaveMSuite="isSaveMSuite" :defaultDeleteDays="defaultDeleteDays" :deleteAfter="deleteAfter" :expDays="expDays"></confirm-save-key-modal>
    <sweet-modal ref="exportOption" class="of_v" icon="info" title="Export Format">
      Kindly Choose the Format of Export
      <button slot="button" v-if="currentMindMap.mm_type === 'Notepad'" @click="exportImage(1)" class="btn btn-warning float-left mr-2">Export to Document</button>
      <button slot="button" v-else @click="exportImage(1)" class="btn btn-warning float-left mr-2">Export to Image</button>

      <button slot="button" v-if="currentMindMap.mm_type === 'Notepad'" @click="exportImage(2)" class="btn btn-info float-left">Export to rtf</button>
      <button slot="button" v-else @click="exportImage(2)" class="btn btn-info float-left">Export to Pdf</button>
      <button slot="button" @click="$refs['exportOption'].close()" class="btn btn-secondary">Cancel</button>
    </sweet-modal>
    <sweet-modal ref="exportOptionCsv" class="of_v" icon="info" title="Export Format">
      Kindly Choose the Format of Export
      <button slot="button" @click="exportXLS(1)" class="btn btn-warning float-left mr-2">Export to Excel</button>

      <button slot="button" @click="exportXLS(2)" class="btn btn-info float-left">Export to csv</button>
      <button slot="button" @click="$refs['exportOptionCsv'].close()" class="btn btn-secondary">Cancel</button>
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
  import CommentMapModal from "./modals/comment_map_modal"
  export default{
    name:"NavigationBar",
    props:["scaleFactor", "currentMindMap", "selectedNode", "copiedNode", "exportId", "defaultDeleteDays","deleteAfter","isEditing","saveElement", "expDays"],
    data() {
      return{
        mSuiteName: this.currentMindMap.title,
        editable: false,
        isSaveMSuite: false
      }
    },
    components:{
      ConfirmSaveKeyModal,
      ResetMapModal,
      CommentMapModal
    },
    computed: {
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
          _this.expDays = res.data.expDays
          _this.deleteAfter = res.data.deleteAfter
        })
      },
      openCommentModal () {
        this.$refs['comment-box-modal'].$refs['commentBoxModal'].open()
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
      exportXLS (option) {
        this.$emit("exportXLS",option)
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
      resetMap () {
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
        } else if (this.currentMindMap.mm_type === 'Notepad') {
          this.$emit('exportToDocument',option)
        } else {
          const _this = this
          let elm = document.getElementById(this.exportId)
          if (this.currentMindMap.mm_type === 'kanban')
          {
            let inner_list = document.getElementsByClassName('drag-inner-list')
            inner_list.forEach(i=>i.classList.add('mh-100'))
          }
          if (this.currentMindMap.mm_type === 'spreadsheet'){
            elm = document.getElementsByClassName('jexcel_content')[0]
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
      },
    }
  }
</script>

<style>
  @import "../components/mindmaps/styles/mindmap_new.scss";

  .dot {
   width: 3px;
   height: 3px;
   background: #0F6674;
   display: inline-block;
   border-radius: 50%;
   right: 0px;
   bottom: 0px;
   margin: 0px 0.2px;
   position: relative;
   animation: jump 1s infinite;
  }
  .dots-cont:hover > .dot {
   animation: none;
  }
  .dots-cont .dot-1 {
   -webkit-animation-delay: 100ms;
   animation-delay: 100ms;
  }
  .dots-cont .dot-2 {
   -webkit-animation-delay: 200ms;
   animation-delay: 200ms;
  }
  .dots-cont .dot-3 {
   -webkit-animation-delay: 300ms;
   animation-delay: 300ms;
  }
  @keyframes jump {
   0%   {bottom: 0px;}
   20%  {bottom: 5px;}
   40%  {bottom: 0px;}
  }



</style>
