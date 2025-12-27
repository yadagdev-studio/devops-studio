## Summary
（何を・なぜ変えたかを1〜3行で）

## Risk
- [ ] low（docs/内部のみ/影響小）
- [ ] medium（設定・運用に影響あり）
- [ ] high（公開面/証明書/Firewall/監視/バックアップ/Compose など）

## Change Category（該当だけチェック）
- [ ] nginx / proxy
- [ ] security headers / deny_sensitive
- [ ] certbot / deploy-hook
- [ ] firewalld
- [ ] backup
- [ ] systemd
- [ ] docker compose
- [ ] internal monitor（docker/monitor）
- [ ] GitHub Actions / runner
- [ ] DNS / domain
- [ ] docs only

## Pre-merge Notes（PR時点で分かること）
- 影響範囲:
- ロールバック方針（revert対象）:
- 参考リンク（該当チェックリスト）:
  - README の Change Gates 索引を参照（infra/checklists/*）

## Post-merge Checklist（Merge後に実施すること）
※本番反映は Chronos で行う。

- [ ] Chronos: pull（ff-only）
- [ ] Chronos: チェックリスト（infra/checklists/*）に該当があれば実施
- [ ] external-smoke: 手動実行で Green（/healthz OK, deny_sensitive 404, HSTSあり, port22 closed）
- [ ] UptimeRobot: 継続成功を確認（反映後しばらく）
- [ ] devops-monitor: FAILED が出ていないことを確認（反映後しばらく）
