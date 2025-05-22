<template>
  <div class="page-header">
    <div class="left">
      <el-button v-if="showBack" class="back-btn" text @click="handleBack">
        <el-icon><ArrowLeft /></el-icon>
      </el-button>
    </div>
    
    <div class="center">
      <h1 class="title">{{ title }}</h1>
    </div>
    
    <div class="right">
      <slot name="right"></slot>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ArrowLeft } from '@element-plus/icons-vue'

defineProps({
  title: {
    type: String,
    required: true
  },
  showBack: {
    type: Boolean,
    default: false
  }
})

const emit = defineEmits(['back'])

const handleBack = () => {
  emit('back')
}
</script>

<style scoped>
.page-header {
  display: flex;
  align-items: center;
  height: 56px;
  padding: 0 16px;
  background: #fff;
  border-bottom: 1px solid #eee;
}

.left {
  flex: 0 0 48px;
  display: flex;
  align-items: center;
}

.back-btn {
  font-size: 20px;
  padding: 8px;
  margin-left: -8px;
}

.center {
  flex: 1;
  text-align: center;
  margin: 0 16px;
}

.title {
  margin: 0;
  font-size: 16px;
  font-weight: 500;
  color: #333;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.right {
  flex: 0 0 48px;
  display: flex;
  justify-content: flex-end;
  align-items: center;
}

@media screen and (max-width: 768px) {
  .page-header {
    height: 48px;
    padding: 0 12px;
  }

  .left {
    flex: 0 0 40px;
  }

  .back-btn {
    font-size: 18px;
    padding: 6px;
  }

  .title {
    font-size: 15px;
  }

  .right {
    flex: 0 0 40px;
  }
}
</style>