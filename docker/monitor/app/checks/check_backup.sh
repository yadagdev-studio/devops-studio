#!/usr/bin/env bash
set -euo pipefail

# ---- config ----
TAG="[backup]"
STATE_KEY="backup"  # /state/backup.state
DAILY_KEY="backup_daily" # /state/backup_daily.last

BACKUP_DIR="${BACKUP_DIR:-/host/backups/devops-studio}"
MIN_AGE_SEC="${BACKUP_MIN_AGE_SEC:-180}"
STALE_SEC="${BACKUP_STALE_SEC:-172800}"
DAILY_SUMMARY="${BACKUP_DAILY_SUMMARY:-1}"

STATE_DIR="${STATE_DIR:-/state}"
mkdir -p "$STATE_DIR"

STATE_FILE="${STATE_DIR}/${STATE_KEY}.state"        # ok / fail
DAILY_FILE="${STATE_DIR}/${DAILY_KEY}.last"         # YYYY-MM-DD (UTC)

now_epoch() { date +%s; }
file_mtime_epoch() {
  # alpine(coreutils) のstat想定
  stat -c %Y "$1"
}

# shellcheck disable=SC2001
human_age() {
  local sec="$1"
  if [ "$sec" -lt 60 ]; then echo "${sec}s"; return; fi
  if [ "$sec" -lt 3600 ]; then echo "$((sec/60))m"; return; fi
  if [ "$sec" -lt 86400 ]; then echo "$((sec/3600))h"; return; fi
  echo "$((sec/86400))d"
}

prev_state() {
  [ -f "$STATE_FILE" ] && cat "$STATE_FILE" || echo "unknown"
}
set_state() {
  echo "$1" > "$STATE_FILE"
}

# monitor.sh 側で notify 関数が提供されている想定。
# 無ければ stdout に出す（ただし通常は monitor.sh が拾って通知する運用）
emit_fail() {
  local msg="$1"
  echo "${TAG} 🚨 ${msg}"
}
emit_ok_daily() {
  local msg="$1"
  echo "${TAG} ✅ ${msg}"
}

# ---- main ----
# 1) 最新バックアップが古すぎる（作られていない）チェック
newest_any="$(ls -1t "${BACKUP_DIR}"/devops-proxy-*.tar.gz 2>/dev/null | head -n 1 || true)"
if [ -z "$newest_any" ]; then
  set_state "fail"
  emit_fail "backup FAILED: no_backup_found dir=${BACKUP_DIR}"
  exit 1
fi

now="$(now_epoch)"
newest_any_mtime="$(file_mtime_epoch "$newest_any")"
newest_any_age="$((now - newest_any_mtime))"
if [ "$newest_any_age" -gt "$STALE_SEC" ]; then
  set_state "fail"
  emit_fail "backup FAILED: stale latest=$(basename "$newest_any") age=$(human_age "$newest_any_age") > $(human_age "$STALE_SEC") dir=${BACKUP_DIR}"
  exit 1
fi

# 2) レース回避：新しすぎる世代をスキップして、整合性チェックできる世代を探す
eligible=""
eligible_age=""
for f in $(ls -1t "${BACKUP_DIR}"/devops-proxy-*.tar.gz 2>/dev/null); do
  mtime="$(file_mtime_epoch "$f")"
  age="$((now - mtime))"

  # sha ファイル必須
  if [ ! -f "${f}.sha256" ]; then
    # shaが無いのは生成途中 or 事故の可能性。新しい順で当たるので、古い世代に進む。
    continue
  fi

  # 生成直後はチェックしない（レース回避）
  if [ "$age" -lt "$MIN_AGE_SEC" ]; then
    continue
  fi

  eligible="$f"
  eligible_age="$age"
  break
done

if [ -z "$eligible" ]; then
  # 新しすぎる/sha無しで対象が見つからない
  set_state "fail"
  emit_fail "backup FAILED: no_eligible_backup (min_age=$(human_age "$MIN_AGE_SEC")) dir=${BACKUP_DIR}"
  exit 1
fi

# 3) sha256 整合性チェック
if ! sha256sum -c "${eligible}.sha256" >/dev/null 2>&1; then
  set_state "fail"
  emit_fail "backup FAILED: sha256_mismatch file=$(basename "$eligible")"
  exit 1
fi

# 4) OK：状態は ok にする（通知は “日次サマリ” のみ）
set_state "ok"

if [ "$DAILY_SUMMARY" = "1" ]; then
  today="$(date -u +%F)"
  last="$(cat "$DAILY_FILE" 2>/dev/null || true)"
  if [ "$today" != "$last" ]; then
    # サイズ情報（人間向け）
    size_bytes="$(stat -c %s "$eligible" 2>/dev/null || echo "")"
    size_h="$( [ -n "$size_bytes" ] && numfmt --to=iec --suffix=B "$size_bytes" 2>/dev/null || echo "" )"

    echo "$today" > "$DAILY_FILE"
    emit_ok_daily "backup daily: latest=$(basename "$eligible") age=$(human_age "$eligible_age") size=${size_h:-${size_bytes:-unknown}} dir=${BACKUP_DIR}"
  fi
fi

exit 0
