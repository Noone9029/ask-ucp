import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ask_ucp_flutter/core/scaffold_messenger.dart';
import 'sign_in_page.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();

  // RegNo parts
  static const String _campus = 'L1'; // locked
  String _season = 'F'; // F/S
  String _yy = '24'; // dropdown YY

  final _degree = TextEditingController(); // letters only, uppercase, no spaces
  final _roll = TextEditingController(); // digits only, max 4, pad to 4

  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _loading = false;
  bool _agreeTos = true;

  // -------- Rules --------
  static const String _ucpDomain = 'ucp.edu.pk';

  static final RegExp _upperRx = RegExp(r'[A-Z]');
  static final RegExp _lowerRx = RegExp(r'[a-z]');
  static final RegExp _digitRx = RegExp(r'\d');

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    _pass.addListener(() {
      if (mounted) setState(() {});
    });

    // Keep degree visually normalized live
    _degree.addListener(() {
      final normalized = _normalizeDegree(_degree.text);
      if (normalized != _degree.text) {
        _degree.value = _degree.value.copyWith(
          text: normalized,
          selection: TextSelection.collapsed(offset: normalized.length),
          composing: TextRange.empty,
        );
      }
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    _confirm.dispose();
    _degree.dispose();
    _roll.dispose();
    super.dispose();
  }

  // -----------------------------
  // Helpers: validation + strength
  // -----------------------------

  String? _validateUcpEmail(String? v) {
    final value = (v ?? '').trim().toLowerCase();
    if (value.isEmpty) return 'Email is required';

    final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value);
    if (!ok) return 'Enter a valid email';

    if (!value.endsWith('@$_ucpDomain')) {
      return 'Use your UCP email (ends with @$_ucpDomain)';
    }
    return null;
  }

  int _passwordScore(String p) {
    int score = 0;
    if (p.length >= 8) score++;
    if (_upperRx.hasMatch(p)) score++;
    if (_lowerRx.hasMatch(p)) score++;
    if (_digitRx.hasMatch(p)) score++;
    return score; // 0..4
  }

  String _passwordStrengthLabel(String p) {
    final s = _passwordScore(p);
    if (p.isEmpty) return '';
    if (s <= 1) return 'Weak';
    if (s == 2) return 'Okay';
    if (s == 3) return 'Good';
    return 'Strong';
  }

  String? _validatePassword(String? v) {
    final p = (v ?? '');
    if (p.isEmpty) return 'Password is required';
    if (p.contains(' ')) return 'Password cannot contain spaces';
    if (p.length < 8) return 'Use at least 8 characters';
    if (!_upperRx.hasMatch(p)) return 'Add at least 1 uppercase letter';
    if (!_lowerRx.hasMatch(p)) return 'Add at least 1 lowercase letter';
    if (!_digitRx.hasMatch(p)) return 'Add at least 1 number';
    return null;
  }

  String _normalizeDegree(String input) {
    // Letters only, uppercase, no spaces
    final onlyLetters = input.replaceAll(RegExp(r'[^A-Za-z]'), '');
    return onlyLetters.toUpperCase();
  }

  String _normalizeRoll(String input) {
    return input.replaceAll(RegExp(r'\D'), '');
  }

  String get _regNoComputed {
  final degree = _normalizeDegree(_degree.text);
  final roll = _normalizeRoll(_roll.text);
  final year = _yy;
  final season = _season;

  // Only build when parts exist (so validation can catch missing)
  return '$_campus$season$year$degree$roll';
}

  String? _validateDegree(String? v) {
    final value = _normalizeDegree(v ?? '');
    if (value.isEmpty) return 'Degree code is required (e.g., BSCS)';
    if (value.length < 2) return 'Degree code too short';
    // optional: cap length so it doesn’t go wild
    if (value.length > 6) return 'Keep degree code within 6 letters';
    return null;
  }

  String? _validateRoll(String? v) {
    final value = _normalizeRoll(v ?? '');
    if (value.isEmpty) return 'Roll # is required';
    if (!RegExp(r'^\d{4}$').hasMatch(value)) return 'Roll must be 4 digits';
    return null;
  }

  String? _validateRegNoComposite() {
    // Final strict check: L1 + (F|S) + YY + DEG + 4 digits
    final reg = _regNoComputed;
    final rx = RegExp(r'^L1[FS]\d{2}[A-Z]{2,6}\d{4}$');
    if (!rx.hasMatch(reg)) return 'Registration format invalid';
    return null;
  }

  // -----------------------------
  // Register
  // -----------------------------
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreeTos) {
      _showError('Please accept the Terms of Service to continue.');
      return;
    }

    final regErr = _validateRegNoComposite();
    if (regErr != null) {
      _showError(regErr);
      return;
    }

    setState(() => _loading = true);
    try {
      final email = _email.text.trim().toLowerCase();
      final password = _pass.text;
      final fullName = _name.text.trim();
      final regNo = _regNoComputed;

      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = cred.user;
      if (user == null) {
        _showError('Registration failed. Please try again.');
        return;
      }

      await user.updateDisplayName(fullName);
      await user.sendEmailVerification();

      // Save regNo to Firestore: users/{uid}.regNo
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {
          'name': fullName,
          'email': email,
          'regNo': regNo,
          'season': _season,
          'yy': _yy,
          'degree': _normalizeDegree(_degree.text),
          'roll': _normalizeRoll(_roll.text),
          'campus': _campus,
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // Don’t keep them signed in after registration.
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      _showSnack('Account created! Please sign in.');

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SignInPage()),
        (route) => route.isFirst || route.settings.name == '/',
      );
    } on FirebaseAuthException catch (e) {
      _showError(_friendlyAuthError(e));
    } on FirebaseException catch (_) {
      _showError('Account created, but saving profile failed. Please try signing in again.');
    } catch (_) {
      _showError('Could not create account. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Use at least 8 chars with uppercase, lowercase and a number.';
      case 'operation-not-allowed':
        return 'Email/password accounts are disabled for this project.';
      case 'network-request-failed':
        return 'Network error. Check your internet and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return e.message ?? 'Registration failed.';
    }
  }

  void _showError(String msg) {
    final scheme = Theme.of(context).colorScheme;
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: scheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSnack(String msg) {
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<String> get _yearOptions {
    // Pick what you want. This gives 20..30 (i.e., 2020..2030) as YY.
    // You can also generate from current year if you prefer.
    return List.generate(11, (i) => (20 + i).toString().padLeft(2, '0'));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final passStrength = _passwordStrengthLabel(_pass.text);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('Create account'),
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
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
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: _Glass(
                    borderRadius: 24,
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Student Portal',
                            style: text.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'University of Central Punjab',
                            style: text.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                          const SizedBox(height: 18),

                          _FilledInput(
                            controller: _name,
                            label: 'Full name',
                            hint: 'e.g., Ramsha Khan',
                            icon: Icons.person_outline,
                            textInputAction: TextInputAction.next,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Name is required'
                                : null,
                          ),
                          const SizedBox(height: 12),

                          // -------- RegNo Builder --------
                          Text(
                            'Registration #',
                            style: text.bodySmall?.copyWith(
                              color: Colors.white.withOpacity(0.92),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),

                          Row(
                            children: [
                              // Campus (locked)
                              Expanded(
                                child: _LockedChip(label: 'Campus', value: _campus),
                              ),
                              const SizedBox(width: 10),

                              // Season dropdown
                              Expanded(
                                child: _DropdownGlass(
                                  label: 'Season',
                                  value: _season,
                                  items: const ['F', 'S'],
                                  onChanged: _loading
                                      ? null
                                      : (v) => setState(() => _season = v),
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Year dropdown
                              Expanded(
                                child: _DropdownGlass(
                                  label: 'Year',
                                  value: _yy,
                                  items: _yearOptions,
                                  onChanged: _loading
                                      ? null
                                      : (v) => setState(() => _yy = v),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: _FilledInput(
                                  controller: _degree,
                                  label: 'Degree code',
                                  hint: 'e.g., BSCS',
                                  icon: Icons.school_outlined,
                                  textInputAction: TextInputAction.next,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z]')),
                                    UpperCaseTextFormatter(),
                                  ],
                                  validator: _validateDegree,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: _FilledInput(
                                  controller: _roll,
                                  label: 'Roll',
                                  hint: 'e.g.,0323',
                                  icon: Icons.confirmation_number_outlined,
                                  keyboard: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(4),
                                  ],
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Roll # is required';
                                    }
                                    if (v.length != 4) {
                                      return 'Roll # must be exactly 4 digits';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          _FilledInput(
                            controller: _email,
                            label: 'UCP Email',
                            hint: 'you@ucp.edu.pk',
                            icon: Icons.alternate_email,
                            keyboard: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: _validateUcpEmail,
                            onChanged: (v) {
                              final lower = v.toLowerCase();
                              if (lower != v) {
                                _email.value = _email.value.copyWith(
                                  text: lower,
                                  selection: TextSelection.collapsed(offset: lower.length),
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 12),

                          _FilledInput(
                            controller: _pass,
                            label: 'Password',
                            hint: 'Min 8, Aa + 1 number',
                            icon: Icons.lock_outline,
                            obscure: _obscure1,
                            textInputAction: TextInputAction.next,
                            trailing: IconButton(
                              onPressed: () => setState(() => _obscure1 = !_obscure1),
                              icon: Icon(_obscure1 ? Icons.visibility : Icons.visibility_off),
                              tooltip: _obscure1 ? 'Show password' : 'Hide password',
                              color: Colors.white.withOpacity(0.9),
                            ),
                            validator: _validatePassword,
                            inputFormatters: [
                              FilteringTextInputFormatter.deny(RegExp(r'\s')),
                            ],
                          ),

                          if (passStrength.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _StrengthBar(score: _passwordScore(_pass.text)),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  passStrength,
                                  style: text.bodySmall?.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 12),

                          _FilledInput(
                            controller: _confirm,
                            label: 'Confirm password',
                            hint: '••••••••',
                            icon: Icons.lock_outline,
                            obscure: _obscure2,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _register(),
                            trailing: IconButton(
                              onPressed: () => setState(() => _obscure2 = !_obscure2),
                              icon: Icon(_obscure2 ? Icons.visibility : Icons.visibility_off),
                              tooltip: _obscure2 ? 'Show password' : 'Hide password',
                              color: Colors.white.withOpacity(0.9),
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.deny(RegExp(r'\s')),
                            ],
                            validator: (v) {
                              if ((v ?? '').isEmpty) return 'Confirm your password';
                              return (v ?? '') != _pass.text ? 'Passwords do not match' : null;
                            },
                          ),
                          const SizedBox(height: 10),

                          Theme(
                            data: Theme.of(context).copyWith(
                              checkboxTheme: CheckboxThemeData(
                                side: BorderSide(color: Colors.white.withOpacity(0.7)),
                                checkColor: WidgetStateProperty.all(Colors.white),
                                fillColor: WidgetStateProperty.resolveWith(
                                  (states) => states.contains(WidgetState.selected)
                                      ? scheme.primary
                                      : Colors.white.withOpacity(0.08),
                                ),
                              ),
                            ),
                            child: CheckboxListTile(
                              value: _agreeTos,
                              onChanged: (v) => setState(() => _agreeTos = v ?? false),
                              controlAffinity: ListTileControlAffinity.leading,
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                'I agree to the Terms of Service',
                                style: text.bodySmall?.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _register,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                backgroundColor: scheme.primary,
                                foregroundColor: Colors.white,
                                elevation: 6,
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                child: _loading
                                    ? const SizedBox(
                                        key: ValueKey('loader'),
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation(Colors.white),
                                        ),
                                      )
                                    : const Text(
                                        'Create account',
                                        key: ValueKey('label'),
                                        style: TextStyle(fontWeight: FontWeight.w800),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account?',
                                style: text.bodySmall?.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                              TextButton(
                                onPressed: _loading ? null : () => Navigator.of(context).pop(),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Sign in'),
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
          ),
        ],
      ),
    );
  }
}

/// Reusable frosted glass container
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
    this.inputFormatters,
    this.onChanged,
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
  final List<TextInputFormatter>? inputFormatters;
  final void Function(String)? onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      textInputAction: textInputAction,
      obscureText: obscure,
      onFieldSubmitted: onSubmitted,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      inputFormatters: inputFormatters,
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

class _StrengthBar extends StatelessWidget {
  const _StrengthBar({required this.score});
  final int score;

  @override
  Widget build(BuildContext context) {
    final base = Colors.white.withOpacity(0.22);
    final fill = Colors.white.withOpacity(0.80);

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 8,
        child: LayoutBuilder(
          builder: (_, c) {
            final w = c.maxWidth;
            final fraction = (score.clamp(0, 4)) / 4.0;
            return Stack(
              children: [
                Positioned.fill(child: ColoredBox(color: base)),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: w * fraction,
                  child: ColoredBox(color: fill),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Forces uppercase typing
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final upper = newValue.text.toUpperCase();
    return newValue.copyWith(
      text: upper,
      selection: newValue.selection,
      composing: TextRange.empty,
    );
  }
}

/// Locked “chip-like” glass tile
class _LockedChip extends StatelessWidget {
  const _LockedChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, color: Colors.white.withOpacity(0.9), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: t.labelSmall?.copyWith(color: Colors.white.withOpacity(0.8))),
                const SizedBox(height: 2),
                Text(value, style: t.bodyMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dropdown styled for your glass UI
class _DropdownGlass extends StatelessWidget {
  const _DropdownGlass({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> items;
  final void Function(String v)? onChanged;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.expand_more, color: Colors.white.withOpacity(0.9)),
          dropdownColor: const Color(0xFF121212),
          style: t.bodyMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
          items: items
              .map(
                (e) => DropdownMenuItem<String>(
                  value: e,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(label, style: t.labelSmall?.copyWith(color: Colors.white.withOpacity(0.8))),
                      const SizedBox(height: 2),
                      Text(e),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged == null ? null : (v) => onChanged!(v!),
        ),
      ),
    );
  }
}