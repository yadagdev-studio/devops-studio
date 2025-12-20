#!/usr/bin/env bash
set -euo pipefail

# 監視対象（コンテナ内部から見える proxy）
BASE="${BASE:-http://devops-proxy}"

# 監視対象(アプリ)
CHECK_PATHS=(
  "/healthz"
  "/delay-api/healthz"
)

echo "[monitor] starting. BASE=${BASE}"
printf '[monitor] check: %s\n' "${CHECK_PATHS[@]}"

# Discord Webhook URL（ホスト側で env 渡す）
WEBHOOK_URL="${DISCORD_WEBHOOK_URL:-}"

STATE_DIR="${STATE_DIR:-/state}"
mkdir -p "$STATE_DIR"
STATE_FILE="${STATE_DIR}/last_state"   # ok / fail

notify() {
  local msg="$1"
  if [ -z "$WEBHOOK_URL" ]; then
    echo "[monitor] DISCORD_WEBHOOK_URL is empty; skip notify"
    return 0
  fi
  curl -fsS -H 'Content-Type: application/json' \
    -d "{\"content\":\"${msg}\"}" \
    "$WEBHOOK_URL" >/dev/null || true
}

prev="unknown"
[ -f "$STATE_FILE" ] && prev="$(cat "$STATE_FILE")"

fail=0
failed_path=""
for p in "${CHECK_PATHS[@]}"; do
  if ! curl -fsS "${BASE}${p}" >/dev/null; then
    fail=1
    failed_path="$p"
    break
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "ok" > "$STATE_FILE"
  if [ "$prev" = "fail" ]; then
    notify "✅ DevOps-Studio recovered: ${BASE} (paths: ${CHECK_PATHS[*]})"
  fi
else
  echo "fail" > "$STATE_FILE"
  echo "[monitor] FAILED path=${failed_path}"
  if [ "$prev" != "fail" ]; then
    notify "🚨 DevOps-Studio healthcheck FAILED: ${BASE} (failed: ${failed_path})"
  fi
fi

# Run every 60 seconds (no cron required)
sleep 60
exec "$0"
