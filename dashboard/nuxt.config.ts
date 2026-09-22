import legacy from '@vitejs/plugin-legacy'

// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: '2025-07-15',
  devtools: { enabled: true },
  vite: {
    plugins: [
      legacy({
        targets: ['iOS >= 12', 'Safari >= 12'],
        additionalLegacyPolyfills: ['regenerator-runtime/runtime'],
        modernPolyfills: true,
      })
    ]
  },
  app: {
    head: {
      title: 'RTMP Live Dashboard',
      link: [
        { rel: 'icon', type: 'image/svg+xml', href: '/favicon.svg' }
      ]
    }
  }
})

