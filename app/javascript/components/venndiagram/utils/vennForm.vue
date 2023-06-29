<template>
  <div>
    <b-row>
      <b-col cols="6">
        <b-form @submit.prevent="addNewSets" class="mt-5">
          <!-- <label class="mr-sm-2" for="add-set-btn">Create Set</label> -->
          <b-row align-v="center">
            <b-col cols="8">
              <b-form-group id="set-input-group" label="Create Set" label-for="set-input"
                description="Enter Name for New Set">
                <b-form-input id="set-input" v-model="setName" type="text">
                </b-form-input>
              </b-form-group>
            </b-col>
            <b-col cols="4">
              <b-button id="add-set-btn" v-b-tooltip.hover title="Create Set" type="submit" variant="success"
                class="mb-2 p-1 pr-2" size="lg"><i
                  class="fa-solid fa-plus fa-2xs"></i>
                  <i class="fa-light fa-circle fa-lg"></i></b-button>
            </b-col>
          </b-row>

          <!-- <b-button v-if="data.length > 0" class="ml-3 mt-3" @click="showSetInput = false">Go to Link Selection</b-button> -->
        </b-form>
      </b-col>
      <b-col v-if="data.length > 1" cols="6">
        <b-form @submit.prevent="addNewLinks" class="mt-5">
          <b-row align-v="center">
            <b-col cols="9">
              <b-form-group id="links-input-group" label="Create Set Link" label-for="links-input"
                description="Click the sets that you would like to link">
                <b-form-input id="links-input" v-model="link" type="text">
                </b-form-input>
              </b-form-group>
            </b-col>
            <b-col cols="3">
              <b-button v-b-tooltip.hover title="Create Link" type="submit" variant="success" size="lg" class="mb-2 p-1 pr-2"><i
                  class="fa-solid fa-plus fa-2xs"></i><i
                  class="fa-light fa-diagram-venn fa-lg"></i></b-button>
            </b-col>
          </b-row>
          <!-- <b-button class="ml-3 mt-3" @click="showSetInput = true">Go back to Set Creation</b-button> -->
        </b-form>
      </b-col>
    </b-row>
    <sweet-modal ref="dataErrorModal" class="of_v" icon="error">
      {{ msgErr }}
    </sweet-modal>
  </div>
</template>
<script>

export default {
  props: {
    data: Object
  },
  data() {
    return {
      msgErr: '',
      dataSet: {
        sets: '',
        value: 1,
        name: '',
      },
      //showSetInput: true,
      numOfSets: 1,
      setName: '',
      setNames: [],
      link: ''
    }
  },
  watch: {
    data() {
      if (this.data) {
        console.log(this.data)
      }
    }
  },
  /* mounted() {
    if (this.data.length > 0) {
      console.log(this.data)
      this.showSetInput = false
    }
  }, */
  methods: {
    /* addNewValue(){
      if(this.dataSet.value > 0 && this.dataSet.sets != ''){
        if(this.dataSet.sets.includes(',')){
          if(this.dataSet.name  != ''){
            this.$emit("addNewValue", this.dataSet)
            this.afterSaveReset()
          } else {
            this.msgErr = 'Name also Required'
            this.$refs["dataErrorModal"].open()
            return
          }
        } else {
        this.$emit("addNewValue", this.dataSet)
        this.afterSaveReset()
        }
      } else if(this.dataSet.value < 1){
        this.msgErr = 'Number must be greater than 0.'
        this.$refs["dataErrorModal"].open()
      } else {
        this.msgErr = "Sets must be Unique."
        this.$refs["dataErrorModal"].open()
      }
    }, */
    addNewSets() {
        let setNum = this.data.filter(d => d.sets.length == 1).length
        console.log(setNum)
        let setName = this.setName == '' ? String.fromCharCode(65 + setNum) : this.setName.toUpperCase()
        //let newVal = this.numOfSets + 1
        /* for (let i = 0; i < this.numOfSets; i++) { */
        let randomColor = Math.floor(Math.random() * 16777215).toString(16)
        let set = {
          sets: setName,
          value: 15,
          name: setName,
          color: `#${randomColor}`
        }
        this.$emit("addNewValue", set)
        this.setName = ''
        //this.showSetInput = false
        //}
         /* else {
        this.msgErr = "Name must not be empty"
        this.$refs["dataErrorModal"].open()
      } */
    },
    addNewLinks() {
      if (this.link != '') {
        if (this.link.match(/,/g)) {
          let linkUpCase = this.link.replace(/ /g, '').toUpperCase()
          if (this.checkForSets(linkUpCase)) {
            let linkName = linkUpCase.split(",").map(String).sort()
            let randomColor = Math.floor(Math.random() * 16777215).toString(16)
            let val = this.setVal(linkUpCase.match(/,/g).length)
            let set = {
              sets: linkName.join(","),
              value: val,
              name: linkName.join(" ∩ "),
              color: `#${randomColor}`
            }
            this.$emit("addNewValue", set)
            this.link = ''
          } else {
            this.msgErr = "Links can only include prexisting sets"
            this.$refs["dataErrorModal"].open()
          }
        } else {
          this.msgErr = "Links must include comma"
          this.$refs["dataErrorModal"].open()
        }
      } else {
        this.msgErr = "Cannot be blank"
        this.$refs["dataErrorModal"].open()
      }
    },
    checkForSets(linkStr) {
      let linkArr = linkStr.split(",")
      let setArr = this.data.filter(d => d.sets.length == 1).map(m => m.sets[0])
      console.log(linkArr, setArr)
      return linkArr.every(l => setArr.includes(l))
    },
    setVal(val) {
      return val == 1 ? 4 :
        val == 2 ? 3 :
          val == 3 ? 2 :
            val == 4 ? 1 : 1
    },
    afterSaveReset() {
      this.dataSet = { sets: '', name: '', value: 0 }
    }
  }
}
</script>
<style>

</style>
