import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});
  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _formKey = GlobalKey<FormState>();
  final _message = TextEditingController();
  final _contactEmail = TextEditingController();

  int _appRating = 0;
  int _servicesRating = 0;
  String _category = 'General';
  bool _allowContact = false;

  bool _submitting = false;
  double _progress = 0;

  final _cats = const ['General','UI/UX','Performance','Features','Bugs/Issues','Other'];

  @override
  void dispose() {
    _message.dispose();
    _contactEmail.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_appRating == 0 || _servicesRating == 0) {
      _toast('Please rate both: App Experience and Services.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _toast('You must be signed in to submit feedback.');
      return;
    }

    setState(() { _submitting = true; _progress = 0.25; });
    try {
      await FirebaseFirestore.instance.collection('feedback').add({
        'uid': user.uid,
        'appRating': _appRating,
        'servicesRating': _servicesRating,
        'category': _category,
        'message': _message.text.trim(),
        'allowContact': _allowContact,
        'contactEmail': _allowContact ? _contactEmail.text.trim() : null,
        'createdAt': FieldValue.serverTimestamp(),
        'createdAtLocal': DateTime.now().toIso8601String(),
        'platform': 'flutter-mobile',
      });
      setState(() => _progress = 1);
      if (!mounted) return;
      _toast('Thanks for your feedback!', success: true);
      setState(() {
        _appRating = 0;
        _servicesRating = 0;
        _category = 'General';
        _allowContact = false;
      });
      _message.clear();
      _contactEmail.clear();
    } catch (e) {
      _toast('Could not submit feedback.');
    } finally {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 300));
      setState(() { _submitting = false; _progress = 0; });
    }
  }

  void _toast(String msg, {bool success = false}) {
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: success ? cs.inverseSurface : cs.error,
        content: Row(
          children: [
            Icon(success ? Icons.check_circle : Icons.error, color: cs.onInverseSurface),
            const SizedBox(width: 8),
            Expanded(child: Text(msg, style: TextStyle(color: cs.onInverseSurface))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Feedback')),
      body: Stack(
        children: [
          // Clean, high-contrast background
          Positioned.fill(
            child: Container(
              color: cs.surface, // solid surface to avoid haze stacking
            ),
          ),

          SafeArea(
            child: Form(
              key: _formKey,
              child: AbsorbPointer(
                absorbing: _submitting,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    // Header (glass frame + solid interior)
                    _GlassCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _IconRing(icon: Icons.rate_review_outlined),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Tell us how we’re doing',
                                  style: tt.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.1,
                                  )),
                                const SizedBox(height: 4),
                                Text(
                                  'Rate the app and our services. Your feedback helps us improve for everyone at UCP.',
                                  style: tt.bodyMedium?.copyWith(
                                    color: cs.onSurfaceVariant,
                                    height: 1.28,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    _GlassCard(
                      title: 'Category',
                      child: SizedBox(
                        width: double.infinity,
                        child: Wrap(
                          alignment: WrapAlignment.start,
                          runAlignment: WrapAlignment.start,
                          spacing: 8,
                          runSpacing: 8,
                          children: _cats.map((c) {
                            final sel = _category == c;
                            return ChoiceChip(
                              label: Text(c),
                              selected: sel,
                              onSelected: (_) => setState(() => _category = c),
                              labelStyle: tt.labelLarge?.copyWith(
                                fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                                color: sel ? cs.onPrimaryContainer : cs.onSurface,
                              ),
                              selectedColor: cs.primaryContainer,
                              backgroundColor: cs.surfaceContainerHighest,
                              side: BorderSide(color: cs.outlineVariant),
                            );
                          }).toList(),
                        ),
                      ),

                    ),
                    const SizedBox(height: 12),

                    _GlassCard(
                      title: 'Rate your experience',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _StarRow(
                            label: 'Overall app experience',
                            value: _appRating,
                            onChanged: (r) => setState(() => _appRating = r),
                          ),
                          const SizedBox(height: 8),
                          _StarRow(
                            label: 'Quality of services',
                            value: _servicesRating,
                            onChanged: (r) => setState(() => _servicesRating = r),
                          ),
                          if (_appRating == 0 || _servicesRating == 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Please provide both ratings.',
                                style: tt.bodySmall?.copyWith(color: cs.error),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    _GlassCard(
                      title: 'Comments (optional)',
                      child: TextFormField(
                        controller: _message,
                        minLines: 4,
                        maxLines: 8,
                        maxLength: 600,
                        decoration: _inputDecoration(context, 'Share details, suggestions, or issues'),
                        validator: (v) {
                          final t = (v ?? '').trim();
                          if (t.isEmpty) return null;
                          if (t.length < 10) return 'Please add at least 10 characters.';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    _GlassCard(
                      title: 'Can we contact you about this?',
                      child: Column(
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('Allow contact', style: tt.bodyLarge),
                            value: _allowContact,
                            onChanged: (v) => setState(() => _allowContact = v),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _contactEmail,
                            enabled: _allowContact,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _inputDecoration(context, 'Contact email (optional)')
                                .copyWith(prefixIcon: const Icon(Icons.alternate_email)),
                            validator: (v) {
                              if (!_allowContact) return null;
                              final val = (v ?? '').trim();
                              if (val.isEmpty) return 'Please provide an email or turn this off.';
                              final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(val);
                              return ok ? null : 'Enter a valid email address.';
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    if (_submitting)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(value: _progress == 0 ? null : _progress),
                      ),
                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _submitting ? null : _submit,
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: _submitting
                              ? const SizedBox(
                                  key: ValueKey('l'),
                                  width: 18, height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.send_rounded, key: ValueKey('i')),
                        ),
                        label: Text(_submitting ? 'Submitting...' : 'Submit Feedback'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (_submitting)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.03)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, String label) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      filled: true,
      isDense: true,
      fillColor: cs.surfaceContainerHigh, // solid for readability
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.primary, width: 1.6),
      ),
      labelStyle: TextStyle(color: cs.onSurfaceVariant),
      hintStyle: TextStyle(color: cs.onSurfaceVariant),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      counterText: '',
    );
  }
}

/* ================= Readable “frosted” building blocks ================= */

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child, this.title});
  final Widget child;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Frame uses frosted edge; content sits on a solid surfaceContainerHigh
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          // Frosted frame
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                border: Border.all(color: Colors.white.withOpacity(0.18)),
              ),
            ),
          ),
          // Solid content area for crisp text
          Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null) ...[
                    Text(
                      title!,
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.1,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  child,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconRing extends StatelessWidget {
  const _IconRing({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        shape: BoxShape.circle,
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Icon(icon, color: cs.primary),
    );
  }
}

/* ================= Stars row with better legibility ================= */

class _StarRow extends StatelessWidget {
  const _StarRow({required this.label, required this.value, required this.onChanged});
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(child: Text(label, style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600))),
        for (int i = 1; i <= 5; i++)
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => onChanged(i),
            iconSize: 26,
            icon: Icon(
              i <= value ? Icons.star_rounded : Icons.star_border_rounded,
              color: i <= value ? cs.secondary : cs.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}
