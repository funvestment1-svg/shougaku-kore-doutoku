import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/child_profile.dart';
import '../../providers/child_provider.dart';
import 'profile_edit_screen.dart';

class ProfileManagementScreen extends ConsumerWidget {
  const ProfileManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('お子様のプロフィール'),
        elevation: 0,
      ),
      body: ref.watch(childrenProfilesProvider).when(
            data: (profiles) {
              return Column(
                children: [
                  Expanded(
                    child: profiles.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person_add,
                                  size: 64,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'プロフィールがありません',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: profiles.length,
                            itemBuilder: (context, index) {
                              final profile = profiles[index];
                              return ProfileCard(
                                profile: profile,
                                onEdit: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ProfileEditScreen(
                                            profile: profile,
                                          ),
                                    ),
                                  );
                                },
                                onDelete: () {
                                  _showDeleteConfirmation(
                                    context,
                                    ref,
                                    profile.id,
                                  );
                                },
                              );
                            },
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ProfileEditScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('新しいプロフィールを作成'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.blue.shade400,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, st) => Center(
              child: Text('エラー: $error'),
            ),
          ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    String childId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('プロフィール削除'),
        content: const Text('このプロフィールを削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(childProfileNotifierProvider.notifier)
                  .deleteChildProfile(childId);
              Navigator.pop(context);
            },
            child: const Text(
              '削除',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileCard extends StatelessWidget {
  final ChildProfile profile;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProfileCard({
    super.key,
    required this.profile,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              profile.avatarEmoji,
              style: const TextStyle(fontSize: 28),
            ),
          ),
        ),
        title: Text(
          profile.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          profile.gradeDisplayName,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              onTap: onEdit,
              child: const Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('編集'),
                ],
              ),
            ),
            PopupMenuItem(
              onTap: onDelete,
              child: const Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text(
                    '削除',
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
