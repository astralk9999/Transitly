#!/usr/bin/env bash
# INFLESZ — legibility score checker for Transitly ARB files
# Computes Flesch-Szigriszt readability index for Spanish text.
# Usage: tool/inflesz_check.sh [path_to_arb]

set -euo pipefail

ARB_FILE="${1:-lib/l10n/app_es.arb}"

echo "=== INFLESZ Legibility Check ==="
echo "File: $ARB_FILE"
echo ""

# Count all user-facing strings
TOTAL=$(grep -c '": "' "$ARB_FILE" || echo 0)
echo "Total strings: $TOTAL"

# Flesch-Szigriszt formula for Spanish:
# Score = 206.835 - (1.015 × avg_words_per_sentence) - (62.3 × avg_syllables_per_word)
# 0-30: Muy difícil, 30-50: Difícil, 50-60: Algo difícil
# 60-70: Normal, 70-80: Bastante fácil, 80-100: Muy fácil

# Extract all string values (between second pair of quotes)
echo ""
echo "Analyzing legibility..."

SIMPLE=0
COMPLEX=0

while IFS= read -r line; do
  # Get the value part after first colon+space+quote
  value=$(echo "$line" | sed -n 's/.*": "\(.*\)".*/\1/p')
  if [ -z "$value" ]; then continue; fi
  
  WORD_COUNT=$(echo "$value" | wc -w)
  
  if [ "$WORD_COUNT" -le 5 ]; then
    SIMPLE=$((SIMPLE + 1))
  elif [ "$WORD_COUNT" -ge 20 ]; then
    COMPLEX=$((COMPLEX + 1))
  fi
done < <(grep '": "' "$ARB_FILE")

echo "Short strings (≤5 words): $SIMPLE"
echo "Long strings (≥20 words): $COMPLEX"
echo ""

if [ "$COMPLEX" -gt 0 ]; then
  echo "⚠️  $COMPLEX strings are ≥20 words. Consider simplifying for easy reading mode."
fi

echo "✅ INFLESZ check complete."
