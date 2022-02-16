<template>
  <div class="filter">
    <div class="main_div">
      <div class="container-fluid pl-0">
        <!-- //SEARCHBAR ROW -->
         <div class="row pl-0 searchbar-row">
            <div class="col text-center">
              <span class="mx-auto text-light"><h1 class="mb-3 msuite-title d-inline px-3">mSuite</h1></span>
            <div class="w-50 mx-auto my-4">
              <span class="text-light searchbar-cta"> <h3><i>QUICK COLLABORATIONS MADE SIMPLE</i></h3></span>
              <input type="text" v-model="mindmapName" class="w-100 mindmap-name rounded" placeholder="ENTER YOUR CONCEPT TITLE, THEN SELECT MAP TYPE BELOW">
            </div>
            </div>
          </div>
          <!-- Row for wrapper containing grid-layout mindmap items -->
        <div class="row mx-auto mm-icon-row">
          <div v-for="type, i in mindmapTypes" class="mx-auto py-auto col-lg-2 col-sm-6 col-md-2 icon-col" :key="i">
            <!-- <div class="item p-0 my-2 px-4" @mouseover.self="hovered = type.key" @mouseleave.self="hovered = false" :class="hovered === type.key ? 'hovering' : ''"> -->
              <div class="item icon-item" @click.prevent="mindMapCreate(type.key)">
              <!-- <img :src="type.imgsrc" class="mindmap-img-size" />  -->
              <i class="fal fa-mind-share mm-icon" v-if="type.key == 'simple'"></i>
              <i class="far fa-columns mm-icon" v-if="type.key == 'kanban'"></i>
              <i class="far fa-chalkboard mm-icon" v-if="type.key == 'whiteboard'"></i>
              <i class="fad fa-th-large mm-icon" v-if="type.key == 'tree_map'"></i>
              <i class="fal fa-sitemap mm-icon" v-if="type.key == 'tree_chart'"></i>
              <span class="text-center">{{type.value}}</span>
            </div>
          </div>
        </div>
        <sweet-modal ref="errorModal" class="of_v" icon="error">
          {{ errorMsg }}
          <button v-if="oldMSuiteName.length > 9 && oldMSuiteName.length < 21" slot="button" class="btn btn-secondary mr-2" @click="continueMSuite()">Open</button>
          <button slot="button" class="btn btn-secondary mr-2" @click="tryAgain()">Try Again</button>
          <button slot="button" class="btn btn-info" @click="mindMapCreate(selectedType)">Create Random URL</button>
        </sweet-modal>
        <footer>
        <cookie-law theme="dark-lime"></cookie-law>
      </footer>
      </div>
      <sweet-modal ref="errorModal" class="of_v" icon="error">
        {{ errorMsg }}
        <button v-if="oldMSuiteName.length > 9 && oldMSuiteName.length < 21" slot="button" class="btn btn-secondary mr-2" @click="continueMSuite()">Open</button>
        <button slot="button" class="btn btn-secondary mr-2" @click="tryAgain()">Try Again</button>
        <button slot="button" class="btn btn-info" @click="mindMapCreate(selectedType)">Create Random URL</button>
      </sweet-modal>
    </div>
  </div>
</template>
<script>
  import CookieLaw from 'vue-cookie-law'
  import http from '../common/http'
  export default {
    data() {
      return {
        mapName: "",
        oldMSuiteName: '',
        mapsArr: [],
        errorMsg: '',
        mindmapName: "",
        uniqueKey: '',
        hovered: false,
        selectedType: 'simple',
        mindmapTypes: [
          { key: 'simple', value: 'Mindmap', imgsrc: "/assets/mindmap_main_menu.png" },
          { key: 'kanban', value: 'Kanban', imgsrc: "/assets/kanban_main_menu.png"  },
          { key: 'whiteboard', value: 'WhiteBoard', imgsrc: "/assets/whiteboard_main_menu.png"  },
          { key: 'tree_map', value: 'TreeMap', imgsrc: "/assets/tree_map_main_menu.png" },
          { key: 'tree_chart', value: 'TreeChart', imgsrc: "/assets/tree_diagram.png" },
        ]
      }
    },
    methods: {
      createNewMap() {
        let _this = this
        http.post(`/msuite.json`, { mindmap: { name: this.mindmapName || "Central Idea", mm_type: this.selectedType } }).then((res) => {
          if(res.data.mindmap.id !== null)
          {
            window.open(`/msuite/${res.data.mindmap.unique_key}`, "_self")
          }
        }).catch((error) => {
          _this.errorMsg = 'This Map Url ' + error.response.data.messages[0]
          _this.selectedType = error.response.data.mindmap.mm_type
          _this.uniqueKey = error.response.data.mindmap.unique_key
          _this.oldMSuiteName = error.response.data.mindmap.name
          _this.mindmapName = ''
          _this.$refs['errorModal'].open()
        })
      },
      openMindMap(key) {
        window.open(`/msuite/${key}`, "_self")
      },
      continueMSuite(){
        if(this.uniqueKey) window.open(`/msuite/${this.uniqueKey}`, "_self")
      },
      tryAgain(){
        this.selectedType = 'simple'
        this.uniqueKey = ''
        this.$refs['errorModal'].close()
      },
      mindMapCreate(key) {
        this.selectedType = key
        this.createNewMap()
      }
    },
    components: { CookieLaw }
  }
</script>

<style scoped lang="css">
  .main_div {
    position: absolute;
    height: 80%;
    width: 100%;
    background:  linear-gradient(0deg, rgba(0, 0, 0, 0.3), rgba(0, 0, 0, 0.3)), url('../../assets/images/landing_bg.jpg') no-repeat center center fixed;
    -webkit-background-size: cover;
    -moz-background-size: cover;
    -o-background-size: cover;
    background-size: cover;
  }
  .main_box {
    margin-left: auto;
    margin-right: auto;
    width: 50%;
    height: max-content;
    background-image: linear-gradient(white, grey);
    box-shadow: 0 5px 5px rgba(0, 0, 0, 0.8);
  }
  .searchbar-row{
    margin: 7rem auto 12rem auto;
  }
  .new_button_container {
    display: flex;
    justify-content: center;
  }
  .searchbar-cta{
    font-size: 1.4rem;
    margin-top: 20px;
    font-family: Arial Narrow, sans-serif;
  }
  .new_button {
    color: white;
    background-color: grey;
    box-shadow: 2px 5px 5px rgba(1, 0, 0, 0.8);
  }
  .new_button:hover {
    background-color: #1f1f1f;
  }
  .input_label {
    text-align: center;
    margin-top: 5%;
  }
  .icon-item {
  position: absolute;
  top: 50%;
  left: 32%;
  -ms-transform: translateY(-50%);
  transform: translateY(-50%);
  }
  .msuite-title {
    font-family: sans-serif;
    font-weight: 600;
    border: solid #fff 4px;
    border-radius: 4px;
    padding: 5px;
  }
  .add_icon_span {
    font-weight: normal;
  }
  .add_icon_span:hover {
    background-color: grey;
    color: white;
    font-weight: 900;
  }
  .input-group.md-form.form-sm.form-1 input{
    border: 1px solid #bdbdbd;
    border-top-left-radius: 0.25rem;
    border-bottom-left-radius: 0.25rem;
  }

  #basic-text1 {
    border-radius: 0.25rem;
    border-top-left-radius: 0 !important;
    border-bottom-left-radius: 0 !important;
  }
  .icon-col{
    /* Each mindmap icon wrapper */
    /* background-color: rgba(255, 255, 255, 0.8); */
    background-color: #fff;
    padding: 8px;
    min-height: 200px;
    border-radius: 4px;
    transition: all .2s ease-in-out;
    box-shadow: 0 14px 28px rgba(0,0,0,0.25), 0 10px 10px rgba(0,0,0,0.22);
  }
  .icon-col:hover{
    /* Each mindmap icon wrapper */
    transform: scale(1.15);
  }
  .mind-map-list-header {
    text-align: center;
    font-size: 20px;
    padding: 0.5em;
    color: white;
    border-radius: 10px;
    background-color: grey;
    box-shadow: 2px 3px 3px rgba(1, 0, 0, 0.8);
    font-variant-caps: petite-caps;
    font-style: italic;
  }
  .mind-map-list {
    max-height: 35vh;
    overflow: auto;
  }
  .map-item {
    border-bottom: 1px solid grey;
    word-break: break-word;
  }
  .map-link {
    color: #212529;
    cursor: pointer;
  }
  .map-link:hover {
    color: #e9ecef;
    font-weight: 500;
    text-decoration: underline;
    cursor: pointer;
  }
  .empty-list {
    justify-content: center;
    color: #e9ecef;
    font-style: italic;
    letter-spacing: 6px;
  }
  .selectPicker {
    justify-content: center;
    border-radius: 50px;
    width: 50%;
    text-align: center;
    margin-left: auto;
    margin-right: auto;
    margin-bottom: 20px;
    height: 30px;
  }
  .mindmap-img-size {
    width: 80px;
    height: 80px;
  }
  .item {
    vertical-align: top;
    display: inline-block;
    text-align: center;
    cursor: pointer;
  }
  .each-icon-wrapper{
    transition: all .2s ease-in-out;
  }
  .each-icon-wrapper:hover{
   transform: scale(1.3);
  }
  .mindmap-name {
    background-color: white;
    color: black;
    border: none;
    padding: 10px;
  }
  ::placeholder { /* Chrome, Firefox, Opera, Safari 10.1+ */
    color: black;
    opacity: 0.25; /* Firefox */
  }

  :-ms-input-placeholder { /* Internet Explorer 10-11 */
    color: black;
  }

  ::-ms-input-placeholder { /* Microsoft Edge */
    color: black;
  }
  .hovering {
    -ms-transform: scale(1.2); /* IE 9 */
    -webkit-transform: scale(1.2); /* Safari 3-8 */
    transform: scale(1.2);
  }

  .mm-icon {
    font-size: 5rem;
    color: #DD9036;
    font-weight: 300;
  }
  .mm-icon-row{
    width: 100%;
    position: fixed;
    bottom: 8%;
  }
</style>
