<template>
	<div v-if="beta_status" class="badge-overlay">
		<span class="top-left badge red p-0">
      <a target="_blank" :href="beta_url" class="text-white">
        Beta
      </a>
    </span>
	</div>
</template>

<script>
	export default {
		data() {
			return {
				beta_status: Vue.prototype.$beta_status,
        beta_url: Vue.prototype.$beta_url
			}
    }
	}
</script>

<style scoped>
  /* ================== Badge Overlay CSS ========================*/
  .badge-overlay {
      position: absolute;
      left: 0%;
      top: 0px;
      /*width: 100%;*/
      /*height: 100%;*/

      -webkit-transition: width 1s ease, height 1s ease;
      -moz-transition: width 1s ease, height 1s ease;
      -o-transition: width 1s ease, height 1s ease;
      transition: width 0.4s ease, height 0.4s ease
  }

  .badge-overlay:hover {
  	cursor: pointer;
  }
  /* ================== Badge CSS ========================*/
  .badge {
      margin: 0;
      padding: 0;
      color: white;
      padding: 12px 18px;
      font-size: 18px;
      font-weight: 900;
      z-index: 10000;
      font-family: Arial, Helvetica, sans-serif;
      text-align: center;
      line-height: normal;
      text-transform: uppercase;
      background: #ed1b24;
      letter-spacing: 3px;
  }

  .badge::before, .badge::after {
      content: '';
      position: absolute;
      top: 0;
      margin: 0 -1px;
      width: 100%;
      height: 100%;
      background: inherit;
      min-width: 55px
  }

  .badge::before {
    right: 100%
  }

  .badge::after {
    left: 100%
  }

  /* ================== Badge Position CSS ========================*/


  .top-left {
    position: absolute;
    top: 0;
    left: 0;
    -ms-transform: translateX(-30%) translateY(0%) rotate(-45deg);
    -webkit-transform: translateX(-30%) translateY(0%) rotate(-45deg);
    transform: translateX(-30%) translateY(0%) rotate(-45deg);
    -ms-transform-origin: top right;
    -webkit-transform-origin: top right;
    transform-origin: top right;
  }

  /* ================== Badge color CSS ========================*/
  .badge.red {
  		/*background: rgb(22,87,93);*/
  		background: linear-gradient(0deg, rgba(22,87,93,1) 0%, rgba(121,173,197,0.9962359943977591) 100%);
      opacity: 0.9;
  }
</style>
