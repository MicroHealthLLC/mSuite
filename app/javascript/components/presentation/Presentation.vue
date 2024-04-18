<template>
  <div>
    <div id="toolbar">
      <div class="presentation-buttons d-flex w-50 justify-content-around my-2">
        <b-button class="d-flex align-items-center pr-4" @click="addText">
          <i class="far pointer fa-text p-2" /> Text
        </b-button>
        <b-button class="d-flex align-items-center pr-4" @click="addImage()">
          <i class="far pointer fa-image p-2" /> Image
        </b-button>
        <b-button class="d-flex align-items-center pr-4" @click="addVideo()">
          <i class="far pointer fa-film p-2" /> Video
        </b-button>
        <b-button
          class="d-flex align-items-center pr-4"
          @click="openColorModal"
        >
          <i class="far pointer fa-droplet p-2" /> Background
        </b-button>
      </div>
    </div>
    <b-row class="d-flex ml-2 w-100 mh-100">
      <b-col cols="2" id="presentation-slides-select">
        <b-col
          v-for="(slide, index) in slides"
          cols="10"
          :id="`slide-${slide.id}`"
          class="slide-mini mx-auto my-4 pointer"
          @mouseover="slideHover(slide.id)"
          @mouseleave="slideLeave"
          @click="selectSlide(slide)"
          :class="{ 'selected-slide': selectedSlide.id === slide.id }"
          :key="slide.id"
          :style="{ 'background-color': slide?.line_color ?? 'white' }"
        >
          <span class="d-flex justify-content-center align-items-center h-100">
            Slide {{ index + 1 }}
          </span>
          <b-button
            v-if="slide.id === hoveredSlide"
            variant="success"
            class="new-slide"
            @click="addNewSlide(slide.position + 1)"
          >
            <i class="far fa-plus" />
          </b-button>
          <b-button
            v-if="slide.id === hoveredSlide"
            variant="danger"
            class="delete-slide"
            @click="deleteSlide(slide)"
          >
            <i class="far fa-xmark" />
          </b-button>
        </b-col>
      </b-col>
      <!-- <b-col
        v-if="selectedSlide.presentation_html"
        v-html="selectedSlide.presentation_html"
        cols="10"
        class="presentation-slides"
      /> -->
      <b-col cols="10" class="presentation-slides">
        <div
          id="slide-picked"
          class="m-5 border border-dark overflow-auto h-75"
          ref="slide-picked"
          :style="{
            'background-color': selectedSlide?.line_color ?? 'white',
            'max-height': '756px',
          }"
        >
          <div
            v-for="component in htmlComponents"
            :style="component?.style ?? ''"
            :class="component?.class ?? ''"
            :id="component?.id"
            :data-x="component?.dataX"
            :data-y="component?.dataY"
            @mouseover="componentHover(component)"
            @mouseleave="componentLeave"
          >
            <div class="h-100 w-100" v-html="component?.html"></div>
            <b-button
              v-if="component && component?.id === hoveredComponent?.id"
              variant="danger"
              class="delete-slide rounded-circle"
              @click="deleteSlideComponent(component)"
            >
              <i class="far fa-xmark" />
            </b-button>
            <b-button
              v-if="
                component &&
                component?.id === hoveredComponent?.id &&
                component.type === 'video'
              "
              variant="secondary"
              class="drag-video rounded-circle"
            >
              <i class="far fa-up-down-left-right" />
            </b-button>
          </div>
        </div>
      </b-col>
    </b-row>
    <div v-if="colorPicker">
      <div class="card p-0 border-none color-picker-placement">
        <div class="card-body p-0">
          <sketch-picker @input="beforeUpdateColor" v-model="colorPicked" />
        </div>
        <div class="card-button d-flex">
          <button class="btn btn-success w-50 border-none" @click="updateColor">
            Update
          </button>
          <button
            class="btn btn-info w-50 border-none"
            @click="closePickerModal"
          >
            Cancel
          </button>
        </div>
      </div>
    </div>
    <div ref="image-add-modal">
      <sweet-modal ref="image-modal" title="Add Image" @close="closeImageModal">
        <h4>URL</h4>
        <b-row class="align-items-center">
          <b-col cols="10">
            <input type="text" class="w-100 p-1" v-model="imageUrl" />
          </b-col>
          <b-col cols="2">
            <b-button @click="showPreview"> Browse </b-button>
          </b-col>
        </b-row>
        <div v-if="previewImage">
          <h4>Preview</h4>
          <div class="w-100 border">
            <img :src="imageUrl" ref="image-preview" class="h-100 w-100" />
          </div>
          <b-row class="justify-content-end mt-3">
            <b-button @click="attachImage()"> Attach </b-button>
          </b-row>
        </div>
      </sweet-modal>
    </div>
    <div ref="video-add-modal">
      <sweet-modal ref="video-modal" title="Add Video" @close="closeVideoModal">
        <h4>URL</h4>
        <b-row class="align-items-center">
          <b-col cols="10">
            <input type="text" class="w-100 p-1" v-model="videoUrl" />
          </b-col>
          <b-col cols="2">
            <b-button @click="showVideoPreview"> Browse </b-button>
          </b-col>
        </b-row>
        <div v-if="previewVideoSrc">
          <h4>Preview</h4>
          <div class="w-100 border">
            <iframe
              ref="video-preview"
              :src="previewVideoSrc"
              width="100%"
              height="100%"
              controls
            />
          </div>
          <b-row class="justify-content-end mt-3">
            <b-button @click="attachVideo()"> Attach </b-button>
          </b-row>
        </div>
      </sweet-modal>
    </div>
  </div>
</template>
<script>
import http from "../../common/http";
import TemporaryUser from "../../mixins/temporary_user.js";
import ColorPalette from "../../common/modals/color_palette_modal";
import History from "../../mixins/history.js";
import Common from "../../mixins/common.js";
import interact from "interactjs";
import { uuid } from "vue-uuid";

export default {
  name: "presentation",
  mixins: [Common, TemporaryUser, History],
  props: {
    undoMap: Function,
    redoMap: Function,
  },
  components: {
    ColorPalette,
  },
  data() {
    return {
      slides: [],
      selectedSlide: {},
      hoveredSlide: 0,
      hoveredComponent: null,
      currentMindMap: this.$store.getters.getMsuite,
      colorPicker: false,
      colorPicked: "#FFFFFF",
      imageUrl: "",
      videoUrl: "",
      previewImage: false,
      previewVideoSrc: false,
      selectedSlideJson: {},
    };
  },
  computed: {
    htmlComponents() {
      return this.selectedSlideJson?.components ?? [];
    },
  },
  channels: {
    WebNotificationsChannel: {
      async received(data) {
        if (
          data.message === "Mindmap Deleted" &&
          this.currentMindMap.id === data.mindmap.id
        ) {
          window.open("/", "_self");
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
          this.$store.dispatch("setTemporaryUser", data.content.userEdit);
          this.$store.dispatch("setUserList", data.content.userEdit);
        } else if (
          data.message === "Reset mindmap" &&
          this.currentMindMap.id === data.mindmap.id
        ) {
          this.$store.commit("setMSuite", data.mindmap);
          this.currentMindMap = data.mindmap;
          this.undoNodes = [];
          this.redoNodes = [];
          this.slides = [];
        } else {
          await this.getMindmap();
          this.selectedSlide = this.slides.find(
            (slide) => slide.id === this.selectedSlide.id
          );
          this.selectedSlideJson = JSON.parse(
            this.selectedSlide.presentation_html
          );
        }
      },
    },
  },
  mounted: async function () {
    this.subscribeCable(this.currentMindMap.id);
    await this.getMindmap();
    if (!this.slides || this.slides?.length < 1) {
      this.addNewSlide();
    } else {
      this.selectedSlide = this.slides[0];
      this.selectedSlideJson = JSON.parse(this.selectedSlide.presentation_html);
    }
    this.slidesLoaded = true;
    this.undoMap(this.undoObj);
    this.redoMap(this.redoObj);
    this.$store.dispatch("setExportId", "slide-exp");
    this.imageDrag();
    this.videoDrag();
  },
  methods: {
    getMindmap: async function () {
      await this.$store.dispatch("getMSuite");
      this.currentMindMap = this.$store.getters.getMsuite;
      this.slides = this.currentMindMap.nodes;
    },

    ////////      SLIDE FUNCTIONALITY          ///////
    slideHover(id) {
      this.hoveredSlide = id;
    },
    slideLeave() {
      this.hoveredSlide = 0;
    },
    selectSlide(slide) {
      this.selectedSlide = slide;
      this.selectedSlideJson =
        JSON.parse(this.selectedSlide.presentation_html) || {};
    },

    addNewSlide(position = 0) {
      let data = {
        node: {
          mindmap_id: this.currentMindMap.id,
          position,
        },
      };
      let _this = this;
      http
        .post("/nodes.json", data)
        .then(async (res) => {
          await _this.getMindmap();
          _this.selectedSlide = res.data.node;
          _this.selectedSlideJson = {};
        })
        .catch((err) => {});
    },
    deleteSlide(slide) {
      if (this.slides.length === 1) {
        return;
      }
      let data = {
        node: {
          id: slide.id,
        },
      };
      let _this = this;
      http
        .delete(`/nodes/${slide.id}`, data)
        .then(async (res) => {
          if (_this.selectedSlide.id === slide.id) {
            _this.selectedSlide = {};
            _this.selectedSlideJson = {};
          }
        })
        .catch();
    },
    openColorModal() {
      this.colorPicker = true;
    },
    closePickerModal() {
      this.colorPicker = false;
    },
    beforeUpdateColor() {
      const element =
        this.$refs["slide-picked"] || document.getElementById("slide-picked");
      element.style["backgroundColor"] = this.colorPicked.hex;
      document.getElementById(`slide-${this.selectedSlide.id}`).style[
        "backgroundColor"
      ] = this.colorPicked.hex;
    },
    updateColor() {
      const element =
        this.$refs["slide-picked"] || document.getElementById("slide-picked");
      this.selectedSlide.line_color = element.style["backgroundColor"];
      let data = {
        node: {
          id: this.selectedSlide.id,
          line_color: this.selectedSlide.line_color,
        },
      };

      let _this = this;
      http
        .patch(`/nodes/${_this.selectedSlide.id}`, data)
        .then((res) => {})
        .catch()
        .finally(() => {
          _this.closePickerModal();
        });
    },

    ///////////////     SLIDE COMPONENT FUNCTIONALITY     /////////////////////

    updateSlideImageData() {
      let data = {
        node: {
          id: this.selectedSlide.id,
          presentation_html: JSON.stringify(this.selectedSlideJson),
        },
      };

      let _this = this;
      http
        .patch(`/nodes/${_this.selectedSlide.id}`, data)
        .then((res) => {})
        .catch();
    },
    addImage() {
      this.$refs["image-modal"].open();
    },
    showPreview() {
      this.previewImage = true;
    },
    closeImageModal() {
      this.imageUrl = "";
      this.previewImage = false;
    },
    attachImage() {
      let components = this.selectedSlideJson?.components || [];
      components.push({
        id: uuid.v1(),
        type: "image",
        style: "height: 25%; width: 25%; position: absolute;",
        class: "draggable-image border",
        dataX: 0,
        dataY: 0,
        html: this.$refs["image-preview"].outerHTML,
      });
      this.selectedSlideJson = { ...this.selectedSlideJson, components };
      this.slides[
        this.slides.findIndex((slide) => slide.id === this.selectedSlide.id)
      ] = this.selectedSlide;
      this.updateSlideImageData();
      this.$refs["image-modal"].close();
    },
    addVideo() {
      this.$refs["video-modal"].open();
    },
    closeVideoModal() {
      this.videoUrl = "";
      this.previewImage = false;
      this.previewVideoSrc = "";
    },
    showVideoPreview() {
      // Check if the video URL is from YouTube
      const youtubeMatch = this.videoUrl.match(
        /(?:https?:\/\/)?(?:www\.)?youtube\.com\/(?:watch\?v=)?([^&\s]+)/
      );

      if (youtubeMatch) {
        const videoId = youtubeMatch[1];
        this.previewVideoSrc = `https://www.youtube.com/embed/${videoId}`;
      } else if (this.videoUrl.endsWith(".webm")) {
        this.previewVideoSrc = this.videoUrl;
      } else {
        console.error("Unsupported video URL or format");
      }
    },
    attachVideo() {
      // const element =
      //   this.$refs["slide-picked"] || document.getElementById("slide-picked");
      // element.insertAdjacentHTML(
      //   "afterbegin",
      //   `<div class="draggable-image border" style="height: 25%; width: 25%;">${this.$refs["video-preview"].outerHTML}<div>`
      // );

      let components = this.selectedSlideJson?.components || [];
      components.push({
        id: uuid.v1(),
        type: "video",
        style: "height: 25%; width: 25%; position: absolute;",
        class: "draggable-image border",
        dataX: 0,
        dataY: 0,
        html: this.$refs["video-preview"].outerHTML,
      });

      this.selectedSlideJson = { ...this.selectedSlideJson, components };
      this.slides[
        this.slides.findIndex((slide) => slide.id === this.selectedSlide.id)
      ] = this.selectedSlide;
      this.updateSlideImageData();
      this.$refs["video-modal"].close();
    },
    dragMoveListener(event) {
      var target = event.target,
        // keep the dragged position in the data-x/data-y attributes
        x = (parseFloat(target.getAttribute("data-x")) || 0) + event.dx,
        y = (parseFloat(target.getAttribute("data-y")) || 0) + event.dy;

      // translate the element
      target.style.webkitTransform = target.style.transform =
        "translate(" + x + "px, " + y + "px)";

      // update the posiion attributes
      target.setAttribute("data-x", x);
      target.setAttribute("data-y", y);
    },
    dragVideoMoveListener(event) {
      var target = event.target.parentElement,
        // keep the dragged position in the data-x/data-y attributes
        x = (parseFloat(target.getAttribute("data-x")) || 0) + event.dx,
        y = (parseFloat(target.getAttribute("data-y")) || 0) + event.dy;

      // translate the element
      target.style.webkitTransform = target.style.transform =
        "translate(" + x + "px, " + y + "px)";

      // update the posiion attributes
      target.setAttribute("data-x", x);
      target.setAttribute("data-y", y);
    },
    imageMovementUpdate(eventTarget) {
      const target = eventTarget;
      this.selectedSlideJson.components = this.selectedSlideJson.components.map(
        (cmp) => {
          if (cmp.id === target.id) {
            return {
              ...cmp,
              dataX: target.getAttribute("data-x"),
              dataY: target.getAttribute("data-y"),
              style: target.style.cssText,
            };
          } else {
            return cmp;
          }
        }
      );

      this.slides[
        this.slides.findIndex((slide) => slide.id === this.selectedSlide.id)
      ] = this.selectedSlide;
      this.updateSlideImageData();
    },
    componentHover(component) {
      this.hoveredComponent = component;
    },
    componentLeave() {
      this.hoveredComponent = null;
    },
    deleteSlideComponent(component) {
      this.selectedSlideJson.components =
        this.selectedSlideJson.components.filter(
          (cmp) => cmp.id !== component.id
        );
      this.updateSlideImageData();
    },
    imageDrag() {
      let _this = this;
      interact(".draggable-image")
        .draggable({
          onmove: this.dragMoveListener,
          onend: (event) => {
            _this.imageMovementUpdate(event.target);
          },
        })
        .resizable({
          preserveAspectRatio: false,
          edges: { left: true, right: true, bottom: true, top: true },
          onend: (event) => {
            _this.imageMovementUpdate(event.target);
          },
        })
        .on("resizemove", function (event) {
          var target = event.target,
            x = parseFloat(target.getAttribute("data-x")) || 0,
            y = parseFloat(target.getAttribute("data-y")) || 0;

          // update the element's style
          target.style.width = event.rect.width + "px";
          target.style.height = event.rect.height + "px";

          // translate when resizing from top or left edges
          x += event.deltaRect.left;
          y += event.deltaRect.top;

          target.style.webkitTransform = target.style.transform =
            "translate(" + x + "px," + y + "px)";

          target.setAttribute("data-x", x);
          target.setAttribute("data-y", y);
        });
    },
    videoDrag() {
      let _this = this;
      interact(".drag-video").draggable({
        onmove: this.dragVideoMoveListener,
        onend: (event) => {
          _this.imageMovementUpdate(event.target.parentElement);
        },
      });
    },
    addText() {
      let components = this.selectedSlideJson?.components || [];
      components.push({
        id: uuid.v1(),
        type: "text",
        style: "height: 25%; width: 25%; position: absolute;",
        class: "draggable-image border",
        dataX: 0,
        dataY: 0,
        html: '<div id="text-editor"> <span> Add New Text </span> </div>',
      });

      this.selectedSlideJson = { ...this.selectedSlideJson, components };
      this.slides[
        this.slides.findIndex((slide) => slide.id === this.selectedSlide.id)
      ] = this.selectedSlide;
      this.updateSlideImageData();
    },
  },
};
</script>
<style lang="scss" scoped>
@import "./style/styles.scss";
</style>
