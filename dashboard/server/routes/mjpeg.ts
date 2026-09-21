import { defineEventHandler, getQuery } from 'h3'
import { spawn } from 'child_process'

export default defineEventHandler((event) => {
  const query = getQuery(event)
  const stream = (query.stream as string) || 'test'

  // Set MJPEG streaming headers
  const res = event.node.res
  res.writeHead(200, {
    'Content-Type': 'multipart/x-mixed-replace; boundary=--ffmpegframe',
    'Cache-Control': 'no-cache, no-store, must-revalidate',
    'Connection': 'close',
    'Pragma': 'no-cache'
  })

  // Spawn ffmpeg to pull RTMP and output 30fps MJPEG stream to stdout
  const rtmpUrl = `rtmp://localhost:1935/live/${stream}`
  const ffmpeg = spawn('ffmpeg', [
    '-loglevel', 'error',
    '-fflags', 'nobuffer',
    '-flags', 'low_delay',
    '-i', rtmpUrl,
    '-vf', 'fps=30,scale=240:135',
    '-q:v', '5',
    '-f', 'mpjpeg',
    '-boundary_tag', 'ffmpegframe',
    'pipe:1'
  ])

  ffmpeg.stdout.pipe(res)

  const cleanup = () => {
    try {
      ffmpeg.kill('SIGKILL')
    } catch {}
  }

  event.node.req.on('close', cleanup)
  event.node.req.on('end', cleanup)
})
