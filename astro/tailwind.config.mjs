/** @type {import('tailwindcss').Config} */
export default {
  content: ['./src/**/*.{astro,html,js,jsx,md,mdx,svelte,ts,tsx,vue}'],
  theme: {
    extend: {
      colors: {
        transit: {
          bg: '#08081A',
          surface: '#10102A',
          raised: '#181838',
          input: '#0C0C1E',
          elevated: '#161636',
          border: '#1E1E3A',
          'border-focus': '#3A3A60',
          divider: '#151530',
          accent: '#977DDF',
          'accent-bg': '#14101E',
          'accent-muted': 'rgba(151, 125, 223, 0.2)',
          neon: {
            cyan: '#00D4FF',
            magenta: '#FF006E',
            purple: '#6C63FF',
            blue: '#3B82F6',
          },
          state: {
            onroute: '#22C55E',
            ontime: '#22C55E',
            delay: '#F59E0B',
            cancelled: '#EF4444',
            idle: '#6A6A80',
          },
        },
        text: {
          hi: '#F8F8FF',
          mid: '#A0A0B8',
          lo: '#6A6A80',
          disabled: '#404060',
        },
      },
      fontFamily: {
        sans: ['DM Sans', 'system-ui', 'sans-serif'],
        mono: ['IBM Plex Mono', 'monospace'],
      },
      backgroundImage: {
        'gradient-accent': 'linear-gradient(135deg, #977DDF, #B8A5F0)',
        'gradient-neon': 'linear-gradient(135deg, #00D4FF, #6C63FF)',
        'gradient-warm': 'linear-gradient(135deg, #FF006E, #F59E0B)',
        'gradient-card': 'linear-gradient(180deg, rgba(24,24,56,0.8), rgba(16,16,42,0.6))',
      },
    },
  },
  plugins: [],
};
