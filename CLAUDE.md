# 小学コレ！道徳 — Claude Code 開発ガイド

## プロジェクト概要
- **名前**: 小学コレ！道徳
- **説明**: 小学3-4年生が、日常のジレンマを選択肢型ストーリーで体験しながら、親向けの月次成長レポートで判断力の成長を見守るサブスク型道徳学習アプリ
- **スタック**: Flutter + Riverpod + Firebase + FastAPI

## セットアップ

### 初回セットアップ
```bash
flutter pub get
flutter pub run build_runner build
```

### Firebase 設定
1. Firebase コンソールでプロジェクトを作成
2. `lib/config/firebase_config.dart` に認証情報を設定
3. `google-services.json` (Android) と `GoogleService-Info.plist` (iOS) を配置

## ディレクトリ構成

```
lib/
├── config/          # Firebase・API 設定
├── models/          # データモデル
├── providers/       # Riverpod プロバイダー
├── screens/         # UI スクリーン
│   ├── auth/        # ログイン・登録
│   ├── home/        # ホーム画面
│   ├── story/       # ストーリー学習
│   ├── library/     # ライブラリ
│   ├── report/      # 親向けレポート
│   └── settings/    # 設定
├── services/        # API・Firebase サービス
├── widgets/         # 再利用可能なウィジェット
├── utils/           # ユーティリティ関数
└── main.dart        # エントリーポイント
```

## 実装フェーズ

### Phase 1: 基盤構築（Week 1-2）
- [ ] Firebase 認証の実装
- [ ] API サービスの実装
- [ ] ローカルDB（Hive）初期化
- [ ] ホーム画面の基本レイアウト

### Phase 2: コンテンツ管理（Week 3-4）
- [ ] ストーリー一覧画面
- [ ] ストーリー学習画面
- [ ] 選択肢の分岐表示

### Phase 3: 学習進捗管理（Week 5-6）
- [ ] 選択履歴の保存
- [ ] バッジシステム
- [ ] 進捗表示

### Phase 4: 親向け機能（Week 7-9）
- [ ] 月次レポート表示
- [ ] レーダーチャート実装
- [ ] 成長パターン分析

### Phase 5: 最適化・リリース（Week 10-15）
- [ ] UI・UX 最適化
- [ ] パフォーマンス改善
- [ ] テスト実施
- [ ] App Store / Google Play 申請

## 命名規則

### Dart ファイル
- **ファイル名**: snake_case (例: `story_learning_screen.dart`)
- **クラス名**: PascalCase (例: `StoryLearningScreen`)
- **関数名**: camelCase (例: `fetchStories()`)
- **定数**: UPPER_SNAKE_CASE (例: `API_BASE_URL`)

### Riverpod プロバイダー
```dart
// FutureProvider
final storyDetailProvider = FutureProvider.autoDispose
    .family<Story, String>((ref, storyId) async { ... });

// StateProvider
final selectedChildProvider = StateProvider<String>((ref) => '');
```

## 注意点

- COPPA準拠: 子どもの個人情報は最小化（名前・学年のみ）
- オフライン対応: ダウンロード済みコンテンツはオフラインで表示
- アクセシビリティ: 音声ナレーション機能を実装
- パフォーマンス: アプリ起動 3秒以内、ストーリー読み込み 1秒以内

## デバッグ・テスト

### ホットリロード
```bash
flutter run
# 実行中に 'r' を押すと hot reload
# 'R' を押すと hot restart
```

### コード生成
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### テスト実行
```bash
flutter test
```

## 参考資料
- 企画書: `../../shougaku-kore-doutoku-kika-v2.md`
- 設計ドキュメント: `../../shougaku-kore-doutoku-design.md`
