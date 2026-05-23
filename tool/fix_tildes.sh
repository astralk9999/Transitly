#!/usr/bin/env bash
# Fix tildes in docs/tfg/05-08 (post-rewrite cleanup)
set -e

FILES=(
  "docs/tfg/05_evaluacion_documentacion.md"
  "docs/tfg/06_manual_tecnico.md"
  "docs/tfg/07_manual_usuario.md"
  "docs/tfg/08_presentacion.md"
)

for f in "${FILES[@]}"; do
  echo "Fixing: $f"
  sed -i \
    -e "s/aplicacion/aplicación/g" \
    -e "s/configuracion/configuración/g" \
    -e "s/implementacion/implementación/g" \
    -e "s/documentacion/documentación/g" \
    -e "s/informacion/información/g" \
    -e "s/comunicacion/comunicación/g" \
    -e "s/planificacion/planificación/g" \
    -e "s/evaluacion/evaluación/g" \
    -e "s/administracion/administración/g" \
    -e "s/presentacion/presentación/g" \
    -e "s/observacion/observación/g" \
    -e "s/instalacion/instalación/g" \
    -e "s/autenticacion/autenticación/g" \
    -e "s/autorizacion/autorización/g" \
    -e "s/certificacion/certificación/g" \
    -e "s/identificacion/identificación/g" \
    -e "s/verificacion/verificación/g" \
    -e "s/modificacion/modificación/g" \
    -e "s/separacion/separación/g" \
    -e "s/integracion/integración/g" \
    -e "s/navegacion/navegación/g" \
    -e "s/generacion/generación/g" \
    -e "s/especificacion/especificación/g" \
    -e "s/recomendacion/recomendación/g" \
    -e "s/migracion/migración/g" \
    -e "s/automatizacion/automatización/g" \
    -e "s/optimizacion/optimización/g" \
    -e "s/localizacion/localización/g" \
    -e "s/internacionalizacion/internacionalización/g" \
    -e "s/traduccion/traducción/g" \
    -e "s/redaccion/redacción/g" \
    -e "s/creacion/creación/g" \
    -e "s/relacion/relación/g" \
    -e "s/operacion/operación/g" \
    -e "s/atencion/atención/g" \
    -e "s/intencion/intención/g" \
    -e "s/explicacion/explicación/g" \
    -e "s/ejecucion/ejecución/g" \
    -e "s/seleccion/selección/g" \
    -e "s/proteccion/protección/g" \
    -e "s/correccion/corrección/g" \
    -e "s/coleccion/colección/g" \
    -e "s/inspeccion/inspección/g" \
    -e "s/direccion/dirección/g" \
    -e "s/estacion/estación/g" \
    -e "s/sesion/sesión/g" \
    -e "s/conexion/conexión/g" \
    -e "s/decision/decisión/g" \
    -e "s/region/región/g" \
    -e "s/division/división/g" \
    -e "s/conclusion/conclusión/g" \
    -e "s/inclusion/inclusión/g" \
    -e "s/exclusion/exclusión/g" \
    -e "s/transmision/transmisión/g" \
    -e "s/comprension/comprensión/g" \
    -e "s/expresion/expresión/g" \
    -e "s/impresion/impresión/g" \
    -e "s/revision/revisión/g" \
    -e "s/mision/misión/g" \
    -e "s/vision/visión/g" \
    -e "s/gestion/gestión/g" \
    -e "s/version/versión/g" \
    -e "s/circulacion/circulación/g" \
    -e "s/estimacion/estimación/g" \
    -e "s/reputacion/reputación/g" \
    -e "s/demostracion/demostración/g" \
    -e "s/transformacion/transformación/g" \
    -e "s/produccion/producción/g" \
    -e "s/prediccion/predicción/g" \
    -e "s/moderacion/moderación/g" \
    -e "s/invitacion/invitación/g" \
    -e "s/eleccion/elección/g" \
    -e "s/continuacion/continuación/g" \
    -e "s/ubicacion/ubicación/g" \
    -e "s/posicion/posición/g" \
    -e "s/seccion/sección/g" \
    -e "s/leccion/lección/g" \
    -e "s/lecciones/lecciones/g" \
    -e "s/anonimo/anónimo/g" \
    -e "s/telefono/teléfono/g" \
    -e "s/linea/línea/g" \
    -e "s/lineas/líneas/g" \
    -e "s/maquina/máquina/g" \
    -e "s/publico/público/g" \
    -e "s/publica/pública/g" \
    -e "s/politica/política/g" \
    -e "s/unico/único/g" \
    -e "s/unica/única/g" \
    -e "s/analitica/analítica/g" \
    -e "s/electronico/electrónico/g" \
    -e "s/electronica/electrónica/g" \
    -e "s/academico/académico/g" \
    -e "s/academica/académica/g" \
    -e "s/tecnologico/tecnológico/g" \
    -e "s/tecnologica/tecnológica/g" \
    -e "s/automatico/automático/g" \
    -e "s/automatica/automática/g" \
    -e "s/grafico/gráfico/g" \
    -e "s/grafica/gráfica/g" \
    -e "s/dinamico/dinámico/g" \
    -e "s/dinamica/dinámica/g" \
    -e "s/estatico/estático/g" \
    -e "s/estatica/estática/g" \
    -e "s/critico/crítico/g" \
    -e "s/critica/crítica/g" \
    -e "s/practico/práctico/g" \
    -e "s/practica/práctica/g" \
    -e "s/teorico/teórico/g" \
    -e "s/teorica/teórica/g" \
    -e "s/fisico/físico/g" \
    -e "s/fisica/física/g" \
    -e "s/logico/lógico/g" \
    -e "s/logica/lógica/g" \
    -e "s/jerarquico/jerárquico/g" \
    -e "s/estrategico/estratégico/g" \
    -e "s/informatico/informático/g" \
    -e "s/informatica/informática/g" \
    -e "s/codigo/código/g" \
    -e "s/metodo/método/g" \
    -e "s/numero/número/g" \
    -e "s/modulo/módulo/g" \
    -e "s/movil/móvil/g" \
    -e "s/pagina/página/g" \
    -e "s/maximo/máximo/g" \
    -e "s/maxima/máxima/g" \
    -e "s/minimo/mínimo/g" \
    -e "s/minima/mínima/g" \
    -e "s/ultimo/último/g" \
    -e "s/ultima/última/g" \
    -e "s/proximo/próximo/g" \
    -e "s/proxima/próxima/g" \
    -e "s/utiles/útiles/g" \
    -e "s/facil/fácil/g" \
    -e "s/faciles/fáciles/g" \
    -e "s/dificil/difícil/g" \
    -e "s/dificiles/difíciles/g" \
    -e "s/tambien/también/g" \
    -e "s/despues/después/g" \
    -e "s/ademas/además/g" \
    -e "s/segun/según/g" \
    -e "s/energia/energía/g" \
    -e "s/bateria/batería/g" \
    -e "s/geografia/geografía/g" \
    -e "s/tipografia/tipografía/g" \
    -e "s/fotografia/fotografía/g" \
    -e "s/caracteristica/característica/g" \
    -e "s/analisis/análisis/g" \
    -e "s/sintesis/síntesis/g" \
    -e "s/etico/ético/g" \
    -e "s/etica/ética/g" \
    -e "s/Tecnico/Técnico/g" \
    -e "s/Tecnica/Técnica/g" \
    -e "s/Evaluacion/Evaluación/g" \
    -e "s/Documentacion/Documentación/g" \
    -e "s/Aplicacion/Aplicación/g" \
    -e "s/Configuracion/Configuración/g" \
    -e "s/Implementacion/Implementación/g" \
    -e "s/Informacion/Información/g" \
    -e "s/Planificacion/Planificación/g" \
    -e "s/Presentacion/Presentación/g" \
    -e "s/Administracion/Administración/g" \
    -e "s/Gestion/Gestión/g" \
    -e "s/Version/Versión/g" \
    -e "s/Seccion/Sección/g" \
    -e "s/Funcion/Función/g" \
    -e "s/Decision/Decisión/g" \
    -e "s/Region/Región/g" \
    -e "s/Sesion/Sesión/g" \
    -e "s/Direccion/Dirección/g" \
    -e "s/Estacion/Estación/g" \
    -e "s/Conexion/Conexión/g" \
    -e "s/Codigo/Código/g" \
    -e "s/Metodo/Método/g" \
    "$f"
done

echo ""
echo "DONE — verificando..."
for f in "${FILES[@]}"; do
  count=$(grep -c "[áéíóúñ]" "$f" 2>/dev/null || echo 0)
  echo "  $f: $count lineas con tildes"
done
