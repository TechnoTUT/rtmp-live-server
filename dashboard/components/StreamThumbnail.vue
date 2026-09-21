<template>
  <div class="preview-wrapper">
    <div v-if="!active" class="preview-placeholder">
      <span>OFFLINE</span>
    </div>
    <div v-else class="image-container">
      <!-- 30 FPS Smooth MJPEG stream via single HTTP persistent connection -->
      <img
        :src="streamUrl"
        alt="Live Preview"
        class="stream-thumb-img"
        @error="onImageError"
      />
      <span class="live-tag">30 FPS</span>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'

const props = defineProps<{
  streamName: string
  active: boolean
}>()

const streamUrl = computed(() => {
  if (!props.active) return ''
  return `/mjpeg?stream=${encodeURIComponent(props.streamName)}`
})

const onImageError = (e: Event) => {
  const target = e.target as HTMLImageElement
  if (target) {
    target.style.opacity = '0.5'
  }
}
</script>

<style scoped>
.preview-wrapper {
  width: 140px;
  height: 80px;
  background: #1a202c;
  border-radius: 4px;
  overflow: hidden;
  position: relative;
  border: 1px solid #cbd5e0;
}

.preview-placeholder {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 11px;
  color: #718096;
  font-weight: 600;
  background: #2d3748;
}

.image-container {
  width: 100%;
  height: 100%;
  position: relative;
  background: #000;
}

.stream-thumb-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
}

.live-tag {
  position: absolute;
  top: 4px;
  left: 4px;
  background: rgba(49, 130, 206, 0.9);
  color: white;
  font-size: 9px;
  font-weight: bold;
  padding: 1px 4px;
  border-radius: 2px;
  letter-spacing: 0.5px;
}
</style>
