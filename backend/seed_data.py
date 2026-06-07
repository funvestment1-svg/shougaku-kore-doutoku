"""
シードデータ投入スクリプト
開発・テスト用のサンプルストーリーとデータを生成します

実行: python seed_data.py
"""
import asyncio
import uuid
from datetime import datetime
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from app.config import get_settings
from app.db.base import Base
from app.models.story import Story, StoryChoice
from app.models.user import User
from app.security import get_password_hash

settings = get_settings()

engine = create_async_engine(settings.database_url, echo=True)
AsyncSessionLocal = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

# サンプルストーリーデータ
# content は StoryContent 形式の JSON
SAMPLE_STORIES = [
    {
        "title": "ともだちのかさ",
        "description": "雨の日、友達のかさを借りるかどうか迷う太郎のお話",
        "content": {
            "introduction": "太郎は学校の帰り道、急に雨が降り出しました。かさを持っていなかった太郎は困ってしまいました。",
            "mainNarrative": [
                "太郎は空を見上げました。雨はどんどん強くなっています。",
                "友達の花子が黄色いかさを持って歩いているのが見えました。花子は遠い家に帰らなければなりません。",
            ],
            "dilemmaScene": "「花子のかさを借りたいな」と太郎は思いました。でも花子も遠い家に帰らなければなりません。さあ、太郎はどうすればいいでしょう？",
            "illustrationUrl": None,
        },
        "theme": "kindness",
        "emoji": "☔",
        "difficulty": 1,
        "week_number": 1,
        "choices": [
            {
                "order": 1,
                "text": "花子に正直に話して、一緒に傘に入れてもらう",
                "branch_content": "花子は「一緒に入ろう」と笑顔で言ってくれました。二人は仲良く帰ることができました。太郎は正直に話して良かったと思いました。",
                "reflection": "困ったとき、正直に話すことが大切です。相手のことを考えながら、自分の気持ちも伝えてみましょう。",
                "value": "honesty",
                "points": 15,
                "is_recommended": True,
                "score_impact": {"honesty": 5, "kindness": 3, "cooperation": 4},
            },
            {
                "order": 2,
                "text": "何も言わずに花子の後ろについていく",
                "branch_content": "花子は気づいてくれましたが、少し困った顔をしていました。太郎は自分から話せば良かったと思いました。",
                "reflection": "勇気を出して話しかけることが大切です。黙ってついていくよりも、正直に伝えましょう。",
                "value": "courage",
                "points": 8,
                "is_recommended": False,
                "score_impact": {"courage": -2, "honesty": -3},
            },
            {
                "order": 3,
                "text": "雨の中を走って帰る",
                "branch_content": "びしょ濡れになりましたが、花子に気を遣わせなくてすみました。でも、風邪を引いてしまいました。",
                "reflection": "自分だけで解決しようとする気持ちも大切ですが、困ったときは助けを求めることも勇気のある行動です。",
                "value": "responsibility",
                "points": 10,
                "is_recommended": False,
                "score_impact": {"responsibility": 2},
            },
        ],
    },
    {
        "title": "あきらめないこころ",
        "description": "運動会のかけっこで転んでしまった次郎のお話",
        "content": {
            "introduction": "次郎はクラスのかけっこで一番になりたいと思っていました。毎日練習して、この日をとても楽しみにしていました。",
            "mainNarrative": [
                "スタートの合図と同時に、みんなが走り出しました。次郎も精一杯走りました。",
                "でも、スタートしてすぐ、次郎は石につまずいて転んでしまいました。ひざがジンジン痛みます。",
            ],
            "dilemmaScene": "みんなはどんどん先へ進んでいきます。立ち上がるのが怖い気持ちもありました。さあ、次郎はどうすればいいでしょう？",
            "illustrationUrl": None,
        },
        "theme": "courage",
        "emoji": "🏃",
        "difficulty": 1,
        "week_number": 2,
        "choices": [
            {
                "order": 1,
                "text": "痛くても最後まで走りきる",
                "branch_content": "最後になったかもしれないけど、次郎は走りきりました。ゴールしたとき、クラスのみんなが大きな拍手をしてくれました。",
                "reflection": "転んでも諦めない勇気は、とても大切な心の力です。結果よりも、最後まで頑張ったことが大切なのです。",
                "value": "courage",
                "points": 20,
                "is_recommended": True,
                "score_impact": {"courage": 8, "responsibility": 4},
            },
            {
                "order": 2,
                "text": "先生を呼んでもらう",
                "branch_content": "先生がすぐに来てくれました。ひざを確認してもらうと、少し擦り傷ができていました。",
                "reflection": "ケガが心配なときは、先生に助けを求めることも正しい判断です。自分の状態を正直に伝えましょう。",
                "value": "honesty",
                "points": 12,
                "is_recommended": False,
                "score_impact": {"honesty": 3, "courage": -1},
            },
        ],
    },
    {
        "title": "みんなのルール",
        "description": "公園でゲームのルールをめぐって意見が分かれたときのお話",
        "content": {
            "introduction": "放課後、公園でドッジボールをすることになりました。友達が5人集まりましたが、チームの分け方でもめてしまいました。",
            "mainNarrative": [
                "花子は「じゃんけんで決めよう」と言います。公平で良さそうです。",
                "健太は「強い人から選ぼう」と言います。強いチームが作れると言っています。",
                "他の子も違う意見を言っています。なかなかまとまりません。",
            ],
            "dilemmaScene": "みんなが違う意見を言っていて、なかなか決まりません。あなたならどうしますか？",
            "illustrationUrl": None,
        },
        "theme": "cooperation",
        "emoji": "⚽",
        "difficulty": 2,
        "week_number": 3,
        "choices": [
            {
                "order": 1,
                "text": "みんなの意見を聞いて、多数決で決める",
                "branch_content": "多数決で決めた結果、じゃんけん方式になりました。みんなが納得してゲームが楽しくできました。",
                "reflection": "みんなの意見を聞いて、公平な方法で決めることが協調性の大切さです。一人の意見だけでなく、みんなで考えましょう。",
                "value": "cooperation",
                "points": 18,
                "is_recommended": True,
                "score_impact": {"cooperation": 7, "respect": 5},
            },
            {
                "order": 2,
                "text": "自分の意見を強く主張する",
                "branch_content": "自分の意見は言えましたが、他の人が嫌な気持ちになってしまいました。遊びが始まっても雰囲気が悪かったです。",
                "reflection": "自分の意見を言うことは大切ですが、相手の気持ちも考えましょう。強く主張するより、みんなで話し合う方が良い結果になります。",
                "value": "courage",
                "points": 8,
                "is_recommended": False,
                "score_impact": {"courage": 2, "cooperation": -4, "respect": -2},
            },
            {
                "order": 3,
                "text": "もめているから、遊ぶのをやめる",
                "branch_content": "問題を避けましたが、楽しい遊びの機会がなくなりました。友達もがっかりした様子でした。",
                "reflection": "困難な状況を避けるより、一緒に解決する方法を考えましょう。諦めないで話し合うことが大切です。",
                "value": "responsibility",
                "points": 5,
                "is_recommended": False,
                "score_impact": {"cooperation": -3},
            },
        ],
    },
    {
        "title": "うそとやさしさ",
        "description": "友達の絵を正直に評価するかどうか悩む美咲のお話",
        "content": {
            "introduction": "美咲の友達の桜子が、一生懸命描いた絵を見せてくれました。桜子はとても嬉しそうです。",
            "mainNarrative": [
                "美咲は絵を見ました。桜子が一生懸命描いたことはわかります。でも、正直に言うと、上手くないと思いました。",
                "桜子は「どう？上手でしょ？」と期待の目で聞いてきました。",
            ],
            "dilemmaScene": "美咲はどう答えればいいか悩んでいます。正直に言うべきか、嘘をついて喜ばせるべきか。さあ、美咲はどうすればいいでしょう？",
            "illustrationUrl": None,
        },
        "theme": "honesty",
        "emoji": "🎨",
        "difficulty": 2,
        "week_number": 4,
        "choices": [
            {
                "order": 1,
                "text": "いいところを見つけて、正直に伝える",
                "branch_content": "「この色使いが素敵だね。もっと練習したらもっと上手くなるよ」と言いました。桜子は少し考えて、「ありがとう、もっと頑張る！」と言いました。",
                "reflection": "正直に伝えながらも、相手を傷つけない言い方を考えることが大切です。良いところを見つけてあげることも思いやりです。",
                "value": "honesty",
                "points": 20,
                "is_recommended": True,
                "score_impact": {"honesty": 6, "kindness": 6},
            },
            {
                "order": 2,
                "text": "「すごく上手だよ！」と言う",
                "branch_content": "桜子はとても喜びました。でも、美咲の心の中には嘘をついた気持ちが残りました。",
                "reflection": "相手を喜ばせたい気持ちは大切ですが、嘘は長い目で見ると信頼を失うことになります。優しい嘘より、優しい正直さを目指しましょう。",
                "value": "kindness",
                "points": 8,
                "is_recommended": False,
                "score_impact": {"kindness": 2, "honesty": -5},
            },
            {
                "order": 3,
                "text": "「うーん、もっと練習したほうがいいよ」と言う",
                "branch_content": "正直な言葉でしたが、桜子の顔が曇ってしまいました。言い方を工夫する必要があったかもしれません。",
                "reflection": "正直さは大切ですが、言い方も同じくらい大切です。相手の気持ちを考えた言い方を学びましょう。",
                "value": "honesty",
                "points": 8,
                "is_recommended": False,
                "score_impact": {"honesty": 3, "kindness": -4},
            },
        ],
    },
    {
        "title": "おとしもの",
        "description": "道でお金が入った財布を見つけた翔太のお話",
        "content": {
            "introduction": "翔太は学校の帰り道、道に財布が落ちているのを見つけました。辺りを見回しましたが、誰もいません。",
            "mainNarrative": [
                "翔太は財布を拾って中を見ました。お札が何枚か入っていました。",
                "「これで好きなお菓子が買えるな」という気持ちが少し湧いてきました。でも、誰かが困っているかもしれません。",
            ],
            "dilemmaScene": "財布を持った翔太は、これからどうすればいいのか考えています。さあ、翔太はどうすればいいでしょう？",
            "illustrationUrl": None,
        },
        "theme": "honesty",
        "emoji": "👛",
        "difficulty": 1,
        "week_number": 1,
        "choices": [
            {
                "order": 1,
                "text": "すぐに警察（交番）に届ける",
                "branch_content": "翔太は交番に届けました。後日、落とした人がとても感謝してくれました。翔太は正しいことをしたと胸を張れました。",
                "reflection": "落とし物を届けることは、正直で責任感のある行動です。誰かが困っているかもしれないと考えて行動できる力を育てましょう。",
                "value": "honesty",
                "points": 25,
                "is_recommended": True,
                "score_impact": {"honesty": 10, "responsibility": 7, "courage": 3},
            },
            {
                "order": 2,
                "text": "家に持ち帰って親に相談する",
                "branch_content": "お父さんやお母さんと一緒に交番に届けました。一人で抱え込まずに相談した、良い判断です。",
                "reflection": "困ったことは一人で抱え込まずに、信頼できる大人に相談することも大切な判断力です。",
                "value": "responsibility",
                "points": 18,
                "is_recommended": False,
                "score_impact": {"responsibility": 5, "honesty": 5},
            },
            {
                "order": 3,
                "text": "誰も見ていないから、使ってしまう",
                "branch_content": "後から罪悪感を感じ、夜も眠れませんでした。正しいことをしなかったと翔太は後悔しました。",
                "reflection": "誰も見ていなくても、正しい行動をすることが本当の正直さです。自分自身の良心に従って行動しましょう。",
                "value": "honesty",
                "points": 0,
                "is_recommended": False,
                "score_impact": {"honesty": -10, "responsibility": -5},
            },
        ],
    },
]


async def seed():
    async with AsyncSessionLocal() as session:
        print("🌱 シードデータを投入しています...")

        # テストユーザー作成
        test_user = User(
            id=uuid.UUID("00000000-0000-0000-0000-000000000001"),
            email="test@example.com",
            name="テスト保護者",
            password_hash=get_password_hash("password123"),
        )
        session.add(test_user)

        # ストーリー作成
        for story_data in SAMPLE_STORIES:
            choices_data = story_data.pop("choices")
            story = Story(
                id=uuid.uuid4(),
                **story_data,
                created_at=datetime.utcnow(),
                updated_at=datetime.utcnow(),
            )
            session.add(story)
            await session.flush()

            for choice_data in choices_data:
                choice = StoryChoice(
                    id=uuid.uuid4(),
                    story_id=story.id,
                    **choice_data,
                )
                session.add(choice)

        await session.commit()
        print(f"✅ {len(SAMPLE_STORIES)} ストーリー + 選択肢を投入しました")
        print("✅ テストユーザー: test@example.com / password123")


if __name__ == "__main__":
    asyncio.run(seed())
