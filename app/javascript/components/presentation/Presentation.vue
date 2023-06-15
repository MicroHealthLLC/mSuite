<template>
  <div>
    <div id="toolbar" class="mx-2">
      <div class="center-margin">
        <i v-b-tooltip.hover title="Add Paragraph" @click="selectedElement ? updateType('p') : addText('p')" class="far pointer fa-text p-2"></i>
        <b-dropdown
          variant="link"
          toggle-class="text-decoration-none text-dark" no-caret >
          <template #button-content>
            <i v-b-tooltip.hover title="Heading" class="fas pointer fa-heading p-2 mb-1"></i>
          </template>
          <div class="d-flex justify-content-center feedback-emoji">
            <div class="px-1">
              <b-dropdown-item @click="selectedElement ? updateType('h1') : addText('h1')">
                <i v-b-tooltip.hover title="Heading H1"  class="pointer fas fa-h1 p-2"></i>
              </b-dropdown-item>
            </div>
            <div class="px-1">
              <b-dropdown-item @click=" selectedElement ? updateType('h2') : addText('h2')">
                <i v-b-tooltip.hover title="Heading H2"  class="fas pointer fa-h2 p-2"></i>
              </b-dropdown-item>
            </div>
            <div class="px-1">
              <b-dropdown-item @click=" selectedElement ? updateType('h3') : addText('h3')">
                <i v-b-tooltip.hover title="Heading H3"  class="fas pointer fa-h3 p-2"></i>
              </b-dropdown-item>
            </div>
            <div class="px-1">
              <b-dropdown-item @click="selectedElement ? updateType('h4') : addText('h4')">
                <i v-b-tooltip.hover title="Heading H4"  class="fas pointer fa-h4 p-2"></i>
              </b-dropdown-item>
            </div>
          </div>
        </b-dropdown>
        <i v-b-tooltip.hover title="Bulleted List" @click="selectedElement ? updateType('ul') : addText('ul')" class="fas fa-list-ul p-2 pointer"></i>
        <i v-b-tooltip.hover title="Numbered List" @click="selectedElement ? updateType('ol') : addText('ol')" class="fas fa-list-ol p-2 pointer"></i>
        <i v-b-tooltip.hover title="Change Color" @click="colorChange()" class="fas fa-eye-dropper p-2 pointer"></i>
        <b-dropdown
          variant="link"
          toggle-class="text-decoration-none text-dark" no-caret >
          <template #button-content>
            <i v-b-tooltip.hover title="Add Shapes" class="fas pointer fa-shapes"></i>
          </template>
          <div class="d-flex justify-content-center feedback-emoji">
            <div class="px-1">
              <b-dropdown-item @click="addShape('square')">
                <i class="fas fa-square"></i>
              </b-dropdown-item>
            </div>
            <div class="px-1">
              <b-dropdown-item @click="addShape('circle')">
                <i class="fas fa-circle"></i>
              </b-dropdown-item>
            </div>
            <div class="px-1">
              <b-dropdown-item @click="addShape('triangle')">
                <i class="fas fa-triangle"></i>
              </b-dropdown-item>
            </div>
          </div>
        </b-dropdown>
        <i v-b-tooltip.hover title="Embed Image" @click="addShape('image')" class="fas fa-image p-2 pointer"></i>
        <i v-b-tooltip.hover title="Embed Video" @click="addShape('video')" class="fas fa-video p-2 pointer"></i>
      </div>
    </div>
    <div class="mt-2 mx-2 d-flex" id="slide-exp">
      <div id="slide-library" class="overflow-auto">
        <div
          v-if="slidesLoaded"
          v-for="(slide, index) in sortedSlides" :key="slide.id"
          @click="selectSlide(index)" class="m-2"
          draggable="true"
          @dragstart="dragSlide($event, index)"
          @dragover.prevent
          @drop="dropSlide($event, index)"
        >
          <div
            :id="`map-canvas-${index}`"
            class="style-canvas position-relative mt-2"
            :class="cSlideIndex == index ? 'border-green' : 'border-dashed'"
            :style="'background: '+ slide.line_color">
            <SlideElement
              v-for="(element, index) in slide.children" :key="element.id"
              :element="element"
              :parent-color="slide.line_color"
              class="position-absolute"
              :style="`
                top: ${element.position_y / 100}vh;
                left: ${element.position_x / 100}vw;
                `">
            </SlideElement>
            <div v-b-tooltip.hover title="Add Slide" v-if="cSlideIndex == index" class="position-absolute add-slide-button">
              <i @click="addDefaultSecSlide(slide)" class="position-relative fas fa-plus bg-success rounded-circle text-white"></i>
            </div>
            <div v-b-tooltip.hover title="Delete Slide" v-if="cSlideIndex == index" class="position-absolute delete-slide-button">
              <i @click="deleteSlide(slide)" :disabled="slides.length === 1" class="position-relative fas fa-times bg-danger rounded-circle text-white px-1"></i>
            </div>
            <span class="position-absolute slide-position">
              <strong class="position-relative pos-text">
                {{ slide.position + 1 }}
              </strong>
            </span>
          </div>
        </div>
      </div>
      <div
        v-if="sortedSlides[cSlideIndex]"
        :id="`slide-editor-${sortedSlides[cSlideIndex].id}`"
        :style="'background: '+ sortedSlides[cSlideIndex].line_color"
        class="element-wrap my-2 mx-3 w-83 h-73"
        @click="selectedElement.element_type !='video' ? selectedElement = null : ''">
        <div v-if="isSlideSelected()">
          <div
            id = 'parent-component'
            v-for="(element, index) in sortedSlides[cSlideIndex].children" :key="element.id"
            :draggable="isDragabble"
            @click.stop="selectedElement = element"
            @dragover.prevent
            @dragend="dragDrop($event, element)"
            >
            <div>
            <component
              :id="`element-${element.id}`"
              :is="element.title"
              :element="element"
              :parent-color="sortedSlides[cSlideIndex].line_color"
              class="position-absolute"
              :videoElement="element.element_type == 'video'"
              :selectedElement="selectedElement"
              :style="`
                top: ${element.position_y}px;
                left: ${element.position_x}px;`"
              @dragStart.passive="dragStart"
              @deleteElement="deleteElement(element)"
              @updateElement="updateElement(element)">
            </component>
            </div>
          </div>
          <div v-if="iconShow" id="imageDisplay" class="position-absolute icons-pos">
              <div id="" class="mx-2">
                <div class="center-margin">
                  <i class="far pointer fa-text p-2"></i>
                  <i class="fas pointer fa-heading p-2"></i>
                  <i class="fas fa-list-ul p-2 pointer"></i>
                  <i class="fas fa-list-ol p-2 pointer"></i>
                  <i class="fas pointer fa-shapes"></i>
                </div>
              </div>
          </div>
        </div>
      </div>
    </div>
    <div v-if="colorSelected">
      <div class="card card-position p-0 border-none mt-5">
        <color-palette
          :selected-node="el"
          :customPallete="customPallete"
          :uniqueColors="uniqueColors"
          :nodes="[]"
          @updateColorNode="updateColorNode"
          @saveNodeColor="saveNodeColor"
          @closeModelPicker="closeModelPicker"
          @updateAllColorNode="updateAllColorNode"
          @updateTreeChartNode="updateSelectedNode"
        ></color-palette>
      </div>
    </div>
  </div>
</template>

<script>
  import TextElement from './elements/TextElement.vue'
  import ShapeElement from './elements/ShapeElement.vue'
  import SlideElement from './elements/SlideElement.vue'
  import TemporaryUser from "../../mixins/temporary_user.js"
  import ColorPalette from '../../common/modals/color_palette_modal'
  import History from "../../mixins/history.js"
  import Common from "../../mixins/common.js"
  import http from "../../common/http"

  export default {
    name: 'presentation',
    data () {
      return {
        slides         : [],
        cSlideIndex    : 0,
        undoNodes      : [],
        redoNodes      : [],
        mapColors      : [],
        uniqueColors   : [],
        colorSelected  : false,
        slidesLoaded   : false,
        selectedElement: null,
        el             : null,
        isDragabble    : false,
        slideSample: {
          label: 'Slide',
        },
      }
    },
    components: {
      TextElement,
      SlideElement,
      ShapeElement,
      ColorPalette
    },
    props: {
      undoMap: Function,
      redoMap: Function
    },
    mixins: [TemporaryUser, Common, History],
    channels: {
      WebNotificationsChannel: {
        async received(data) {
          if (data.message === "Mindmap Deleted" && this.currentMindMap.id === data.mindmap.id)
          {
            window.open('/','_self')
          }
          else if (data.message === "Password Updated" && this.currentMindMap.id === data.mindmap.id) {
            setTimeout(() => {
              location.reload()
            }, 500)
          }
          else if ( data.message === "storage updated" && this.currentMindMap.id == data.content.mindmap_id) {
            this.$store.dispatch('setUserEdit'     , data.content.userEdit)
            this.$store.dispatch('setTemporaryUser', data.content.userEdit)
            this.$store.dispatch('setUserList'     , data.content.userEdit)
          }
          else if (data.message === "Reset mindmap" && this.currentMindMap.id === data.mindmap.id) {
            this.$store.commit('setMSuite', data.mindmap)
            this.currentMindMap = data.mindmap
            this.undoNodes = []
            this.redoNodes = []
            this.slides    = []
            await this.addSlide(null).then(() => {
              this.addDefaultSlide()
            })
            setTimeout(()=>{
              this.selectSlide(0)
            }, 500)
          }
          else {
            this.getMindmap()
          }
        }
      }
    },
    computed: {
      currentMindMap() {
        return this.$store.getters.getMsuite
      },
      sortedSlides() {
        return this.slides.sort((a, b) => a.position - b.position).filter(slide => slide.parent == 'Central Idea')
      },
      iconShow() {
        return !this.sortedSlides[this.cSlideIndex].is_disabled && !this.sortedSlides[this.cSlideIndex].hide_children
      }
    },
    mounted: async function(){
      this.subscribeCable(this.currentMindMap.id)
      await this.getMindmap()
      if (this.slides.length < 1) {
        (async () => {
          await this.addSlide(null).then(() => {
            this.addDefaultSlide()
          })
        })();
      }
      this.slidesLoaded = true
      this.undoMap(this.undoObj)
      this.redoMap(this.redoObj)
      setTimeout(()=>{
        this.selectSlide(0)
      }, 500)
      this.$store.dispatch('setExportId', 'slide-exp')
    },
    methods: {
      getMindmap: async function() {
        await this.$store.dispatch('getMSuite')
        this.currentMindMap = await this.$store.getters.getMsuite
        this.slides         = this.currentMindMap.nodes
        this.mapColors      = []
        this.uniqueColors   = []
        Object.values(this.sortedSlides).forEach(el => {
          this.mapColors.push(el.line_color);
        });
        this.uniqueColors = this.getUniqueColors(this.mapColors);
      },
      async updatepresentationUser(){
        await this.$store.dispatch('updateMSuite', {
          canvas: this.$store.getters.getUser
          });
      },
      async addDefaultSlide(){
        await this.addShape('square', 1)
        await this.addShape('square', 2)
        setTimeout(()=>{
          this.addText('h1', 1)
          this.addText('h4', 2)
        }, 1500)
      },
      async addDefaultSecSlide(slide) {
        await this.addSlide(slide)
        await this.addShape('square', 3)
        await this.addShape('square', 4)
        setTimeout(()=>{
          this.addText('h1', 3)
          this.addText('ul', 4)
        }, 1400)
      },
      async addSlide(slide) {
        let _this = this
        let slidePosition = slide != undefined ? slide.position + 1 : 0
        let data = {
          node: {
            description: this.slideSample.label,
            line_color: '#ffffff',
            mindmap_id: this.currentMindMap.id,
            position: slidePosition,
          }
        }
        data.node.is_disabled = slide == undefined ? true : false
        await http.post('/nodes.json', data).then( async (res) => {
          let receivedData = res.data.node
          this.undoNodes.push({'req': 'addNode', 'node': receivedData})
          await this.getMindmap()
          this.cSlideIndex = slidePosition
        })
        setTimeout(()=> {
          this.selectSlide(this.cSlideIndex)
        }, 500)
        if (this.sortedSlides.length > 1) this.updatepresentationUser()
      },

      async updateSlidePosition(id, status, position) {
        let _this = this
        let slide = this.sortedSlides.find(sld => blk.id === Number(id))
        block.position = position
        const response = await this.updateSlideRequest(slide)
        if(response){
          this.sendLocals(true)
        } else alert('slide position didn\'t updated')
        this.updatepresentationUser()
      },

      updateSlideRequest(obj){
        let data = {
          node: {
            id: obj.id,
            description: obj.description,
            position: obj.position,
            line_color: obj.line_color,
          }
        }
        this.updatepresentationUser()
        this.colorSelected = false
        return http.patch(`/nodes/${obj.id}.json`,data)
        this.updatepresentationUser()
      },

      async deleteSlide(slide) {
        await http.delete(`/nodes/${slide.id}.json`).then((res) => {
          let receivedNodes = res.data.node
          if(receivedNodes && receivedNodes.length > 0){
            this.undoNodes.push({'req': 'deleteNode', 'node' : receivedNodes})
          }
          let myNode = {
            id: slide.id,
            title: slide.title,
            line_color: slide.line_color,
            mindmap_id: slide.mindmap_id,
            parent_node: slide.parent_node,
            position: slide.position,
            position_x: slide.position_x,
            position_y: slide.position_y,
            description: slide.description,
            element_type: slide.element_type,
            element_width:slide.element_width,
            element_height:slide.element_height,
          }
          this.undoNodes.push({'req': 'deleteNode', node: myNode})
        });
        this.sendLocals(false)
        this.getMindmap()
        setTimeout(()=> {
          this.selectSlide(this.cSlideIndex - 1)
        }, 300)
        this.updatepresentationUser()
      },
      dragSlide(event, index) {
        this.cSlideIndex = index;
      },
      dropSlide(event, index) {
        const slide = this.sortedSlides[this.cSlideIndex];
        this.sortedSlides.splice(this.cSlideIndex, 1);
        this.sortedSlides.splice(index, 0, slide);
        this.cSlideIndex = index;
        slide.position = this.sortedSlides.indexOf(slide);
        this.updateSlideRequest(slide);
        this.selectSlide(this.cSlideIndex);
      },
      async addText(tag, pos) {
        let data = {
          node: {
            description: 'Tap and Type',
            title: 'TextElement',
            mindmap_id: this.currentMindMap.id,
            parent_node: this.sortedSlides[this.cSlideIndex].id,
            element_type: tag,
            line_color: '#000000',
            element_width: 350
          }
        }
        if(pos == 1){
          data.node.description   = 'Click to add title'
          data.node.position_x = $('.element-wrap')[0].offsetWidth / 1.77
          data.node.position_y = $('.element-wrap')[0].offsetHeight / 1.3
        } else if (pos == 2){
          data.node.description   = 'Click to add subtitle'
          data.node.position_x = $('.element-wrap')[0].offsetWidth / 1.69
          data.node.position_y    = $('.element-wrap')[0].offsetHeight - $('.element-wrap')[0].offsetHeight / 8.1
        } else if (pos == 3){
          data.node.description   = 'Click to add title'
          data.node.position_y = $('.element-wrap')[0].offsetHeight / 2.67
          data.node.position_x = $('.element-wrap')[0].offsetWidth / 5
        } else if (pos == 4){
          data.node.description   = 'Click to add text'
          data.node.position_y = $('.element-wrap')[0].offsetHeight / 1.7
        }
        let res = await http.post('/nodes.json', data)
        await this.getMindmap()
        this.cSlideIndex = this.sortedSlides.indexOf(this.sortedSlides[this.cSlideIndex])
        if (res) {
          pos == 1 || pos == 2 ? document.getElementById(`element-${res.data.node.id}`).style.justifyContent = 'center' : ''
          let receivedData = res.data.node
          this.undoNodes.push({'req': 'addNode', 'node': receivedData})
        }
        if(pos != 1 && pos != 2) this.updatepresentationUser()
      },
      updateType(tag){
        let data = {
          node: {
            element_type: tag,
          }
        }
        this.updatePowerpointUser()
        this.colorSelected = false
        return http.patch(`/nodes/${this.selectedElement.id}.json`,data)
        this.updatePowerpointUser()
      },
      addShape(type, pos) {
        let url = null
        if(type == 'image' || type == 'video'){
          url = prompt('Please Enter Url')
          if(!url) return
        }
        let data = {
          node: {
            description: url,
            title: 'ShapeElement',
            mindmap_id: this.currentMindMap.id,
            parent_node: this.sortedSlides[this.cSlideIndex].id,
            element_type: type,
            line_color: '#000000',
            element_width: 100,
            element_height: 100,
            position_x: 210,
            position_y: 160
          }
        }
        if(url) {
          data.node.element_width = 350
          data.node.element_height= 200
        }
        if (pos) {
          data.node.element_width  = $('.element-wrap')[0].offsetWidth - 5
          data.node.hide_self = true
        }
        if (pos == 1) {
          data.node.element_height = ($('.element-wrap')[0].offsetHeight / 2) + 25
        } else if (pos == 2) {
          data.node.element_height = ($('.element-wrap')[0].offsetHeight / 2) - 31
          data.node.position_y     = $('.element-wrap')[0].offsetHeight - $('.element-wrap')[0].offsetHeight / 8
        } else if (pos == 3) {
          data.node.element_height = ($('.element-wrap')[0].offsetHeight / 5)
        } else if (pos == 4) {
          data.node.element_height = $('.element-wrap')[0].offsetHeight / 1.3
          data.node.position_y     = $('.element-wrap')[0].offsetHeight - $('.element-wrap')[0].offsetHeight / 2.15
        }
        http.post('/nodes.json', data).then(res => {
          let receivedData = res.data.node
          this.undoNodes.push({'req': 'addNode', 'node': receivedData})
        })
        this.getMindmap()
        this.cSlideIndex = this.sortedSlides.indexOf(this.sortedSlides[this.cSlideIndex])
        if(pos != 1 && pos != 2) this.updatepresentationUser()
      },
      selectSlide(index) {
        this.cSlideIndex = index
        this.selectedElement = null
        this.colorSelected = false
      },
      isSlideSelected() {
        return this.sortedSlides.length > 0 &&  this.sortedSlides[this.cSlideIndex] && this.sortedSlides[this.cSlideIndex].children && this.sortedSlides[this.cSlideIndex].children.length > 0
      },
      colorChange() {
        this.colorSelected = true
        if(this.selectedElement != null) this.el = JSON.parse(JSON.stringify(this.selectedElement))
        else this.el = JSON.parse(JSON.stringify(this.sortedSlides[this.cSlideIndex]))
      },
      updateColorNode(color){
        this.changeColor(color.hex8)
      },
      saveNodeColor(){
        this.el.line_color = this.el.line_color.hex8
        this.updateSlideRequest(this.el)
        this.updatepresentationUser()
      },
      updateAllColorNode(){
        if(this.el.line_color.hex8 == null) {
          alert('Please select color before updating')
          return
        }
        http.post(`/nodes/${this.el.id}/update_all_colors`,{line_color: this.el.line_color.hex8})
        this.colorSelected = false
        this.updatepresentationUser()
      },
      changeColor(color){
        let bgColor = this.selectedElement && this.selectedElement.hide_self ? this.selectedElement.parent_nod.line_color : color
        let ele_id = this.selectedElement != null ? `element-${this.selectedElement.id}` : `slide-editor-${this.sortedSlides[this.cSlideIndex].id}`
        if (this.selectedElement) {
          if (this.selectedElement.element_height){
            if (this.selectedElement.element_type == 'triangle'){
              document.getElementById(ele_id).children[0].children[0].children[0].style.borderBottomColor = color
            }
            else {
              document.getElementById(ele_id).children[0].children[0].style.backgroundColor= bgColor
              document.getElementById(ele_id).children[0].children[0].style.borderColor = color
            }
          } else document.getElementById(ele_id).children[0].style.color = color
        } else document.getElementById(ele_id).style.backgroundColor = color
      },
      closeModelPicker() {
        let oldColor = this.selectedElement != null ? this.selectedElement.line_color : this.sortedSlides[this.cSlideIndex].line_color
        this.changeColor(oldColor)
        this.colorSelected = false
      },
      dragStart(event, element) {
        this.isDragabble = event.target.classList.contains('fas') ? true : false
        this.selectedElement = element
      },
      getPosition(event){
        const rect = event.target.getBoundingClientRect();
        let position_x = event.clientX - (this.selectedElement.element_width / 2)
        let position_y = event.clientY - rect.top + 170

        if (
          position_x < rect.x ||
          position_y < rect.y ||
          this.selectedElement.element_width + position_x > rect.right ||
          this.selectedElement.element_height + position_y > $('.element-wrap')[0].offsetHeight + rect.bottom )
        {
          alert('element must be inside slide')
          return
        }
        return {
          position_x: position_x,
          position_y: position_y
        }
      },
      dragDrop(event) {
        let positions = this.getPosition(event)
        if(positions){
          this.selectedElement.position_x = positions.position_x
          this.selectedElement.position_y = positions.position_y
          this.updateElement(this.selectedElement)
        }
        this.isDragabble = false
      },
      updateElement(element) {
        http.put(`/nodes/${element.id}.json`, element).then(()=> {
          this.getMindmap()
        })
        this.updatepresentationUser()
      },
      deleteElement(element) {
        http.delete(`/nodes/${element.id}.json`).then((res) => {
          let receivedNodes = res.data.node
          if(receivedNodes && receivedNodes.length > 0){
            this.undoNodes.push({'req': 'deleteNode', 'node' : receivedNodes})
          }
          let myNode = {
            id: element.id,
            title: element.title,
            line_color: element.line_color,
            mindmap_id: element.mindmap_id,
            parent_node: element.parent_node,
            position: element.position,
            position_x: element.position_x,
            position_y: element.position_y,
            description: element.description,
            element_type: element.element_type,
            element_width: element.element_width,
            element_height: element.element_height
          }
          this.undoNodes.push({'req': 'deleteNode', node: myNode})
        });
        this.sendLocals(false)
        this.updatepresentationUser()
      },
      async undoObj(){
        let undoObj = await this.undoNode(this.undoNodes)
        if(undoObj){
          this.undoNodes.pop()
          this.redoNodes.push({req: undoObj.req, node: undoObj.node})
        }
      },
      async redoObj(){
        let redoObj = await this.redoNode(this.redoNodes)
        if(redoObj){
          this.redoNodes.pop()
          this.undoNodes.push({req: redoObj.req, node: redoObj.node})
        }
      },
    },
  }
</script>

<style lang="scss" scoped>
  @import "./style/styles.scss"
</style>
