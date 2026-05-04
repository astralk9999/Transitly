#!/usr/bin/env bash
# Modo watch: regenera codegen en cada cambio de fuente. Pensado para
# dejar corriendo en una terminal mientras se editan modelos.
set -euo pipefail

cd "$(dirname "$0")/.."
exec dart run build_runner watch --delete-conflicting-outputs "$@"
