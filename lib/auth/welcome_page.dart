import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sign_in_page.dart';
import 'register_page.dart';

class WelcomePage extends ConsumerStatefulWidget {
  const WelcomePage({super.key});

  @override
  ConsumerState<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends ConsumerState<WelcomePage>
    with TickerProviderStateMixin {
  late final AnimationController _timeline;
  late final Animation<double> _bgZoom;      // 1.04 → 1.0
  late final Animation<double> _heroFade;    // 0 → 1
  late final Animation<Offset> _heroSlide;   // (0, .04) → (0, 0)
  late final Animation<double> _panelFade;   // 0 → 1
  late final Animation<Offset> _panelSlide;  // (0, .12) → (0, 0)
  late final Animation<Offset> _ctaSlide1;   // Sign in
  late final Animation<Offset> _ctaSlide2;   // Create account

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
    ));

    // Single, well-tuned timeline
    _timeline = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    // Background zoom: quick settle
    _bgZoom = Tween<double>(begin: 1.04, end: 1.0).animate(
      CurvedAnimation(parent: _timeline, curve: const Interval(0.0, 0.45, curve: Curves.easeOut)),
    );

    // Hero brand chips: fade+slide (slightly staggered vs panel)
    _heroFade = CurvedAnimation(
      parent: _timeline,
      curve: const Interval(0.15, 0.55, curve: Curves.easeOutCubic),
    );
    _heroSlide = Tween<Offset>(begin: const Offset(0, .04), end: Offset.zero).animate(
      CurvedAnimation(parent: _timeline, curve: const Interval(0.15, 0.55, curve: Curves.easeOutCubic)),
    );

    // Bottom panel: fade+rise
    _panelFade = CurvedAnimation(
      parent: _timeline,
      curve: const Interval(0.35, 0.95, curve: Curves.easeOutCubic),
    );
    _panelSlide = Tween<Offset>(begin: const Offset(0, .12), end: Offset.zero).animate(
      CurvedAnimation(parent: _timeline, curve: const Interval(0.35, 0.95, curve: Curves.easeOutCubic)),
    );

    // Stagger CTAs inside panel
    _ctaSlide1 = Tween<Offset>(begin: const Offset(0, .08), end: Offset.zero).animate(
      CurvedAnimation(parent: _timeline, curve: const Interval(0.55, 0.9, curve: Curves.easeOut)),
    );
    _ctaSlide2 = Tween<Offset>(begin: const Offset(0, .10), end: Offset.zero).animate(
      CurvedAnimation(parent: _timeline, curve: const Interval(0.62, 0.98, curve: Curves.easeOut)),
    );

    // Kick it off on first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _timeline.forward());
  }

  @override
  void dispose() {
    _timeline.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final start = scheme.primary;
    final end   = scheme.secondary;

    return Scaffold(
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            // Background image with shader + gentle zoom-in settle
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _bgZoom,
                builder: (context, _) {
                  return Transform.scale(
                    scale: _bgZoom.value,
                    child: ShaderMask(
                      shaderCallback: (rect) => const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black87],
                        stops: [0.25, 1.0],
                      ).createShader(rect),
                      blendMode: BlendMode.darken,
                      child: Image.asset(
                        'assets/images/ucp_bg.jpg',
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                      ),
                    ),
                  );
                },
              ),
            ),

            // Subtle top-to-mid gradient for legibility
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                    colors: [
                      Colors.black.withOpacity(0.35),
                      Colors.black.withOpacity(0.05),
                    ],
                  ),
                ),
              ),
            ),

            // Brand cluster with fade + slide
            _HeroOverlayAnimated(
              fade: _heroFade,
              slide: _heroSlide,
            ),

            // Bottom panel: rise + fade, with CTA staggers
            Align(
              alignment: Alignment.bottomCenter,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final h = MediaQuery.of(context).size.height;
                  final panelH = h * 0.55;

                  return SlideTransition(
                    position: _panelSlide,
                    child: FadeTransition(
                      opacity: _panelFade,
                      child: ClipPath(
                        clipper: _SoftConcaveClipper(curveHeight: 64),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 450),
                          curve: Curves.easeOutCubic,
                          height: panelH,
                          width: double.infinity,
                          color: scheme.surface,
                          child: Center(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 460),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Welcome back',
                                      textAlign: TextAlign.center,
                                      style: text.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.2,
                                        color: scheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Instant answers. Maps. Notices. All things UCP — in one place.',
                                      textAlign: TextAlign.center,
                                      style: text.bodyMedium?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                        height: 1.35,
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // CTA 1 (staggered)
                                    SlideTransition(
                                      position: _ctaSlide1,
                                      child: _GradientButton(
                                        label: 'Sign in',
                                        start: start,
                                        end: end,
                                        onPressed: () {
                                          HapticFeedback.lightImpact();
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => const SignInPage(),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 14),

                                    // CTA 2 (staggered)
                                    SlideTransition(
                                      position: _ctaSlide2,
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton(
                                          onPressed: () {
                                            HapticFeedback.selectionClick();
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
                                            side: BorderSide(color: scheme.outlineVariant),
                                            backgroundColor: scheme.surfaceContainerHighest,
                                          ),
                                          child: Text(
                                            'Create account',
                                            style: text.titleSmall?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: scheme.onSurface,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 18),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.verified_user_rounded,
                                            size: 16, color: scheme.primary),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Secure and Private',
                                          style: text.bodySmall?.copyWith(
                                            color: scheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      'By continuing, you agree to our Terms of Service.',
                                      textAlign: TextAlign.center,
                                      style: text.bodySmall?.copyWith(
                                        color: scheme.onSurfaceVariant,
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated brand overlay (fade + slide) to keep your file tidy
class _HeroOverlayAnimated extends StatelessWidget {
  const _HeroOverlayAnimated({
    required this.fade,
    required this.slide,
  });

  final Animation<double> fade;
  final Animation<Offset> slide;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final top = MediaQuery.of(context).size.height * 0.36;

    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: FadeTransition(
        opacity: fade,
        child: SlideTransition(
          position: slide,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Glass(
                borderRadius: 16,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                child: Text(
                  'AskUCP',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                  semanticsLabel: 'Ask U C P',
                ),
              ),
              const SizedBox(height: 8),
              _Glass(
                borderRadius: 999,
                padding: EdgeInsets.symmetric(
                  horizontal: w < 360 ? 10 : 14,
                  vertical: 6,
                ),
                child: Text(
                  'YOUR CAMPUS ASSISTANT',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white.withOpacity(0.96),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.3,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple reusable frosted glass container.
class _Glass extends StatelessWidget {
  const _Glass({
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.borderRadius = 16,
  });

  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.14),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Softer concave curve using cubic instead of a sharp quadratic.
class _SoftConcaveClipper extends CustomClipper<Path> {
  _SoftConcaveClipper({this.curveHeight = 64});
  final double curveHeight;

  @override
  Path getClip(Size size) {
    final p = Path();
    p.moveTo(0, curveHeight + 24);
    p.cubicTo(
      size.width * 0.25, curveHeight * 0.4,
      size.width * 0.75, curveHeight * 0.4,
      size.width,        curveHeight + 24,
    );
    p.lineTo(size.width, size.height);
    p.lineTo(0, size.height);
    p.close();
    return p;
  }

  @override
  bool shouldReclip(covariant _SoftConcaveClipper oldClipper) =>
      oldClipper.curveHeight != curveHeight;
}

/// Primary gradient pill button with elevation & ink ripple.
class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.onPressed,
    required this.start,
    required this.end,
  });

  final String label;
  final VoidCallback onPressed;
  final Color start;
  final Color end;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [start, end],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: onPressed,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: _ButtonLabel(text: 'Sign in'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Keeps button label crisp without rebuilding text style too often.
class _ButtonLabel extends StatelessWidget {
  const _ButtonLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Text(
      text,
      style: t.titleSmall?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
      ),
    );
  }
}
