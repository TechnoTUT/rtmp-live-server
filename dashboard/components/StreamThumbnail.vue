<template>
  <div
    class="preview-wrapper"
    @mouseenter="onMouseEnter"
    @mouseleave="onMouseLeave"
  >
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

      <!-- Zoomed Hover Preview Overlay -->
      <transition name="zoom-fade">
        <div v-if="isHovered && currentSrc" class="hover-preview-popover">
          <div class="hover-preview-header">
            <span class="hover-stream-name">{{ streamName }}</span>
            <span class="hover-fps-badge">24 FPS LIVE</span>
          </div>
          <div class="hover-preview-img-box">
            <img
              :src="currentSrc"
              alt="Enlarged Live Preview"
              class="hover-preview-img"
            />
          </div>
        </div>
      </transition>
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
const isHovered = ref(false)
let timer: ReturnType<typeof setInterval> | null = null
let isFetching = false

const onMouseEnter = () => {
  if (props.active) {
    isHovered.value = true
  }
}

const onMouseLeave = () => {
  isHovered.value = false
}

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
    isHovered.value = false
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
  position: relative;
  border: 1px solid #cbd5e0;
  cursor: pointer;
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
  border-radius: 3px;
}

.stream-thumb-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
  border-radius: 3px;
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
  pointer-events: none;
}

/* Enlarged Hover Popover */
.hover-preview-popover {
  position: absolute;
  top: -20px;
  left: calc(100% + 14px);
  width: 360px;
  background: #1a202c;
  border-radius: 8px;
  box-shadow: 0 15px 35px rgba(0, 0, 0, 0.5), 0 3px 10px rgba(0, 0, 0, 0.3);
  border: 2px solid #4a5568;
  z-index: 1000;
  overflow: hidden;
  pointer-events: none;
}

.hover-preview-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 6px 10px;
  background: #2d3748;
  border-bottom: 1px solid #4a5568;
}

.hover-stream-name {
  font-size: 12px;
  font-weight: 700;
  color: #edf2f7;
}

.hover-fps-badge {
  font-size: 10px;
  font-weight: bold;
  color: #fff;
  background: #e53e3e;
  padding: 2px 6px;
  border-radius: 3px;
}

.hover-preview-img-box {
  width: 100%;
  height: 202px; /* 16:9 ratio for 360px width */
  background: #000;
}

.hover-preview-img {
  width: 100%;
  height: 100%;
  object-fit: contain;
  display: block;
}

/* Transition */
.zoom-fade-enter-active,
.zoom-fade-leave-active {
  transition: opacity 0.18s ease, transform 0.18s ease;
}

.zoom-fade-enter-from,
.zoom-fade-leave-to {
  opacity: 0;
  transform: scale(0.95) translateX(-6px);
}
</style>
