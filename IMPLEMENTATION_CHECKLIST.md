# 小学コレ！道徳 v1.1+v1.2 実装完了チェックリスト

## ✅ フロントエンド実装（完了）
- [x] lib/ ディレクトリ構造構築
- [x] main.dart + firebase_options.dart
- [x] モデルクラス（6個）
  - [x] distribution_response.dart
  - [x] revisit_schedule.dart
  - [x] parent_child_comparison.dart
  - [x] kindness_mission.dart
  - [x] ai_features.dart
- [x] API サービス（api_service.dart）
- [x] Riverpod プロバイダー（4個）
- [x] UIウィジェット（4個）

## ✅ バックエンド実装（完了）
- [x] FastAPI アプリ構造
- [x] Pydantic モデル（5個）
- [x] APIエンドポイント（6個）
  - [x] stories.py — ① 全国分布
  - [x] revisit.py — ② 再訪
  - [x] parent_child.py — ④ 親子
  - [x] kindness.py — ⑥ ミッション
  - [x] ai_features.py — ③⑤ AI機能
  - [x] batch_jobs.py — バッチジョブ
- [x] AI コスト最適化サービス（ai_optimizer.py）
- [x] Cloud Scheduler 設定

## 📋 次のステップ（本番化）

### Phase 1: 環境構築（1日）
- [ ] Firebase プロジェクト作成
- [ ] サービスアカウントキー取得
- [ ] firebase_options.dart 設定
- [ ] Firestore 初期化
  ```bash
  cd backend/scripts
  python init_firestore.py
  ```

### Phase 2: Dartコード生成（1時間）
- [ ] `flutter pub get`
- [ ] `flutter pub run build_runner build --delete-conflicting-outputs`
- [ ] 確認: lib/**/*.g.dart が生成されたか

### Phase 3: ローカルテスト（2日）
- [ ] `flutter run` で iOS/Android デバイス実行
- [ ] 各画面の UI テスト
- [ ] API 通信テスト（モック API で）
- [ ] Firestore 接続確認

### Phase 4: Firebase 接続（1日）
- [ ] android/google-services.json 配置
- [ ] ios/GoogleService-Info.plist 配置
- [ ] lib/services/firebase_service.dart 実装
- [ ] 本番 Firestore との接続確認

### Phase 5: デプロイ（1日）
- [ ] Cloud Run に FastAPI デプロイ
- [ ] Cloud Scheduler ジョブ登録
  ```bash
  gcloud scheduler jobs create http monthly-reason-analysis \
    --schedule="0 0 1 * *" \
    --uri="https://api.shougaku-kore.jp/api/v1/jobs/monthly-reason-analysis" \
    --http-method=POST
  ```
- [ ] Google Play / App Store 申請

## 🎯 コスト構成（月額）
| 項目 | コスト | 
|------|--------|
| v1.1 機能（①②④⑥） | $0 |
| v1.2 AI（③⑤） | ¥11 |
| **合計** | **¥11（予算$300の0.04%）** |

## 📝 重要な TODO
- [ ] Firestore セキュリティルール設定
- [ ] COPPA コンプライアンス確認
- [ ] Firebase Authentication 実装
- [ ] クラウド関数（Scheduler ジョブ）の本番化

---

**実装完了：2026年6月14日**
**次のリリース：v1.1（2026年7月中旬）→ v1.2（2026年8月中旬）**
