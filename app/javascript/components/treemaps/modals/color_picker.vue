<template>
  <div class="input-group color-picker w-100 c" ref="colorpicker">
    <input type="text" class="form-control" v-model="colorValue" @focus="showPicker()" @input="updateFromInput" />
    <span class="input-group-addon color-picker-container">
      <span class="current-color" :style="'background-color: ' + colorValue" @click="togglePicker()"></span>
      <chrome-picker :value="colors" @input="updateFromPicker" v-if="displayPicker" />
    </span>
  </div>
</template>
<script type="text/javascript">
  import { mapGetters, mapActions } from 'vuex'
  export default {
    data(){
      return{
        colors: {
          hex: ''
        },
        colorValue: '',
        displayPicker: false,
        defaultColor: "#FF0000",
      }
    },
    computed: {
      ...mapGetters([
        'getColorCode'
      ])
    },
    mounted() {
      this.setColor('#FF0000');
    },
    methods:{
      ...mapActions([
          'addColor'
        ]),
      setColor(color) {
        this.updateColors(color);
        this.colorValue = color;
      },
      updateColors(color) {
        if(color.slice(0, 1) == '#') {
          this.colors = {
            hex: color
          };
        }
        else if(color.slice(0, 4) == 'rgba') {
          var rgba = color.replace(/^rgba?\(|\s+|\)$/g,'').split(','),
            hex = '#' + ((1 << 24) + (parseInt(rgba[0]) << 16) + (parseInt(rgba[1]) << 8) + parseInt(rgba[2])).toString(16).slice(1);
          this.colors = {
            hex: hex,
            a: rgba[3],
          }
        }
      },
      showPicker() {
        document.addEventListener('click', this.documentClick);
        this.displayPicker = true;
      },
      hidePicker() {
        document.removeEventListener('click', this.documentClick);
        this.displayPicker = false;
      },
      togglePicker() {
        this.displayPicker ? this.hidePicker() : this.showPicker();
      },
      updateFromInput() {
        this.updateColors(this.colorValue);
      },
      updateFromPicker(color) {
        this.colors = color;
        if(color.rgba.a == 1) {
          this.colorValue = color.hex;
        }
        else {
          this.colorValue = 'rgba(' + color.rgba.r + ', ' + color.rgba.g + ', ' + color.rgba.b + ', ' + color.rgba.a + ')';
        }
        this.addColor({hex: this.colors.hex})
      },
      documentClick(e) {
        var el = this.$refs.colorpicker,
          target = e.target;
        if(el !== target && !el.contains(target)) {
          this.hidePicker()
        }
      }
    },
    watch: {
      colorValue(val) {
        if(val) {
          this.updateColors(val);
          this.$emit('input', val);
          // document.body.style.background = val;
        }
      },
      getColorCode(val){
        this.setColor(val);
        this.$emit('input', val);
      }
    }
  }
</script>
<style>
  h1 {
    height: 120px;
    line-height: 120px;
    text-align: center;
  }
  .vc-chrome {
    position: absolute;
    top: 35px;
    right: 0;
    z-index: 9;
  }
  .current-color {
    display: inline-block;
    width: 2rem;
    height: 2.36rem;
    background-color: #000;
    cursor: pointer;
    border-radius: 0 4px 6px 0;
  }
  .footer {
    margin-top: 20px;
    text-align: center;
  }
</style>
