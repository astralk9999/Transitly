#!/usr/bin/env bash
# Sincroniza cifras en docs/tfg/*.md con valores reales del repositorio.
# Uso: bash tool/sync_tfg_numbers.sh
# Idempotente: ejecutar varias veces no rompe nada.

set -e

FILES=(
  docs/tfg/01_analisis_contexto.md
  docs/tfg/02_diseno_proyecto.md
  docs/tfg/03_planificacion.md
  docs/tfg/04_desarrollo_implementacion.md
  docs/tfg/05_evaluacion_documentacion.md
  docs/tfg/06_manual_tecnico.md
  docs/tfg/07_manual_usuario.md
  docs/tfg/08_presentacion.md
)

for f in "${FILES[@]}"; do
  echo "Sincronizando: $f"
  sed -i \
    -e 's/620 tests/616 tests/g' \
    -e 's/620 pruebas/616 pruebas/g' \
    -e 's/\*\*620\*\*/**616**/g' \
    -e 's/846 claves ARB/628 claves ARB/g' \
    -e 's/846 claves/628 claves/g' \
    -e 's/\*\*846\*\*/**628**/g' \
    -e 's/4 jobs CI/7 jobs CI/g' \
    -e 's/4 CI jobs/7 CI jobs/g' \
    -e 's/4 jobs de CI/7 jobs de CI/g' \
    -e 's/cuatro jobs/siete jobs/g' \
    "$f"
done

echo ""
echo "DONE — verificación:"
for f in "${FILES[@]}"; do
  remaining=$(grep -cE '620|846|4 jobs|cuatro jobs' "$f" || echo 0)
  echo "  $f: $remaining referencias antiguas restantes (revisar si son legítimas)"
done
