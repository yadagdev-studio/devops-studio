# 変更ゲート: GitHub Actions / self-hosted runner

対象:
- .github/workflows/*.yml（external-smoke等）
- self-hosted runner（Chronos）の設定変更
- runnerが参照する secrets/vars（ただし内容自体はGitに入れない）
- Actionsの権限（permissions）、schedule、timeout、必要ツールのインストール

目的:
- “CI/監視の目” が静かに死ぬ事故を防ぐ。
- 変更後、手動トリガーでGreenを確認し、定期実行に乗ることを担保する。

---

## 0. 原則
- workflow変更後は必ず `workflow_dispatch` で1回 Green を確認する。
- scheduleは遅延することがある（数分〜）ので、初回は手動で確認。
- runner変更は「ジョブがPendingのまま」になる事故が多い。 → 監視観点を強く持つ。

---

## 1. 変更前スナップショット（Windows）
- [ ] 変更対象workflowファイル名を控える
- [ ] 変更目的（何を追加/削除/変更）を1行で言える
- [ ] secretsを追加/変更するなら、どのrepository/environmentに入れるか控える（値は貼らない）

---

## 2. 変更反映（GitHub）
- [ ] workflowを push（デフォルトブランチへ）
- [ ] 可能ならPRでレビューを通す（Astraeus/Selene/Windows）

---

## 3. workflow検証（必須）
### 3.1 手動実行（workflow_dispatch）
- [ ] GitHub Actions UI から該当workflowを手動実行
- [ ] Green になること
- [ ] 失敗時はログの失敗箇所を控える（コマンド/HTTP code）

### 3.2 schedule確認（該当する場合）
- [ ] 次回以降はcronで回る前提でOK（ただし遅延はあり得る）

---

## 4. self-hosted runner の健全性確認（Chronos / 該当する場合）
runnerを systemd で管理している場合の例（ユニット名は環境に合わせる）:

```
# 例: actions-runner.service のような名前を想定
sudo systemctl status actions-runner.service --no-pager || true
sudo journalctl -u actions-runner.service --since "1 day ago" --no-pager | tail -n 200
```

runnerがコンテナ運用の場合は、該当compose/コンテナの status/logs を確認。

---

## 5. よくある事故チェック（推奨）
- permissions不足で失敗。（checkout/contents権限など）
- scheduleがデフォルトブランチに無い。（ブランチ違い）
- runnerがオフライン。（ジョブがずっと待つ）
- runner側のツール不足。（curl/nc等のinstall漏れ）

---

## 6. ロールバック（最低限）
### 6.1 workflowの revert（推奨）
Windowsで revert→push
```
git log --oneline -n 10
git revert <BAD_COMMIT_SHA>
git push
```

### 6.2 runner変更の戻し（該当する場合）
- runnerユニット/設定を戻したら再起動してログ確認。
```
sudo systemctl daemon-reload
sudo systemctl restart actions-runner.service || true
sudo systemctl status actions-runner.service --no-pager || true
```
