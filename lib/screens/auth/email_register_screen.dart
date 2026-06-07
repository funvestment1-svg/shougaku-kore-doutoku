import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/story_provider.dart';

class EmailRegisterScreen extends ConsumerStatefulWidget {
  const EmailRegisterScreen({super.key});

  @override
  ConsumerState<EmailRegisterScreen> createState() =>
      _EmailRegisterScreenState();
}

class _EmailRegisterScreenState extends ConsumerState<EmailRegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final name = _nameController.text.trim();

    // Validation
    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      setState(() {
        _errorMessage = 'すべての項目を入力してください';
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _errorMessage = 'パスワードが一致しません';
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _errorMessage = 'パスワードは6文字以上である必要があります';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Firebase でユーザーを作成
      final firebaseUser = await ref.read(
        emailRegisterProvider(
          (email: email, password: password, displayName: name),
        ).future,
      );
      if (firebaseUser == null) return;

      // 2. バックエンドに Firebase IDToken を送って JWT を取得
      final api = ref.read(apiServiceProvider);
      try {
        final idToken = await firebaseUser.getIdToken();
        if (idToken != null) {
          final result = await api.loginWithFirebase(idToken);
          final jwt = result['accessToken'] as String?;
          if (jwt != null) api.setAuthToken(jwt);
        }
      } catch (_) {
        // バックエンド登録に失敗してもホームへ進む
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/child-registration');
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('登録に失敗しました: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('保護者登録'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'お名前',
              hintText: '太郎',
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            enabled: !_isLoading,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'メールアドレス',
              hintText: 'parent@example.com',
              prefixIcon: const Icon(Icons.email),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
            enabled: !_isLoading,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'パスワード',
              hintText: '6文字以上',
              prefixIcon: const Icon(Icons.lock),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            obscureText: true,
            enabled: !_isLoading,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _confirmPasswordController,
            decoration: InputDecoration(
              labelText: 'パスワード（確認）',
              prefixIcon: const Icon(Icons.lock),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            obscureText: true,
            enabled: !_isLoading,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red.shade700, fontSize: 12),
              ),
            ),
          ],
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isLoading ? null : _handleRegister,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('登録'),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'COPPA準拠: お子さんの個人情報は名前と学年のみ保存されます。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
            ),
          ),
        ],
      ),
    );
  }
}
