import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SimpleLoginView extends StatefulWidget {
  const SimpleLoginView({super.key});

  @override
  State<SimpleLoginView> createState() => _SimpleLoginViewState();
}

class _SimpleLoginViewState extends State<SimpleLoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _message = '';

  Future<void> _login() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      setState(() => _message = 'Đăng nhập thành công');
    } on FirebaseAuthException catch (e) {
      setState(() => _message = 'Lỗi: ${e.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Mật khẩu'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _login,
            child: const Text('Đăng nhập'),
          ),
          Text(_message),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}