<template>
  <div>
    <sweet-modal ref="lockModal" class="of_v" hide-close-button blocking>
      <h5 class="mt-2">Sorry, this Mindmap is permanently locked. Please contact the Administrator for further assistance.</h5>
      <span class="stamp is-nope mt-4">Permanently Locked</span>
      <button slot="button" @click="goHome" class="btn btn-secondary">Home Page</button>
    </sweet-modal>
  </div>
</template>

<script>
  import "../common/styles/permanent_lock.css"
  export default {
    mounted() {
      this.$refs['lockModal'].open()
    },
    methods: {
      goHome() {
        window.open(`/`, "_self")
      }
    },
    watch: {
      delayTime: {
        handler(value){
          this.displayTime = value
        }
      }
    }
  }
</script>
