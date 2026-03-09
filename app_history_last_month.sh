#!/usr/bin/env bash
set -euo pipefail

# Approximate app-open history on macOS using Spotlight last-used metadata.
# Default window: last 30 days.
# Usage:
#   scripts/app_history_last_month.sh
#   scripts/app_history_last_month.sh 14
#   scripts/app_history_last_month.sh 30 --names-only

DAYS="${1:-30}"
MODE="${2:-full}"

if ! [[ "$DAYS" =~ ^[0-9]+$ ]]; then
  echo "Usage: $0 [days] [--names-only]" >&2
  exit 1
fi

if [[ "$MODE" != "full" && "$MODE" != "--names-only" ]]; then
  echo "Usage: $0 [days] [--names-only]" >&2
  exit 1
fi

CUTOFF_EPOCH="$(date -v-"${DAYS}"d +%s)"

mdfind 'kMDItemContentTypeTree == "com.apple.application-bundle"' |
while IFS= read -r app_path; do
  used_raw="$(mdls -raw -name kMDItemLastUsedDate "$app_path" 2>/dev/null || true)"
  [[ -z "$used_raw" || "$used_raw" == "(null)" || "$used_raw" == "null" ]] && continue

  used_epoch="$(date -j -f '%Y-%m-%d %H:%M:%S %z' "$used_raw" +%s 2>/dev/null || true)"
  [[ -z "$used_epoch" ]] && continue

  if (( used_epoch >= CUTOFF_EPOCH )); then
    used_local="$(date -r "$used_epoch" '+%Y-%m-%d %H:%M:%S %Z')"
    app_name="$(basename "$app_path")"

    if [[ "$MODE" == "--names-only" ]]; then
      printf '%s\t%s\n' "$used_local" "$app_name"
    else
      printf '%s\t%s\n' "$used_local" "$app_path"
    fi
  fi
done | sort -r
