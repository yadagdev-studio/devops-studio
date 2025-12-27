# 変更ゲート: systemd（service / timer）

対象:
- /etc/systemd/system/*.service, *.timer
- drop-in（/etc/systemd/system/<unit>.d/*.conf）
- ExecStart のスクリプト（/usr/local/bin/*.sh）
- timerスケジュール、RandomizedDelaySec、EnvironmentFile 等

目的:
- “静かに止まる” を防ぐ。（バックアップ/更新/証明書/監視などの運用基盤）
- 変更後に「実際に動く」ことまで確認する。

---

## 0. 原則
- 変更は Git で管理。（Unitファイルやスクリプトのソースが repo 管理でない場合は、変更内容を必ずログ/メモに残す）
- 変更後は必ず `daemon-reload` → 検証（start/enable/list-timers/journal）までやる。
- timer 変更は「次回実行時刻」が変わるので `systemctl list-timers` で必ず確認する。

---

## 1. 変更前スナップショット（Chronos / 変更前）
対象ユニットを `<UNIT>` として控える。（例: backup-devops-proxy, certbot-renew など）

```
UNIT="<UNIT>"

# ユニット定義
systemctl cat "${UNIT}.service"
systemctl cat "${UNIT}.timer" 2>/dev/null || true

# 現在の状態
systemctl status "${UNIT}.service" --no-pager || true
systemctl status "${UNIT}.timer" --no-pager || true

# timer一覧（次回実行時刻の確認）
systemctl list-timers --all | head -n 200

# 直近ログ
sudo journalctl -u "${UNIT}.service" --since "14 days ago" --no-pager | tail -n 200
```

---

## 2. 変更反映（Chronos）
repository管理のファイル変更なら:
```
cd devops-studio/
git pull --ff-only
```

---

## 3. 変更適用（必須）
```
# 定義再読込
sudo systemctl daemon-reload

# timerがあるなら有効化（必要に応じて）
sudo systemctl enable --now "${UNIT}.timer" 2>/dev/null || true
```

---

## 4. 検証（必須）
### 4.1 定義チェック（systemd-analyze verify）
```
sudo systemd-analyze verify "/etc/systemd/system/${UNIT}.service" 2>/dev/null || true
sudo systemd-analyze verify "/etc/systemd/system/${UNIT}.timer" 2>/dev/null || true
```

### 4.2 手動実行（timer待ちにしない）
oneshot/定期どちらでも、まずは手で回して「動く」を確認する。
```
sudo systemctl start "${UNIT}.service"
sudo systemctl status "${UNIT}.service" --no-pager
sudo journalctl -u "${UNIT}.service" --since "10 minutes ago" --no-pager
```

### 4.3 timerの次回実行を確認（timer変更時は必須）
```
systemctl list-timers --all | grep -E "${UNIT}\.timer|NEXT|LEFT" || true
```

---

## 5. 典型事故チェック（強く推奨）
- ExecStart のパス違い。（スクリプトが存在しない/権限なし）
- EnvironmentFile の読み込み失敗。（.envや設定ファイルが無い）
- User/Group の権限不足。
- WorkingDirectory が存在しない。
- timer の OnCalendar 書式ミス。

確認コマンド例:
```
sudo systemctl show "${UNIT}.service" -p ExecStart -p User -p Group -p WorkingDirectory
```

---

## 6. ロールバック（最低限）
### 6.1 Gitで revert（推奨）
Windowsで revert→push
```
git log --oneline -n 10
git revert <BAD_COMMIT_SHA>
git push
```

### 6.2 Chronosで pull → 再読込 → 再実行
```
cd devops-studio
git pull --ff-only

sudo systemctl daemon-reload
sudo systemctl start "${UNIT}.service"
sudo journalctl -u "${UNIT}.service" --since "10 minutes ago" --no-pager
```

※ それでも壊れてる場合（緊急回避）:
- timerを止める（暴走/連続失敗回避）
```
sudo systemctl disable --now "${UNIT}.timer" 2>/dev/null || true
```
