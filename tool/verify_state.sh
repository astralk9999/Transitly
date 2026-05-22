#!/usr/bin/env bash
set -euo pipefail

HEAD_REF=$(git rev-parse --short HEAD)
DATE_TODAY=$(date +%Y-%m-%d)

TEST_OUTPUT=$(flutter test 2>&1 | tail -3)
TEST_PASSED=$(echo "$TEST_OUTPUT" | grep -oP '\+\K\d+' | head -1 || echo "?")
TEST_SKIPPED=$(echo "$TEST_OUTPUT" | grep -oP '~\K\d+' | head -1 || echo "0")

COVERAGE=$(awk -F'[:,]' '/^DA:/ {t++; if($3>0) h++} END {printf "%.2f", h/t*100}' coverage/lcov.info 2>/dev/null || echo "?")

APK_BYTES=$(stat -c%s build/app/outputs/flutter-apk/app-release.apk 2>/dev/null || echo "0")
APK_MIB=$(awk "BEGIN {printf \"%.2f\", $APK_BYTES/1048576}")

MIGRATIONS=$(ls supabase/migrations/*.sql 2>/dev/null | wc -l)
FEATURES=$(ls -d lib/features/*/ 2>/dev/null | wc -l)

ANALYZE_OUTPUT=$(flutter analyze 2>&1)
ANALYZE_ERRORS=$(echo "$ANALYZE_OUTPUT" | grep -c "error" || echo "0")
ANALYZE_WARNINGS=$(echo "$ANALYZE_OUTPUT" | grep -c "warning" || echo "0")
ANALYZE_INFO=$(echo "$ANALYZE_OUTPUT" | grep -c "info" || echo "0")

COMMITS=$(git log --oneline | wc -l)
JOBS_CI=$(grep -c "^  [a-z].*:$" .github/workflows/ci.yml 2>/dev/null || echo "?")

cat <<EOF
<!-- BEGIN ESTADO -->
**Estado verificado ($DATE_TODAY · master @ $HEAD_REF)**

- \`flutter analyze\`: **$ANALYZE_ERRORS errors, $ANALYZE_WARNINGS warnings, $ANALYZE_INFO info**
- \`flutter test\`: **$TEST_PASSED passed + $TEST_SKIPPED skipped**
- Cobertura global: **$COVERAGE %**
- APK release: **$APK_MIB MiB**
- Migraciones SQL: **$MIGRATIONS**
- Features: **$FEATURES**
- Commits totales: **$COMMITS**
- CI jobs: **$JOBS_CI**

> Bloque autogenerado por \`tool/verify_state.sh\`. NO editar a mano.
<!-- END ESTADO -->
EOF
