#!/usr/bin/env bash
# Genera los archivos de codegen (.freezed.dart, .g.dart) una vez y sale.
#
# --delete-conflicting-outputs es necesario tras renombrar/borrar
# archivos generados; sin él, build_runner falla por archivos huérfanos.
set -euo pipefail

cd "$(dirname "$0")/.."
exec dart run build_runner build --delete-conflicting-outputs "$@"
