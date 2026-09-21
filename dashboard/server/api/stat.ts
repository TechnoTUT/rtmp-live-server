import { defineEventHandler } from 'h3'
import { XMLParser } from 'fast-xml-parser'

function maskIp(ip: string | undefined): string {
  if (!ip) return '-'
  if (ip.includes(':')) {
    // IPv6: mask host part
    const parts = ip.split(':')
    return parts.slice(0, 3).join(':') + ':****:****'
  }
  // IPv4
  const parts = ip.split('.')
  if (parts.length === 4) {
    return `${parts[0]}.${parts[1]}.*.*`
  }
  return ip
}

export default defineEventHandler(async (event) => {
  const config = useRuntimeConfig()
  const rtmpStatUrl = config.rtmpStatUrl || process.env.RTMP_STAT_URL || 'http://localhost:8080/stat'

  try {
    const response = await fetch(rtmpStatUrl, {
      headers: {
        'Cache-Control': 'no-cache'
      }
    })

    if (!response.ok) {
      throw new Error(`Failed to fetch RTMP stats: ${response.status} ${response.statusText}`)
    }

    const xmlData = await response.text()
    const parser = new XMLParser({
      ignoreAttributes: false,
      attributeNamePrefix: '@_'
    })
    const jsonObj = parser.parse(xmlData)

    // Normalize server / application / stream data
    const rtmp = jsonObj?.rtmp || {}
    let applications = rtmp?.server?.application || []
    if (!Array.isArray(applications)) {
      applications = [applications]
    }

    const apps = applications.map((app: any) => {
      let liveStreams = app?.live?.stream || []
      if (!Array.isArray(liveStreams)) {
        liveStreams = liveStreams ? [liveStreams] : []
      }

      const streams = liveStreams.map((s: any) => {
        let clients = s?.client || []
        if (!Array.isArray(clients)) {
          clients = clients ? [clients] : []
        }

        return {
          name: s.name,
          time: s.time,
          bwIn: s.bw_in,
          bwOut: s.bw_out,
          bytesIn: s.bytes_in,
          bytesOut: s.bytes_out,
          bwVideo: s.bw_video,
          bwAudio: s.bw_audio,
          meta: s.meta,
          nclients: s.nclients,
          active: 'active' in s,
          clients: clients.map((c: any) => ({
            id: c.id,
            address: maskIp(c.address),
            time: c.time,
            flashver: c.flashver,
            dropped: c.dropped,
            avsync: c.avsync,
            timestamp: c.timestamp,
            publishing: 'publishing' in c
          }))
        }
      })

      return {
        name: app.name,
        nclients: app?.live?.nclients || 0,
        streams
      }
    })

    return {
      success: true,
      data: {
        nginxVersion: rtmp.nginx_version,
        nginxRtmpVersion: rtmp.nginx_rtmp_version,
        uptime: rtmp.uptime,
        naccepted: rtmp.naccepted,
        bwIn: rtmp.bw_in,
        bwOut: rtmp.bw_out,
        bytesIn: rtmp.bytes_in,
        bytesOut: rtmp.bytes_out,
        applications: apps
      }
    }
  } catch (err: any) {
    return {
      success: false,
      error: err.message
    }
  }
})
