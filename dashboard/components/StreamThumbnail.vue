<template>
  <div class="preview-wrapper">
    <div v-if="!active" class="preview-placeholder">
      <span>OFFLINE</span>
    </div>
    <div v-else class="image-container">
      <!-- Lightweight image tag: zero browser video-decoding load -->
      <img
        :src="currentSrc"
        alt="Live Preview"
        class="stream-thumb-img"
        @error="onImageError"
      />
      <span class="live-tag">LIVE</span>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, watch } from 'vue'

const props = defineProps<{
  streamName: string
  active: boolean
}>()

const currentSrc = ref('')
let timer: any = null

const updateThumbnail = () => {
  if (!props.active) return
  // Cache busting query parameter every 2 seconds
  currentSrc.value = `http://localhost:8080/thumbnails/${props.streamName}.jpg?t=${Date.now()}`
}

const onImageError = (e: Event) => {
  // If thumbnail is still generating, suppress broken image
  const target = e.target as HTMLImageElement
  if (target) {
    target.style.opacity = '0.5'
  }
}

watch(() => props.active, (isActive) => {
  if (isActive) {
    updateThumbnail()
    if (!timer) {
      timer = setInterval(updateThumbnail, 2000)
    }
  } else {
    if (timer) {
      clearInterval(timer)
      timer = null
    }
    currentSrc.value = ''
  }
}, { immediate: true })

onMounted(() => {
  if (props.active) {
    updateThumbnail()
    timer = setInterval(updateThumbnail, 2000)
  }
})

onUnmounted(() => {
  if (timer) {
    clearInterval(timer)
    timer = null
  }
})
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
  transition: opacity 0.2s ease;
}

.live-tag {
  position: absolute;
  top: 4px;
  left: 4px;
  background: rgba(229, 62, 62, 0.9);
  color: white;
  font-size: 9px;
  font-weight: bold;
  padding: 1px 4px;
  border-radius: 2px;
  letter-spacing: 0.5px;
}
</style>
