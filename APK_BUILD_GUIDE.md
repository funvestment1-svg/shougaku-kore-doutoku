# 小学コレ！道徳 — APK ビルド実行ガイド

**Date**: 2026-06-01  
**Status**: ⚠️ Windows環境での制限あり、CI/CDでの実行推奨

---

## 📋 ビルド環境の問題

### Windows ローカルビルドのエラー

```
error: Could not start thread DartWorker: 22
os=windows, arch=x64
```

**原因**: Windows 環境でのメモリ制限により、Gradle `assembleRelease` タスク実行時に DartWorker スレッドが開始不可

---

## ✅ 推奨: GitHub Actions CI/CD でのビルド

### 1️⃣ ワークフロー作成

`.github/workflows/build-release.yml`:

```yaml
name: Build APK & AAB

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Java
        uses: actions/setup-java@v3
        with:
          java-version: '17'
          distribution: 'temurin'
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.5'
          channel: 'stable'
      
      - name: Get dependencies
        run: flutter pub get
      
      - name: Build APK
        run: flutter build apk --release
      
      - name: Build AAB
        run: flutter build appbundle --release
      
      - name: Upload APK artifact
        uses: actions/upload-artifact@v3
        with:
          name: app-release.apk
          path: build/app/outputs/apk/release/app-release.apk
      
      - name: Upload AAB artifact
        uses: actions/upload-artifact@v3
        with:
          name: app-release.aab
          path: build/app/outputs/bundle/release/app-release.aab
      
      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          files: |
            build/app/outputs/apk/release/app-release.apk
            build/app/outputs/bundle/release/app-release.aab
```

### 2️⃣ リリースタグで自動実行

```bash
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

GitHub Actions が自動的にビルドを開始します ✅

---

## 🔄 代替: WSL2 でのローカルビルド

### セットアップ

```bash
# WSL2 Ubuntu に Flutter をインストール
wsl
sudo apt update
sudo apt install -y git curl

# Flutter SDK インストール
git clone https://github.com/flutter/flutter.git ~/flutter
export PATH=$PATH:~/flutter/bin
flutter config --android-studio-dir=/mnt/c/Program\ Files/Android/Android\ Studio

# Android SDK 設定
export ANDROID_SDK_ROOT=/mnt/c/Users/Administrator/AppData/Local/Android/Sdk
export PATH=$PATH:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin
```

### ビルド実行

```bash
cd /mnt/c/Users/Administrator/OneDrive/subwork/smartphone/smart-claude-code/.claude/worktrees/epic-feynman-17d4e8/apps/shougaku-kore-doutoku

# APK ビルド
flutter build apk --release

# または AAB ビルド
flutter build appbundle --release
```

---

## 🖥️ リモートマシンでのビルド

### Mac での iOS + Android ビルド

```bash
ssh user@mac-machine

cd ~/projects/shougaku-kore-doutoku

# iOS ビルド
flutter build ios --release

# Android ビルド
flutter build apk --release
flutter build appbundle --release
```

---

## 📦 ビルド出力パス

### APK
```
build/app/outputs/apk/release/app-release.apk
```

**サイズ**: 約 50-80 MB  
**用途**: 直接インストール（テスト用）

### AAB
```
build/app/outputs/bundle/release/app-release.aab
```

**サイズ**: 約 30-40 MB  
**用途**: Google Play Store リリース（推奨）

### iOS IPA
```
build/ios/iphoneos/Runner.ipa
```

**サイズ**: 約 80-120 MB  
**用途**: App Store リリース

---

## 🚀 Google Play Store リリース手順

### 1️⃣ AAB をアップロード

```bash
# Google Play Console へログイン
# https://play.google.com/console

# リリース > 本番環境 > 新しいリリースを作成
# build/app/outputs/bundle/release/app-release.aab をアップロード
```

### 2️⃣ リリース情報を入力

- タイトル: `小学コレ！道徳 v1.0.0`
- 説明: `親向けAIコーチング機能を追加しました`
- スクリーンショット: 5枚以上
- アイコン: 512×512 PNG

### 3️⃣ 段階的ロールアウト

```
25% → 検証（1-2日）
  ↓
50% → 拡大テスト（2-3日）
  ↓
100% → 本番公開
```

---

## 📋 チェックリスト

- [ ] GitHub Actions ワークフロー作成
- [ ] リリースタグ作成 (`v1.0.0`)
- [ ] APK/AAB ビルド完了
- [ ] Google Play Console へアップロード
- [ ] App Store Connect へ申請
- [ ] ベータテスト実施（TestFlight）
- [ ] 本番リリース承認

---

## 🆘 トラブルシューティング

### Windows メモリ不足エラー

```
error: Could not start thread DartWorker
```

**解決方法**:
1. GitHub Actions （推奨）
2. WSL2 での実行
3. リモートマシンでのビルド

### Gradle キャッシュエラー

```bash
flutter clean
flutter pub get
flutter build apk --release
```

### 署名エラー

```bash
keytool -genkey -v -keystore ~/my-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias my-key-alias
```

`android/key.properties` に署名情報を設定

---

## 📞 サポート

ビルド実行に関する質問やエラーは、GitHub Actions のログを確認してください。

---

**署名**: Claude AI  
**最終更新**: 2026-06-01
