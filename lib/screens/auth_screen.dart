import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    setState(() {
      _isLoading = true;
    });
    try {
      if (_isLogin) {
        await context.read<AuthProvider>().signIn(email, password);
      } else {
        await context.read<AuthProvider>().signUp(email, password);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Log In' : 'Sign Up')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v != null && v.contains('@') ? null : 'Enter a valid email',
                ),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (v) => v != null && v.length >= 6 ? null : 'Min 6 chars',
                ),
                const SizedBox(height: 20),
                if (_isLoading) const CircularProgressIndicator(),
                if (!_isLoading) ElevatedButton(onPressed: _submit, child: Text(_isLogin ? 'Login' : 'Sign Up')),
                TextButton(
                  onPressed: () => setState(() {
                    _isLogin = !_isLogin;
                  }),
                  child: Text(_isLogin ? 'Create an account' : 'Have an account? Log in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
