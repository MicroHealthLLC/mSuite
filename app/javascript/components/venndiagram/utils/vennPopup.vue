<template>
  <div>
    <b-row class="mt-1">
      <b-col sm="3">
        <label>Name:</label>
      </b-col>
      <b-col sm="9">
        <input class="" type ="text" v-model="selectedSet.name"/>
      </b-col>
    </b-row>

    <b-row class="">
      <b-col sm="3">
        <label>Size:</label>
      </b-col>
      <b-col sm="9">
        <label for="range-id">{{ selectedSet.value }}</label>
        <input id="range-id" class="mt-1" type="range" min="1" max="30" v-model="selectedSet.value"/>
      </b-col>
    </b-row>

    <b-row class="">
      <b-col sm="3">
        <label>Sets:</label>
      </b-col>
      <b-col sm="9">
        <input class="mt-1" type ="text" v-model="selectedSet.sets"/>
      </b-col>
    </b-row>

    <b-row class="">
      <b-col sm="3">
        <label>Color:</label>
      </b-col>
      <b-col sm="9">
        <b-form-input class="mt-1" type ="color" v-model="selectedSet.color"></b-form-input>
      </b-col>
    </b-row>

    <div class="d-flex mt-2">
      <b-button class="w-50 my-1" variant="success" @click="$emit('updateSet',selectedSet)"> Update </b-button>
      <b-button class="w-50  m-1" variant="danger"  @click="$emit('deleteSet',selectedSet)"> Delete </b-button>
      <b-button class="my-1" v-b-tooltip.hover title="Cancel" variant="outline-danger" @click="$emit('closeEditBox')">
        <i class="fa fa-times" ></i>
      </b-button>
    </div>
  </div>
</template>
<script>
  export default{
    props:["selectedSet"],
  }

</script>
<style>

</style>
