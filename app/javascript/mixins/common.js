export default {
  created() {
   this.getUniqueColors();
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
    }
  }
}
