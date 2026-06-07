import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/child_profile.dart';
import '../../providers/child_provider.dart';

const _primaryColor = Color(0xFF9B59B6);

class ProfileEditScreen extends ConsumerStatefulWidget {
  final ChildProfile? profile;

  const ProfileEditScreen({super.key, this.profile});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  late TextEditingController _nameController;
  late int _selectedGrade;
  late String _selectedEmoji;

  static const _avatarEmojis = [
    '🦁', '🐯', '🐶', '🐱', '🐰', '🦊', '🦝', '🐨',
    '🐸', '🦋', '⭐', '🌟', '🌈', '🎵', '🎨', '🚀',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameController = TextEditingController(text: p?.name ?? '');
    _selectedGrade = p?.grade ?? 3;
    _selectedEmoji = p?.avatarEmoji ?? _avatarEmojis.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('お子様の名前を入力してください')),
      );
      return;
    }

    final notifier = ref.read(childProfileNotifierProvider.notifier);

    try {
      if (widget.profile != null) {
        await notifier.updateChildProfile(
          childId: widget.profile!.id,
          name: name,
          grade: _selectedGrade,
          avatarEmoji: _selectedEmoji,
        );
      } else {
        final child = await notifier.createChildProfile(
          name: name,
          grade: _selectedGrade,
          avatarEmoji: _selectedEmoji,
        );
        ref.read(currentChildIdProvider.notifier).state = child.id;
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          widget.profile != null ? 'プロフィール編集' : 'プロフィール作成',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // アバター選択
            const Text('アバターを選択',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF666666))),
            const SizedBox(height: 12),
            GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemCount: _avatarEmojis.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final emoji = _avatarEmojis[index];
                final isSelected = emoji == _selectedEmoji;
                return GestureDetector(
                  onTap: () => setState(() => _selectedEmoji = emoji),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: isSelected ? _primaryColor.withAlpha(20) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? _primaryColor : Colors.grey.shade300,
                        width: isSelected ? 2.5 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 34)),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // 名前入力
            const Text('お子様の名前',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF666666))),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: '例: 太郎',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _primaryColor, width: 2)),
              ),
            ),

            const SizedBox(height: 24),

            // 学年選択
            const Text('学年',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF666666))),
            const SizedBox(height: 8),
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
              onSelectionChanged: (s) => setState(() => _selectedGrade = s.first),
            ),

            const SizedBox(height: 36),

            // 保存ボタン
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  widget.profile != null ? '変更を保存' : '作成する',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
