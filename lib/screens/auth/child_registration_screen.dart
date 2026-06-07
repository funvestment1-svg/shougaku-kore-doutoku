import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/child_provider.dart';

const _primaryColor = Color(0xFF9B59B6);

class ChildRegistrationScreen extends ConsumerStatefulWidget {
  const ChildRegistrationScreen({super.key});

  @override
  ConsumerState<ChildRegistrationScreen> createState() =>
      _ChildRegistrationScreenState();
}

class _ChildRegistrationScreenState
    extends ConsumerState<ChildRegistrationScreen> {
  final _nicknameController = TextEditingController();
  int _selectedGrade = 3;
  int _selectedAvatar = 0;
  bool _isLoading = false;

  static const _avatarEmojis = [
    '🦁', '🐯', '🐶', '🐱', '🐰', '🦊', '🦝', '🐨',
  ];

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _handleComplete() async {
    final name = _nicknameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ニックネームを入力してください')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final notifier = ref.read(childProfileNotifierProvider.notifier);
      final child = await notifier.createChildProfile(
        name: name,
        grade: _selectedGrade,
        avatarEmoji: _avatarEmojis[_selectedAvatar],
      );

      // 作成した子どもを現在の子どもとして設定
      ref.read(currentChildIdProvider.notifier).state = child.id;

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('登録に失敗しました: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F5FF),
      appBar: AppBar(
        title: const Text('お子さんの情報登録'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _primaryColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // ヘッダー
          Center(
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: _primaryColor.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('👶', style: TextStyle(fontSize: 36)),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'お子さんのプロフィールを作成しましょう',
                  style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ニックネーム入力
          const Text(
            'ニックネーム',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nicknameController,
            decoration: InputDecoration(
              hintText: '例）たろう',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _primaryColor, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // 学年選択（3〜4年生のみ）
          const Text(
            '学年',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 12),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 3, label: Text('3年生')),
              ButtonSegment(value: 4, label: Text('4年生')),
            ],
            selected: {_selectedGrade},
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: _primaryColor,
              selectedForegroundColor: Colors.white,
            ),
            onSelectionChanged: (Set<int> newSelection) {
              setState(() => _selectedGrade = newSelection.first);
            },
          ),
          const SizedBox(height: 28),

          // アバター選択
          const Text(
            'アバターを選択',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: _avatarEmojis.length,
            itemBuilder: (context, index) {
              final isSelected = _selectedAvatar == index;
              return GestureDetector(
                onTap: () => setState(() => _selectedAvatar = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _primaryColor.withAlpha(20)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? _primaryColor : Colors.grey.shade300,
                      width: isSelected ? 2.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: _primaryColor.withAlpha(50),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      _avatarEmojis[index],
                      style: const TextStyle(fontSize: 38),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 40),

          // 完了ボタン
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleComplete,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text(
                      '登録して始める',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
