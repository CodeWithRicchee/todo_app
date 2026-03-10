import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // ── Palette ──────────────────────────────────────────────────────────────
  static const _bg = Color(0xFF0D0F14);
  static const _surface = Color(0xFF151820);
  static const _card = Color(0xFF1C2030);
  static const _gold = Color(0xFFCCA84B);
  static const _goldLight = Color(0xFFE8C870);
  static const _textPrimary = Color(0xFFF0EDE6);
  static const _textMuted = Color(0xFF7A8099);
  static const _border = Color(0xFF2A2F42);
  static const _error = Color(0xFFE05252);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    _animController.reset();
    setState(() => _isLogin = !_isLogin);
    _animController.forward();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await context.read<AuthProvider>().signIn(email, password);
      } else {
        await context.read<AuthProvider>().signUp(email, password);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnack(e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: _error, width: 1),
        ),
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: _error, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: const TextStyle(color: _textPrimary, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // ── Decorative background orbs ────────────────────────────────
          Positioned(top: -120, right: -80, child: _Orb(color: _gold.withOpacity(0.07), size: 380)),
          Positioned(bottom: -60, left: -100, child: _Orb(color: const Color(0xFF3A4AFF).withOpacity(0.06), size: 300)),

          // ── Content ───────────────────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Todo App',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontFamily: 'Georgia', fontSize: 18, fontWeight: FontWeight.w500, color: _gold, letterSpacing: 1.5),
                        ),
                        SizedBox(height: 10),
                        // Logo / Brand mark
                        Center(
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: _surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _gold.withOpacity(0.4), width: 1.5),
                              boxShadow: [BoxShadow(color: _gold.withOpacity(0.15), blurRadius: 24, spreadRadius: 2)],
                            ),
                            child: const Icon(Icons.diamond_outlined, color: _gold, size: 30),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Headline
                        Text(
                          _isLogin ? 'Welcome back.' : 'Create account.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary,
                            letterSpacing: -0.5,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isLogin ? 'Sign in to continue your journey.' : 'Join us and get started today.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14, color: _textMuted, letterSpacing: 0.2),
                        ),
                        const SizedBox(height: 40),

                        // Form card
                        Container(
                          decoration: BoxDecoration(
                            color: _card,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: _border, width: 1),
                          ),
                          padding: const EdgeInsets.all(24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _FieldLabel(label: 'Email address'),
                                const SizedBox(height: 8),
                                _AuthField(
                                  controller: _emailController,
                                  hint: 'you@example.com',
                                  keyboardType: TextInputType.emailAddress,
                                  prefixIcon: Icons.alternate_email_rounded,
                                  validator: (v) => v != null && v.contains('@') ? null : 'Enter a valid email',
                                ),
                                const SizedBox(height: 20),
                                _FieldLabel(label: 'Password'),
                                const SizedBox(height: 8),
                                _AuthField(
                                  controller: _passwordController,
                                  hint: '••••••••',
                                  obscureText: _obscurePassword,
                                  prefixIcon: Icons.lock_outline_rounded,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      color: _textMuted,
                                      size: 18,
                                    ),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                  validator: (v) => v != null && v.length >= 6 ? null : 'Minimum 6 characters',
                                ),
                                if (_isLogin) ...[
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      'Forgot password?',
                                      style: TextStyle(fontSize: 12, color: _gold.withOpacity(0.85), letterSpacing: 0.2),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 28),

                                // Primary CTA
                                _PrimaryButton(label: _isLogin ? 'Sign In' : 'Create Account', isLoading: _isLoading, onPressed: _submit),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Toggle row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isLogin ? "Don't have an account? " : 'Already have an account? ',
                              style: const TextStyle(color: _textMuted, fontSize: 13),
                            ),
                            GestureDetector(
                              onTap: _toggleMode,
                              child: Text(
                                _isLogin ? 'Sign up' : 'Log in',
                                style: const TextStyle(color: _goldLight, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.2),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Divider + social hint
                        Row(
                          children: [
                            const Expanded(child: Divider(color: _border)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              child: Text('or continue with', style: TextStyle(color: _textMuted.withOpacity(0.7), fontSize: 11, letterSpacing: 0.5)),
                            ),
                            const Expanded(child: Divider(color: _border)),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Social buttons
                        Row(
                          children: [
                            Expanded(
                              child: _SocialButton(
                                icon: Icons.g_mobiledata_rounded,
                                label: 'Google',
                                onTap: _isLoading
                                    ? null
                                    : () async {
                                        setState(() => _isLoading = true);
                                        try {
                                          await context.read<AuthProvider>().signInWithGoogle();
                                        } catch (e) {
                                          if (mounted) _showErrorSnack(e.toString());
                                        } finally {
                                          if (mounted) setState(() => _isLoading = false);
                                        }
                                      },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helper widgets ──────────────────────────────────────────────────────────

class _Orb extends StatelessWidget {
  final Color color;
  final double size;
  const _Orb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(color: Color(0xFFB0B8CC), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8),
    );
  }
}

class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final IconData prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _AuthField({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
  });

  static const _bg = Color(0xFF13161F);
  static const _border = Color(0xFF2A2F42);
  static const _gold = Color(0xFFCCA84B);
  static const _textPrimary = Color(0xFFF0EDE6);
  static const _textMuted = Color(0xFF7A8099);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(color: _textPrimary, fontSize: 14, letterSpacing: 0.3),
      cursorColor: _gold,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _textMuted, fontSize: 14),
        filled: true,
        fillColor: _bg,
        prefixIcon: Icon(prefixIcon, color: _textMuted, size: 18),
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _gold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE05252)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE05252), width: 1.5),
        ),
        errorStyle: const TextStyle(color: Color(0xFFE05252), fontSize: 11),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  const _PrimaryButton({required this.label, required this.isLoading, required this.onPressed});

  static const _gold = Color(0xFFCCA84B);
  static const _goldLight = Color(0xFFE8C870);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(colors: [_gold, _goldLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
          boxShadow: [BoxShadow(color: _gold.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 6))],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0D0F14)))
              : Text(
                  label,
                  style: const TextStyle(color: Color(0xFF0D0F14), fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.4),
                ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _SocialButton({required this.icon, required this.label, this.onTap});

  static const _surface = Color(0xFF151820);
  static const _border = Color(0xFF2A2F42);
  static const _textPrimary = Color(0xFFF0EDE6);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: _textPrimary, size: 20),
        label: Text(
          label,
          style: const TextStyle(color: _textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: _surface,
          side: const BorderSide(color: _border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
