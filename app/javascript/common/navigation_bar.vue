<template>
  <div class="buttons_area">
    <div class="buttons_container mx-2">
      <span class="flex">
        <a
          href="javascript:;"
          role="button"
          class="navbar-brand"
          @click.stop="goHome"
        >
          <img src="/assets/microhealthllc.png"/>
        </a>
        <a
          href="javascript:;"
          role="button"
          class="fa-icon d-flex text-info pointer edit_delete_btn mr-3 center_flex"
          @click.stop="openPrivacy"
        >
          <i class="fas fa-shield-alt icons d-flex center_flex"></i>
          <span class="fa-icon-text">Make Private</span>
        </a>
      </span>
      <span v-show="!editable" v-if="navigationTitle.includes(currentMindMap.mm_type)" @click="makeEditable" class="w-25 mt-1 pt-2 pointer" data-toggle="tooltip" :title="mSuiteTitle">{{ mSuiteTitle | truncate(30) }}</span>
      <textarea
        v-show="editable"
        v-if="navigationTitle.includes(currentMindMap.mm_type)"
        :rows="1"
        id="mSuiteTitle"
        @keydown.enter.prevent="mSuiteTitleUpdate"
        type="text"
        v-debounce:3000ms="blurEvent"
        v-model="mSuiteName"
        class="border-0 mindmap-title w-25 text-sapphire font-weight-bold align-items-center pt-2 mt-1"
        @blur="mSuiteTitleUpdate"
        placeholder="Enter Mindmap Title"
      >
      </textarea>
      <span v-if="currentMindMap.editable && currentMindMap.mm_type === 'simple'" class="ml_14">
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
          v-if="currentMindMap.editable && currentMindMap.mm_type==='simple'"
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
          @click.prevent.stop="exportToImage"
        >
          <i class="material-icons export_icon icons d-flex center_flex"></i>
        </a>
        <span class="scaling_area" v-if="currentMindMap.mm_type === 'simple' || currentMindMap.mm_type === 'tree_chart'">
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
  </div>
</template>

<script>
  export default{
    name:"NavigationBar",
    props:["scaleFactor","currentMindMap","selectedNode","copiedNode"],
    data() {
      return{
        mSuiteName: this.currentMindMap.name,
        navigationTitle: ['kanban', 'whiteboard'],
        deleteableMSuite: ['simple', 'kanban', 'whiteboard'],
        editable: false
      }
    },
    methods:{
      goHome () {
        this.$emit("goHome")
      },
      openPrivacy () {
        this.$emit("openPrivacy")
      },
      deleteMindmap () {
        this.$emit("deleteMindmap")
      },
      resetMap () {
        this.$emit("resetMap")
      },
      exportToWord () {
        this.$emit("exportToWord")
      },
      exportToImage () {
        this.$emit("exportToImage")
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
      makeEditable () {
        this.editable = true
        setTimeout(() => {
          document.getElementById('mSuiteTitle').focus()
        }, 300)
      },
      mSuiteTitleUpdate () {
        this.editable = false
        this.mSuiteName = this.mSuiteName.trim()
        if(this.mSuiteName) this.$emit("mSuiteTitleUpdate", this.mSuiteName)
        else this.mSuiteName = this.currentMindMap.name
      },
      blurEvent (val, e) {
       if (e.target) e.target.blur();
      },
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
        let reqdString = data.split("").slice(0, num).join("");
        if (reqdString.length < data.length) {
          reqdString = reqdString.concat('.....')
        }
        return reqdString;
      }
    }
  }
</script>

<style>
  @import "../components/mindmaps/styles/mindmap_new.scss";
  @import "./styles/navigation_style.scss";
</style>
