<template>
  <div class="render-container" id="remoteSteamView">
    <img src="https://zego-ai.oss-cn-shanghai.aliyuncs.com/agent-avatar/38597_1740990880443-20250303-163355.jpeg" alt="normal" />
  </div>
</template>
<script setup lang="ts">
</script>
<style scoped>
  .render-container {
    position: relative;
    width: 234px;
    height: 416px;
  }
  .render-container img {
    position: absolute;
    left: 0;
    right: 0;
    top: 0;
    bottom: 0;
    width: 100%;
    height: 100%;
    object-fit: cover;
  }
</style>