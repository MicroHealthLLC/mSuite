<template>
    <div>
      <sweet-modal ref="cloneModal" class="of_v" icon="clone" title="Clone">
        Select Month and year You want to clone into
        <date-picker v-model="cloneDate" type="month" :format="format"></date-picker>

        <button slot="button" class="btn btn-info" @click="closeModal"> Cancel </button>
        <button slot="button" class="btn btn-success ml-2" @click="cloneMap"> Clone </button>
      </sweet-modal>
    </div>
  </template>
  
  <script>
  import DatePicker from 'vue2-datepicker';
  import 'vue2-datepicker/index.css';

    export default {
      name:"cloneModal",
      components: { DatePicker },
      data () {
        return{
        format    : 'MM/YYYY',
        cloneDate : new Date()
        }
      },
      methods:{
        cloneMap() {
          let month = this.cloneDate.getMonth() + 1
          let year = this.cloneDate.getFullYear()
          let data = {
            month :month,
            year  :year
          }
          this.$store.dispatch('setCloneMapDate', data)
          this.$refs['cloneModal'].close();
        },
        closeModal() {
          // window.open('/', "_self")
          this.$refs['cloneModal'].close();
        }
      }
    }
  </script>
  
