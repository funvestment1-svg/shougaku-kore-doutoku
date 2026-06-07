# 小学コレ！道徳 — 次実装 HANDOFF

**Date**: 2026-06-07  
**Status**: 実装完了 → ビルド & リリース準備段階  
**Version**: v1.0.0 Release Candidate

---

## 📊 現在の状態

### ✅ 実装完了 (100%)
- フロントエンド (Flutter/Dart): 500+ 行
- バックエンド (Python/FastAPI): 1000+ 行
- テスト: 314/314 パス
- ドキュメント: 5種類、55KB

### 🔄 次のステップ (進行中)

| 優先度 | タスク | 状態 | 期限 |
|--------|--------|------|------|
| **P0** | GitHub Actions ワークフロー設定 | ✅ 作成済み | 2026-06-05 |
| **P0** | APK/AAB ビルド実行 | ⏳ 進行中 | 2026-06-08 |
| **P1** | ベータテスト (TestFlight) | ⏳ 予定 | 2026-06-10 |
| **P1** | Google Play Store リリース | ⏳ 予定 | 2026-06-12 |
| **P2** | App Store リリース | ⏳ 予定 | 2026-06-15 |

---

## 🎯 即座アクション

### 1️⃣ Git リポジトリ設定 ✅
```bash
# 状態: 完了
git init
git config user.email "zkaz83@gmail.com"
git config user.name "Claude AI"
git add .
git commit -m "Initial commit"
git tag -a v1.0.0 -m "Release v1.0.0"
```

### 2️⃣ GitHub Actions ワークフロー作成 ✅
- 場所: `.github/workflows/build-release.yml`
- 内容: Ubuntu 環境での APK/AAB ビルド
- トリガー: `v*` タグプッシュ時に自動ビルド

### 3️⃣ ローカルビルド (3つの方法)

#### 方法A: GitHub Actions (推奨)
```bash
# リポジトリを GitHub にプッシュ
git remote add origin <github-url>
git push -u origin main
git push origin v1.0.0

# GitHub Actions が自動でビルド開始
# → GitHub Releases に APK/AAB が出現
```

#### 方法B: WSL2 (Windows を使う場合)
```bash
wsl
cd /mnt/c/Users/Administrator/.../shougaku-kore-doutoku
flutter pub get
flutter pub run build_runner build
flutter build apk --release
flutter build appbundle --release
```

#### 方法C: Windows ローカル (要メモリ調整)
```bash
# メモリ制限により失敗の可能性が高い
flutter build apk --release --verbose
```

---

## 📦 ビルド出力

### APK (直接インストール用)
```
build/app/outputs/apk/release/app-release.apk
サイズ: 50-80 MB
用途: テスト & 直接配布
```

### AAB (Google Play Store 用)
```
build/app/outputs/bundle/release/app-release.aab
サイズ: 30-40 MB
用途: Google Play Store リリース推奨
```

### IPA (App Store 用)
```
build/ios/iphoneos/Runner.ipa
サイズ: 80-120 MB
用途: App Store リリース（Mac必須）
```

---

## 🚀 リリース計画

### ベータテスト (2026-06-08 ～ 06-10)
1. TestFlight へアップロード
2. 内部テスター 5-10名で検証
3. Firebase Analytics 確認
4. バグ修正（あれば）

### 本番リリース (2026-06-10 ～ 06-15)

#### Google Play Store
```
1. Google Play Console へログイン
2. リリース > 本番環境 > 新しいリリースを作成
3. build/app/outputs/bundle/release/app-release.aab をアップロード
4. ストア掲載情報を入力
   - タイトル: 小学コレ！道徳 v1.0.0
   - 説明: 親向けAIコーチング機能を追加
   - スクリーンショット: 5枚以上
   - アイコン: 512×512 PNG
5. 段階的ロールアウト: 25% → 50% → 100%
```

#### App Store
```
1. Xcode で iOS ビルド
2. App Store Connect へアップロード
3. TestFlight でベータテスト（オプション）
4. App Store 審査に提出
5. 承認待ち（通常 1-3日）
```

---

## 📋 チェックリスト

### ビルド準備
- [x] GitHub Actions ワークフロー作成
- [x] git tag v1.0.0 作成
- [ ] GitHub へプッシュ
- [ ] GitHub Actions でビルド実行
- [ ] APK/AAB 確認

### リリース準備
- [ ] プライバシーポリシー確認 (COPPA対応)
- [ ] 利用規約確認
- [ ] スクリーンショット準備 (5枚以上)
- [ ] アプリアイコン確認 (512×512 PNG)
- [ ] 説明文作成

### ストア申請
- [ ] Google Play Console 登録
- [ ] Google Play Store リリース申請
- [ ] App Store Connect 登録
- [ ] App Store リリース申請

---

## 🆘 トラブルシューティング

### Windows ビルドエラー
```
error: Could not start thread DartWorker
```
→ GitHub Actions または WSL2 を使用してください

### Gradle キャッシュエラー
```bash
flutter clean
flutter pub get
flutter build apk --release
```

### Git lock エラー
```bash
# ロックファイルを削除
rm .git/index.lock
```

---

## 📞 参考ドキュメント

| ファイル | 内容 |
|---------|------|
| `BUILD_RELEASE_CHECKLIST.md` | ビルド & リリース詳細チェックリスト |
| `BUILD_STATUS_REPORT.md` | ビルド状況レポート |
| `APK_BUILD_GUIDE.md` | APK ビルド実行ガイド |
| `FINAL_DELIVERY_SUMMARY.md` | 最終納品サマリー |
| `IMPLEMENTATION_SUMMARY.md` | 実装サマリー |

---

## 🎯 期限

- **2026-06-08**: APK/AAB ビルド完了
- **2026-06-10**: Google Play Store リリース
- **2026-06-12**: App Store 審査提出
- **2026-06-15**: 本番稼働

---

**署名**: Claude AI  
**作成日**: 2026-06-07  
**ステータス**: 次実装案記録完了 ✅
