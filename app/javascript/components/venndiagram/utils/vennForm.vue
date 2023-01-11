<template>
  <div>
    <b-form v-if="showSetInput" @submit.prevent="addNewSets" class="mt-1 w-50">
      <!-- <b-form-group id="sets-input-group" label="Enter Set" label-for="sets-input"
        description="Enter sets, then enter links with sets seperated by commas">
        <b-form-input id="sets-input" v-model="dataSet.sets" type="text">
        </b-form-input>
      </b-form-group>
      <b-form-group id="name-input-group" label="Enter Name for Set" label-for="name-input">
        <b-form-input id="name-input" class="w-100" v-model='dataSet.name' type="text"></b-form-input>
      </b-form-group>
      <b-form-group id="value-input-group" label="Enter Value" label-for="value-input">
        <b-form-input id="value-input" class="w-50" v-model='dataSet.value' type="number"></b-form-input>
      </b-form-group> -->
      <b-form-group id="num-sets-input-group" label="Number of sets to add" label-for="num-sets-input" description="How many sets would you like to add?">
        <b-form-input id="num-sets-input" v-model="numOfSets" type="number" min="1" max="5">
        </b-form-input>
      </b-form-group>
      <b-button v-b-tooltip.hover title="Save & Proceed" type="submit" variant="success"> <i class="fas fa-check"></i></b-button>
      <b-button v-if="data.length > 0" @click="showSetInput = false">Go to Link Selection</b-button>
    </b-form>
    <b-form v-else @submit.prevent="addNewLinks" class="mt-1 w-50">
      <b-form-group id="links-input-group" label="Create Set Link" label-for="links-input"
        description="Create set links by entering set names seperated by a comma ">
        <b-form-input id="links-input" v-model="link" type="text">
        </b-form-input>
      </b-form-group>
      <b-button v-b-tooltip.hover title="Apply" type="submit" variant="success"> <i class="fas fa-check"></i></b-button>
      <b-button @click="showSetInput = true">Go back to Set Creation</b-button>
    </b-form>
    <sweet-modal ref="dataErrorModal" class="of_v" icon="error">
      {{ msgErr }}
    </sweet-modal>
    </div>
</template>
<script>
  export default{
    props: {
      data: Object
    },
    data(){
      return {
        msgErr: '',
        dataSet: {
          sets: '',
          value: 1,
          name: '',
        },
        showSetInput: true,
        numOfSets: 0,
        link: ''
      }
    },
    watch: {
      data() {
        if(this.data) {
          console.log(this.data)
        }
      }
    },
    mounted() {
      if (this.data.length > 0) {
        console.log(this.data)
        this.showSetInput = false
      }
    },
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
        if (this.numOfSets != 0) {
          let setNum = this.data.filter(d => d.sets.length == 1).length
          console.log(setNum)
          //let newVal = this.numOfSets + 1
            for (let i = 0; i < this.numOfSets; i++) {
              let randomColor = Math.floor(Math.random() * 16777215).toString(16)
              let set = {
                sets: String.fromCharCode(65 + setNum + i),
                value: 5,
                name: String.fromCharCode(65 + setNum + i),
                color: `#${randomColor}`
              }
              this.$emit("addNewValue", set)
              this.showSetInput = false
            }
        } else {
          this.msgErr = "Number must be greater than 1"
          this.$refs["dataErrorModal"].open()
        }
      },
      addNewLinks() {
        if (this.link != '') {
          if (this.link.match(/,/g)) {
            let linkUpCase = this.link.toUpperCase()
            if (this.checkForSets(linkUpCase)) {
              let linkName = linkUpCase.split(",").map(String).sort().join(" ∩ ")
              let randomColor = Math.floor(Math.random()*16777215).toString(16)
              let set = {
                sets: linkUpCase,
                value: linkUpCase.match(/,/g).length + 2,
                name: linkName,
                color: `#${randomColor}`
              }
              this.$emit("addNewValue", set)
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
      afterSaveReset(){
        this.dataSet = {sets: '', name: '', value: 0}
      }
    }
  }
</script>
<style>

</style>
