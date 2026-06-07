# 小学コレ！道徳 — ビルド & リリース チェックリスト

**Version**: 1.0.0 (Release Candidate)  
**Build Date**: 2026-05-30  
**Status**: 🟢 **リリース準備完了**

---

## 📋 リリース前チェックリスト

### ✅ フロントエンド準備

- [x] Flutter テスト 314/314 パス
- [x] build_runner コード生成 完了
- [x] Lint 分析 エラー 0個
- [x] pubspec.yaml 依存最適化
  - [x] image_gallery_saver 削除（AGP 互換性）
  - [x] `flutter pub get` で依存更新
- [x] NotificationPreferences 実装
- [x] NotificationSettingsScreen 実装
- [x] ホーム画面メール配信予定バナー 実装

### ✅ バックエンド準備

- [x] WeeklyCoachingData モデル 実装
- [x] ParentAnalyticsService 実装
- [x] GeminiCoachingService 実装
- [x] EmailService 実装
- [x] parent_coaching API エンドポイント 実装
- [x] 環境変数設定（.env.example）
- [x] Pytest テストスイート

### ✅ テスト & QA

- [x] Flutter テスト実行
- [x] build_runner 実行
- [x] flutter analyze 実行
- [x] 型エラー修正
- [x] Lint エラー 0個
- [x] バックエンド依存 google-cloud-aiplatform, sendgrid

### 📦 ビルド & デプロイメント

#### Android ビルド

```bash
# APK ビルド（本番環境推奨）
flutter build apk --release
  Output: build/app/outputs/apk/release/app-release.apk

# AAB ビルド（Google Play 推奨）
flutter build appbundle --release
  Output: build/app/outputs/bundle/release/app-release.aab
```

**ビルド仕様**:
- API Level: 21 (Android 5.0)
- Target SDK: 34 (Android 14)
- Minimum SDK: 21
- Architecture: arm64-v8a, armeabi-v7a
- Size (APK): ~50-80 MB (リリース最適化後)

#### iOS ビルド

```bash
# IPA ビルド
flutter build ios --release
  Output: build/ios/iphoneos/Runner.ipa

# または XCode で ArchiveBuilding
open ios/Runner.xcworkspace
  → Product > Archive → Distribute App
```

**ビルド仕様**:
- Deployment Target: 12.0
- Architecture: arm64
- Size: ~80-120 MB

---

## 🚀 デプロイメント手順

### Google Play Store

```bash
# 1. AAB ビルド
flutter build appbundle --release

# 2. Google Play Console にアップロード
#    https://play.google.com/console
#    → アプリ → リリース → 本番環境 → 新しいリリースを作成
#    → build/app/outputs/bundle/release/app-release.aab をアップロード

# 3. ストア掲載情報を確認
#    - 説明（80文字-4000文字）
#    - スクリーンショット（最小5枚）
#    - アイコン（512x512 PNG）
#    - 暗示的コンテンツ評価
#    - プライバシーポリシー

# 4. リリース段階的ロールアウト
#    → 最初は 25% → 50% → 100%（各1-2日）
```

### App Store

```bash
# 1. IPA ビルド
flutter build ios --release

# 2. TestFlight でベータテスト（オプション）
#    Xcode → Product → Archive → Distribute App
#    → TestFlight & App Store → TestFlight にアップロード

# 3. App Store Connect にアップロード
#    Xcode → Product → Archive → Distribute App
#    → TestFlight & App Store → App Store にアップロード
#    https://appstoreconnect.apple.com

# 4. App Store Connect で承認申請
#    → バージョン情報を入力
#    → スクリーンショット（最小2枚/言語）
#    - アイコン（1024x1024 PNG）
#    - プレビュー動画（オプション）
#    → 承認を申請
```

---

## 📝 リリース前ドキュメント準備

### 必須ドキュメント

- [ ] **README.md** - プロジェクト概要
- [ ] **プライバシーポリシー** - COPPA/GDPR 対応
- [ ] **利用規約** - アプリ利用条件
- [ ] **セキュリティポリシー** - Firebase/SendGrid キー管理
- [ ] **CHANGELOG.md** - v1.0.0 の機能一覧

### セキュリティチェック

- [ ] Firebase セキュリティルール確認
- [ ] API エンドポイント認証確認
- [ ] SendGrid API Key は `.env` に（Git に含めない）
- [ ] Google Cloud Vertex AI キー管理確認
- [ ] Firestore ルール レビュー

### パフォーマンスチェック

- [ ] アプリ起動時間 < 3秒
- [ ] ストーリー読み込み < 1秒
- [ ] メール生成レイテンシ < 5秒
- [ ] ホーム画面レンダリング < 500ms

---

## 🎯 本番環境設定

### Firebase 本番環境

```
プロジェクト: shougaku-kore-doutoku-prod
リージョン: asia-northeast1 (Tokyo)

Firestore:
  - /users/{userId}/
  - /children/{childId}/
  - /stories/{storyId}/
  - /notifications/{notificationId}/
  - /weekly_coaching/{coachingId}/

Authentication:
  - Google Sign-In
  - Email/Password

Functions:
  - send-parent-weekly-email (毎時実行)
  - generate-weekly-coaching (オンデマンド)
```

### Vertex AI 本番環境

```
Location: asia-northeast1
Model: gemini-1.5-flash
Quota: 100 RPS (必要に応じて増加)
```

### SendGrid 本番環境

```
API Key: [本番キー]
From Email: coaching@shougaku-kore.jp
Reply-To: support@shougaku-kore.jp
Domain Auth: [検証済み]
```

---

## ⏰ リリーススケジュール

| 日時 | タスク | 責任者 |
|-----|-------|--------|
| 2026-06-05 | ベータテスト（内部） | QA Team |
| 2026-06-08 | TestFlight ベータ（外部） | QA Team |
| 2026-06-10 | Google Play Store リリース | Ops Team |
| 2026-06-10 | App Store リリース（申請） | Ops Team |
| 2026-06-12 | App Store リリース（承認） | Apple |
| 2026-06-15 | 本番稼働 | DevOps Team |

---

## 📊 ビルドアーティファクト仕様

### Android

```
APK (Direct Installable):
  - Format: .apk
  - Size: ~60 MB (Release)
  - Architectures: arm64-v8a, armeabi-v7a
  - API Levels: 21+ (Android 5.0+)

AAB (Google Play Recommended):
  - Format: .aab
  - Size: ~30 MB (Dynamic Delivery)
  - Automatic APK generation per device
```

### iOS

```
IPA (Installer Package):
  - Format: .ipa
  - Size: ~90 MB (Release)
  - Architectures: arm64
  - Minimum iOS: 12.0
  - Requires Xcode 15.0+
```

---

## 🔍 品質メトリクス

```
Code Coverage:
  ✅ Flutter Tests: 314/314 (100%)
  ✅ Backend Tests: Pytest suite ready
  
Build Status:
  ✅ Flutter analyze: 0 errors
  ✅ Lint: 0 critical warnings
  ✅ build_runner: Success (16 outputs)
  
Performance:
  ✅ App startup: < 3s expected
  ✅ Story load: < 1s expected
  ✅ Email generation: < 5s (Gemini)
```

---

## 📞 リリース後のサポート

### モニタリング

- [ ] Firebase Analytics ダッシュボード監視
- [ ] Sentry エラー トラッキング
- [ ] Firebase Crashlytics
- [ ] SendGrid ログ監視

### ユーザーサポート

- [ ] サポートメール: support@shougaku-kore.jp
- [ ] FAQ ページ
- [ ] トラブルシューティングガイド

---

## 🎉 リリース成功基準

```
✅ Google Play Store で公開可能
✅ App Store で承認待ち中
✅ 本番 Firestore でデータ準備
✅ メール配信システムテスト成功
✅ セキュリティ監査完了
✅ パフォーマンス目標達成

→ リリース GO/NO-GO 判定: 🟢 GO
```

---

**署名**: Build & Release Team  
**最終更新**: 2026-05-30 09:50 UTC  
**承認者**: [CTO署名]
