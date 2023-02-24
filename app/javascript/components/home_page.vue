<template>
  <div class="filter">
    <HomeNavbar />
    <Recaptcha v-if="is_config && !fromCaptcha"></Recaptcha>
    <div class="main_div" v-else>
      <div class="container-fluid pl-0">
      <!-- //SEARCHBAR ROW -->
        <div class="row pl-0 searchbar-row mb-0">
          <div class="col text-center">
            <span class="mx-auto text-light"><h1 class="mb-3 msuite-title d-inline px-3">msuite.app</h1></span>
          <div class="w-50 mx-auto my-4">
            <span class="text-light searchbar-cta"> <h3><i>MULTIPLAYER COLLABORATION SUITE</i></h3></span>
             <!--
            <input type="text" v-model="mindmapName" class="w-100 mindmap-name rounded" placeholder="ENTER UNIQUE URL NAME, THEN CLICK BUTTON OR JUST CLICK BUTTON FOR RANDOM URL">
             -->
         </div>
          </div>
          <!-- Row for wrapper containing grid-layout mindmap items -->
          <div class="row mm-icon-row pl-5">
            <div v-for="type, i in mindmapTypes" :key="i" class="card-width my-2 mb-5">
              <div class="item icon-item mx-2 my-2 py-3 icon-col" @click.prevent="mindMapCreate(type.key)">
                <i class="mx-auto fal fa-mind-share mm-icon mt-3" v-if="type.key == 'simple'"></i>
                <i class="mx-auto far fa-columns mm-icon mt-3" v-if="type.key == 'kanban'"></i>
                <i class="mx-auto far fa-chalkboard mm-icon mt-3" v-if="type.key == 'whiteboard'"></i>
                <i class="mx-auto fad fa-th-large mm-icon mt-3" v-if="type.key == 'tree_map'"></i>
                <i class="mx-auto fal fa-sitemap mm-icon mt-3" v-if="type.key == 'tree_chart'"></i>
                <i class="mx-auto fas fa-project-diagram mm-icon mt-3" v-if="type.key == 'flowmap'"></i>
                <i class="mx-auto fas fa-tasks mm-icon mt-3" v-if="type.key == 'todo'"></i>
                <i class="fas fa-file-alt mm-icon mt-3" v-if="type.key == 'Notepad'"></i>
                <i class="far fa-poll-h mm-icon mt-3" v-if="type.key == 'poll'"></i>
                <i class="mx-auto fas fa-file-spreadsheet mm-icon mt-3" v-if="type.key == 'spreadsheet'"></i>
                <i class="mx-auto fad fa-calendar-alt mm-icon mt-3" v-if="type.key == 'calendar'"></i>
                <i class="mx-auto fad fa-chart-pie mm-icon mt-3" v-if="type.key == 'venndiagram'"></i>
                <i class="mx-auto far fa-file-powerpoint mm-icon mt-3" v-if="type.key == 'presentation'"></i>
                <i class="mx-auto fas fa-share-alt mm-icon mt-3" v-if="type.key == 'fileshare'"></i>
                <span class="text-center icon-text">{{type.value}}</span>
              </div>
            </div>
          </div>
        </div>
        <footer>
          <cookie-law theme="dark-lime"></cookie-law>
        </footer>
      </div>
    </div>
    <Beta v-if="beta_status" />
  </div>
</template>
<script>
  import Recaptcha from './recaptcha';
  import Beta from './beta';
  import CookieLaw from 'vue-cookie-law';
  import HomeNavbar from '../common/navbar/home_navbar'
  export default {
    data() {
      return {
        fromCaptcha: true,
        is_config: true,
        beta_status: Vue.prototype.$beta_status,
        mindmapTypes: [
          { key: 'simple', value: 'Mindmap', imgsrc: "" },
          { key: 'kanban', value: 'Kanban', imgsrc: ""  },
          { key: 'whiteboard', value: 'Whiteboard', imgsrc: ""  },
          { key: 'tree_map', value: 'Tree map', imgsrc: "" },
          { key: 'tree_chart', value: 'Tree chart', imgsrc: "" },
          { key: 'flowmap', value: 'Flowmap', imgsrc: "" },
          { key: 'todo', value: 'Todo', imgsrc: "" },
          { key: 'Notepad', value: 'Notepad', imgsrc: "" },
          { key: 'spreadsheet', value: 'Spreadsheet', imgsrc: "" },
          { key: 'poll', value: 'Poll', imgsrc: "" },
          { key: 'calendar', value: 'Calendar', imgsrc: "" },
          { key: 'venndiagram', value: 'Venndiagram', imgsrc: "" },
          { key: 'presentation', value: 'Presentation', imgsrc: "" },
          { key: 'fileshare', value: 'Fileshare', imgsrc: "" },
        ]
        //Test
      }
    },
    components: { CookieLaw, Recaptcha, Beta, HomeNavbar },
    methods: {
      createNewMap(key) {
        this.$store.dispatch('createMsuite', key)
      },
      mindMapCreate(key) {
        this.createNewMap(key)
      }
    },
    mounted(){
      if(this.$cookies.get('verifiedCaptcha') == null) this.fromCaptcha = false
      if(Vue.prototype.$google_recaptcha_site_key == "") this.is_config = false

      if(this.beta_status === 'true'){
        this.beta_status = true
        $(".navbar-brand").css("margin-left", "5%");
      } else {
        this.beta_status = false
        $(".navbar-brand").css("margin-left", "0%");
      }
    },
  }
</script>

<style scoped lang="css">
  .main_div {
    position: absolute;
    width: 100%;
    height: 100vh;
    background:  linear-gradient(0deg, rgba(0, 0, 0, 0.3), rgba(0, 0, 0, 0.3)), url('../../assets/images/landing_bg.jpg') no-repeat center center fixed;
    -webkit-background-size: cover;
    -moz-background-size: cover;
    -o-background-size: cover;
    background-size: cover;
  }
  .searchbar-row{
    margin: 2rem auto 12rem auto;
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
    background-color: #fff;
    padding: 8px;
    min-height: 9rem;
    min-width: 5rem;
    border-radius: 4px;
    transition: all .2s ease-in-out;
    box-shadow: 0 14px 28px rgba(0,0,0,0.25), 0 10px 10px rgba(0,0,0,0.22);
  }
  .icon-col:hover{
    /* Each mindmap icon wrapper */
    transform: scale(1.1);
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
  .item {
    vertical-align: top;
    display: inline-block;
    text-align: center;
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
  .mm-icon {
    font-size: 6rem;
    color: #DD9036;
    font-weight: 300;
  }
  .card-width {
    width: 14rem;
    height: 8rem;
  }
  .mx-center{
    margin-left:  2.5rem !important;
    margin-right: 2.5rem !important;
  }
</style>
