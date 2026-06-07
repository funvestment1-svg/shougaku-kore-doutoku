"""initial schema

Revision ID: 001
Revises:
Create Date: 2026-05-26 00:00:00.000000
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = '001'
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    # users テーブル
    op.create_table(
        'users',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('firebase_uid', sa.String(128), unique=True, nullable=True),
        sa.Column('email', sa.String(255), unique=True, nullable=False),
        sa.Column('name', sa.String(100), nullable=False),
        sa.Column('password_hash', sa.String(255), nullable=True),
        sa.Column('is_active', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('fcm_token', sa.String(512), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.Column('updated_at', sa.DateTime(), nullable=False, server_default=sa.func.now()),
    )
    op.create_index('ix_users_firebase_uid', 'users', ['firebase_uid'])
    op.create_index('ix_users_email', 'users', ['email'])

    # children テーブル
    op.create_table(
        'children',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('parent_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('name', sa.String(50), nullable=False),
        sa.Column('avatar_emoji', sa.String(10), nullable=False, server_default='🌟'),
        sa.Column('grade', sa.Integer(), nullable=False),
        sa.Column('level', sa.Integer(), nullable=False, server_default='1'),
        sa.Column('total_points', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('kindness_score', sa.Float(), server_default='50.0'),
        sa.Column('honesty_score', sa.Float(), server_default='50.0'),
        sa.Column('responsibility_score', sa.Float(), server_default='50.0'),
        sa.Column('courage_score', sa.Float(), server_default='50.0'),
        sa.Column('respect_score', sa.Float(), server_default='50.0'),
        sa.Column('cooperation_score', sa.Float(), server_default='50.0'),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.Column('updated_at', sa.DateTime(), nullable=False, server_default=sa.func.now()),
    )
    op.create_index('ix_children_parent_id', 'children', ['parent_id'])

    # stories テーブル
    op.create_table(
        'stories',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('title', sa.String(200), nullable=False),
        sa.Column('description', sa.Text(), nullable=True),
        # content は StoryContent 形式の JSON
        # {"introduction": str, "mainNarrative": [str], "dilemmaScene": str, "illustrationUrl": str|null}
        sa.Column('content', postgresql.JSON(), nullable=False, server_default='{}'),
        sa.Column('theme', sa.String(50), nullable=False),
        sa.Column('grade_min', sa.Integer(), server_default='3'),
        sa.Column('grade_max', sa.Integer(), server_default='4'),
        sa.Column('difficulty', sa.Integer(), server_default='1'),
        sa.Column('is_premium', sa.Boolean(), server_default='false'),
        sa.Column('is_published', sa.Boolean(), server_default='true'),
        sa.Column('emoji', sa.String(10), server_default='📖'),
        sa.Column('audio_url', sa.String(512), nullable=True),
        sa.Column('image_url', sa.String(512), nullable=True),
        sa.Column('estimated_minutes', sa.Integer(), server_default='5'),
        sa.Column('week_number', sa.Integer(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.Column('updated_at', sa.DateTime(), nullable=False, server_default=sa.func.now()),
    )
    op.create_index('ix_stories_theme', 'stories', ['theme'])
    op.create_index('ix_stories_week_number', 'stories', ['week_number'])

    # story_choices テーブル
    op.create_table(
        'story_choices',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('story_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('stories.id', ondelete='CASCADE'), nullable=False),
        sa.Column('order', sa.Integer(), nullable=False),
        sa.Column('text', sa.Text(), nullable=False),
        sa.Column('branch_content', sa.Text(), nullable=False, server_default=''),  # 選択後の展開
        sa.Column('reflection', sa.Text(), nullable=False, server_default=''),      # 振り返り
        sa.Column('value', sa.String(50), nullable=True),                            # 関わる徳目
        sa.Column('points', sa.Integer(), server_default='10'),
        sa.Column('is_recommended', sa.Boolean(), server_default='false'),
        sa.Column('score_impact', postgresql.JSON(), nullable=True),
    )

    # quiz_sessions テーブル
    op.create_table(
        'quiz_sessions',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('child_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('children.id', ondelete='CASCADE'), nullable=False),
        sa.Column('story_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('stories.id', ondelete='SET NULL'), nullable=True),
        sa.Column('chosen_choice_id', postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('points_earned', sa.Integer(), server_default='0'),
        sa.Column('time_spent_seconds', sa.Integer(), server_default='0'),
        sa.Column('is_completed', sa.Boolean(), server_default='false'),
        sa.Column('reflection_text', sa.Text(), nullable=True),
        sa.Column('started_at', sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.Column('completed_at', sa.DateTime(), nullable=True),
    )
    op.create_index('ix_quiz_sessions_child_id', 'quiz_sessions', ['child_id'])

    # progress テーブル
    op.create_table(
        'progress',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('child_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('children.id', ondelete='CASCADE'), nullable=False),
        sa.Column('story_id', postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('action', sa.String(50), nullable=False),
        sa.Column('detail', sa.String(255), nullable=True),
        sa.Column('points_delta', sa.Integer(), server_default='0'),
        sa.Column('recorded_at', sa.DateTime(), nullable=False, server_default=sa.func.now()),
    )

    # monthly_reports テーブル
    op.create_table(
        'monthly_reports',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('child_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('children.id', ondelete='CASCADE'), nullable=False),
        sa.Column('year', sa.Integer(), nullable=False),
        sa.Column('month', sa.Integer(), nullable=False),
        sa.Column('stories_completed', sa.Integer(), server_default='0'),
        sa.Column('total_study_minutes', sa.Integer(), server_default='0'),
        sa.Column('total_points_earned', sa.Integer(), server_default='0'),
        sa.Column('kindness_score', sa.Float(), server_default='50.0'),
        sa.Column('honesty_score', sa.Float(), server_default='50.0'),
        sa.Column('responsibility_score', sa.Float(), server_default='50.0'),
        sa.Column('courage_score', sa.Float(), server_default='50.0'),
        sa.Column('respect_score', sa.Float(), server_default='50.0'),
        sa.Column('cooperation_score', sa.Float(), server_default='50.0'),
        sa.Column('highlight_comment', sa.Text(), nullable=True),
        sa.Column('growth_comment', sa.Text(), nullable=True),
        sa.Column('advice_comment', sa.Text(), nullable=True),
        sa.Column('parent_message', sa.Text(), nullable=True),
        sa.Column('theme_breakdown', postgresql.JSON(), nullable=True),
        sa.Column('generated_at', sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.Column('updated_at', sa.DateTime(), nullable=False, server_default=sa.func.now()),
    )
    op.create_index('ix_monthly_reports_child_year_month', 'monthly_reports', ['child_id', 'year', 'month'], unique=True)

    # notifications テーブル
    op.create_table(
        'notifications',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('title', sa.String(200), nullable=False),
        sa.Column('body', sa.Text(), nullable=False),
        sa.Column('notification_type', sa.String(50), nullable=False),
        sa.Column('is_sent', sa.Boolean(), server_default='false'),
        sa.Column('is_read', sa.Boolean(), server_default='false'),
        sa.Column('sent_at', sa.DateTime(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.func.now()),
    )


def downgrade() -> None:
    op.drop_table('notifications')
    op.drop_table('monthly_reports')
    op.drop_table('progress')
    op.drop_table('quiz_sessions')
    op.drop_table('story_choices')
    op.drop_table('stories')
    op.drop_table('children')
    op.drop_table('users')
