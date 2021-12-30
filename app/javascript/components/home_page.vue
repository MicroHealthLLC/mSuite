<template>
  <div class="main_div">
    <h1 class="main_heading">mSuite Maps</h1>
    <div class="box_shadow box main_box">
      <div class="w-100 text-center mb-3">
         <input type="text" v-model="mindmapName" class="w-100 mindmap-name rounded" placeholder="Enter name of Concept Map here then select map type below">
      </div>
      <div class="row container pl-0">
        <div v-for="type in mindmapTypes">
          <div class="col mr-4 item" @mouseover.self="hovered = type.key" @mouseleave.self="hovered = false" :class="hovered===type.key ? 'hovering':'' ">
            <img :src="type.imgsrc" class="mindmap-img-size" @click.prevent="mindMapCreate(type.key)"
            />
            <span class="text-center">{{type.value}}</span>
          </div>
        </div>
      </div>
      <div class="row w_10">
        <div class="col-12 input_label">
          <h4>Or Open a Map with the unique key</h4>
        </div>
        <div class="offset-2 col-8">
          <div class="input-group md-form form-sm form-1 pl-0">
            <input class="form-control my-0 py-1" type="text" v-model="mapName" placeholder="Please enter Map unique key">
            <div class="input-group-prepend">
              <span @click="openOrCreateMap" class="add_icon_span input-group-text lighten-3 pointer" id="basic-text1">
                <i class="material-icons mr-1">done</i>
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
  import http from '../common/http'
  export default {
    data() {
      return {
        mapName: "",
        mapsArr: [],
        mindmapName:"",
        hovered:false,
        selectedType: 'simple',
        mindmapTypes: [
          { key: 'simple', value: 'Mindmap', imgsrc: "/assets/mindmap_main_menu.png" },
          { key: 'kanban', value: 'Kanban', imgsrc: "/assets/kanban_main_menu.png"  },
          { key: 'whiteboard', value: 'White Board', imgsrc: "/assets/whiteboard_main_menu.png"  },
          { key: 'tree_map', value: 'TreeMap', imgsrc: "/assets/tree_map_main_menu.png" },
          { key: 'tree_chart', value: 'TreeChart', imgsrc: "/assets/tree_diagram.png" }
        ]
      }
    },
    methods: {
      createNewMap() {
        http.post(`/mindmaps.json`, { mindmap: { name: this.mindmapName || "Central Idea", mm_type:this.selectedType } }).then((res) => {
          window.open(`/mindmaps/${res.data.mindmap.unique_key}`, "_self")
        }).catch((error) => {
          alert("Unable to open/create mindmap.")
          console.log(error)
        })
      },
      openOrCreateMap() {
        if (this.mapName == "" || this.mapName == null || this.mapName == undefined) {
          alert("Please enter name for map to open/create")
          return
        }

        http.get(`/mindmaps/find_or_create.json?key=${this.mapName}`).then((res) => {
          {window.open(`/mindmaps/${res.data.mindmap.unique_key}`, "_self")}
        }).catch((error) => {
          alert("Unable to open/create mindmap with this name. Please try again changing the name.")
          console.log(error)
        })
      },
      openMindMap(key) {
        window.open(`/mindmaps/${key}`, "_self")
      },
      mindMapCreate(key) {
        this.selectedType = key
        this.createNewMap()
      }
    }
  }
</script>

<style scoped lang="css">
.main_div {
  position: absolute;
  height: 100%;
  width: 100%;
  background-image: linear-gradient(grey, white);
}
.main_heading {
  font-family: 'Montserrat', sans-serif;
  margin: 8vh;
  text-align: center;
}
.main_box {
  margin-left: auto;
  margin-right: auto;
  width: 50%;
  height: max-content;
  background-image: linear-gradient(white, grey);
  box-shadow: 0 5px 5px rgba(0, 0, 0, 0.8);
}
.new_button_container {
  display: flex;
  justify-content: center;
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
  width: 120px;
  cursor: pointer;
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
</style>
