<template>
  <sweet-modal ref="RecurringCalendarEventModal" class="of_v">
    <div class="sweet_model_icon_div">
      <div class="radius_circle bg-warning center_flex mlr_a">
        <i class="material-icons text-white">delete</i>
      </div>
    </div>
    <h3 class="f_smooth_auto">Add Recurrence</h3>
    <div>
      <span>
        <p>Repeat Every <input type="number" value="1" class="w-10"/>
          <select name="cars" id="cars">
            <option value="Week">Week</option>
            <option value="Month">Month</option>
            <option value="Year">Year</option>
          </select>
        </p> 
      </span>
      <span>
        <p> Repeat on</p>
        <p>
          <span class="day">S</span>
          <span class="day">M</span>
          <span class="day">T</span>
          <span class="day">W</span>
          <span class="day">T</span>
          <span class="day">F</span>
          <span class="day">S</span>
        </p>
      </span>
      <span>
        <p>Ends</p>
      <div>
        <input type="radio" id="never" name="drone" value="never"checked>
        <label for="never">Never</label>
      </div>

    <div>
      <input type="radio" id="on" name="drone" value="on">
      <label for="on">On</label>
    </div>

    <div>
      <input type="radio" id="after" name="drone" value="after">
      <label for="after">After</label>
    </div>
      </span>
    </div>    
    <div class="center_flex mt_2">
      <a
        href="javascript:;"
        class="btn_2 bg-danger text-white mr_1"
        @click.stop="deleteMindmap"
      >
        <i class="material-icons mr-1">done</i>
        Continue
      </a>
      <a
        href="javascript:;"
        class="btn_2 bg-primary text-white mr_1"
        @click.stop="closeMapModal"
      >
        <i class="material-icons mr-1">cancel</i>
        Cancel
      </a>
    </div>
  </sweet-modal>
</template>

<script>
  export default {
    Name: "RecurringCalendarEventModal",
    methods: {
      deleteMindmap() {
        this.$emit('delete-mindmap')
        this.closeMapModal()
      },
      closeMapModal() {
        this.$refs.deleteMapModal.close()
      }
    }
  }
</script>
<style>
  .day{
  background-color:powderblue;
  border-radius: 50%;
  padding: 1vh 1vh;
}
</style>
