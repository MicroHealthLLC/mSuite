export default {
  created() {
    this.getUniqueColors();
    this.getColorNode();
  },
  methods: {
    getUniqueColors(colors) {
      if(colors == undefined) return;
      let objColors = {}
      let uniqueColors = []
      colors.forEach(item => {
        if(!objColors[item])
          objColors[item] = 0;
        objColors[item] += 1;
      })
      for (let val in objColors)
        if(objColors[val] != undefined && val != 'null') uniqueColors.push(val)
      return uniqueColors;
    },
    getColorNode(myNodeClass){
        setTimeout(()=>{
          $(myNodeClass).each((index, color) => {
            if(this.rgbToHex(color.style.backgroundColor)){
              color.style.color = '#000'
              if(this.$store.state.mSuite.mm_type == 'kanban' && color.children[0]){
                $('.stage-title')[index].style.color = '#000'
                  let kanbanElement = color.children[0].children[0].children[0].children[0].children[0].children[1]
                  kanbanElement.children[2].children[0].style.color = "#C14E57"
                  kanbanElement.children[1].children[0].style.color = "dodgerblue"
                  kanbanElement.children[0].children[0].style.color = "#474748"
              } else if(this.$store.state.mSuite.mm_type == 'kanban'){
                color.style.color = '#000'
              }
              if (this.$store.state.mSuite.mm_type == 'flowmap' || this.$store.state.mSuite.mm_type == 'tree_chart'){
                let nodeElement = color.children[0]
                nodeElement.children.forEach(node => {
                  node.style.filter = "invert(0%)"
                })
              }
            } else {
              color.style.color = '#fff'
              if(this.$store.state.mSuite.mm_type == 'kanban' && color.children[0]){
                $('.stage-title')[index].style.color = '#fff'
                  let kanbanElement = color.children[0].children[0].children[0].children[0].children[0].children[1]
                  kanbanElement.children[0].children[0].style.color = "#948A85"
                  kanbanElement.children[1].children[0].style.color = "#BE7917"
                  kanbanElement.children[2].children[0].style.color = "#168C80"
              } else if (this.$store.state.mSuite.mm_type == 'kanban') {
                color.style.color = '#fff'
              } else if (this.$store.state.mSuite.mm_type == 'tree_map'){
                if(color.children[4] == undefined){
                  color.children[1].style.filter = "invert(100%)"
                  color.children[2].style.filter = "invert(100%)"
                  color.children[3].style.filter = "invert(100%)"
                } else {
                  let parentElementIndex = color.children.length - 3
                  color.children[parentElementIndex].style.filter = "invert(100%)"
                  color.children[parentElementIndex + 1].style.filter = "invert(100%)"
                  color.children[parentElementIndex + 2].style.filter = "invert(100%)"
                }
              } else if (this.$store.state.mSuite.mm_type == 'flowmap' || this.$store.state.mSuite.mm_type == 'tree_chart'){
                let nodeElement = color.children[0]
                nodeElement.children.forEach(node => {
                  node.style.filter = "invert(100%)"
                })
              }
            }
          })
        }, 50)
      },
      rgbToHex(bgColor) {
        if(bgColor != ''){
          let r = bgColor.substr(4,3)
          let g = bgColor.substr(9,3)
          let b = bgColor.substr(14,3)
          if(this.wc_hex_is_light("#" + this.componentToHex(r) + this.componentToHex(g) + this.componentToHex(b))){
            return true
          } else {
            return false
          }
        } else return true
      },
      componentToHex(c) {
        let hex = parseInt(c).toString(16);
        return hex.length == 1 ? "0" + hex : hex;
      },
      wc_hex_is_light(color) {
        const hex = color.replace('#', '');
        const c_r = parseInt(hex.substr(0, 2), 16);
        const c_g = parseInt(hex.substr(2, 2), 16);
        const c_b = parseInt(hex.substr(4, 2), 16);
        const brightness = ((c_r * 299) + (c_g * 587) + (c_b * 114)) / 1000;
        return brightness > 155;
      },
      getDateDifference(date1, date2){
        let utcDate1 = Date.UTC(
          date1.getFullYear(),
          date1.getMonth(),
          date1.getDate()
        )
        let utcDate2 = Date.UTC(
          date2.getFullYear(),
          date2.getMonth(),
          date2.getDate()
        )
        let difference = utcDate2 - utcDate1
        difference = difference/(1000 * 60 * 60 * 24)
        return difference
      },
      getTimeZone(date){
        date = new Date(date)
        return new Date(date.getTime() - date.getTimezoneOffset() * 60 * 1000)
      },
  }
}
