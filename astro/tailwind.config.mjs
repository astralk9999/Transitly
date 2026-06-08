/** @type {import('tailwindcss').Config} */

// Colores como canales RGB para que `bg-x/opacity` siga funcionando.
// Los valores reales viven en variables CSS (ver Layout.astro): paleta
// oscura por defecto y clara en `html.light`.
const v = (name) => `rgb(var(${name}) / <alpha-value>)`;

export default {
  content: ['./src/**/*.{astro,html,js,jsx,md,mdx,svelte,ts,tsx,vue}'],
  theme: {
    extend: {
      colors: {
        transit: {
          bg: v('--c-bg'),
          surface: v('--c-surface'),
          raised: v('--c-raised'),
          input: v('--c-input'),
          elevated: v('--c-elevated'),
          border: v('--c-border'),
          'border-focus': v('--c-border-focus'),
          divider: v('--c-divider'),
          accent: v('--c-accent'),
          'accent-bg': v('--c-accent-bg'),
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
          hi: v('--c-text-hi'),
          mid: v('--c-text-mid'),
          lo: v('--c-text-lo'),
          disabled: v('--c-text-disabled'),
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
