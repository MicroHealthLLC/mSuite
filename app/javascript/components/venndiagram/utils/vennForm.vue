<template>
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
</template>
<script>
  export default{
    data(){
      return {
        dataSet: {
          sets: '',
          value: 0,
          name: '',
        }
      }
    },
    methods: {
      addNewValue(){
        this.$emit("addNewValue", this.dataSet)
        this.dataSet.sets  = ''
        this.dataSet.name  = ''
        this.dataSet.value = 0
      }
    }
  }
</script>
<style>

</style>
