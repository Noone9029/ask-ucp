import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// shared style utilities
import '../common/style_utils.dart';
import '../app/theme.dart';

// Feature pages
import '../features/map/map_page.dart';
import '../features/uploads/uploads_page.dart';
import '../features/faq/faq_page.dart';
import '../features/chat/chat_page.dart';
import '../features/directory/teacher_directory_page.dart';
import '../features/feedback/feedback_page.dart';
import '../features/notices/notices_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final _search = TextEditingController();
  late final AnimationController _gridCtrl;
  String _q = '';

  @override
  void initState() {
    super.initState();
    _gridCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
    _search.addListener(() => setState(() => _q = _search.text.trim()));
  }

  @override
  void dispose() {
    _search.dispose();
    _gridCtrl.dispose();
    super.dispose();
  }

  void _go(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  String _greet() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _first(String? name) {
    if (name == null || name.trim().isEmpty) return '';
    final f = name.trim().split(RegExp(r'\s+')).first;
    return f[0].toUpperCase() + (f.length > 1 ? f.substring(1).toLowerCase() : '');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final user = FirebaseAuth.instance.currentUser;
    final fname = _first(user?.displayName);
    final greet = fname.isEmpty ? _greet() : '${_greet()}, $fname';

    // features
    final all = <_Feature>[
      _Feature(Icons.badge_outlined, 'ID/Challan Upload', 'Submit ID photo or challan',
          const UploadsPage(), const Color(0xFF86E7FF)),
      _Feature(Icons.help_center_outlined, 'FAQ', 'Common questions & answers',
          const FaqPage(), const Color(0xFFFFE28A)),
      _Feature(Icons.chat_bubble_outline, 'Chatbot', 'Ask anything about UCP',
          const ChatPage(), const Color(0xFF9BF6A1)),
      _Feature(Icons.people_outline, 'Teacher Directory', 'Faculty contacts & ratings',
          const TeachersPage(), const Color(0xFFFFB3C7)),
      _Feature(Icons.rate_review_outlined, 'Feedback', 'Share your thoughts',
          const FeedbackPage(), const Color(0xFFA4B8FF)),
      _Feature(Icons.notifications_none, 'Notices', 'Latest announcements',
          const NoticesPage(), const Color(0xFFFFD1A1)),
    ];

    // filter
    final q = _q.toLowerCase();
    final items = q.isEmpty
        ? all
        : all.where((f) =>
            f.title.toLowerCase().contains(q) || f.subtitle.toLowerCase().contains(q)).toList();

    // responsive columns
    final w = MediaQuery.of(context).size.width;
    final columns = w >= 1100 ? 4 : w >= 820 ? 3 : 2;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: scheme.background,

      // frosted app bar over hero
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              backgroundColor: Colors.white.withOpacity(0.08),
              foregroundColor: Colors.white,
              elevation: 0,
              titleSpacing: 12,
              title: Row(
                children: [
                  Image.asset('assets/images/school.png', height: 22),
                  const SizedBox(width: 10),
                  const Text('AskUCP',
                      style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: 'Help',
                  onPressed: () => _go(const FaqPage()),
                  icon: const Icon(Icons.help_outline, color: Colors.white),
                ),
                IconButton(
                  tooltip: 'Sign out',
                  onPressed: () async => FirebaseAuth.instance.signOut(),
                  icon: const Icon(Icons.logout, color: Colors.white),
                ),
                const SizedBox(width: 6),
              ],
            ),
          ),
        ),
      ),

      // no global background image here — only the hero shows the photo
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // HERO with image + readable gradient
          SliverAppBar(
            automaticallyImplyLeading: false,
            expandedHeight: 210,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: LayoutBuilder(
              builder: (context, c) {
                final t = ((c.biggest.height - kToolbarHeight) / (210 - kToolbarHeight))
                    .clamp(0.0, 1.0);
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/images/ucp_bg.jpg',
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color.fromARGB(130, 0, 0, 0),
                            Color.fromARGB(60, 0, 0, 0),
                            Colors.transparent,
                          ],
                          stops: [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, 92 * t + 10, 16, 14),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Opacity(
                            opacity: max(.4, t),
                            child: Text(
                              greet,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: tt.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _SearchWithAsk(
                            controller: _search,
                            onAsk: () => _go(const ChatPage()),
                            onSubmit: (qq) {
                              final s = qq.toLowerCase();
                              if (s.contains('map')) _go(const MapPage());
                              else if (s.contains('teacher')) _go(const TeachersPage());
                              else if (s.contains('faq')) _go(const FaqPage());
                              else if (s.contains('notice')) _go(const NoticesPage());
                            },
                          ),
                          const SizedBox(height: 12),
                          _QuickStrip(
                            chips: [
                              _QuickChip(icon: Icons.map_outlined, label: 'Map', onTap: () => _go(const MapPage())),
                              _QuickChip(icon: Icons.chat_bubble_outline, label: 'Chat', onTap: () => _go(const ChatPage())),
                              _QuickChip(icon: Icons.help_center_outlined, label: 'FAQ', onTap: () => _go(const FaqPage())),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // SOLID CONTENT PANEL
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -100), // pulls panel up
                child: Container(
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                  child: items.isEmpty
                      ? _EmptyState(query: _q)
                      : GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: columns,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1.05,
                          children: [
                            for (int i = 0; i < items.length; i++)
                              _SimpleTile(
                                feature: items[i],
                                query: _q,
                                animation: CurvedAnimation(
                                  parent: _gridCtrl,
                                  curve: Interval(
                                    0.05 + (min(i, 6) / 10),
                                    0.95,
                                    curve: Curves.easeOutCubic,
                                  ),
                                ),
                                onTap: () => _go(items[i].page),
                              ),
                          ],
                        ),
                  ),
              ),
            ),
        ],
      ),
    );
  }
}

/* ================== data model ================== */
class _Feature {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget page;
  final Color color;
  _Feature(this.icon, this.title, this.subtitle, this.page, this.color);
}

/* ================== widgets ================== */

/// Search field + gradient Ask button
class _SearchWithAsk extends StatelessWidget {
  const _SearchWithAsk({
    required this.controller,
    required this.onAsk,
    required this.onSubmit,
  });
  final TextEditingController controller;
  final VoidCallback onAsk;
  final void Function(String) onSubmit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search features (e.g., “map”, “teacher”)',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white.withOpacity(.9),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: cs.outlineVariant),
              ),
            ),
            onSubmitted: onSubmit,
          ),
        ),
        const SizedBox(width: 10),
        _GradientButton(icon: Icons.smart_toy_outlined, label: 'Ask', onTap: onAsk),
      ],
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: askUcpGradient(),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            const Text('Ask', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

/// Quick actions as rounded solid chips (not glass)
class _QuickChip {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  _QuickChip({required this.icon, required this.label, required this.onTap});
}

class _QuickStrip extends StatelessWidget {
  const _QuickStrip({required this.chips});
  final List<_QuickChip> chips;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (int i = 0; i < chips.length; i++) ...[
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: chips[i].onTap,
              child: Container(
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: cs.surface,
                  border: Border.all(color: cs.outlineVariant),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(chips[i].icon, size: 18, color: cs.primary),
                    const SizedBox(width: 6),
                    Text(chips[i].label, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ),
          if (i != chips.length - 1) const SizedBox(width: 8),
        ]
      ],
    );
  }
}

/// Simple, high-contrast tile shown on solid panel
class _SimpleTile extends StatelessWidget {
  const _SimpleTile({
    required this.feature,
    required this.query,
    required this.animation,
    required this.onTap,
  });

  final _Feature feature;
  final String query;
  final Animation<double> animation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return AnimatedBuilder(
      animation: animation,
      builder: (_, child) => Opacity(
        opacity: animation.value,
        child: Transform.translate(
          offset: Offset(0, 22 * (1 - animation.value)),
          child: child,
        ),
      ),
      child: Material(
        color: cs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: cs.outlineVariant),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _IconPlate(icon: feature.icon, hue: feature.color),
                const SizedBox(height: 10),
                _Highlight(
                  text: feature.title,
                  query: query,
                  maxLines: 1,
                  style: tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.1,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                _Highlight(
                  text: feature.subtitle,
                  query: query,
                  maxLines: 2,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.25,
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Open',
                        style: tt.labelMedium?.copyWith(
                            color: cs.primary, fontWeight: FontWeight.w700)),
                    Icon(Icons.arrow_forward_rounded, size: 18, color: cs.primary),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconPlate extends StatelessWidget {
  const _IconPlate({required this.icon, required this.hue});
  final IconData icon;
  final Color hue;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [hue.withOpacity(.95), hue.withOpacity(.65)],
        ),
        border: Border.all(color: hue.withOpacity(.9), width: 1),
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }
}

class _Highlight extends StatelessWidget {
  const _Highlight({
    required this.text,
    required this.query,
    required this.style,
    required this.maxLines,
  });
  final String text;
  final String query;
  final TextStyle? style;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(text, maxLines: maxLines, overflow: TextOverflow.ellipsis, style: style);
    }
    final lower = text.toLowerCase();
    final q = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;
    while (true) {
      final idx = lower.indexOf(q, start);
      if (idx < 0) { spans.add(TextSpan(text: text.substring(start))); break; }
      if (idx > start) spans.add(TextSpan(text: text.substring(start, idx)));
      spans.add(TextSpan(
        text: text.substring(idx, idx + q.length),
        style: (style ?? const TextStyle()).copyWith(fontWeight: FontWeight.w900),
      ));
      start = idx + q.length;
    }
    return Text.rich(TextSpan(children: spans, style: style),
        maxLines: maxLines, overflow: TextOverflow.ellipsis);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.query});
  final String query;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome, size: 56, color: AppColors.secondary),
            const SizedBox(height: 10),
            Text('Nothing yet…',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text('No results for “$query”. Try different words or tap Ask for help.',
              textAlign: TextAlign.center),
            const SizedBox(height: 12),
            _GradientButton(icon: Icons.smart_toy_outlined, label: 'Ask', onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChatPage()));
            }),
          ],
        ),
      ),
    );
  }
}
