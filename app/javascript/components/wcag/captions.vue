<template>
  <div id="captions" v-if="isEnableCaption" class="notification info">
    <div class="cancelButton">
      <i v-if="mainBubble" class="fas fa-times" @click="isEnableCaption = false"></i>
    </div>
    <h1 class="title">{{ heading }}</h1>
    <div class="content">{{ msg }}</div>
  </div>
</template>

<script>
export default {
  name: 'captions',
  props: ['heading','msg','mainBubble'],
  data () {
    return {
      isEnableCaption: true,
    }
  },
  computed: {
    currentMindMap(){
      return this.$store.getters.getMsuite
    }
  },
  mounted(){
    let navHeight = document.getElementById('nav').offsetHeight
    document.getElementById('captions').style.top = `calc(1vh + ${navHeight}px)`
  },
  watch: {
    currentMindMap: {
      handler(value){
        if(value.nodes && value.nodes.length > 1) this.isEnableCaption = false
      }, deep: true
    }
  }
}
</script>

<style lang="scss" scoped>
  @import "./captions.scss";
</style>
