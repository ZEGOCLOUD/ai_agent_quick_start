<template>
  <div class="app-container">
    <Quickstart />
  </div>
</template>
<script setup lang="ts">
import Quickstart from './components/Quickstart.vue'

</script>
<style scoped>
.app-container {
  max-width: 800px;
  margin: 0 auto;
  font-family: Arial, sans-serif;
}

h1 {
  color: #2c3e50;
  text-align: center;
  margin-bottom: 30px;
}
</style>
