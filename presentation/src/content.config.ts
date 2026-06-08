import { defineCollection } from 'astro:content';
import { glob } from 'astro/loaders';

// Memoria del TFG: se renderiza directamente desde docs/tfg/*.md
// (fuente única de verdad; no se duplica el contenido en la web).
const tfg = defineCollection({
  loader: glob({ pattern: '*.md', base: '../docs/tfg' }),
});

export const collections = { tfg };
