import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'models/teacher.dart';
import 'services/teachers_service.dart';

class TeachersPage extends StatefulWidget {
  const TeachersPage({super.key});

  @override
  State<TeachersPage> createState() => _TeachersPageState();
}

enum _SortBy { nameAsc, ratingDesc }

class _TeachersPageState extends State<TeachersPage> with TickerProviderStateMixin {
  final TextEditingController _search = TextEditingController();
  String _q = '';
  _SortBy _sort = _SortBy.ratingDesc;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 220), () {
      setState(() => _q = v.trim().toLowerCase());
    });
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.take(2).map((p) => p.isNotEmpty ? p[0] : '').join().toUpperCase();
  }

  Color _avatarColor(String seed, BuildContext context) {
    // Stable pastel-ish color based on hash
    final hash = seed.codeUnits.fold<int>(0, (a, b) => (a * 31 + b) & 0x7fffffff);
    final hue = (hash % 360).toDouble();
    final sat = 0.55;
    final val = Theme.of(context).brightness == Brightness.dark ? 0.55 : 0.75;
    return HSVColor.fromAHSV(1, hue, sat, val).toColor();
  }

  List<Teacher> _applySort(List<Teacher> items) {
    final list = [...items];
    switch (_sort) {
      case _SortBy.nameAsc:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case _SortBy.ratingDesc:
        list.sort((a, b) => (b.rating ?? -1).compareTo(a.rating ?? -1));
        break;
    }
    return list;
  }

  /// Turns:
  ///   "Dr. Muhammad Sarwar Ehsan" -> "dr-muhammad-sarwar-ehsan"
  ///   "Dr Mohsin Ashraf"          -> "dr-mohsin-ashraf"
  ///   "Dr. Abbas Khalid"          -> "dr-abbas-khalid"
  String _slugifyName(String input) {
    var s = input.trim().toLowerCase();

    // Normalize common "Dr" variants to "dr"
    s = s.replaceAll(RegExp(r'\bdr\.\b'), 'dr');
    s = s.replaceAll(RegExp(r'\bdr\b'), 'dr');

    // Remove anything not letter/number/space/hyphen
    // (this drops dots, commas, parentheses, etc.)
    s = s.replaceAll(RegExp(r'[^a-z0-9\s-]'), '');

    // Collapse spaces/hyphens -> single hyphen
    s = s.replaceAll(RegExp(r'[\s-]+'), '-');

    // Trim hyphens
    s = s.replaceAll(RegExp(r'^-+|-+$'), '');

    return s;
  }

  String _memberUrlForTeacher(Teacher t) {
    final slug = _slugifyName(t.name);
    return 'https://ucp.edu.pk/member/$slug/';
  }

  String _searchUrlForTeacher(Teacher t) {
    final q = Uri.encodeComponent(t.name);
    return 'https://ucp.edu.pk/?s=$q';
  }

  void _openTeacher(BuildContext context, Teacher t) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TeacherProfileWebView(
          title: t.name,
          primaryUrl: _memberUrlForTeacher(t),
          fallbackUrl: _searchUrlForTeacher(t),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teachers & Ratings'),
        actions: [
          PopupMenuButton<_SortBy>(
            initialValue: _sort,
            tooltip: 'Sort',
            onSelected: (v) => setState(() => _sort = v),
            itemBuilder: (ctx) => const [
              PopupMenuItem(
                value: _SortBy.ratingDesc,
                child: Row(
                  children: [
                    Icon(Icons.star_rounded),
                    SizedBox(width: 8),
                    Text('Rating (high → low)'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: _SortBy.nameAsc,
                child: Row(
                  children: [
                    Icon(Icons.sort_by_alpha_rounded),
                    SizedBox(width: 8),
                    Text('Name (A → Z)'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search by name or designation',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _q.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _search.clear();
                          setState(() => _q = '');
                        },
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<List<Teacher>>(
              stream: TeachersService.instance.streamAll(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return _CenteredMessage(
                    icon: Icons.error_outline_rounded,
                    title: 'Something went wrong',
                    subtitle: '${snap.error}',
                  );
                }
                if (!snap.hasData) {
                  return const _LoadingList();
                }

                final all = snap.data!;
                final q = _q;

                final filtered = q.isEmpty
                    ? all
                    : all.where((t) {
                        final hay = '${t.name} ${(t.designation ?? '')}'.toLowerCase();
                        return hay.contains(q);
                      }).toList();

                final items = _applySort(filtered);

                final total = all.length;
                final shown = items.length;
                final label = q.isEmpty ? 'Total: $total' : 'Results: $shown / $total';

                if (items.isEmpty) {
                  return Column(
                    children: [
                      _CounterChip(label: label),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _CenteredMessage(
                          icon: Icons.search_off_rounded,
                          title: q.isEmpty ? 'No teachers found' : 'No matches',
                          subtitle: q.isEmpty ? 'Directory looks empty.' : 'Try a different name or title.',
                        ),
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    _CounterChip(label: label),
                    const SizedBox(height: 6),
                    Expanded(
                      child: ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: scheme.outlineVariant),
                        itemBuilder: (_, i) {
                          final t = items[i];

                          // Your animation (kept as-is)
                          final anim = Tween<double>(begin: 0, end: 1).animate(
                            CurvedAnimation(
                              parent: AnimationController(
                                vsync: this,
                                duration: Duration(milliseconds: 300 + min(i, 8) * 20),
                              )..forward(),
                              curve: Curves.easeOutCubic,
                            ),
                          );

                          return AnimatedBuilder(
                            animation: anim,
                            builder: (ctx, child) => Opacity(
                              opacity: anim.value,
                              child: Transform.translate(
                                offset: Offset(0, 12 * (1 - anim.value)),
                                child: child,
                              ),
                            ),
                            child: _TeacherTile(
                              teacher: t,
                              initials: _initials(t.name),
                              color: _avatarColor(t.name, context),
                              onTap: () => _openTeacher(context, t),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/* ————— Widgets ————— */

class _TeacherTile extends StatelessWidget {
  const _TeacherTile({
    required this.teacher,
    required this.initials,
    required this.color,
    required this.onTap,
  });

  final Teacher teacher;
  final String initials;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasRating = teacher.rating != null;
    final rating = (teacher.rating ?? 0).clamp(0, 5).toDouble();

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color,
              foregroundColor: Colors.white,
              child: Text(
                initials,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    teacher.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    teacher.designation ?? '—',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _RatingPill(rating: hasRating ? rating : null),
          ],
        ),
      ),
    );
  }
}

class _RatingPill extends StatelessWidget {
  const _RatingPill({this.rating});
  final double? rating;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (rating == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_border_rounded, size: 18),
            const SizedBox(width: 4),
            Text('—', style: TextStyle(color: scheme.onSurface)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 18),
          const SizedBox(width: 4),
          Text(
            rating!.toStringAsFixed(1),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: scheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class _CounterChip extends StatelessWidget {
  const _CounterChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 44, color: scheme.onSurfaceVariant),
            const SizedBox(height: 10),
            Text(title, style: text.titleMedium),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    final hi = Theme.of(context).colorScheme.onSurface.withOpacity(0.06);
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 8,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, i) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: base,
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    _shimmerBar(context, height: 12, widthFactor: 0.65, color: hi),
                    const SizedBox(height: 8),
                    _shimmerBar(context, height: 10, widthFactor: 0.45, color: hi),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 64,
                height: 28,
                decoration: BoxDecoration(
                  color: base,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _shimmerBar(BuildContext context,
      {required double height, required double widthFactor, required Color color}) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}

/* ————— WebView Screen ————— */

class TeacherProfileWebView extends StatefulWidget {
  const TeacherProfileWebView({
    super.key,
    required this.title,
    required this.primaryUrl,
    required this.fallbackUrl,
  });

  final String title;
  final String primaryUrl;
  final String fallbackUrl;

  @override
  State<TeacherProfileWebView> createState() => _TeacherProfileWebViewState();
}

class _TeacherProfileWebViewState extends State<TeacherProfileWebView> {
  late final WebViewController _controller;

  int _progress = 0;
  bool _triedFallback = false;
  String? _fatalError;

  static const _allowedHosts = <String>{
    'ucp.edu.pk',
    'www.ucp.edu.pk',
  };

  @override
  void initState() {
    super.initState();

    final primary = Uri.tryParse(widget.primaryUrl);
    if (primary == null || !(primary.isScheme('https') || primary.isScheme('http'))) {
      _fatalError = 'Invalid URL';
      return;
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) => setState(() => _progress = p),
          onWebResourceError: (err) async {
            // If the member page doesn't exist / fails, auto-fallback to search once
            if (!_triedFallback) {
              _triedFallback = true;
              final fb = Uri.tryParse(widget.fallbackUrl);
              if (fb != null) {
                await _controller.loadRequest(fb);
                return;
              }
            }
            setState(() => _fatalError = err.description);
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null) return NavigationDecision.prevent;

            // Keep users inside UCP domain (prevents random external redirects)
            if (_allowedHosts.contains(uri.host)) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(primary);
  }

  @override
  Widget build(BuildContext context) {
    if (_fatalError != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
        body: _CenteredMessage(
          icon: Icons.wifi_off_rounded,
          title: 'Couldn’t open profile',
          subtitle: _fatalError,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Reload',
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: _progress < 100
              ? LinearProgressIndicator(value: _progress / 100)
              : const SizedBox(height: 3),
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
