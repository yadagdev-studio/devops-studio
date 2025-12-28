# LLM運用 Runbook（DevOps-Studio）

目的：ローカルLLM運用（案出し→レビュー→統合→本番反映）を、事故なく再現性高く回す。

## フロー（固定）
1) PoC/Design：実装案・パッチ案を作る（Continue prompts: patch-request）
2) Review：批判的レビューで穴を潰す（Continue prompts: review-request）
3) Integration：Windowsで統合し、人間が最終判断
4) Production：Chronosで最小手順で反映（pull/compose/確認）

## 目次
- 01-templates.md：入力/出力テンプレ（依頼書・パッチ・レビュー）
- 02-acceptance.md：受け入れ基準（テスト/静的解析/ゲート/確認）
- 03-info-boundary.md：公開情報と内部情報の線引き
- 04-incident.md：秘密を貼った/漏らした時の初動
