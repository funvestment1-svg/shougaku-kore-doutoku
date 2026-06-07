"""メール送信サービス - EmailService (SendGrid)"""

import logging
from typing import Dict, Optional
from datetime import datetime
from jinja2 import Template
from sendgrid import SendGridAPIClient
from sendgrid.helpers.mail import Mail, Email, To, Content, HtmlContent

from app.models import WeeklyCoachingData

logger = logging.getLogger(__name__)


class EmailService:
    """SendGrid を使用してメール送信を管理"""

    def __init__(self, sendgrid_api_key: str):
        self.sg = SendGridAPIClient(sendgrid_api_key)
        self.from_email = "coaching@shougaku-kore.jp"

    async def send_weekly_coaching_email(
        self,
        parent_email: str,
        child_name: str,
        coaching_data: WeeklyCoachingData,
    ) -> Dict[str, any]:
        """
        親に対して週次コーチングメールを送信

        Args:
            parent_email: 親のメールアドレス
            child_name: 子の名前
            coaching_data: 週次コーチング分析データ

        Returns:
            送信結果 {"success": bool, "message_id": str, "error": str}
        """

        try:
            # HTML メール本文を構築
            html_content = self._render_email_template(child_name, coaching_data)

            # SendGrid メール オブジェクト を作成
            message = Mail(
                from_email=self.from_email,
                to_emails=To(parent_email),
                subject=f"[小学コレ！道徳] {child_name}の今週の学習レポート",
                html_content=HtmlContent(html_content),
            )

            # メールを送信
            response = self.sg.send(message)

            # レスポンスからメッセージID を抽出
            message_id = response.headers.get("X-Message-ID", "")

            logger.info(f"メール送信成功: {parent_email} ({message_id})")

            return {
                "success": True,
                "message_id": message_id,
                "parent_email": parent_email,
                "sent_at": datetime.utcnow().isoformat(),
            }

        except Exception as e:
            logger.error(f"メール送信エラー ({parent_email}): {e}")
            return {
                "success": False,
                "error": str(e),
                "parent_email": parent_email,
            }

    def _render_email_template(
        self,
        child_name: str,
        coaching_data: WeeklyCoachingData,
    ) -> str:
        """
        Jinja2 テンプレートを使用して HTML メール本文を生成
        """

        template_html = """<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ child_name }}の週間学習レポート</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background-color: #f5f5f5;
            margin: 0;
            padding: 20px;
        }
        .container {
            max-width: 600px;
            margin: 0 auto;
            background-color: #ffffff;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            overflow: hidden;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px 20px;
            text-align: center;
        }
        .header h1 {
            margin: 0;
            font-size: 24px;
        }
        .content {
            padding: 30px 20px;
        }
        .section {
            margin-bottom: 25px;
        }
        .section-title {
            font-size: 16px;
            font-weight: bold;
            color: #333;
            margin-bottom: 10px;
            display: flex;
            align-items: center;
        }
        .section-title .emoji {
            margin-right: 8px;
            font-size: 20px;
        }
        .stats {
            background-color: #f9f9f9;
            border-left: 4px solid #667eea;
            padding: 15px;
            border-radius: 4px;
            margin-bottom: 15px;
        }
        .stat-item {
            display: flex;
            justify-content: space-between;
            margin-bottom: 8px;
            font-size: 14px;
        }
        .stat-item strong {
            color: #333;
        }
        .stat-value {
            color: #667eea;
            font-weight: bold;
        }
        .virtue-list {
            font-size: 14px;
            line-height: 1.8;
            color: #555;
        }
        .virtue-positive {
            color: #27ae60;
        }
        .virtue-negative {
            color: #e74c3c;
        }
        .message-box {
            background-color: #f0f4ff;
            border-left: 4px solid #667eea;
            padding: 15px;
            border-radius: 4px;
            font-size: 14px;
            line-height: 1.6;
            color: #555;
            margin-bottom: 15px;
        }
        .cta-button {
            display: inline-block;
            background-color: #667eea;
            color: white;
            padding: 12px 24px;
            border-radius: 4px;
            text-decoration: none;
            font-size: 14px;
            font-weight: bold;
            text-align: center;
            margin-right: 10px;
            margin-bottom: 10px;
        }
        .cta-button:hover {
            background-color: #764ba2;
        }
        .footer {
            background-color: #f9f9f9;
            padding: 20px;
            text-align: center;
            font-size: 12px;
            color: #999;
            border-top: 1px solid #eee;
        }
        .footer a {
            color: #667eea;
            text-decoration: none;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>📧 {{ child_name }}の週間学習レポート</h1>
            <p style="margin: 10px 0 0 0; font-size: 14px;">小学コレ！道徳</p>
        </div>

        <div class="content">
            <!-- 学習成績サマリー -->
            <div class="section">
                <div class="section-title">
                    <span class="emoji">📈</span>
                    この週の学習成績
                </div>
                <div class="stats">
                    <div class="stat-item">
                        <strong>完了ストーリー:</strong>
                        <span class="stat-value">{{ weekly_stories_completed }}個</span>
                    </div>
                    <div class="stat-item">
                        <strong>学習時間:</strong>
                        <span class="stat-value">{{ weekly_study_minutes }}分</span>
                    </div>
                    <div class="stat-item">
                        <strong>獲得ポイント:</strong>
                        <span class="stat-value">{{ weekly_points_earned }}ポイント</span>
                    </div>
                </div>
            </div>

            <!-- 成長ポイント -->
            <div class="section">
                <div class="section-title">
                    <span class="emoji">🌟</span>
                    {{ child_name }}の成長ポイント
                </div>
                <div class="message-box">
                    {{ highlight }}
                </div>
            </div>

            <!-- 徳目分析 -->
            <div class="section">
                <div class="section-title">
                    <span class="emoji">💫</span>
                    徳目の伸び
                </div>
                <div class="virtue-list">
                    <div>
                        <strong>最も成長した徳目:</strong>
                        <span class="virtue-positive">{{ strongest_virtue or '未評価' }}</span>
                    </div>
                    <div style="margin-top: 8px;">
                        <strong>改善が必要な徳目:</strong>
                        <span class="virtue-negative">{{ weakest_virtue or '未評価' }}</span>
                    </div>
                </div>
            </div>

            <!-- 来週へのアドバイス -->
            <div class="section">
                <div class="section-title">
                    <span class="emoji">💡</span>
                    来週へのアドバイス
                </div>
                <div class="message-box">
                    {{ advice }}
                </div>
            </div>

            <!-- 保護者へのメッセージ -->
            <div class="section">
                <div class="section-title">
                    <span class="emoji">👨‍👩‍👧</span>
                    保護者へのメッセージ
                </div>
                <div class="message-box">
                    {{ parent_tip }}
                </div>
            </div>

            <!-- 次のマイルストーン -->
            {% if next_milestone %}
            <div class="section">
                <div class="section-title">
                    <span class="emoji">🎯</span>
                    次のマイルストーン
                </div>
                <div class="stats">
                    <p style="margin: 0; color: #555;">{{ next_milestone }}</p>
                </div>
            </div>
            {% endif %}

            <!-- トレンド分析 -->
            {% if trend_analysis %}
            <div class="section">
                <div class="section-title">
                    <span class="emoji">📊</span>
                    進捗トレンド
                </div>
                <p style="font-size: 14px; color: #555;">{{ trend_analysis }}</p>
            </div>
            {% endif %}

            <!-- CTAボタン -->
            <div style="text-align: center; margin-top: 30px;">
                <a href="https://app.shougaku-kore.jp/reports/{{ child_id }}" class="cta-button">
                    アプリで詳細を確認する
                </a>
                <br>
                <a href="https://app.shougaku-kore.jp/settings/notifications" class="cta-button" style="background-color: #95a5a6;">
                    通知設定を変更する
                </a>
            </div>

        </div>

        <div class="footer">
            <p>このメールは自動送信です。返信はしないでください。</p>
            <p>
                <a href="https://support.shougaku-kore.jp">サポート</a> |
                <a href="https://shougaku-kore.jp/privacy">プライバシーポリシー</a>
            </p>
            <p>&copy; 小学コレ！道徳. All rights reserved.</p>
        </div>
    </div>
</body>
</html>
"""

        # Jinja2 テンプレートをレンダリング
        template = Template(template_html)
        html_content = template.render(
            child_name=child_name,
            child_id=coaching_data.child_id,
            weekly_stories_completed=coaching_data.weekly_stories_completed,
            weekly_study_minutes=coaching_data.weekly_study_minutes,
            weekly_points_earned=coaching_data.weekly_points_earned,
            strongest_virtue=coaching_data.strongest_virtue,
            weakest_virtue=coaching_data.weakest_virtue,
            highlight=coaching_data.highlight or "頑張りました！",
            advice=coaching_data.advice or "次週も応援しています！",
            parent_tip=coaching_data.parent_tip or "お子様の成長を応援いただきありがとうございます。",
            next_milestone=coaching_data.next_milestone,
            trend_analysis=coaching_data.trend_analysis,
        )

        return html_content
