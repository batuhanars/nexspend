import 'package:flutter/material.dart';

class ResetPasswordPage extends StatelessWidget {
  const ResetPasswordPage({super.key, required this.token});
  final String token;
  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: Text('Reset Password Page')),
      );
}
