# 変更ゲート: firewalld（public zone / SSH LAN制限）

対象:
- firewalld のゾーン設定（主に public）
- rich rule（SSHのLAN制限など）
- http/https の許可、不要露出の削除

目的:
- 露出事故（誤ってSSH公開/不要ポート公開）を防ぐ。

---

## 1. 変更前セルフチェック（Windows）
- [ ] 変更目的が明確（何を許可/拒否したいか）
- [ ] 影響範囲（public zone / docker zone / NIC）を把握
- [ ] ロールバック方針がある（元に戻せる）

---

## 2. 現状スナップショット（Chronos / 変更前）
以下を貼れる状態で保存（logsに保存でOK、Gitには入れない）:

```
sudo firewall-cmd --get-active-zones
sudo firewall-cmd --zone=public --list-all
sudo firewall-cmd --zone=public --list-rich-rules
sudo ss -tulpen | egrep '(:22|:80|:443)\s'
```

期待（現状の原則）:
- public: http/https は許可。
- ssh は rich rule で 192.168.1.0/24 のみ許可。
- ルータ側で 22 は未転送。（ただしこれは firewalld 外）

---

## 3. 変更適用（Chronos: AlmaLinux10.1）
- 変更は permanent で入れる。
- 反映後に reload。

例:
```
sudo firewall-cmd --permanent ...（必要な変更）
sudo firewall-cmd --reload
```

---

## 4. 変更後の必須検証（Chronos: AlmaLinux10.1）
```
sudo firewall-cmd --get-active-zones
sudo firewall-cmd --zone=public --list-all
sudo firewall-cmd --zone=public --list-rich-rules
sudo ss -tulpen | egrep '(:22|:80|:443)\s'
```

SSH到達の最低確認（LAN内から実施）:
- [ ] LAN内端末から ssh chronos が通る
- [ ] LAN外からの到達は “external-smoke で 22 closed” で担保する

---

## 5. 外部回帰（external-smoke）
- [ ] Actions の external-smoke が Green（特に port 22 must be CLOSED）

---

## 6. ロールバック（最低限）
- [ ] 変更した rule/service を戻す → --reload
- [ ] 変更前スナップショットと一致するまで戻す