import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'register_page.dart';
import 'auth_gate.dart';
import 'package:ask_ucp_flutter/core/scaffold_messenger.dart';


class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Make status bar content light over the hero image
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _pass.text,
      );

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      _err(_friendly(e));
    } catch (_) {
      _err('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgot() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      _err('Enter your email first to receive a reset link.');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _snack('Password reset link sent to $email');
    } on FirebaseAuthException catch (e) {
      _err(_friendly(e));
    }
  }

  String _friendly(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-not-found':
        return 'No account found for this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Try again in a moment.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }

void _err(String msg) {
  final scheme = Theme.of(context).colorScheme;
  scaffoldMessengerKey.currentState?.showSnackBar(
    SnackBar(
      content: Text(msg),
      backgroundColor: scheme.error,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

void _snack(String msg) {
  scaffoldMessengerKey.currentState?.showSnackBar(
    const SnackBar(behavior: SnackBarBehavior.floating, content: Text('')),
  );
  scaffoldMessengerKey.currentState?.showSnackBar(
    SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
  );
}


  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      // Transparent app bar over hero image
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('Sign in'),
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // HERO BACKGROUND
          Positioned.fill(
            child: ShaderMask(
              shaderCallback: (rect) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black87],
                stops: [0.1, 0.5],
              ).createShader(rect),
              blendMode: BlendMode.darken,
              child: Image.asset(
                'assets/images/ucp_bg.jpg',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
          ),

          // CONTENT
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: _Glass(
                    borderRadius: 24,
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Title + subtitle
                          Text(
                            'Welcome back',
                            style: text.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Sign in to continue',
                            style: text.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // EMAIL
                          _FilledInput(
                            controller: _email,
                            label: 'Email',
                            hint: 'you@ucp.edu.pk',
                            icon: Icons.alternate_email,
                            keyboard: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: (v) {
                              final value = v?.trim() ?? '';
                              if (value.isEmpty) return 'Email is required';
                              final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value);
                              return ok ? null : 'Enter a valid email';
                            },
                          ),
                          const SizedBox(height: 12),

                          // PASSWORD
                          _FilledInput(
                            controller: _pass,
                            label: 'Password',
                            hint: '••••••••',
                            icon: Icons.lock_outline,
                            obscure: _obscure,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _signIn(),
                            trailing: IconButton(
                              onPressed: () => setState(() => _obscure = !_obscure),
                              icon: Icon(
                                _obscure ? Icons.visibility : Icons.visibility_off,
                              ),
                              tooltip: _obscure ? 'Show password' : 'Hide password',
                              color: Colors.white.withOpacity(0.9),
                            ),
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Password is required'
                                : null,
                          ),
                          const SizedBox(height: 8),

                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _loading ? null : _forgot,
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Forgot password?'),
                            ),
                          ),
                          const SizedBox(height: 6),

                          // SIGN IN BUTTON
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _signIn,
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                backgroundColor: scheme.primary,
                                foregroundColor: Colors.white,
                                elevation: 6,
                              ),
                              child: AnimatedSwitcher(
                                duration:
                                    const Duration(milliseconds: 250),
                                child: _loading
                                    ? const SizedBox(
                                        key: ValueKey('loader'),
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation(Colors.white),
                                        ),
                                      )
                                    : const Text(
                                        'Sign in',
                                        key: ValueKey('label'),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // REGISTER
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _loading
                                  ? null
                                  : () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const RegisterPage(),
                                        ),
                                      );
                                    },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(26),
                                ),
                                side: BorderSide(
                                  color: Colors.white.withOpacity(0.5),
                                ),
                                foregroundColor: Colors.white,
                                backgroundColor:
                                    Colors.white.withOpacity(0.04),
                              ),
                              child: const Text(
                                'Create an account',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),

                          const SizedBox(height: 4),
                          // Tiny legal line
                          Text(
                            'By continuing, you agree to our Terms of Service.',
                            textAlign: TextAlign.center,
                            style: text.bodySmall?.copyWith(
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
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

/// Frosted “glass” container (no extra deps).
class _Glass extends StatelessWidget {
  const _Glass({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 20,
  });

  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            border: Border.all(color: Colors.white.withOpacity(0.16)),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Unified filled input used above (matches the glass style).
class _FilledInput extends StatelessWidget {
  const _FilledInput({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboard,
    this.textInputAction,
    this.validator,
    this.obscure = false,
    this.onSubmitted,
    this.trailing,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboard;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final bool obscure;
  final void Function(String)? onSubmitted;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      textInputAction: textInputAction,
      obscureText: obscure,
      onFieldSubmitted: onSubmitted,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.white),
        suffixIcon: trailing,
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.95)),
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.75)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      ),
    );
  }
}
