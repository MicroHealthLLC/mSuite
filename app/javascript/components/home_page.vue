<template>
  <div class="main_div">
    <h1 class="main_heading"></h1>
    <div class="box_shadow box main_box">
      <div class="row w_10">
        <div class="offset-3 col-6 new_button_container">
          <button @click.stop="createNewMap" class="btn_2 new_button pointer">
          <i class="material-icons mr-1">add</i> Create New Map</button>
        </div>
      </div>
      <div class="row w_10">
        <div class="col-12 input_label">
          <h4>Or create/open a Map with the unique key</h4>
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
        <!-- <div class="col-12 my-4">
          <div class="mind-map-list-header">
            List of all Mind Maps (keys and names)
          </div>
          <div class="mt-2 mind-map-list">
            <div v-if="mapsArr.length > 0">
              <div class="row mb-2 map-item py-2" v-for="(map, index) in mapsArr">
                <div class="col-1">
                  {{++index}}
                </div>
                <div class="col-5 map-link"
                    @click.stop="openMindMap(map.unique_key)"
                  >
                  {{map.unique_key}}
                </div>
                <div class="col-6">
                  {{map.name}}
                </div>
              </div>
            </div>
            <div v-else class="row empty-list">
              List is empty...
            </div>
          </div>
        </div> -->
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
        mapsArr: []
      }
    },

    methods: {
      createNewMap() {
        window.open("/mindmaps/new", "_self")
      },
      openOrCreateMap() {
        if (this.mapName == "" || this.mapName == null || this.mapName == undefined) {
          alert("Please enter name for map to open/create")
          return
        }

        http.get(`/mindmaps/find_or_create.json?key=${this.mapName}`).then((res) => {
          window.open(`/mindmaps/new?key=${res.data.mindmap.unique_key}`,"_self")
        }).catch((error) => {
          alert("Unable to open/create mindmap with this name. Please try again changing the name.")
          console.log(error)
        })
      },
      // call api for listing all the mind maps names and keys
      // listAllMaps() {
      //   http.get(`/mindmaps/list_all_maps.json?`).then((res) => {
      //     this.mapsArr = res.data.mindmaps
      //   }).catch((err) => {
      //     console.log(err)
      //   })
      // },
      openMindMap(key) {
        window.open(`/mindmaps/new?key=${key}`, "_self")
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
  font-family: fantasy;
  margin: 12vh;
  text-decoration: underline;
}
.main_box {
  margin-left: 25%;
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
</style>
