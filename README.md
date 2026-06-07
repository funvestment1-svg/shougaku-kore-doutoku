# 小学コレ！道徳 ～かっこいい大人になるために～

小学3-4年生が、日常のジレンマを選択肢型ストーリーで体験しながら、親向けの月次成長レポートで判断力の成長を見守るサブスク型道徳学習アプリです。

## 特徴

- 📖 **ジレンマ型ストーリー**: 正解のない日常の判断を通じて、子どもが自分で考える力を育成
- 👨‍👧 **親向け月次レポート**: 子どもの道徳的判断パターンを可視化し、成長を見守る（業界初）
- 🎯 **4つのテーマ特化**: 友人関係・家族・自分探し・社会に絞り、ニーズ直撃
- 👤 **偉人 + 同年代キャラ**: 実在の人物と架空キャラで、子どもの実行可能性を高める

## セットアップ

### 前提条件
- Flutter 3.x 以上
- Dart 3.x 以上
- iOS 14+ / Android 6.0+ デバイス

### インストール

```bash
# 依存関係をインストール
flutter pub get

# コード生成
flutter pub run build_runner build

# 開発実行
flutter run
```

## アーキテクチャ

- **フロントエンド**: Flutter + Riverpod + Firebase
- **バックエンド**: Python FastAPI + PostgreSQL + Firestore
- **認証**: Firebase Authentication
- **キャッシング**: Hive + Redis

詳細は [設計ドキュメント](../../shougaku-kore-doutoku-design.md) を参照。

## 開発

すべての開発手順は [CLAUDE.md](./CLAUDE.md) を参照してください。

## ライセンス

Proprietary - 小学コレ（Petit Works）
