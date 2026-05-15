import { defineConfig } from 'astro/config';
import tailwind from '@astrojs/tailwind';
import sitemap from '@astrojs/sitemap';
import node from '@astrojs/node';

export default defineConfig({
  output: 'server',
  adapter: node({
    mode: 'standalone',
  }),
  integrations: [
    tailwind(),
    sitemap({
      filter: (page) => !page.startsWith('https://transitly.app/app/'),
    }),
  ],
  site: 'https://transitly.app',
  trailingSlash: 'never',
});
