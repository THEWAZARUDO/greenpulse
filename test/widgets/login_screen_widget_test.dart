import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class TestLoginForm extends StatefulWidget {
  final Future<void> Function(String email, String password)? onSubmit;

  const TestLoginForm({super.key, this.onSubmit});

  @override
  State<TestLoginForm> createState() => _TestLoginFormState();
}

class _TestLoginFormState extends State<TestLoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            key: const Key('email_field'),
            controller: _emailCtrl,
            decoration: const InputDecoration(labelText: 'Email'),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Vui lòng nhập email';
              if (!v.contains('@')) return 'Email không hợp lệ';
              return null;
            },
          ),
          TextFormField(
            key: const Key('password_field'),
            controller: _passwordCtrl,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Mật khẩu',
              suffixIcon: IconButton(
                key: const Key('toggle_password_btn'),
                icon: Icon(
                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
              return null;
            },
          ),
          if (_errorMessage != null)
            Text(_errorMessage!, key: const Key('error_text'), style: const TextStyle(color: Colors.red)),
          ElevatedButton(
            key: const Key('login_btn'),
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                if (widget.onSubmit != null) {
                  await widget.onSubmit!(_emailCtrl.text, _passwordCtrl.text);
                }
              }
            },
            child: const Text('Đăng nhập'),
          ),
        ],
      ),
    );
  }
}

void main() {
  group('Login Form Widget Tests', () {
    testWidgets('Shows validation errors on empty submission', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TestLoginForm(),
            ),
          ),
        ),
      );

      // Tap login without entering credentials
      await tester.tap(find.byKey(const Key('login_btn')));
      await tester.pump();

      expect(find.text('Vui lòng nhập email'), findsOneWidget);
      expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);
    });

    testWidgets('Validates email format properly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TestLoginForm(),
            ),
          ),
        ),
      );

      await tester.enterText(find.byKey(const Key('email_field')), 'invalid-email');
      await tester.enterText(find.byKey(const Key('password_field')), 'password123');

      await tester.tap(find.byKey(const Key('login_btn')));
      await tester.pump();

      expect(find.text('Email không hợp lệ'), findsOneWidget);
      expect(find.text('Vui lòng nhập mật khẩu'), findsNothing);
    });

    testWidgets('Toggles password visibility on suffix icon click', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TestLoginForm(),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

      await tester.tap(find.byKey(const Key('toggle_password_btn')));
      await tester.pump();

      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });

    testWidgets('Invokes onSubmit callback when inputs are valid', (tester) async {
      String submittedEmail = '';
      String submittedPassword = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TestLoginForm(
                onSubmit: (email, pass) async {
                  submittedEmail = email;
                  submittedPassword = pass;
                },
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byKey(const Key('email_field')), 'user@greenpulse.vn');
      await tester.enterText(find.byKey(const Key('password_field')), 'Secret123!');

      await tester.tap(find.byKey(const Key('login_btn')));
      await tester.pump();

      expect(find.text('Vui lòng nhập email'), findsNothing);
      expect(find.text('Vui lòng nhập mật khẩu'), findsNothing);
      expect(submittedEmail, 'user@greenpulse.vn');
      expect(submittedPassword, 'Secret123!');
    });
  });
}
