<template>
  <div class="preview-wrapper">
    <div v-if="!active" class="preview-placeholder">
      <span>OFFLINE</span>
    </div>
    <div v-else class="image-container">
      <img
        :src="currentSrc"
        alt="Live Preview"
        class="stream-thumb-img"
        @load="onImageLoaded"
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
let timer: ReturnType<typeof setInterval> | null = null
let isFetching = false

const updateFrame = () => {
  if (!props.active || isFetching) return
  isFetching = true
  const nextSrc = `/api/thumbnail?stream=${encodeURIComponent(props.streamName)}&t=${Date.now()}`
  
  // Preload image off-DOM to eliminate any flicker
  const img = new Image()
  img.onload = () => {
    currentSrc.value = nextSrc
    isFetching = false
  }
  img.onerror = () => {
    isFetching = false
  }
  img.src = nextSrc
}

const startPolling = () => {
  stopPolling()
  if (props.active) {
    updateFrame()
    // Poll at 24 fps (~41ms) - cinematic smooth preview with iGPU acceleration
    timer = setInterval(updateFrame, 41)
  }
}

const stopPolling = () => {
  if (timer) {
    clearInterval(timer)
    timer = null
  }
  isFetching = false
}

watch(() => props.active, (val) => {
  if (val) {
    startPolling()
  } else {
    stopPolling()
    currentSrc.value = ''
  }
})

const onImageLoaded = () => {
  // successfully rendered
}

const onImageError = (e: Event) => {
  const target = e.target as HTMLImageElement
  if (target) {
    target.style.opacity = '0.5'
  }
}

onMounted(() => {
  if (props.active) {
    startPolling()
  }
})

onUnmounted(() => {
  stopPolling()
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
