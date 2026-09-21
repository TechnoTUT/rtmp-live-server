import { defineEventHandler, getQuery, createError, sendStream } from 'h3'

export default defineEventHandler(async (event) => {
  const query = getQuery(event)
  const stream = (query.stream as string) || 'test'

  // Validate stream name to prevent path traversal
  if (!/^[a-zA-Z0-9_-]+$/.test(stream)) {
    throw createError({ statusCode: 400, statusMessage: 'Invalid stream name' })
  }

  // Fetch thumbnail from internal Nginx
  try {
    const nginxRes = await fetch(`http://127.0.0.1:8080/thumbnails/${encodeURIComponent(stream)}.jpg`)
    if (!nginxRes.ok) {
      throw createError({ statusCode: 404, statusMessage: 'Thumbnail not available' })
    }

    const res = event.node.res
    res.writeHead(200, {
      'Content-Type': 'image/jpeg',
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      'Pragma': 'no-cache',
      'Expires': '0'
    })

    if (nginxRes.body) {
      // Stream arrayBuffer or body directly to response
      const buffer = Buffer.from(await nginxRes.arrayBuffer())
      res.end(buffer)
    } else {
      res.end()
    }
  } catch (err: any) {
    if (err.statusCode) throw err
    throw createError({ statusCode: 502, statusMessage: 'Failed to fetch thumbnail' })
  }
})
