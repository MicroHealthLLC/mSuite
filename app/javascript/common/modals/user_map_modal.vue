<template>
  <sweet-modal ref="UserBoxModal">
    <div class="">
        <div class="form__group__parent field">
          <input
            type="input"
            ref="user"
            v-model="user"
            class="form__field"
            :placeholder="user"
            @blur="$refs['UserBoxModal'].close()"
            @keyup.enter="$refs['UserBoxModal'].close()"
            required />
          <label for="name" class="form__label">Tell Us About Yourself. Name Please...</label>
        </div>
      </div>
  </sweet-modal>
</template>
<script>

  export default {
    data(){
      return {
        user: ''
      }
    },
    mounted(){
      if(localStorage.user) this.user = localStorage.user
    },
    watch:{
      user(newName) {
        if (newName == ''){
          if(localStorage.userNumber == 'NaN') localStorage.userNumber = 1
          else localStorage.userNumber = parseInt(localStorage.userNumber) + 1
          newName = 'User ' + localStorage.userNumber
        }
        localStorage.user = newName;
      }
    },
  }

</script>
<style lang="scss">
  $primary: #AB9AFD;
  $secondary: #3F96FF;
  $gray: #9b9b9b;
  .form__group {
    position: relative;
    padding: 15px 0 0;
    margin-top: -5px;
    margin-left: 0;
    width: 50%;
  }
  .form__group__parent {
    position: relative;
    padding: 15px 0 0;
    margin-top: 10px;
    width: 100%;
  }
  .form__field {
    width: 100%;
    border: 0;
    border-bottom: 2px solid $gray;
    outline: 0;
    font-size: 15px;
    padding: 7px 0;
    background: transparent;
    transition: border-color 0.2s;

    &::placeholder {
      color: transparent;
    }

    &:placeholder-shown ~ .form__label {
      font-size: 12px;
      cursor: text;
      top: 30px;
    }
  }

  .form__label {
    position: absolute;
    top: 0;
    display: block;
    transition: 0.2s;
    font-size: 1rem;
    color: $gray;
  }

  .form__field:focus {
    ~ .form__label {
      position: absolute;
      top: 0;
      display: block;
      transition: 0.2s;
      font-size: 1rem;
      color: $primary;
      font-weight:700;
    }
    padding-bottom: 6px;
    font-weight: 700;
    border-width: 3px;
    border-image: linear-gradient(to right, $primary,$secondary);
    border-image-slice: 1;
  }
  /* reset input */
  .form__field{
    &:required,&:invalid { box-shadow:none; }
  }
  .btn-outline-primary {
    color: #aaaaaa;
    border: none !important;
    &:hover, &:focus, &:active{
      background: none !important;
      color: grey;
    }
  }
  .show > .btn-outline-primary.dropdown-toggle {
    color: grey;
    background: none !important;
    border: none !important;
  }
  .form__field {
    width: 100%;
    border: 0;
    border-bottom: 2px solid $gray;
    outline: 0;
    font-size: 15px;
    padding: 7px 0;
    background: transparent;
    transition: border-color 0.2s;

    &::placeholder {
      color: transparent;
    }

    &:placeholder-shown ~ .form__label {
      font-size: 12px;
      cursor: text;
      top: 30px;
    }
  }
  .form__field:focus {
    ~ .form__label {
      position: absolute;
      top: 0;
      display: block;
      transition: 0.2s;
      font-size: 1rem;
      color: $primary;
      font-weight:700;
    }
    padding-bottom: 6px;
    font-weight: 700;
    border-width: 3px;
    border-image: linear-gradient(to right, $primary,$secondary);
    border-image-slice: 1;
  }
  .form__field{
    &:required,&:invalid { box-shadow:none; }
  }
</style>
