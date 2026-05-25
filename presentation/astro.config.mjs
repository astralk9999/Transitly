// @ts-check
import { defineConfig } from 'astro/config';
import tailwindcss from '@tailwindcss/vite';
import sitemap from '@astrojs/sitemap';

// https://astro.build/config
export default defineConfig({
  output: 'static',

  site: 'https://astralk9999.github.io',
  base: '/Transitly',

  vite: {
    plugins: [tailwindcss()],
  },

  integrations: [sitemap()],

  build: {
    inlineStylesheets: 'auto',
  },

  trailingSlash: 'never',
});
