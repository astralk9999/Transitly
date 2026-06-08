// @ts-check
import { defineConfig } from 'astro/config';
import tailwindcss from '@tailwindcss/vite';
import sitemap from '@astrojs/sitemap';

// Convierte los bloques ```mermaid en <pre class="mermaid"> con el código
// crudo, evitando que Shiki los resalte. Mermaid.js los renderiza en el
// cliente (ver src/pages/docs/[id].astro). Walker manual para no depender
// de unist-util-visit.
function remarkMermaid() {
  return (tree) => {
    const walk = (node) => {
      if (!node || !Array.isArray(node.children)) return;
      for (const child of node.children) {
        if (child.type === 'code' && child.lang === 'mermaid') {
          const code = String(child.value || '')
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;');
          child.type = 'html';
          child.value = `<pre class="mermaid">${code}</pre>`;
          delete child.lang;
          delete child.meta;
        } else {
          walk(child);
        }
      }
    };
    walk(tree);
  };
}

// https://astro.build/config
export default defineConfig({
  output: 'static',

  site: 'https://astralk9999.github.io',
  base: '/Transitly',

  vite: {
    plugins: [tailwindcss()],
  },

  integrations: [sitemap()],

  markdown: {
    remarkPlugins: [remarkMermaid],
  },

  build: {
    inlineStylesheets: 'auto',
  },

  trailingSlash: 'never',
});
