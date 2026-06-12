#!/usr/bin/env bash
# Ratchet anti-regresión de i18n (P3.2 del plan post-TFG).
#
# Cuenta las líneas de lib/ con literales que contienen caracteres españoles
# (tildes, ñ, ¿¡) — heurística de string ES hardcodeado que debería vivir en
# los ARB. Falla si el recuento SUPERA la línea base (tool/i18n_baseline.txt);
# si baja, pide actualizar la base para consolidar el progreso.
#
# Uso: bash tool/check_i18n_ratchet.sh          (verifica)
#      bash tool/check_i18n_ratchet.sh --update (reescribe la línea base)
set -euo pipefail
cd "$(dirname "$0")/.."

BASELINE_FILE="tool/i18n_baseline.txt"

COUNT=$(grep -rEc "'[^']*[áéíóúñÁÉÍÓÚÑ¿¡][^']*'" lib --include="*.dart" 2>/dev/null \
  | grep -v "^lib/l10n/" \
  | grep -v "\.g\.dart:" \
  | grep -v "\.freezed\.dart:" \
  | awk -F: '{s+=$NF} END {print s+0}')

if [ "${1:-}" = "--update" ]; then
  echo "$COUNT" > "$BASELINE_FILE"
  echo "Línea base actualizada: $COUNT líneas con strings ES hardcodeados."
  exit 0
fi

BASELINE=$(cat "$BASELINE_FILE")
echo "Strings ES hardcodeados: $COUNT líneas (línea base: $BASELINE)"

if [ "$COUNT" -gt "$BASELINE" ]; then
  echo "::error::Regresión de i18n: $COUNT > $BASELINE. Usa AppLocalizations" \
    "(claves ARB en lib/l10n/app_*.arb) en lugar de literales en español."
  echo "Peores ficheros:"
  grep -rEc "'[^']*[áéíóúñÁÉÍÓÚÑ¿¡][^']*'" lib --include="*.dart" 2>/dev/null \
    | grep -v "^lib/l10n/" | grep -v "\.g\.dart:" | grep -v "\.freezed\.dart:" \
    | grep -v ":0$" | sort -t: -k2 -rn | head -10
  exit 1
fi

if [ "$COUNT" -lt "$BASELINE" ]; then
  echo "Progreso ✔ ($((BASELINE - COUNT)) líneas menos). Consolida con:" \
    "bash tool/check_i18n_ratchet.sh --update"
fi
