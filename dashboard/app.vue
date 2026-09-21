<template>
  <div class="dashboard-container">
    <!-- Header -->
    <header class="header">
      <div class="header-left">
        <h1 class="title">RTMP Live Dashboard</h1>
        <span v-if="data?.data" class="server-info">
          Nginx {{ data.data.nginxVersion }} / RTMP {{ data.data.nginxRtmpVersion }} (Uptime: {{ formatTime(data.data.uptime * 1000) }})
        </span>
      </div>

      <div class="header-controls">
        <div class="refresh-control">
          <label for="refresh-rate">Auto Refresh:</label>
          <select id="refresh-rate" v-model="refreshInterval" @change="resetTimer">
            <option :value="1000">1s</option>
            <option :value="2000">2s</option>
            <option :value="5000">5s</option>
            <option :value="0">Off</option>
          </select>
        </div>
        <button class="btn" :class="{ 'btn-loading': pending }" @click="fetchStats(true)">
          <span class="refresh-icon" :class="{ 'spin': pending }">🔄</span>
          <span>Refresh</span>
        </button>
      </div>
    </header>

    <!-- Global Bandwidth Cards -->
    <section v-if="data?.data" class="metrics-grid">
      <div class="metric-card">
        <span class="metric-label">Inbound Traffic</span>
        <span class="metric-value">{{ formatBps(data.data.bwIn) }}</span>
        <span class="metric-sub">Total: {{ formatBytes(data.data.bytesIn) }}</span>
      </div>
      <div class="metric-card">
        <span class="metric-label">Outbound Traffic</span>
        <span class="metric-value">{{ formatBps(data.data.bwOut) }}</span>
        <span class="metric-sub">Total: {{ formatBytes(data.data.bytesOut) }}</span>
      </div>
      <div class="metric-card">
        <span class="metric-label">Accepted Connections</span>
        <span class="metric-value">{{ data.data.naccepted }}</span>
        <span class="metric-sub">Total Handshakes</span>
      </div>
      <div class="metric-card">
        <span class="metric-label">Active Streams</span>
        <span class="metric-value">{{ totalActiveStreams }}</span>
        <span class="metric-sub">{{ totalClients }} total clients</span>
      </div>
    </section>

    <!-- Error State -->
    <div v-if="errorMsg" class="alert-box">
      <strong>Connection Error:</strong> {{ errorMsg }}
    </div>

    <!-- Streams Section -->
    <main class="content">
      <div v-for="app in data?.data?.applications" :key="app.name" class="app-section">
        <div class="app-header">
          <h2>Application: <code>/{{ app.name }}</code></h2>
          <span class="client-count">{{ app.nclients }} clients connected</span>
        </div>

        <div v-if="app.streams.length === 0" class="empty-state">
          No streams currently broadcasting. Send RTMP stream to <code>rtmp://&lt;host&gt;:1935/{{ app.name }}/&lt;stream-key&gt;</code>
        </div>

        <div v-else class="streams-table-wrapper">
          <table class="data-table">
            <thead>
              <tr>
                <th style="width: 150px;">Live Preview</th>
                <th>Stream Name</th>
                <th>Status</th>
                <th>Resolution / FPS</th>
                <th>Video Codec</th>
                <th>In Rate</th>
                <th>Clients</th>
                <th>Uptime</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              <template v-for="stream in app.streams" :key="stream.name">
                <tr :class="{ 'row-active': stream.active }">
                  <td>
                    <!-- Persistent Low-Footprint Live Preview -->
                    <StreamThumbnail :stream-name="stream.name" :active="stream.active" />
                  </td>
                  <td>
                    <span class="stream-name">
                      {{ stream.name || '[EMPTY]' }}
                    </span>
                  </td>
                  <td>
                    <span :class="['badge', stream.active ? 'badge-online' : 'badge-offline']">
                      {{ stream.active ? 'ONLINE' : 'OFFLINE' }}
                    </span>
                  </td>
                  <td>
                    <span v-if="stream.meta?.video">
                      {{ stream.meta.video.width }}x{{ stream.meta.video.height }} @ {{ Math.round(stream.meta.video.frame_rate) }}fps
                    </span>
                    <span v-else class="text-muted">-</span>
                  </td>
                  <td>
                    <span v-if="stream.meta?.video">
                      {{ stream.meta.video.codec }} ({{ formatBps(stream.bwVideo) }})
                    </span>
                    <span v-else class="text-muted">-</span>
                  </td>
                  <td>
                    <strong>{{ formatBps(stream.bwIn) }}</strong>
                  </td>
                  <td>{{ stream.nclients }}</td>
                  <td>{{ formatTime(stream.time) }}</td>
                  <td>
                    <button class="btn-sm" @click="toggleDetails(stream.name)">
                      {{ expandedStreams.has(stream.name) ? 'Hide Clients' : 'View Clients' }}
                    </button>
                  </td>
                </tr>

                <!-- Client Details Sub-table -->
                <tr v-if="expandedStreams.has(stream.name)" class="sub-table-row">
                  <td colspan="9">
                    <div class="client-details-box">
                      <h4>Connected Clients ({{ stream.clients.length }})</h4>
                      <table v-if="stream.clients.length > 0" class="client-table">
                        <thead>
                          <tr>
                            <th>ID</th>
                            <th>Role</th>
                            <th>Address</th>
                            <th>Flash/Client</th>
                            <th>Dropped Frames</th>
                            <th>Duration</th>
                          </tr>
                        </thead>
                        <tbody>
                          <tr v-for="client in stream.clients" :key="client.id">
                            <td>{{ client.id }}</td>
                            <td>
                              <span :class="['badge', client.publishing ? 'badge-pub' : 'badge-sub']">
                                {{ client.publishing ? 'Publisher' : 'Subscriber' }}
                              </span>
                            </td>
                            <td>{{ client.address }}</td>
                            <td>{{ client.flashver }}</td>
                            <td>
                              <span :class="{ 'drop-alert': client.dropped > 0 }">
                                {{ client.dropped }}
                              </span>
                            </td>
                            <td>{{ formatTime(client.time) }}</td>
                          </tr>
                        </tbody>
                      </table>
                      <div v-else class="text-muted">No individual client records.</div>
                    </div>
                  </td>
                </tr>
              </template>
            </tbody>
          </table>
        </div>
      </div>
    </main>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import Hls from 'hls.js'

interface StatResponse {
  success: boolean
  data?: any
  error?: string
}

const data = ref<StatResponse | null>(null)
const pending = ref(false)
const errorMsg = ref('')
const refreshInterval = ref(2000)
let timer: any = null

const expandedStreams = ref<Set<string>>(new Set())

const totalActiveStreams = computed(() => {
  if (!data.value?.data?.applications) return 0
  return data.value.data.applications.reduce((acc: number, app: any) => {
    return acc + app.streams.filter((s: any) => s.active).length
  }, 0)
})

const totalClients = computed(() => {
  if (!data.value?.data?.applications) return 0
  return data.value.data.applications.reduce((acc: number, app: any) => acc + (app.nclients || 0), 0)
})

const fetchStats = async (isManual = false) => {
  if (isManual) pending.value = true
  try {
    const res = await $fetch<StatResponse>('/api/stat')
    if (res.success) {
      data.value = res
      errorMsg.value = ''
    } else {
      errorMsg.value = res.error || 'Failed to fetch'
    }
  } catch (err: any) {
    errorMsg.value = err.message
  } finally {
    if (isManual) pending.value = false
  }
}

const resetTimer = () => {
  if (timer) clearInterval(timer)
  if (refreshInterval.value > 0) {
    timer = setInterval(fetchStats, refreshInterval.value)
  }
}

const toggleDetails = (streamName: string) => {
  if (expandedStreams.value.has(streamName)) {
    expandedStreams.value.delete(streamName)
  } else {
    expandedStreams.value.add(streamName)
  }
}

// Helpers
const formatBps = (bits: number | undefined) => {
  if (!bits) return '0 bps'
  if (bits >= 1000000000) return (bits / 1000000000).toFixed(2) + ' Gbps'
  if (bits >= 1000000) return (bits / 1000000).toFixed(2) + ' Mbps'
  if (bits >= 1000) return (bits / 1000).toFixed(1) + ' Kbps'
  return bits + ' bps'
}

const formatBytes = (bytes: number | undefined) => {
  if (!bytes) return '0 B'
  if (bytes >= 1073741824) return (bytes / 1073741824).toFixed(2) + ' GB'
  if (bytes >= 1048576) return (bytes / 1048576).toFixed(2) + ' MB'
  if (bytes >= 1024) return (bytes / 1024).toFixed(1) + ' KB'
  return bytes + ' B'
}

const formatTime = (ms: number | undefined) => {
  if (!ms || ms <= 0) return '0s'
  const sec = Math.floor(ms / 1000)
  const d = Math.floor(sec / 86400)
  const h = Math.floor((sec % 86400) / 3600)
  const m = Math.floor((sec % 3600) / 60)
  const s = sec % 60

  const parts = []
  if (d > 0) parts.push(`${d}d`)
  if (h > 0) parts.push(`${h}h`)
  if (m > 0) parts.push(`${m}m`)
  parts.push(`${s}s`)
  return parts.join(' ')
}

onMounted(() => {
  fetchStats()
  resetTimer()
})

onUnmounted(() => {
  if (timer) clearInterval(timer)
})
</script>

<style scoped>
.dashboard-container {
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
  padding: 24px;
  background-color: #f7f9fc;
  min-height: 100vh;
  color: #2d3748;
}

.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
}

.title {
  font-size: 22px;
  font-weight: 700;
  margin: 0;
}

.server-info {
  font-size: 13px;
  color: #718096;
}

.header-controls {
  display: flex;
  align-items: center;
  gap: 12px;
}

.refresh-control {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 13px;
}

.btn {
  padding: 6px 14px;
  background-color: #3182ce;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 13px;
  display: inline-flex;
  align-items: center;
  gap: 6px;
  min-width: 88px;
  justify-content: center;
  user-select: none;
}
.btn:hover { background-color: #2b6cb0; }
.btn:disabled { opacity: 0.6; cursor: not-allowed; }

.refresh-icon {
  display: inline-block;
  font-size: 12px;
  transition: transform 0.3s ease;
}

.spin {
  animation: spin 1s linear infinite;
}

@keyframes spin {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}

.btn-sm {
  padding: 3px 8px;
  font-size: 12px;
  border: 1px solid #cbd5e0;
  background: white;
  border-radius: 3px;
  cursor: pointer;
}
.btn-sm:hover { background: #edf2f7; }

.metrics-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 16px;
  margin-bottom: 28px;
}

.metric-card {
  background: white;
  padding: 16px;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
  display: flex;
  flex-direction: column;
}

.metric-label {
  font-size: 12px;
  color: #718096;
  text-transform: uppercase;
  font-weight: 600;
  margin-bottom: 4px;
}

.metric-value {
  font-size: 24px;
  font-weight: 700;
  color: #1a202c;
}

.metric-sub {
  font-size: 12px;
  color: #a0aec0;
  margin-top: 4px;
}

.alert-box {
  background: #fed7d7;
  color: #9b2c2c;
  padding: 12px;
  border-radius: 6px;
  margin-bottom: 20px;
}

.app-section {
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  margin-bottom: 24px;
  overflow: visible;
}

.app-header {
  padding: 14px 20px;
  background: #edf2f7;
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-bottom: 1px solid #e2e8f0;
}

.app-header h2 {
  font-size: 16px;
  margin: 0;
}

.empty-state {
  padding: 32px;
  text-align: center;
  color: #718096;
  font-size: 14px;
}

.data-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 13px;
}

.data-table th, .data-table td {
  padding: 10px 16px;
  text-align: left;
  border-bottom: 1px solid #edf2f7;
}

.data-table th {
  background: #f7fafc;
  color: #4a5568;
  font-weight: 600;
}

.stream-name {
  color: #2b6cb0;
  font-weight: 600;
  cursor: pointer;
  text-decoration: underline;
}

.badge {
  display: inline-block;
  padding: 2px 8px;
  border-radius: 12px;
  font-size: 11px;
  font-weight: 600;
}
.badge-online { background: #c6f6d5; color: #22543d; }
.badge-offline { background: #edf2f7; color: #718096; }
.badge-pub { background: #bee3f8; color: #2c5282; }
.badge-sub { background: #e2e8f0; color: #4a5568; }

.drop-alert { color: #e53e3e; font-weight: bold; }
.text-muted { color: #a0aec0; }

.sub-table-row td {
  background: #f8fafc;
  padding: 16px 24px;
}

.client-details-box h4 {
  margin: 0 0 10px 0;
  font-size: 13px;
}

.client-table {
  width: 100%;
  border-collapse: collapse;
  background: white;
  border: 1px solid #e2e8f0;
  font-size: 12px;
}
.client-table th, .client-table td {
  padding: 8px 12px;
  border-bottom: 1px solid #edf2f7;
}
</style>
