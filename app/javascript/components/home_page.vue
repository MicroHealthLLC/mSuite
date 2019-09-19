<template>
  <div class="main_div">
    <h1 class="main_heading">Mind Map</h1>
    <div class="box_shadow box main_box">
      <div class="row w_10">
        <div class="offset-3 col-6 new_button_container">
          <button @click.stop="createNewMap" class="btn_2 new_button pointer">
          <i class="material-icons mr-1">add</i> Create New Map</button>
        </div>
      </div>
      <div class="row w_10">
        <div class="col-12 input_label">
          <h4>Or create/open a Map with the name:</h4>
        </div>
        <div class="offset-3 col-6">
          <div class="input-group md-form form-sm form-1 pl-0">
            <input class="form-control my-0 py-1" type="text" v-model="mapName" placeholder="Please enter Map Name">
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
        mapName: ""
      }
    },
    methods: {
      createNewMap() {
        window.open("/mindmaps/new","_self");
      },
      openOrCreateMap() {
        if (this.mapName == "" || this.mapName == null || this.mapName == undefined) {
          alert("Please enter name for map to open/create");
          return;
        }
        http.get(`/mindmaps/find_or_create.json?key=${this.mapName}`).then((res) => {
          window.open(`/mindmaps/new?key=${res.data.mindmap.unique_key}`,"_self");
        }).catch((error) => {
          alert("Unable to open/create mindmap with this name. Please try again changing the name.")
          console.log(error)
        })
      }
    }
  }
</script>

<style scoped lang="css">
.main_div {
  position: absolute;
  height: 100%;
  width: 98%;
  background-image: linear-gradient(grey, white);
}
.main_heading {
  font-family: fantasy;
  margin: 10vh;
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
  &:hover {
    background-color: #1f1f1f;
  }
}
.input_label {
  text-align: center;
  margin-top: 5%;
}
.add_icon_span {
  font-weight: normal;
}
.add_icon_span:hover {
  background-color: #c1f9c1;
  color: green;
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
</style>