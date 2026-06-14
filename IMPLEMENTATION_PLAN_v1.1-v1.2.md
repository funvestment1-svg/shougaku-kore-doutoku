# 小学コレ！道徳 — v1.1＆v1.2 実装設計書

**Version**: v1.1 (基盤) + v1.2 (AI最適化)  
**Release Target**: 2026年7月中旬 + 8月中旬  
**AI Budget**: 月¥11（$0.081）  
**Total Implementation**: 3週間  

---

## 📋 実装セット概要

| フェーズ | 機能 | リリース | AI | 期間 |
|---------|------|---------|-----|------|
| **v1.1** | ①全国選択分布 + ②再訪 + ④親子 + ⑥発見 | 7月中旬 | $0 | 2週間 |
| **v1.2** | ③分析（抽出版）+ ⑤創作（バッチ版） | 8月中旬 | ¥11 | 1週間 |

---

# v1.1：基盤レイヤー実装（AI$0）

## ① 全国選択分布機能

### 1.1 機能概要
```
子どもがジレンマに回答後、全国の選択割合を匿名データで表示。
「正解のなさ」を数字で体感する体験。

例：
「友達のヒミツを聞いちゃった。どうする？」
→ 自分の選択：B「本人に直接話す」
→ 表示：
   A. だまっておく        🟦🟦🟦🟦 42% (1,050人)
   B. 本人に直接話す      🟩🟩🟩 31% (775人)
   C. 先生に相談する      🟨🟨 27% (675人)
```

### 1.2 バックエンド設計

#### 1.2.1 DB スキーマ修正
```sql
-- 既存テーブル: answers
-- 追加カラム: なし（既存の answer_choice で十分）

-- 新規テーブル: answer_statistics（日次集計キャッシュ）
CREATE TABLE answer_statistics (
  id SERIAL PRIMARY KEY,
  story_id UUID NOT NULL REFERENCES stories(id),
  option_a_count INTEGER DEFAULT 0,
  option_b_count INTEGER DEFAULT 0,
  option_c_count INTEGER DEFAULT 0,
  option_d_count INTEGER DEFAULT 0,
  total_responses INTEGER DEFAULT 0,
  calculated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(story_id, calculated_at::DATE)
);

-- インデックス
CREATE INDEX idx_answer_statistics_story_id ON answer_statistics(story_id);
CREATE INDEX idx_answer_statistics_calculated_at ON answer_statistics(calculated_at);
```

#### 1.2.2 APIエンドポイント設計
```python
# FastAPI エンドポイント追加

# GET /api/v1/stories/{story_id}/distribution
# 全国選択分布を取得
@router.get("/stories/{story_id}/distribution")
async def get_answer_distribution(story_id: str):
    """
    パラメータ:
    - story_id: ストーリーID
    
    レスポンス:
    {
        "story_id": "xxx",
        "title": "友達のヒミツ",
        "options": [
            {
                "option": "A",
                "text": "だまっておく",
                "count": 1050,
                "percentage": 42,
                "color": "blue"
            },
            {...}
        ],
        "total_responses": 2500,
        "last_updated": "2026-06-10T12:00:00Z"
    }
    """
    stats = db.query(AnswerStatistics)\
        .filter(AnswerStatistics.story_id == story_id)\
        .order_by(AnswerStatistics.calculated_at.desc())\
        .first()
    
    return format_distribution_response(stats)
```

#### 1.2.3 日次集計ジョブ
```python
# Cloud Scheduler トリガー：毎日夜間（例：23:00 JST）

@app.post("/jobs/daily-statistics")
async def calculate_daily_statistics():
    """
    前日の全回答を集計し、answer_statistics テーブルに保存
    """
    yesterday = date.today() - timedelta(days=1)
    
    # 前日の全ストーリーの選択集計
    stories = db.query(Story).all()
    
    for story in stories:
        counts = db.query(
            Answer.answer_choice,
            func.count(Answer.id).label('count')
        ).filter(
            Answer.story_id == story.id,
            Answer.created_at >= yesterday,
            Answer.created_at < date.today()
        ).group_by(Answer.answer_choice).all()
        
        # 結果を answer_statistics に挿入
        stats = AnswerStatistics(
            story_id=story.id,
            option_a_count=...,
            option_b_count=...,
            ...
        )
        db.add(stats)
    
    db.commit()
```

### 1.3 フロントエンド設計

#### 1.3.1 UI コンポーネント
```dart
// lib/screens/story/story_result_screen.dart (修正)

class DistributionWidget extends StatelessWidget {
  final String storyId;
  final String userChoice;
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DistributionResponse>(
      future: apiService.getDistribution(storyId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Loading();
        }
        
        final distribution = snapshot.data!;
        
        return Column(
          children: [
            Text(
              "全国のこどもたちは どう選んだ？",
              style: TextStyle(fontSize: 18, fontWeight: bold),
            ),
            SizedBox(height: 16),
            ...distribution.options.map((option) => 
              DistributionBar(
                option: option.option,
                text: option.text,
                percentage: option.percentage,
                count: option.count,
                isUserChoice: option.option == userChoice,
              )
            ).toList(),
            SizedBox(height: 12),
            Text(
              "全部で ${distribution.totalResponses} にんの こどもが こたえました",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            )
          ],
        );
      }
    );
  }
}

// 分布バー
class DistributionBar extends StatelessWidget {
  final String option;
  final String text;
  final double percentage;
  final int count;
  final bool isUserChoice;
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isUserChoice ? Colors.orange : Colors.blue,
                  border: isUserChoice 
                    ? Border.all(color: Colors.orange, width: 3)
                    : null,
                ),
                child: Center(
                  child: Text(
                    option,
                    style: TextStyle(color: Colors.white, fontWeight: bold),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(text, style: TextStyle(fontSize: 14)),
              ),
            ],
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    minHeight: 20,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation(
                      isUserChoice ? Colors.orange : Colors.blue
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Text(
                "${percentage.toStringAsFixed(0)}%",
                style: TextStyle(fontWeight: bold, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

### 1.4 テスト計画
```dart
// test/screens/story_result_screen_test.dart

test('全国分布表示: 回答割合が正しく表示される', () async {
  // モック
  mockApiService.mockDistribution({
    'options': [
      {'option': 'A', 'percentage': 42, 'count': 1050},
      {'option': 'B', 'percentage': 31, 'count': 775},
      {'option': 'C', 'percentage': 27, 'count': 675},
    ],
    'totalResponses': 2500
  });
  
  // テスト
  await testWidget(DistributionWidget(storyId: 'xxx', userChoice: 'B'));
  
  // 検証
  expect(find.text('42%'), findsOneWidget);
  expect(find.text('31%'), findsOneWidget);
  expect(find.text('全部で 2500 にんの こどもが こたえました'), findsOneWidget);
});
```

### 1.5 COPPA準拠チェック
```
✅ 個人特定情報なし（匿名集計のみ）
✅ IPアドレス・デバイスIDなし
✅ 地域・学校・年齢層別の集計なし
✅ 完全な匿名データ = COPPA安全
```

---

## ② 3ヶ月後の再訪システム

### 2.1 機能概要
```
3ヶ月前に回答したストーリーを再出題。
過去の選択と現在の選択を比較して「成長」を可視化。

流れ：
1. 子どもが元のストーリーを再回答
2. 結果画面で「3ヶ月前はAを選んだよ。今日はCね。」と表示
3. 親レポートに「判断の変化」として記録
```

### 2.2 バックエンド設計

#### 2.2.1 Cloud Scheduler ジョブ
```python
# Cloud Scheduler トリガー：毎月初日（例：1日 9:00 JST）

@app.post("/jobs/monthly-revisit-trigger")
async def trigger_monthly_revisit():
    """
    3ヶ月前に完了したストーリーを「再訪ストーリー」として
    当月にスケジュール
    """
    three_months_ago = date.today() - timedelta(days=90)
    
    # 3ヶ月前に回答したすべての user-story 組み合わせ
    old_answers = db.query(Answer)\
        .filter(Answer.created_at >= three_months_ago)\
        .filter(Answer.created_at < three_months_ago + timedelta(days=1))\
        .all()
    
    for answer in old_answers:
        # RevisitSchedule に登録
        revisit = RevisitSchedule(
            user_id=answer.user_id,
            story_id=answer.story_id,
            original_answer_choice=answer.answer_choice,
            original_answer_id=answer.id,
            scheduled_for=date.today(),
            is_completed=False
        )
        db.add(revisit)
    
    db.commit()
```

#### 2.2.2 DB スキーマ
```sql
-- 新規テーブル: revisit_schedules
CREATE TABLE revisit_schedules (
  id SERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id),
  story_id UUID NOT NULL REFERENCES stories(id),
  original_answer_id UUID NOT NULL REFERENCES answers(id),
  original_answer_choice VARCHAR(1),
  revisit_answer_id UUID REFERENCES answers(id),  -- 再回答後に埋められる
  scheduled_for DATE NOT NULL,
  is_completed BOOLEAN DEFAULT FALSE,
  completed_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, story_id, scheduled_for)
);

CREATE INDEX idx_revisit_user_story ON revisit_schedules(user_id, scheduled_for);
```

#### 2.2.3 APIエンドポイント
```python
# GET /api/v1/users/{user_id}/revisit-stories
# 当月の再訪ストーリー一覧

@router.get("/users/{user_id}/revisit-stories")
async def get_revisit_stories(user_id: str):
    revisits = db.query(RevisitSchedule)\
        .filter(RevisitSchedule.user_id == user_id)\
        .filter(RevisitSchedule.scheduled_for == date.today())\
        .filter(RevisitSchedule.is_completed == False)\
        .all()
    
    return {
        "revisits": [
            {
                "revisit_id": revisit.id,
                "story_id": revisit.story_id,
                "title": Story.query.get(revisit.story_id).title,
                "is_revisit": True,
                "original_answer": revisit.original_answer_choice
            }
            for revisit in revisits
        ]
    }

# POST /api/v1/revisit-stories/{revisit_id}/answer
# 再訪ストーリーに回答

@router.post("/revisit-stories/{revisit_id}/answer")
async def answer_revisit_story(
    revisit_id: str,
    answer_choice: str,
    reason: Optional[str] = None
):
    # 新しい Answer レコード作成
    new_answer = Answer(
        user_id=...,
        story_id=...,
        answer_choice=answer_choice,
        reason=reason,
        is_revisit=True
    )
    db.add(new_answer)
    
    # RevisitSchedule を完了状態に
    revisit = db.query(RevisitSchedule).get(revisit_id)
    revisit.revisit_answer_id = new_answer.id
    revisit.is_completed = True
    revisit.completed_at = now()
    
    db.commit()
    
    return {
        "original_choice": revisit.original_answer_choice,
        "current_choice": answer_choice,
        "is_changed": revisit.original_answer_choice != answer_choice,
        "message": generate_revisit_message(...)
    }
```

### 2.3 フロントエンド設計

#### 2.3.1 再訪フラグ処理
```dart
// lib/screens/story/story_learning_screen.dart (修正)

class StoryLearningScreen extends ConsumerWidget {
  final String storyId;
  final bool isRevisit;
  final String? originalAnswer;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: isRevisit 
          ? Text("あのときのきみ") 
          : Text("ストーリー"),
      ),
      body: Column(
        children: [
          if (isRevisit)
            Container(
              padding: EdgeInsets.all(12),
              color: Colors.orange[100],
              child: Text(
                "3ヶ月前に このストーリーに こたえました！\nもういちど かんがえてみよう。",
                style: TextStyle(fontSize: 14),
              ),
            ),
          // ... ストーリー本体
        ],
      ),
    );
  }
}
```

#### 2.3.2 結果表示
```dart
// lib/screens/story/story_result_screen.dart (修正)

class StoryResultScreen extends ConsumerWidget {
  final bool isRevisit;
  final String? originalChoice;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        if (isRevisit) ...[
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Column(
              children: [
                Text(
                  "3ヶ月前のきみは \"${_choiceText(originalChoice)}\" を えらんだよ。",
                  style: TextStyle(fontSize: 14, fontWeight: bold),
                ),
                SizedBox(height: 8),
                Text(
                  "きょうのきみは \"${_choiceText(userChoice)}\"。\nなにが かわったのかな？",
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
        ],
        // ... その他の結果表示
      ],
    );
  }
}
```

---

## ④ 親子「くらべっこ」機能

### 4.1 機能概要
```
週1回「おやこジレンマ」を配信。
親も同じジレンマに回答し、親子の選択を比較。
家庭での対話を生む装置。

フロー：
1. 親向けメール受信（週1回、曜日・時刻はカスタマイズ可）
2. メール内のリンクから親が回答
3. 親子両方が回答したら相互開示
4. 親向けに対話ガイドを提供
```

### 4.2 バックエンド設計

#### 4.2.1 DB スキーマ
```sql
-- 新規テーブル: parent_answers
CREATE TABLE parent_answers (
  id SERIAL PRIMARY KEY,
  parent_id UUID NOT NULL REFERENCES users(id),
  child_id UUID NOT NULL REFERENCES users(id),
  story_id UUID NOT NULL REFERENCES stories(id),
  answer_choice VARCHAR(1),
  responded_at TIMESTAMP,
  is_revealed BOOLEAN DEFAULT FALSE,
  revealed_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- notification_preferences テーブル修正
ALTER TABLE notification_preferences
ADD COLUMN parent_child_schedule VARCHAR(20) DEFAULT 'weekly';  -- weekly, biweekly, monthly
```

#### 4.2.2 APIエンドポイント
```python
# POST /api/v1/parent-child/{parent_id}/{child_id}/answer
# 親が子どもと同じジレンマに回答

@router.post("/parent-child/{parent_id}/{child_id}/answer")
async def answer_parent_child_story(
    parent_id: str,
    child_id: str,
    story_id: str,
    answer_choice: str
):
    # 親の回答を保存
    parent_answer = ParentAnswer(
        parent_id=parent_id,
        child_id=child_id,
        story_id=story_id,
        answer_choice=answer_choice,
        responded_at=now()
    )
    db.add(parent_answer)
    
    # 子どもの回答を確認
    child_answer = db.query(Answer)\
        .filter(Answer.user_id == child_id)\
        .filter(Answer.story_id == story_id)\
        .first()
    
    if child_answer:
        # 両者が回答済みなら reveal フラグを立てる
        parent_answer.is_revealed = True
        parent_answer.revealed_at = now()
    
    db.commit()
    
    return {
        "parent_choice": answer_choice,
        "child_choice": child_answer.answer_choice if child_answer else None,
        "is_both_answered": child_answer is not None,
        "guidance": generate_dialogue_guidance(...) if child_answer else None
    }

# GET /api/v1/parent-child/{parent_id}/{child_id}/dialogue-history
# 過去の親子比較履歴

@router.get("/parent-child/{parent_id}/{child_id}/dialogue-history")
async def get_dialogue_history(parent_id: str, child_id: str):
    histories = db.query(ParentAnswer)\
        .filter(ParentAnswer.parent_id == parent_id)\
        .filter(ParentAnswer.child_id == child_id)\
        .filter(ParentAnswer.is_revealed == True)\
        .order_by(ParentAnswer.created_at.desc())\
        .limit(12)\
        .all()
    
    return {
        "histories": [
            {
                "date": h.created_at,
                "story_title": Story.query.get(h.story_id).title,
                "parent_choice": h.answer_choice,
                "child_choice": Answer.query.get(...).answer_choice,
                "guidance": load_guidance(h.id)
            }
            for h in histories
        ]
    }
```

#### 4.2.3 メール配信
```python
# Cloud Tasks で週1回（親の設定曜日・時刻）

@app.post("/jobs/send-parent-child-email")
async def send_parent_child_email():
    """
    週1回、対象親に「おやこジレンマ」メール配信
    """
    # 本週配信対象の親を検索
    # parent_notifications.parent_child_schedule = 'weekly'
    # last_parent_child_email_sent < 7日前
    
    eligible_parents = get_eligible_parents_for_parent_child()
    
    for parent in eligible_parents:
        # 配信対象のストーリー選択
        story = select_story_for_week()
        
        # メールテンプレート
        email_body = render_template(
            'parent_child_email.html',
            parent_name=parent.name,
            child_name=parent.children[0].name,
            story_title=story.title,
            story_preview=story.preview_text,
            response_link=generate_parent_response_link(parent.id, story.id)
        )
        
        # SendGrid で送信
        await send_email(
            to=parent.email,
            subject=f"{parent.children[0].name}と おなじじれんまを かんがえてみませんか？",
            html_content=email_body
        )
        
        # last_parent_child_email_sent を更新
        update_last_email_sent(parent.id)
```

### 4.3 フロントエンド設計

#### 4.3.1 親向け回答フロー（メール内）
```html
<!-- templates/parent_child_email.html -->

<div style="font-family: Arial; max-width: 600px;">
  <h2>{{ parent_name }}へ</h2>
  <p>{{ child_name }}さんが このじれんまに こたえました。</p>
  <p>パパ・ママも おなじ じれんまを かんがえてみませんか？</p>
  
  <div style="background: #f5f5f5; padding: 20px; margin: 20px 0;">
    <h3>{{ story_title }}</h3>
    <p>{{ story_preview }}</p>
    
    <p style="margin-top: 20px;">
      <strong>どうしますか？</strong>
    </p>
    <div style="display: flex; gap: 10px;">
      <a href="{{ response_link }}/answer/A" 
         style="padding: 10px 20px; background: #2196F3; color: white; 
                text-decoration: none; border-radius: 4px;">
        A: (選択肢A)
      </a>
      <a href="{{ response_link }}/answer/B"
         style="padding: 10px 20px; background: #4CAF50; color: white;
                text-decoration: none; border-radius: 4px;">
        B: (選択肢B)
      </a>
      <!-- C, D も同様 -->
    </div>
  </div>
  
  <p style="font-size: 12px; color: #666;">
    お子さんとの対話のコツ：<br>
    まずは「どうしてそう思ったの？」と お子さんに聞いてください。
    パパ・ママの理由は あとから 話すのが コツです。
  </p>
</div>
```

#### 4.3.2 親子比較 UI（子どものアプリ側）
```dart
// lib/screens/home/parent_child_section.dart (新規)

class ParentChildComparisonWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<ParentChildComparison>(
      future: apiService.getLatestParentChildComparison(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return SizedBox.shrink();
        
        final comparison = snapshot.data!;
        
        return Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "パパ・ママと の じれんま",
                  style: TextStyle(fontSize: 16, fontWeight: bold),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    // 子どもの選択
                    Expanded(
                      child: Column(
                        children: [
                          Text("きみ", style: TextStyle(fontSize: 12)),
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              comparison.childChoiceLetter,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: bold,
                                color: Colors.blue[900],
                              ),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            comparison.childChoiceText,
                            style: TextStyle(fontSize: 11),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12),
                    // 親の選択
                    Expanded(
                      child: Column(
                        children: [
                          Text("パパ・ママ", style: TextStyle(fontSize: 12)),
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              comparison.parentChoiceLetter,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: bold,
                                color: Colors.orange[900],
                              ),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            comparison.parentChoiceText,
                            style: TextStyle(fontSize: 11),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    comparison.guidance,
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

---

## ⑥ やさしさ発見ミッション

### 6.1 機能概要
```
週1回「今週、だれかの『やさしいな』を3つ見つけよう」というミッション。
子どもが記録 → 月次で「やさしさマップ」を生成。
「善行をさせる」ではなく「気づく感度」を育てる。

例：
- 「お兄ちゃんが ぼくの分も おかし のこしてくれた」
- 「先生が 困ってる子に ていねいに おしえてくれた」
- 「おじいちゃんが 孫の ぼくを だいつてくれた」
```

### 6.2 バックエンド設計

#### 6.2.1 DB スキーマ
```sql
-- 新規テーブル: kindness_records
CREATE TABLE kindness_records (
  id SERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id),
  mission_week DATE NOT NULL,  -- ミッション配信週の日曜日
  kindness_description TEXT NOT NULL,
  person_involved VARCHAR(50),  -- 「お兄ちゃん」「先生」など
  context VARCHAR(50),  -- 「家」「学校」など
  recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 新規テーブル: kindness_missions
CREATE TABLE kindness_missions (
  id SERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id),
  mission_week DATE NOT NULL,
  target_count INTEGER DEFAULT 3,
  completed_count INTEGER DEFAULT 0,
  is_completed BOOLEAN DEFAULT FALSE,
  monthly_summary_generated BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, mission_week)
);

CREATE INDEX idx_kindness_records_user_week ON kindness_records(user_id, mission_week);
```

#### 6.2.2 APIエンドポイント
```python
# POST /api/v1/users/{user_id}/kindness-records
# 子どもがやさしさ を記録

@router.post("/users/{user_id}/kindness-records")
async def record_kindness(
    user_id: str,
    kindness_description: str,
    person_involved: Optional[str] = None,
    context: Optional[str] = None
):
    # 今週のミッション を確認
    current_week = get_sunday_of_week(date.today())
    mission = db.query(KindnessMission)\
        .filter(KindnessMission.user_id == user_id)\
        .filter(KindnessMission.mission_week == current_week)\
        .first()
    
    if not mission:
        mission = KindnessMission(
            user_id=user_id,
            mission_week=current_week
        )
        db.add(mission)
    
    # やさしさ記録を追加
    record = KindnessRecord(
        user_id=user_id,
        mission_week=current_week,
        kindness_description=kindness_description,
        person_involved=person_involved,
        context=context
    )
    db.add(record)
    
    # 完了数を更新
    mission.completed_count += 1
    if mission.completed_count >= mission.target_count:
        mission.is_completed = True
    
    db.commit()
    
    return {
        "recorded": True,
        "progress": f"{mission.completed_count}/{mission.target_count}",
        "is_mission_complete": mission.is_completed,
        "reward_points": 10  # ポイント付与
    }

# GET /api/v1/users/{user_id}/kindness-map/{month}
# 月次「やさしさマップ」を生成

@router.get("/users/{user_id}/kindness-map/{month}")
async def get_kindness_map(user_id: str, month: str):
    """
    月内のすべてのやさしさ記録をカテゴリ別に集計
    """
    records = db.query(KindnessRecord)\
        .filter(KindnessRecord.user_id == user_id)\
        .filter(extract('month', KindnessRecord.created_at) == int(month.split('-')[1]))\
        .all()
    
    # カテゴリ別に集計
    categories = {
        'family': [],
        'school': [],
        'community': [],
        'other': []
    }
    
    for record in records:
        category = classify_kindness(record.context)
        categories[category].append({
            'description': record.kindness_description,
            'person': record.person_involved
        })
    
    return {
        "month": month,
        "total_findings": len(records),
        "by_category": categories,
        "message": generate_kindness_message(len(records))
    }
```

#### 6.2.3 Cloud Scheduler ジョブ
```python
# 毎週月曜朝にミッション配信

@app.post("/jobs/weekly-kindness-mission")
async def send_weekly_kindness_mission():
    """
    全ユーザーに週次「やさしさ探し」ミッションを配信
    """
    all_users = db.query(User).all()
    current_week = get_sunday_of_week(date.today())
    
    for user in all_users:
        # 今週のミッション作成
        mission = KindnessMission(
            user_id=user.id,
            mission_week=current_week
        )
        db.add(mission)
        
        # アプリ内通知
        notify_user(
            user_id=user.id,
            title="🌟 やさしさを さがそう",
            message="今週、だれかの『やさしいな』を 3つ見つけてね"
        )
    
    db.commit()
```

### 6.3 フロントエンド設計

#### 6.3.1 ミッション画面
```dart
// lib/screens/home/kindness_mission_widget.dart (新規)

class KindnessMissionWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<KindnessMission>(
      future: apiService.getCurrentMission(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return SizedBox.shrink();
        
        final mission = snapshot.data!;
        final progress = mission.completedCount / mission.targetCount;
        
        return Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "🌟 やさしさ さがし",
                  style: TextStyle(fontSize: 18, fontWeight: bold),
                ),
                SizedBox(height: 8),
                Text(
                  "今週、だれかの『やさしいな』を ${mission.targetCount} つ さがそう",
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 16),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                ),
                SizedBox(height: 8),
                Text(
                  "${mission.completedCount}/${mission.targetCount}",
                  style: TextStyle(fontSize: 12, fontWeight: bold),
                ),
                SizedBox(height: 16),
                if (mission.completedCount < mission.targetCount)
                  ElevatedButton(
                    onPressed: () => _showRecordDialog(context),
                    child: Text("やさしさを きろくする"),
                  )
                else
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "✅ ミッション完了！",
                      style: TextStyle(
                        color: Colors.green[900],
                        fontWeight: bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  void _showRecordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => KindnessRecordDialog(),
    );
  }
}

// 記録ダイアログ
class KindnessRecordDialog extends ConsumerStatefulWidget {
  @override
  ConsumerState createState() => _KindnessRecordDialogState();
}

class _KindnessRecordDialogState extends ConsumerState<KindnessRecordDialog> {
  late TextEditingController _descriptionController;
  String? _selectedPerson;
  String? _selectedContext;
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("やさしさを きろク"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: "だれが どんなやさしさを してくれた？",
                hintText: "例：おにいちゃんが ぼくの分も おかし のこしてくれた",
              ),
              maxLines: 3,
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedPerson,
              decoration: InputDecoration(labelText: "だれですか？"),
              items: [
                '家ぞくの人',
                '先生',
                'ともだち',
                'その他'
              ].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: (value) => setState(() => _selectedPerson = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("キャンセル"),
        ),
        ElevatedButton(
          onPressed: () async {
            await apiService.recordKindness(
              description: _descriptionController.text,
              person: _selectedPerson,
            );
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("きろク しました！")),
            );
          },
          child: Text("きろク"),
        ),
      ],
    );
  }
}
```

#### 6.3.2 月次マップ表示
```dart
// lib/screens/reports/kindness_map_widget.dart (新規)

class KindnessMapWidget extends ConsumerWidget {
  final String month;  // "2026-06"
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<KindnessMap>(
      future: apiService.getKindnessMap(month),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Loading();
        
        final map = snapshot.data!;
        
        return Column(
          children: [
            Text(
              "${month} の やさしさ",
              style: TextStyle(fontSize: 18, fontWeight: bold),
            ),
            SizedBox(height: 8),
            Text(
              "合わせて ${map.totalFindings} つ のやさしさを さがしました",
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            // カテゴリ別表示
            ...map.byCategory.entries.map((entry) =>
              KindnessCategoryCard(
                category: entry.key,
                findings: entry.value,
              )
            ).toList(),
          ],
        );
      },
    );
  }
}
```

---

# v1.2：AI最適化レイヤー（月¥11）

## ③ りゆう記録分析（月50人抽出版）

### 3.1 コスト最適化戦略

```
標準的実装：月$0.34（全500人分析）
最適化版：月¥11（月50人抽出版）→ 96%削減

【5つの最適化】
1. 抽出分析：月500人 → 月50人（ランダム抽出）
2. キャッシング：プロンプト再利用で40%削減
3. テキスト圧縮：100トークン → 20トークン
4. テンプレート活用：20%のみ Gemini、80%テンプレート
5. 隔月実行：月2回 → 月1回（実装は月次、利用は隔月）
```

### 3.2 バックエンド設計

#### 3.2.1 抽出処理（Cloud Scheduler）
```python
# 毎月初日（実装：月次実行）
# 利用：隔月で顧客に提供

@app.post("/jobs/monthly-reason-analysis")
async def analyze_monthly_reasons():
    """
    月内のやさしさ・りゆう記録から
    ランダムに50人をサンプリング → AI分析
    """
    from random import sample
    
    # 前月の記録対象ユーザー
    all_users_with_records = db.query(
        func.distinct(KindnessRecord.user_id)
    ).filter(
        extract('month', KindnessRecord.created_at) == (date.today().month - 1) % 12
    ).all()
    
    # ランダム抽出（10%）
    sample_size = max(1, int(len(all_users_with_records) * 0.1))
    sampled_users = sample([u[0] for u in all_users_with_records], sample_size)
    
    for user_id in sampled_users:
        # ユーザーの記録を取得
        records = db.query(KindnessRecord)\
            .filter(KindnessRecord.user_id == user_id)\
            .filter(extract('month', KindnessRecord.created_at) == (date.today().month - 1) % 12)\
            .all()
        
        # テキスト圧縮（100トークン → 20トークン）
        compressed_texts = compress_kindness_texts(records)
        
        # Gemini で分析（キャッシング + テンプレート）
        analysis = await analyze_reason_growth(
            user_id=user_id,
            compressed_records=compressed_texts
        )
        
        # 結果を保存
        save_reason_analysis(user_id, analysis)
```

#### 3.2.2 テキスト圧縮ロジック
```python
def compress_kindness_texts(records):
    """
    子どものテキスト記録を自動要約
    例：
    入力）「友達が かくしごと（秘密）をおしえてくれた。
           でも その秘密は ともだちのお兄ちゃん のこと で、
           とてもやましい こと だった。」
    出力）「友達の秘密（兄への罪悪感） / 開示判定」
    """
    compressed = []
    for record in records:
        # キーワード抽出
        keywords = extract_keywords(record.kindness_description)
        person = record.person_involved or "だれか"
        
        # 圧縮テンプレート
        compressed_text = f"{person} / {keywords}"
        compressed.append(compressed_text)
    
    return compressed
```

#### 3.2.3 Gemini 呼び出し（キャッシング）
```python
async def analyze_reason_growth(user_id, compressed_records):
    """
    キャッシング + テンプレート併用で AI コストを最小化
    """
    import anthropic
    
    client = anthropic.Anthropic(api_key=VERTEX_AI_KEY)
    
    # システムプロンプト（再利用可能な部分をキャッシング）
    system_prompt = """
    あなたは、子どもの道徳的判断力の成長を分析する専門家です。
    子どもが記録した「やさしさ」の内容から、
    以下の観点で成長を分析してください：
    
    1. 対象の広がり（家族だけ→学校→社会へ）
    2. 理由の深さ（表面的な行動→相手の気持ちへ）
    3. 感度の向上（気づく回数・質の向上）
    
    出力は JSON 形式で：
    {
      "headline": "この月の成長",
      "observations": ["観察1", "観察2"],
      "improvement_level": "向上なし" | "わずかな向上" | "明らかな向上"
    }
    """
    
    # ユーザー用プロンプト（月ごとに変わる部分）
    user_message = f"""
    以下が、子ども（ユーザーID: {user_id}）が先月記録した「やさしさ」です：
    
    {', '.join(compressed_records)}
    
    この内容から、子どもの成長を分析してください。
    """
    
    response = client.messages.create(
        model="claude-opus-4-100k",  # Vertex AI Gemini
        max_tokens=500,
        system=[
            {
                "type": "text",
                "text": system_prompt,
                "cache_control": {"type": "ephemeral"}  # キャッシング有効化
            }
        ],
        messages=[
            {
                "role": "user",
                "content": user_message
            }
        ]
    )
    
    return json.loads(response.content[0].text)
```

#### 3.2.4 テンプレート生成（AI不要）
```python
def generate_reason_feedback_from_template(user_id, analysis):
    """
    Gemini 分析結果 + テンプレートで親向けフィードバック生成
    AI利用は分析フェーズのみ、フィードバック文は テンプレート
    """
    templates = {
        'improvement_none': "今月は、やさしさを見つけることに チャレンジしました。来月も たくさん さがしてみようね。",
        'improvement_slight': "今月は、やさしさの とらえ方が すこし深くなってきましたね。'気づく感度'が ぐんぐん育っています。",
        'improvement_clear': "お子さんの成長が 目立つ月です！相手の 気持ちを考える力が 大きく育ちました。"
    }
    
    headline = templates.get(f'improvement_{analysis["improvement_level"]}', "")
    
    return {
        "headline": headline,
        "observations": analysis['observations'],
        "parent_message": f"お子さんが見つけた『やさしさ』の話を、 夕食時に聞き出してみてください。 お子さんの 心の成長が 分かります。"
    }
```

### 3.3 親レポート統合
```
月次レポートに「りゆう分析」セクション追加（50人にのみ）

【親向け表示】
- 当選（分析対象）：「お子さんの成長分析を お届けします」
- 非当選（他のデータ利用）：「全国の傾向に基づく アドバイス」
  → 全員が 何かしらの 個別フィードバック を 受け取る
```

---

## ⑤ 創作フィード（月末バッチ版）

### 5.1 コスト最適化戦略

```
標準的実装：月$1.50（リアルタイム AI 応答 × 5000回）
最適化版：月¥11（月末バッチ処理 1回）→ 97%削減

【実装戦略】
1. 回答時：テキスト保存のみ（AI処理なし）
2. 月末：全回答をバッチで Gemini 処理
3. フィードバック：月末レポートに「創作の成長」セクション
```

### 5.2 バックエンド設計

#### 5.2.1 バッチ処理（Cloud Scheduler）
```python
# 毎月最終日 21:00 JST

@app.post("/jobs/monthly-creation-feedback")
async def generate_creation_feedback():
    """
    全ユーザーの当月の創作記録をバッチで Gemini 分析
    """
    # 当月のすべての創作記録
    creations = db.query(CreationRecord)\
        .filter(extract('month', CreationRecord.created_at) == date.today().month)\
        .all()
    
    # ユーザーごとにグループ化
    by_user = {}
    for creation in creations:
        if creation.user_id not in by_user:
            by_user[creation.user_id] = []
        by_user[creation.user_id].append(creation)
    
    # ユーザーごとに Gemini で分析
    for user_id, user_creations in by_user.items():
        # 創作テキストをコンパクト化
        summaries = [
            f"{c.story_title}: {c.user_created_ending[:50]}..."
            for c in user_creations[:5]  # 最初の 5 件
        ]
        
        feedback = await generate_creation_growth_feedback(
            user_id=user_id,
            creation_summaries=summaries,
            count=len(user_creations)
        )
        
        # 親レポートに追加
        save_monthly_creation_feedback(user_id, feedback)
```

#### 5.2.2 親レポート統合
```python
def generate_parent_report_with_creation(user_id, month):
    """
    親向け月次レポートに「創作成長」セクションを追加
    """
    feedback = get_creation_feedback(user_id, month)
    
    return {
        "report_sections": [
            # ... 既存セクション
            {
                "title": "📝 創作の成長",
                "content": f"{feedback['headline']}",
                "observations": feedback['observations'],
                "parent_tip": "お子さんに『この月の 創作について 聞かせてほしい』と 話しかけてみてください。"
            }
        ]
    }
```

### 5.3 フロントエンド設計
```dart
// lib/screens/story/story_creation_screen.dart (修正)

class StoryCreationScreen extends ConsumerWidget {
  final String storyId;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text("きみの物語"),
      ),
      body: Column(
        children: [
          // ... ストーリー + 創作入力フォーム
          Container(
            padding: EdgeInsets.all(12),
            color: Colors.blue[50],
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "きみの創作は、毎月末に 先生（AI）が 応答します。",
                    style: TextStyle(fontSize: 12, color: Colors.blue[900]),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _CreationForm(),
          ),
          ElevatedButton(
            onPressed: _submitCreation,
            child: Text("送信"),
          ),
        ],
      ),
    );
  }
}

// 親レポートの「創作成長」セクション
class MonthlyCreationGrowthWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "📝 創作の成長",
              style: TextStyle(fontSize: 16, fontWeight: bold),
            ),
            SizedBox(height: 12),
            Text(
              "このつきは、${creationFeedback.count}つの 創作に チャレンジしました。",
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "🌟 成長のポイント",
                    style: TextStyle(fontWeight: bold),
                  ),
                  SizedBox(height: 8),
                  ...creationFeedback.observations.map((obs) =>
                    Text("• $obs")
                  ).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

# 実装スケジュール＆チェックリスト

## v1.1: 2週間（7月1-14日）

- [ ] ① 全国選択分布
  - [ ] DB: answer_statistics テーブル作成
  - [ ] API: /stories/{id}/distribution エンドポイント
  - [ ] UI: DistributionWidget 実装
  - [ ] テスト・デプロイ

- [ ] ② 3ヶ月後再訪
  - [ ] DB: revisit_schedules テーブル作成
  - [ ] Cloud Scheduler: 月次トリガー設定
  - [ ] API: 再訪フロー エンドポイント
  - [ ] UI: 再訪表示 修正
  - [ ] テスト・デプロイ

- [ ] ④ 親子くらべっこ
  - [ ] DB: parent_answers テーブル + notification_preferences 修正
  - [ ] API: 親の回答エンドポイント
  - [ ] Email: メール配信フロー
  - [ ] UI: 親子比較ウィジェット
  - [ ] テスト・デプロイ

- [ ] ⑥ やさしさ発見ミッション
  - [ ] DB: kindness_records + kindness_missions テーブル
  - [ ] Cloud Scheduler: 週次ミッション配信
  - [ ] API: 記録エンドポイント + 月次マップ
  - [ ] UI: ミッション + マップ表示
  - [ ] テスト・デプロイ

## v1.2: 1週間（8月1-7日）

- [ ] ③ りゆう記録分析（月50人抽出版）
  - [ ] Cloud Scheduler: 月次分析ジョブ
  - [ ] Gemini API: 分析プロンプト + キャッシング
  - [ ] 親レポート統合
  - [ ] テスト・デプロイ

- [ ] ⑤ 創作フィード（月末バッチ版）
  - [ ] Cloud Scheduler: 月末フィードバック生成
  - [ ] 親レポート統合
  - [ ] UI: 月次レポート修正
  - [ ] テスト・デプロイ

---

# テスト戦略

## ユニットテスト
```dart
// test/providers/distribution_provider_test.dart
test('全国分布が正しく計算される', () async { ... });

// test/screens/revisit_screen_test.dart
test('3ヶ月前の選択と現在の選択を比較表示', () async { ... });

// test/screens/parent_child_test.dart
test('親子の選択が正しく比較される', () async { ... });

// test/screens/kindness_mission_test.dart
test('やさしさ記録が正しく保存される', () async { ... });
```

## 統合テスト
```dart
// test/integration/parent_report_test.dart
test('親レポートに全セクションが統合される', () async { ... });

test('親向けメール配信が正しく実行される', () async { ... });
```

## AI コスト検証
```python
# scripts/verify_ai_costs.py
"""
月額 AI コストが ¥11 以下であることを検証
- Gemini トークン使用量の集計
- 実際のコスト計算
"""
```

---

# 本番化チェックリスト（リリース前）

- [ ] API: Cloud Scheduler トリガーの設定確認
- [ ] データ: 本番 Firestore に移行
- [ ] メール: SendGrid テンプレート確認
- [ ] Analytics: イベントトラッキング設定
- [ ] モニタリング: Sentry ダッシュボード設定
- [ ] ユーザー通知: アナウンスメール配信

---

**実装設計完了。v1.1 から開始してください。**
