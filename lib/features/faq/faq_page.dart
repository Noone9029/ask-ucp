import 'dart:async';
import 'package:flutter/material.dart';

class FaqPage extends StatefulWidget {
  const FaqPage({super.key});
  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> with TickerProviderStateMixin {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  final Map<int, GlobalKey> _sectionKeys = {}; // index -> key (for jump)
  final Set<String> _open = {}; // persistent open state by question key

  String _q = '';
  Timer? _debounce;
  bool _allExpanded = false;

  /// --- Sectioned data (edit freely) ---------------------------------------
  final List<Map<String, dynamic>> _sections = [
    {
      'title': 'Admission & Enrollment',
      'items': [
        {
          'q': 'I am unable to view my test/interview letter on my admission portal.',
          'a': 'You can view your test/interview letter on your admission portal after your admission application processing fee (Rs 1500/-) is paid and verified.'
        },
        {
          'q': 'My degree(s) are not getting attached in the academic section.',
          'a': 'Ensure your degree certificates are uploaded in the correct format. If the issue persists, contact the admissions office for assistance.'
        },
        {
          'q': 'My O/A levels result is divided into multiple pages, and the portal only allows me to attach a single sheet; how can I attach my results?',
          'a': 'Attach the result sheet that covers the majority of your major grades. Also submit the IBCC equivalence certificate.'
        },
        {
          'q': 'My admission application processing fee is not getting verified.',
          'a': 'If you paid at Albaraka Bank, verification may take 2–3 working days. You can also email the paid challan to admissions@ucp.edu.pk.'
        },
        {
          'q': 'E-mail of signup credentials is not received ?',
          'a': 'Check Spam/Junk. If still missing, try another email provider (e.g. Gmail) or contact admissions support.'
        },
        {
          'q': 'Do I have to print and submit the admission form manually?',
          'a': 'No—UCP does not require a manually printed admission form.'
        },
      ],
    },
    {
      'title': 'Academic Information',
      'items': [
        {
          'q': 'Where can I see my timetable?',
          'a': 'Your timetable appears on the Student Portal once sections are scheduled.'
        },
        {
          'q': 'What is the grading system used at UCP?',
          'a': 'Standard letter grades; GPA computed on a 4.0 scale as per university policy.'
        },
        {
          'q': 'How can I apply for course withdrawal?',
          'a': 'Submit a withdrawal request from the SSC within the official window.'
        },
      ],
    },
    {
      'title': 'Financial Services',
      'items': [
        {
          'q': 'What are the payment methods for fee submission?',
          'a': 'Bank challan, online banking partners (pay.ucp.edu.pk) , or bank counter at the admission office.'
        },
        {
          'q': 'Does UCP charge fee annually or per semester?',
          'a': 'Per semester split into two installments.'
        },
        {
          'q': 'Is there a late fee penalty?',
          'a': 'Yes—Rs. 1000 per week applies after the due date per policy.'
        },
        {
          'q': 'My tuition fee challan is not uploaded on the portal.',
          'a': 'Visit the Student Service Centre (SSC) for document verification; SSC will then provide your fee challan.'
        },
      ],
    },
    {
      'title': 'Student Services',
      'items': [
        {
          'q': 'How do I get my student ID card?',
          'a': 'After enrollment & fee verification, visit SSC with a photo to collect your card.'
        },
        {
          'q': 'What library services are available?',
          'a': 'Book lending, digital databases, study cabins, and research help via your student credentials.'
        },
      ],
    },
  ];
  /// ------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _search.addListener(() {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 220), () {
        setState(() => _q = _search.text.trim().toLowerCase());
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filtered {
    if (_q.isEmpty) return _sections;
    return _sections
        .map((s) {
          final items = (s['items'] as List)
              .where((m) =>
                  (m['q'] as String).toLowerCase().contains(_q) ||
                  (m['a'] as String).toLowerCase().contains(_q))
              .toList();
          return {'title': s['title'], 'items': items};
        })
        .where((s) => (s['items'] as List).isNotEmpty)
        .toList();
  }

  void _toggleAll(bool expand) {
    setState(() {
      _allExpanded = expand;
      _open.clear();
      if (expand) {
        for (final s in _filtered) {
          for (final m in (s['items'] as List)) {
            _open.add(_qid(s['title'] as String, m['q'] as String));
          }
        }
      }
    });
  }

  void _jumpToSection(int index) {
    final key = _sectionKeys[index];
    if (key == null) return;
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      alignment: 0.1,
    );
  }

  String _qid(String section, String q) => '${section.trim()}::${q.trim()}';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final filtered = _filtered;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: CustomScrollView(
          controller: _scroll,
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Sticky app bar + search + section chips
            SliverAppBar(
              pinned: true,
              elevation: 0,
              backgroundColor: cs.surface,
              title: Text('Frequently Asked Questions',
                  style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              actions: [
                IconButton(
                  tooltip: _allExpanded ? 'Collapse all' : 'Expand all',
                  icon: Icon(_allExpanded ? Icons.unfold_less : Icons.unfold_more),
                  onPressed: () => _toggleAll(!_allExpanded),
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(92),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                      child: TextField(
                        controller: _search,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Search questions or answers',
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
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        ),
                      ),
                    ),
                    // Section chips (based on current filter)
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        scrollDirection: Axis.horizontal,
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final t = filtered[i]['title'] as String;
                          return ActionChip(
                            label: Text(t, style: tt.labelMedium),
                            onPressed: () => _jumpToSection(i),
                            backgroundColor: cs.surfaceContainerHighest,
                            side: BorderSide(color: cs.outlineVariant),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(query: _q),
              )
            else
              SliverList.builder(
                itemCount: filtered.length + 1, // +1 for help panel at end
                itemBuilder: (context, i) {
                  if (i == filtered.length) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                      child: const _HelpPanel(),
                    );
                  }
                  _sectionKeys[i] = _sectionKeys[i] ?? GlobalKey();
                  final section = filtered[i];
                  final items = (section['items'] as List).cast<Map<String, String>>();
                  return Container(
                    key: _sectionKeys[i],
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: _Section(
                      title: section['title'] as String,
                      items: items,
                      query: _q,
                      open: _open,
                      onToggle: (qid, isOpen) {
                        setState(() {
                          if (isOpen) {
                            _open.add(qid);
                          } else {
                            _open.remove(qid);
                          }
                          // Sync the global expand/collapse icon state heuristically
                          _allExpanded = _open.length ==
                              filtered.fold<int>(
                                0, (acc, s) => acc + (s['items'] as List).length);
                        });
                      },
                      vsync: this,
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

/* ---------------------- SECTIONS & TILES ---------------------- */

class _Section extends StatelessWidget {
  final String title;
  final List<Map<String, String>> items;
  final String query;
  final Set<String> open;
  final void Function(String qid, bool isOpen) onToggle;
  final TickerProvider vsync;

  const _Section({
    required this.title,
    required this.items,
    required this.query,
    required this.open,
    required this.onToggle,
    required this.vsync,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: tt.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.secondary,
                )),
            const SizedBox(height: 10),
            for (final m in items)
              _FaqTile(
                sectionTitle: title,
                q: m['q']!,
                a: m['a']!,
                query: query,
                initiallyOpen: open.contains('${title.trim()}::${m['q']!.trim()}'),
                onToggle: onToggle,
                vsync: vsync,
              ),
          ],
        ),
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  final String sectionTitle;
  final String q;
  final String a;
  final String query;
  final bool initiallyOpen;
  final void Function(String qid, bool isOpen) onToggle;
  final TickerProvider vsync;

  const _FaqTile({
    required this.sectionTitle,
    required this.q,
    required this.a,
    required this.query,
    required this.initiallyOpen,
    required this.onToggle,
    required this.vsync,
  });

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  late bool open;
  late final AnimationController _c;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  String get _qid => '${widget.sectionTitle.trim()}::${widget.q.trim()}';

  @override
  void initState() {
    super.initState();
    open = widget.initiallyOpen;
    _c = AnimationController(
      vsync: widget.vsync,
      duration: const Duration(milliseconds: 250),
    );
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, .04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
    if (open) _c.value = 1;
  }

  @override
  void didUpdateWidget(covariant _FaqTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initiallyOpen != open) {
      open = widget.initiallyOpen;
      if (open) {
        _c.forward();
      } else {
        _c.reverse();
      }
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _toggle(bool v) {
    setState(() => open = v);
    if (v) {
      _c.forward();
    } else {
      _c.reverse();
    }
    widget.onToggle(_qid, v);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            splashColor: cs.primary.withOpacity(0.06),
            highlightColor: cs.primary.withOpacity(0.03),
          ),
          child: ExpansionTile(
            initiallyExpanded: open,
            onExpansionChanged: _toggle,
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            trailing: AnimatedRotation(
              duration: const Duration(milliseconds: 180),
              turns: open ? 0.5 : 0,
              child: Icon(Icons.expand_more, color: cs.onSurfaceVariant),
            ),
            title: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(.14),
                    shape: BoxShape.circle,
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: Icon(Icons.question_mark, size: 16, color: cs.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Highlight(
                    text: widget.q,
                    query: widget.query,
                    style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            children: [
              SlideTransition(
                position: _slide,
                child: FadeTransition(
                  opacity: _fade,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb_outline, size: 18, color: cs.secondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _Highlight(
                          text: widget.a,
                          query: widget.query,
                          style: tt.bodyMedium?.copyWith(height: 1.4),
                        ),
                      ),
                    ],
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

/// Highlights [query] inside [text] using secondary color.
class _Highlight extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle? style;
  const _Highlight({required this.text, required this.query, this.style});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (query.isEmpty) return Text(text, style: style);

    final lower = text.toLowerCase();
    final q = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final idx = lower.indexOf(q, start);
      if (idx < 0) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (idx > start) spans.add(TextSpan(text: text.substring(start, idx)));
      spans.add(TextSpan(
        text: text.substring(idx, idx + q.length),
        style: (style ?? const TextStyle()).copyWith(
          color: cs.secondary,
          fontWeight: FontWeight.w700,
        ),
      ));
      start = idx + q.length;
    }

    return RichText(text: TextSpan(style: style, children: spans));
  }
}

/* ---------------------- HELP / EMPTY ---------------------- */

class _HelpPanel extends StatelessWidget {
  const _HelpPanel();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Icon(Icons.chat_bubble_outline, color: cs.primary),
            ),
            const SizedBox(height: 10),
            Text('Still need help?',
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              'Can’t find the answer you’re looking for? Contact our support team.',
              textAlign: TextAlign.center,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            _HelpRow(icon: Icons.email_outlined, label: 'Email', value: 'info@ucp.edu.pk'),
            const SizedBox(height: 6),
            _HelpRow(icon: Icons.phone_outlined, label: 'Phone', value: '+92-42-111-000-827'),
            const SizedBox(height: 6),
            _HelpRow(icon: Icons.access_time, label: 'Office Hours', value: 'Mon–Fri, 9:00 AM – 5:00 PM'),
          ],
        ),
      ),
    );
  }
}

class _HelpRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _HelpRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: cs.primary),
        const SizedBox(width: 8),
        Text('$label: ', style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        Expanded(child: Text(value, style: tt.bodyMedium)),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.query});
  final String query;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: cs.onSurfaceVariant),
            const SizedBox(height: 12),
            Text('No matches', style: tt.titleMedium),
            const SizedBox(height: 4),
            Text(
              'No results for “$query”. Try a different word or check spelling.',
              textAlign: TextAlign.center,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
