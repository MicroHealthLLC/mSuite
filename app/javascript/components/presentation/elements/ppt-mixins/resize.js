export default {
  data(){
    return{
      resizing: false
    }
  },
  methods: {
    startResizing(event) {
      this.resizing = true;
    },
    resize(event) {
      if (this.resizing) {
        if (event.target.classList[0] != 'resizable-circle'){
          this.width  = event.clientX - this.element.position_x + 12
          this.height = event.clientY - this.element.position_y + 12
        } else {
          this.width  = event.clientX - this.element.position_x + 50
          this.height = event.clientY - this.element.position_y + 50
        }
      }
    },
    stopResizing(event) {
      this.resizing = false;
      this.element.element_width = this.width
      this.element.element_height = this.height
      this.$emit("updateElement", this.element)
    }
  }
}
