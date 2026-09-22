<template>
  <div class="dashboard-container" :class="{ dark: isDark }">
    <!-- Top Navigation Bar -->
    <header class="top-nav">
      <div class="nav-left">
        <a href="/" class="brand-link">
          <!-- Light theme logo -->
          <img
            v-if="!isDark"
            src="/logo.svg"
            alt="TechnoTUT"
            class="brand-logo"
          />
          <!-- Dark theme logo -->
          <img
            v-else
            src="/logo_dark.svg"
            alt="TechnoTUT"
            class="brand-logo"
          />
          <div class="divider"></div>
          <div>
            <h1 class="brand-title">RTMP Live Server</h1>
            <p class="brand-sub">The Utopia Tone Streaming Network</p>
          </div>
        </a>
      </div>

      <div class="nav-right">
        <div v-if="data?.data" class="server-status-pill">
          <span class="status-dot"></span>
          <span>Nginx {{ data.data.nginxVersion }} / RTMP {{ data.data.nginxRtmpVersion }} (Up: {{ formatTime(data.data.uptime * 1000) }})</span>
        </div>

        <div class="refresh-control">
          <label for="refresh-rate">Auto:</label>
          <select id="refresh-rate" v-model="refreshInterval" @change="resetTimer">
            <option :value="1000">1s</option>
            <option :value="2000">2s</option>
            <option :value="5000">5s</option>
            <option :value="0">Off</option>
          </select>
        </div>

        <button class="btn-refresh" :class="{ 'btn-loading': pending }" title="Refresh data" @click="fetchStats(true)">
          <svg class="refresh-icon" :class="{ 'spin': pending }" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
          </svg>
          <span>Refresh</span>
        </button>

        <!-- Dark/Light Theme Toggle Button -->
        <button
          class="theme-toggle-btn"
          title="Toggle Light / Dark Mode"
          @click="toggleTheme"
        >
          <!-- Sun icon when dark (click to switch to light) -->
          <svg v-if="isDark" class="theme-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z" />
          </svg>
          <!-- Moon icon when light (click to switch to dark) -->
          <svg v-else class="theme-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z" />
          </svg>
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

// Theme state
const isDark = ref(false)

const applyTheme = (dark: boolean) => {
  if (typeof document !== 'undefined') {
    if (dark) {
      document.documentElement.classList.add('dark')
    } else {
      document.documentElement.classList.remove('dark')
    }
  }
}

const toggleTheme = () => {
  isDark.value = !isDark.value
  applyTheme(isDark.value)
  if (typeof localStorage !== 'undefined') {
    localStorage.setItem('theme', isDark.value ? 'dark' : 'light')
  }
}

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
  if (typeof localStorage !== 'undefined') {
    const savedTheme = localStorage.getItem('theme')
    if (savedTheme === 'dark' || (!savedTheme && window.matchMedia('(prefers-color-scheme: dark)').matches)) {
      isDark.value = true
    }
  }
  applyTheme(isDark.value)
  fetchStats()
  resetTimer()
})

onUnmounted(() => {
  if (timer) clearInterval(timer)
})
</script>

<style scoped>
/* Base Dashboard Theme */
.dashboard-container {
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
  padding: 0 0 32px 0;
  background-color: #f8fafc;
  min-height: 100vh;
  color: #0f172a;
  transition: background-color 0.2s ease, color 0.2s ease;
}

.dashboard-container.dark {
  background-color: #0b0f19;
  color: #f1f5f9;
}

/* Top Navigation Bar */
.top-nav {
  position: sticky;
  top: 0;
  z-index: 30;
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px 24px;
  background-color: rgba(255, 255, 255, 0.9);
  backdrop-filter: blur(8px);
  -webkit-backdrop-filter: blur(8px);
  border-bottom: 1px solid #e2e8f0;
  box-shadow: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
  transition: background-color 0.2s ease, border-color 0.2s ease;
}

.dashboard-container.dark .top-nav {
  background-color: rgba(15, 23, 42, 0.85);
  border-bottom-color: #1e293b;
}

.nav-left {
  display: flex;
  align-items: center;
  gap: 20px;
}

.brand-link {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 2px 0;
  text-decoration: none;
  color: inherit;
}

.brand-logo {
  height: 48px;
  width: auto;
  max-width: 200px;
  object-fit: contain;
  display: block;
}

.divider {
  height: 32px;
  width: 1px;
  background-color: #e2e8f0;
}

.dashboard-container.dark .divider {
  background-color: #334155;
}

.brand-title {
  font-size: 16px;
  font-weight: 700;
  letter-spacing: -0.01em;
  margin: 0;
  color: #0f172a;
  display: flex;
  align-items: center;
  gap: 8px;
}

.dashboard-container.dark .brand-title {
  color: #f8fafc;
}

.brand-sub {
  font-size: 11px;
  color: #64748b;
  margin: 2px 0 0 0;
}

.dashboard-container.dark .brand-sub {
  color: #94a3b8;
}

/* Nav Right & Controls */
.nav-right {
  display: flex;
  align-items: center;
  gap: 12px;
}

.server-status-pill {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 6px 12px;
  font-size: 12px;
  font-weight: 500;
  color: #475569;
  background-color: #f1f5f9;
  border-radius: 9999px;
  border: 1px solid #e2e8f0;
}

.dashboard-container.dark .server-status-pill {
  background-color: #1e293b;
  color: #cbd5e1;
  border-color: #334155;
}

.status-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background-color: #10b981;
  box-shadow: 0 0 6px #10b981;
}

.refresh-control {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 13px;
  color: #64748b;
}

.dashboard-container.dark .refresh-control {
  color: #94a3b8;
}

.refresh-control select {
  padding: 4px 8px;
  font-size: 13px;
  border-radius: 6px;
  border: 1px solid #cbd5e1;
  background-color: white;
  color: #0f172a;
  outline: none;
  cursor: pointer;
}

.dashboard-container.dark .refresh-control select {
  background-color: #1e293b;
  border-color: #334155;
  color: #f8fafc;
}

.btn-refresh {
  padding: 7px 14px;
  background-color: #c7000a;
  color: white;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  font-size: 13px;
  font-weight: 600;
  display: inline-flex;
  align-items: center;
  gap: 6px;
  box-shadow: 0 2px 4px rgba(199, 0, 10, 0.2);
  transition: background-color 0.15s ease, transform 0.1s ease;
  user-select: none;
}

.btn-refresh:hover {
  background-color: #a80008;
}

.btn-refresh:active {
  transform: scale(0.98);
}

.refresh-icon {
  width: 14px;
  height: 14px;
  display: inline-block;
}

.spin {
  animation: spin 1s linear infinite;
}

@keyframes spin {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}

.theme-toggle-btn {
  padding: 8px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
  background: transparent;
  color: #64748b;
  cursor: pointer;
  transition: all 0.15s ease;
}

.theme-toggle-btn:hover {
  background-color: #f1f5f9;
  color: #0f172a;
}

.dashboard-container.dark .theme-toggle-btn {
  border-color: #334155;
  color: #94a3b8;
}

.dashboard-container.dark .theme-toggle-btn:hover {
  background-color: #1e293b;
  color: #f8fafc;
}

.theme-icon {
  width: 20px;
  height: 20px;
}

/* Global Bandwidth Cards */
.metrics-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
  gap: 16px;
  margin: 24px;
}

.metric-card {
  background: white;
  padding: 18px 20px;
  border-radius: 12px;
  border: 1px solid #e2e8f0;
  display: flex;
  flex-direction: column;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
  transition: background-color 0.2s ease, border-color 0.2s ease;
}

.dashboard-container.dark .metric-card {
  background: #131b2e;
  border-color: #1e293b;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.2);
}

.metric-label {
  font-size: 12px;
  color: #64748b;
  text-transform: uppercase;
  font-weight: 600;
  letter-spacing: 0.04em;
  margin-bottom: 6px;
}

.dashboard-container.dark .metric-label {
  color: #94a3b8;
}

.metric-value {
  font-size: 26px;
  font-weight: 700;
  color: #0f172a;
}

.dashboard-container.dark .metric-value {
  color: #f8fafc;
}

.metric-sub {
  font-size: 12px;
  color: #94a3b8;
  margin-top: 4px;
}

.dashboard-container.dark .metric-sub {
  color: #64748b;
}

/* Alert */
.alert-box {
  background: #fef2f2;
  color: #991b1b;
  border: 1px solid #fecaca;
  padding: 14px 20px;
  border-radius: 8px;
  margin: 24px;
}

.dashboard-container.dark .alert-box {
  background: #450a0a;
  color: #fecaca;
  border-color: #7f1d1d;
}

/* Main Content & Applications */
.content {
  padding: 0 24px;
}

.app-section {
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  margin-bottom: 24px;
  overflow: visible;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
  transition: background-color 0.2s ease, border-color 0.2s ease;
}

.dashboard-container.dark .app-section {
  background: #131b2e;
  border-color: #1e293b;
}

.app-header {
  padding: 16px 20px;
  background: #f8fafc;
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-bottom: 1px solid #e2e8f0;
  border-top-left-radius: 12px;
  border-top-right-radius: 12px;
}

.dashboard-container.dark .app-header {
  background: #0f172a;
  border-bottom-color: #1e293b;
}

.app-header h2 {
  font-size: 15px;
  margin: 0;
  color: #0f172a;
}

.dashboard-container.dark .app-header h2 {
  color: #f8fafc;
}

.app-header code {
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
  background: #e2e8f0;
  padding: 2px 6px;
  border-radius: 4px;
  font-size: 13px;
}

.dashboard-container.dark .app-header code {
  background: #1e293b;
  color: #38bdf8;
}

.client-count {
  font-size: 13px;
  color: #64748b;
  font-weight: 500;
}

.dashboard-container.dark .client-count {
  color: #94a3b8;
}

.empty-state {
  padding: 40px;
  text-align: center;
  color: #64748b;
  font-size: 14px;
}

.dashboard-container.dark .empty-state {
  color: #94a3b8;
}

.empty-state code {
  font-family: ui-monospace, monospace;
  background: #f1f5f9;
  padding: 2px 6px;
  border-radius: 4px;
}

.dashboard-container.dark .empty-state code {
  background: #1e293b;
  color: #f1f5f9;
}

/* Data Table */
.streams-table-wrapper {
  overflow-x: auto;
}

.data-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 13px;
}

.data-table th, .data-table td {
  padding: 12px 16px;
  text-align: left;
  border-bottom: 1px solid #f1f5f9;
}

.dashboard-container.dark .data-table th,
.dashboard-container.dark .data-table td {
  border-bottom-color: #1e293b;
}

.data-table th {
  background: #f8fafc;
  color: #64748b;
  font-weight: 600;
  font-size: 12px;
  text-transform: uppercase;
  letter-spacing: 0.03em;
}

.dashboard-container.dark .data-table th {
  background: #0f172a;
  color: #94a3b8;
}

.stream-name {
  color: #2563eb;
  font-weight: 600;
}

.dashboard-container.dark .stream-name {
  color: #60a5fa;
}

.badge {
  display: inline-block;
  padding: 2px 8px;
  border-radius: 6px;
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.02em;
}

.badge-online {
  background: #dcfce7;
  color: #15803d;
}
.dashboard-container.dark .badge-online {
  background: #064e3b;
  color: #6ee7b7;
}

.badge-offline {
  background: #f1f5f9;
  color: #64748b;
}
.dashboard-container.dark .badge-offline {
  background: #1e293b;
  color: #94a3b8;
}

.badge-pub {
  background: #e0f2fe;
  color: #0369a1;
}
.dashboard-container.dark .badge-pub {
  background: #0c4a6e;
  color: #7dd3fc;
}

.badge-sub {
  background: #f1f5f9;
  color: #475569;
}
.dashboard-container.dark .badge-sub {
  background: #1e293b;
  color: #cbd5e1;
}

.drop-alert {
  color: #dc2626;
  font-weight: bold;
}

.text-muted {
  color: #94a3b8;
}

.btn-sm {
  padding: 4px 10px;
  font-size: 12px;
  font-weight: 500;
  border: 1px solid #cbd5e1;
  background: white;
  color: #334155;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-sm:hover {
  background: #f1f5f9;
  border-color: #94a3b8;
}

.dashboard-container.dark .btn-sm {
  background: #1e293b;
  border-color: #334155;
  color: #cbd5e1;
}

.dashboard-container.dark .btn-sm:hover {
  background: #334155;
  color: #f8fafc;
}

.sub-table-row td {
  background: #f8fafc;
  padding: 16px 20px;
}

.dashboard-container.dark .sub-table-row td {
  background: #0f172a;
}

.client-details-box h4 {
  margin: 0 0 10px 0;
  font-size: 13px;
  color: #334155;
}

.dashboard-container.dark .client-details-box h4 {
  color: #cbd5e1;
}

.client-table {
  width: 100%;
  border-collapse: collapse;
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  font-size: 12px;
  overflow: hidden;
}

.dashboard-container.dark .client-table {
  background: #131b2e;
  border-color: #1e293b;
}

.client-table th, .client-table td {
  padding: 8px 12px;
  border-bottom: 1px solid #f1f5f9;
}

.dashboard-container.dark .client-table th,
.dashboard-container.dark .client-table td {
  border-bottom-color: #1e293b;
}

.client-table th {
  background: #f8fafc;
  color: #64748b;
}

.dashboard-container.dark .client-table th {
  background: #0b0f19;
  color: #94a3b8;
}
</style>

<style>
/* Global reset to eliminate white edges/margins */
html, body {
  margin: 0;
  padding: 0;
  min-height: 100%;
  background-color: #f8fafc;
  transition: background-color 0.2s ease, color 0.2s ease;
}

html.dark, html.dark body {
  background-color: #0b0f19;
  color: #f1f5f9;
}

#__nuxt {
  min-height: 100%;
}
</style>
