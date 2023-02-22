import _ from 'lodash'
export default {
  data(){
    return{
      isRotating: false,
      rotateStartPosition: null,
      startX: 0,
      startY: 0,
    }
  },
  methods: {
    startRotate(event, element) {
      this.isRotating = true
      this.rotateStartPosition = { x: event.clientX, y: event.clientY }
    },
    doRotate(event, element) {
      if (this.isRotating) {
        let angle = this.calculateAngle(event, element)
        element.node_width = angle
      }
    },
    stopRotate(event, element) {
      this.isRotating = false
      this.rotateStartPosition = null
      this.updateElement(element)
    },
    calculateAngle(event, element) {
      let centerX = element.position_x + element.element_width / 2
      let centerY = element.position_y + element.element_height / 2
      let startX = this.rotateStartPosition.x
      let startY = this.rotateStartPosition.y
      let endX = event.clientX
      let endY = event.clientY
      let angle = Math.atan2(endY - centerY, endX - centerX) - Math.atan2(startY - centerY, startX - centerX)
      angle = angle * (180 / Math.PI)

      return angle
    }
  }
}

