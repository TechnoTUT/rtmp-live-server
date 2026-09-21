<template>
  <div class="preview-wrapper">
    <div v-if="!active" class="preview-placeholder">
      <span>OFFLINE</span>
    </div>
    <div v-else class="canvas-container">
      <!-- Low FPS lightweight render target -->
      <canvas
        ref="canvasElement"
        width="140"
        height="80"
        class="stream-thumb-canvas"
      ></canvas>
      <span class="live-tag">LIVE</span>

      <!-- Hidden video element for lightweight background frame extraction -->
      <video
        ref="videoElement"
        muted
        autoplay
        playsinline
        style="display: none;"
      ></video>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, watch } from 'vue'
import Hls from 'hls.js'

const props = defineProps<{
  streamName: string
  active: boolean
}>()

const canvasElement = ref<HTMLCanvasElement | null>(null)
const videoElement = ref<HTMLVideoElement | null>(null)
let hls: Hls | null = null
let captureTimer: any = null

const captureFrame = () => {
  if (!props.active) return
  const video = videoElement.value
  const canvas = canvasElement.value
  if (!video || !canvas) return

  if (video.readyState >= 2 && video.videoWidth > 0) {
    const ctx = canvas.getContext('2d', { alpha: false })
    if (ctx) {
      // Draw frame into miniature 140x80 canvas (1 FPS)
      ctx.drawImage(video, 0, 0, canvas.width, canvas.height)
    }
  }
}

const startPlayer = () => {
  if (!props.active || !videoElement.value) return

  const src = `http://localhost:8080/hls/${props.streamName}.m3u8`

  if (hls) {
    hls.destroy()
    hls = null
  }

  if (Hls.isSupported()) {
    hls = new Hls({
      maxBufferLength: 0.5,
      maxMaxBufferLength: 1,
      liveSyncDurationCount: 1,
      enableWorker: true,
      lowLatencyMode: true,
      backBufferLength: 0
    })

    hls.loadSource(src)
    hls.attachMedia(videoElement.value)
    hls.on(Hls.Events.MANIFEST_PARSED, () => {
      videoElement.value?.play().catch(() => {})
    })
    hls.on(Hls.Events.ERROR, (_event, data) => {
      if (data.fatal) {
        hls?.destroy()
        hls = null
      }
    })
  } else if (videoElement.value.canPlayType('application/vnd.apple.mpegurl')) {
    videoElement.value.src = src
    videoElement.value.play().catch(() => {})
  }

  // 1 FPS periodic snapshot extraction to keep CPU/GPU load near zero
  if (captureTimer) clearInterval(captureTimer)
  captureTimer = setInterval(captureFrame, 1000)
}

const stopPlayer = () => {
  if (captureTimer) {
    clearInterval(captureTimer)
    captureTimer = null
  }
  if (videoElement.value) {
    videoElement.value.pause()
    videoElement.value.removeAttribute('src')
    videoElement.value.load()
  }
  if (hls) {
    hls.destroy()
    hls = null
  }
}

watch(() => props.active, (isActive) => {
  if (isActive) {
    startPlayer()
  } else {
    stopPlayer()
  }
})

onMounted(() => {
  startPlayer()
})

onUnmounted(() => {
  stopPlayer()
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

.canvas-container {
  width: 100%;
  height: 100%;
  position: relative;
}

.stream-thumb-canvas {
  width: 100%;
  height: 100%;
  object-fit: cover;
  background: #000;
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
