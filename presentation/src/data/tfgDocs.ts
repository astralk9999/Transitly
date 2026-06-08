// Metadatos de los 8 documentos del TFG. Se relacionan con cada entrada del
// content layer por su prefijo numérico (01..08), de modo que funciona sea
// cual sea la forma exacta del `id` que genere el glob loader.

export interface TfgDocMeta {
  num: string; // "01".."08"
  title: string;
  short: string;
  desc: string;
  phase: string;
}

export const TFG_DOCS: TfgDocMeta[] = [
  {
    num: '01',
    title: 'Análisis del Contexto y Detección de Necesidades',
    short: 'Análisis del contexto',
    desc: 'Sector de la movilidad urbana, caso COMUJESA, carencias detectadas y oportunidades de negocio.',
    phase: '1 · Análisis',
  },
  {
    num: '02',
    title: 'Diseño del Proyecto',
    short: 'Diseño del proyecto',
    desc: 'Objetivos funcionales y no funcionales, pila tecnológica, viabilidad, indicadores y requisitos legales.',
    phase: '2 · Diseño',
  },
  {
    num: '03',
    title: 'Planificación de la Ejecución',
    short: 'Planificación',
    desc: 'Metodología, diagrama de Gantt, WBS, recursos, análisis de riesgos y entregables parciales.',
    phase: '3 · Planificación',
  },
  {
    num: '04',
    title: 'Desarrollo e Implementación',
    short: 'Desarrollo',
    desc: 'Arquitectura, capas, base de datos, servicios, pruebas técnicas y CI/CD de la aplicación.',
    phase: '4 · Desarrollo',
  },
  {
    num: '05',
    title: 'Seguimiento, Evaluación y Documentación',
    short: 'Evaluación',
    desc: 'Control y seguimiento, registro de incidencias, feedback de usuarios, métricas finales y lecciones.',
    phase: '5 · Evaluación',
  },
  {
    num: '06',
    title: 'Manual Técnico',
    short: 'Manual técnico',
    desc: 'Instalación, configuración, despliegue del backend, CI/CD, mantenimiento y resolución de problemas.',
    phase: 'Documentación técnica',
  },
  {
    num: '07',
    title: 'Manual de Usuario',
    short: 'Manual de usuario',
    desc: 'Guía de uso para el usuario final: instalación, pantallas, NFC, offline, accesibilidad y privacidad.',
    phase: 'Manual de usuario',
  },
  {
    num: '08',
    title: 'Presentación Final (guion)',
    short: 'Guion de defensa',
    desc: 'Guion de diapositivas para la defensa oral del TFG, con notas de orador por diapositiva.',
    phase: 'Presentación',
  },
];

/** Devuelve los metadatos a partir del `id` del content layer (por prefijo). */
export function metaForId(id: string): TfgDocMeta | undefined {
  const num = id.replace(/[^0-9]/g, '').slice(0, 2);
  return TFG_DOCS.find((d) => d.num === num);
}

/** Orden numérico estable a partir del `id`. */
export function orderForId(id: string): number {
  return parseInt(id.replace(/[^0-9]/g, '').slice(0, 2) || '99', 10);
}
