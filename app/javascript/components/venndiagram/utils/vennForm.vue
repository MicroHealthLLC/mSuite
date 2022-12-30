<template>
  <div>
    <b-form @submit.prevent="addNewValue" class="mt-1">
      <b-row>
        <b-col cols="4" class="todo-field">
          <b-form-input
            v-model="dataSet.sets"
            type="text"
            placeholder="Enter Sets with commas"
          >
          </b-form-input>
        </b-col>
        <b-col cols="2">
            <b-form-input
              id="input"
              class="w-100"
              v-model='dataSet.value'
              placeholder="value"
              type="number"
              ></b-form-input>
        </b-col>
        <b-col cols="3">
            <b-form-input
              id="input"
              class="w-100"
              v-model='dataSet.name'
              placeholder="Enter Name of New Set"
              type="text"
              ></b-form-input>
        </b-col>
        <b-col cols="3" class="d-flex flex-row justify-content-end">
          <b-button v-b-tooltip.hover title="Save" type="submit" variant="success"> <i class="fas fa-check"></i> </b-button>
        </b-col>
      </b-row>
    </b-form>
    <sweet-modal ref="dataErrorModal" class="of_v" icon="error">
      {{ msgErr }}
    </sweet-modal>
  </div>
</template>
<script>
  export default{
    data(){
      return {
        msgErr: '',
        dataSet: {
          sets: '',
          value: 0,
          name: '',
        }
      }
    },
    methods: {
      addNewValue(){
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
      },
      afterSaveReset(){
        this.dataSet = {sets: '', name: '', value: 0}
      }
    }
  }
</script>
<style>

</style>
