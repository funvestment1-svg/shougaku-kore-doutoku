import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('小学コレ！道徳'),
      ),
      body: const Center(
        child: Text('v1.1 実装中...'),
      ),
    );
  }
}
