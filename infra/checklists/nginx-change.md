# 変更ゲート: nginx（devops-proxy）設定変更

対象:
- devops-studio の nginx 設定（conf.d / snippets / includes / deny_sensitive / ratelimit 等）
- certbot deploy-hook / reload スクリプトの変更もここに準拠

目的:
- 外部公開に直結する変更を「事故らず」「再現性高く」反映する。

---

## 0. 事前条件
- 変更は GitHub に push 済み。
- Chronos では pull + 検証コマンドのみ。（原則）
- ヘルス系は rate limit により 429 が出ても正常扱い。（過負荷時）

---

## 1. 変更前セルフチェック（Windows）
- [ ] `git diff` で意図しない差分がない。
- [ ] secrets/個人情報が混入していない。（`.env` / token / webhook / 鍵）
- [ ] 変更対象ファイルの一覧をメモできる。（レビュー用）
- [ ] ロールバックが可能。（前コミットに戻せる）

---

## 2. Chronos反映（Chronos: AlmaLinux10.1）
### 2.1 pull
```
cd /home/chronos/workspace/AIUtilizationProject/devops-studio
git pull --ff-only
```

### 2.2 nginx 構文チェック（必須）
```
docker compose -f /home/chronos/workspace/AIUtilizationProject/devops-studio/docker/proxy/docker-compose.proxy.yaml exec -T devops-proxy nginx -t
```

期待結果:
- syntax is ok
- test is successful

NGなら:
- 変更を戻す（ロールバック）か、修正コミットを作る。