#!/usr/bin/env python3
"""
Google Drive へドキュメントをアップロードするスクリプト
"""

import os
import sys
from pathlib import Path

# Google Drive API を使用するために必要なライブラリ
try:
    from google.colab import auth
    from googleapiclient.discovery import build
    from googleapiclient.http import MediaFileUpload
    IN_COLAB = True
except ImportError:
    IN_COLAB = False
    print("Note: Running outside Google Colab. Using gcloud command instead.")

def upload_to_gdrive_colab():
    """Google Colab 環境で実行する場合"""
    if not IN_COLAB:
        return False

    # Google Drive に認証
    auth.authenticate_user()
    drive = build('drive', 'v3')

    # ファイルリスト
    files_to_upload = [
        'IMPLEMENTATION_SUMMARY.md',
        'PARENT_COACHING_BACKEND_GUIDE.md',
        'PHASE_COMPLETION_REPORT.md',
        'BUILD_RELEASE_CHECKLIST.md',
        'FINAL_DELIVERY_SUMMARY.md',
    ]

    # apk フォルダを検索または作成
    results = drive.files().list(
        q="name='apk' and mimeType='application/vnd.google-apps.folder' and trashed=false",
        spaces='drive',
        fields='files(id, name)'
    ).execute()

    if results['files']:
        apk_folder_id = results['files'][0]['id']
        print(f"✅ Found apk folder: {apk_folder_id}")
    else:
        # フォルダが存在しない場合は作成
        file_metadata = {
            'name': 'apk',
            'mimeType': 'application/vnd.google-apps.folder'
        }
        folder = drive.files().create(body=file_metadata, fields='id').execute()
        apk_folder_id = folder.get('id')
        print(f"✅ Created apk folder: {apk_folder_id}")

    # ファイルをアップロード
    for filename in files_to_upload:
        filepath = Path(filename)
        if not filepath.exists():
            print(f"⚠️ File not found: {filename}")
            continue

        file_metadata = {
            'name': filename,
            'parents': [apk_folder_id]
        }

        media = MediaFileUpload(filepath, mimetype='text/plain')
        file = drive.files().create(
            body=file_metadata,
            media_body=media,
            fields='id, webViewLink'
        ).execute()

        print(f"✅ Uploaded: {filename}")
        print(f"   Link: {file.get('webViewLink')}")

    return True

def upload_to_gdrive_gcloud():
    """gcloud コマンドを使用する場合"""
    print("📲 Google Drive へのアップロード手順:")
    print()
    print("方法1: Google Colab 内で実行")
    print("-" * 50)
    print("1. Google Colab (https://colab.research.google.com/) を開く")
    print("2. このスクリプトを Notebook にコピーして実行")
    print("3. Google Drive 認証を承認")
    print()
    print("方法2: gcloud CLI を使用")
    print("-" * 50)
    print("$ gcloud auth login")
    print("$ gsutil -m cp *.md gs://your-bucket/apk/")
    print()
    print("方法3: 手動アップロード")
    print("-" * 50)
    print("1. Google Drive (https://drive.google.com/) を開く")
    print("2. 「apk」フォルダを作成")
    print("3. 以下のファイルをドラッグ&ドロップ:")
    print("   - IMPLEMENTATION_SUMMARY.md")
    print("   - PARENT_COACHING_BACKEND_GUIDE.md")
    print("   - PHASE_COMPLETION_REPORT.md")
    print("   - BUILD_RELEASE_CHECKLIST.md")
    print("   - FINAL_DELIVERY_SUMMARY.md")
    print()

def main():
    """メイン処理"""
    print("=" * 60)
    print("Google Drive へのアップロード")
    print("=" * 60)
    print()

    # 現在のディレクトリを表示
    cwd = Path.cwd()
    print(f"📂 Current directory: {cwd}")
    print()

    # ファイルの存在確認
    files = [
        'IMPLEMENTATION_SUMMARY.md',
        'PARENT_COACHING_BACKEND_GUIDE.md',
        'PHASE_COMPLETION_REPORT.md',
        'BUILD_RELEASE_CHECKLIST.md',
        'FINAL_DELIVERY_SUMMARY.md',
    ]

    missing = []
    for f in files:
        if not Path(f).exists():
            missing.append(f)

    if missing:
        print(f"⚠️ Missing files: {missing}")
        print()
    else:
        print("✅ All files found:")
        for f in files:
            size = Path(f).stat().st_size / 1024  # KB
            print(f"   - {f} ({size:.1f} KB)")
        print()

    # Colab かどうか判定
    if IN_COLAB:
        print("🟢 Google Colab 環境を検出しました。")
        print("認証情報を使用してアップロードします...")
        print()
        if upload_to_gdrive_colab():
            print("✅ アップロード完了！")
        else:
            print("❌ アップロード失敗")
    else:
        print("🟡 Google Colab 環境ではありません。")
        upload_to_gdrive_gcloud()

if __name__ == '__main__':
    main()
