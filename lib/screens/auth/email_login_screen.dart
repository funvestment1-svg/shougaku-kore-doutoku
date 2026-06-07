import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/story_provider.dart';
import '../../providers/child_provider.dart';
import 'email_register_screen.dart';

class EmailLoginScreen extends ConsumerStatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  ConsumerState<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends ConsumerState<EmailLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      final user = await ref.read(
        emailSignInProvider(
          (email: email, password: password),
        ).future,
      );

      if (user == null || !mounted) return;

      // Firebase ID トークンをバックエンド JWT に交換
      final api = ref.read(apiServiceProvider);
      try {
        final idToken = await user.getIdToken();
        if (idToken != null) {
          final result = await api.loginWithFirebase(idToken);
          final jwt = result['accessToken'] as String?;
          if (jwt != null) api.setAuthToken(jwt);
        }
      } catch (_) {
        // JWT 取得失敗でもホームに進む（再試行は apiServiceProvider のリスナーに委ねる）
      }

      if (!mounted) return;

      // 子どもプロフィールの存在を確認してルーティング
      try {
        final children = await api.fetchChildrenProfiles();
        if (!mounted) return;
        if (children.isNotEmpty) {
          ref.read(currentChildIdProvider.notifier).state = children.first.id;
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          Navigator.of(context).pushReplacementNamed('/child-registration');
        }
      } catch (_) {
        if (mounted) Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ログインに失敗しました: ${e.toString()}')),
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
        title: const Text('メールでログイン'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 40),
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
            onPressed: _isLoading ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('ログイン'),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _isLoading
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const EmailRegisterScreen(),
                      ),
                    );
                  },
            child: const Text('アカウントをお持ちでない方は登録'),
          ),
        ],
      ),
    );
  }
}
