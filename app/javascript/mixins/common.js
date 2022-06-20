export default {
  created() {
   this.getUniqueColors();
   this.getColorNode();
  },
  methods: {
    getUniqueColors(colors) {
      let objColors = {}
      let uniqueColors = []
      colors.forEach(item => {
        if(!objColors[item])
          objColors[item] = 0;
        objColors[item] += 1;
      })
      for (let val in objColors)
        if(objColors[val] != undefined) uniqueColors.push(val);
      return uniqueColors;
    },
    getColorNode(myNodeClass){
        setTimeout(()=>{
          $(myNodeClass).each((index, color) => {
            console.log(this.rgbToHex(color.style.backgroundColor))
            if(this.rgbToHex(color.style.backgroundColor)){
              if(this.currentMindMap.mm_type == 'kanban'){
                $('.stage-title')[index].style.color = '#000'
                let kanbanElement = color.children[0].children[0].children[0].children[0].children[0].children[1]
                kanbanElement.children[2].children[0].style.color = "#C14E57"
              }
            color.style.color = '#000'
            } else {
              color.style.color = '#fff'
              if(this.currentMindMap.mm_type == 'kanban'){
                let kanbanElement = color.children[0].children[0].children[0].children[0].children[0].children[1]
                $('.stage-title')[index].style.color = '#fff'
                kanbanElement.children[0].children[0].style.color = "#948A85"
                kanbanElement.children[1].children[0].style.color = "#BE7917"
                kanbanElement.children[2].children[0].style.color = "#168C80"
              } else if (this.currentMindMap.mm_type == 'tree_map'){
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
              } else if (this.currentMindMap.mm_type == 'flowmap' || this.currentMindMap.mm_type == 'tree_chart'){
                let nodeElement = color.children[0]
                nodeElement.children[0].style.filter = "invert(100%)"
                nodeElement.children[1].style.filter = "invert(100%)"
                nodeElement.children[2].style.filter = "invert(100%)"
                nodeElement.children[3].style.filter = "invert(100%)"
              }
            }
          })
        }, 50)
      },
      rgbToHex(bgColor) {
        let r = bgColor.substr(4,3)
        let g = bgColor.substr(9,3)
        let b = bgColor.substr(14,3)
        if(this.wc_hex_is_light("#" + this.componentToHex(r) + this.componentToHex(g) + this.componentToHex(b))){
          return true
        } else {
          return false
        }
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
      }
  }
}
