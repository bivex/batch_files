#!/bin/zsh

set -euo pipefail

DOMAIN="com.apple.universalaccess"
KEY="mouseDriverCursorSize"

usage() {
  cat <<'EOF'
Usage:
  ./cursor-size.sh show
  ./cursor-size.sh set <value>
  ./cursor-size.sh up [factor]
  ./cursor-size.sh down [factor]

Examples:
  ./cursor-size.sh show
  ./cursor-size.sh set 4
  ./cursor-size.sh up 2
  ./cursor-size.sh down 2
EOF
}

is_number() {
  [[ "$1" =~ ^[0-9]+([.][0-9]+)?$ ]]
}

current_value() {
  defaults read "$DOMAIN" "$KEY" 2>/dev/null || echo "1.0"
}

write_value() {
  local value="$1"
  defaults write "$DOMAIN" "$KEY" -float "$value"
  killall cfprefsd >/dev/null 2>&1 || true
  echo "Cursor size set to: $value"
  echo "If it does not change immediately, log out/in or reboot macOS."
}

calc_value() {
  local base="$1"
  local factor="$2"
  local op="$3"

  awk -v base="$base" -v factor="$factor" -v op="$op" 'BEGIN {
    if (op == "mul") {
      printf "%.2f", base * factor
    } else {
      printf "%.2f", base / factor
    }
  }'
}

command="${1:-show}"

case "$command" in
  show)
    echo "Current cursor size: $(current_value)"
    ;;
  set)
    value="${2:-}"
    if [[ -z "$value" ]] || ! is_number "$value"; then
      echo "Error: set requires a numeric value."
      usage
      exit 1
    fi
    write_value "$value"
    ;;
  up)
    factor="${2:-2}"
    if ! is_number "$factor"; then
      echo "Error: up requires a numeric factor."
      usage
      exit 1
    fi
    next_value="$(calc_value "$(current_value)" "$factor" "mul")"
    write_value "$next_value"
    ;;
  down)
    factor="${2:-2}"
    if ! is_number "$factor"; then
      echo "Error: down requires a numeric factor."
      usage
      exit 1
    fi
    next_value="$(calc_value "$(current_value)" "$factor" "div")"
    write_value "$next_value"
    ;;
  help|-h|--help)
    usage
    ;;
  *)
    echo "Unknown command: $command"
    usage
    exit 1
    ;;
esac
