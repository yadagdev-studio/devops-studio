# 02 Acceptance（受け入れ基準）

変更を採用するための最小基準。

## 必須
- 該当する infra/checklists/* がすべて通っている
- external-smoke が Green（該当する場合）
- deny_sensitive / security headers / health が期待通り
- 監視（内部/外部）に悪影響がない

## 変更種別ごとの最低限チェック
- nginx系：nginx -t / reload / curlヘッダ確認
- certbot系：renewフロー、hookログ確認
- firewalld/sshd：LAN制限維持、外部到達不可の再確認
- monitor系：ヘルス/通知の動作確認
- backup系：tar.gz生成、sha256、復元手順の妥当性
