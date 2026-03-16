import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'models/notice.dart';
import 'services/notices_service.dart';

class NoticesPage extends StatefulWidget {
  const NoticesPage({super.key});
  @override
  State<NoticesPage> createState() => _NoticesPageState();
}

class _NoticesPageState extends State<NoticesPage> {
  static const _pageSize = 20;
  final _controller = ScrollController();

  // We’ll keep a live first page via Stream, and append more via pagination fetches.
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _tailDocs = [];
  bool _loadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_maybeLoadMore);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _maybeLoadMore() async {
    if (!_hasMore || _loadingMore) return;
    if (_controller.position.pixels >= _controller.position.maxScrollExtent - 400) {
      setState(() => _loadingMore = true);
      final last = _tailDocs.isEmpty ? null : _tailDocs.last;
      final newDocs = await NoticesService.instance.fetchPage(
        limit: _pageSize,
        startAfter: last,
      );
      setState(() {
        _tailDocs.addAll(newDocs);
        _hasMore = newDocs.length == _pageSize;
        _loadingMore = false;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _tailDocs.clear();
      _hasMore = true;
      _loadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('EEE, d MMM • h:mm a'); // e.g., Mon, 16 Sep • 3:40 PM

    return Scaffold(
      appBar: AppBar(title: const Text('Notices')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: StreamBuilder<List<Notice>>(
          stream: NoticesService.instance.streamFirst(limit: _pageSize),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const _SkeletonList();
            }
            if (snap.hasError) {
              return _ErrorView(
                message: 'Couldn’t load notices.',
                onRetry: _refresh,
              );
            }
            final firstPage = snap.data ?? [];
            final combined = [
              ...firstPage,
              ..._tailDocs.map((d) => Notice.fromDoc(d)),
            ];

            if (combined.isEmpty) {
              return const _EmptyView();
            }

            return ListView.separated(
              controller: _controller,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: combined.length + (_loadingMore ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                if (_loadingMore && i == combined.length) {
                  return const _LoadingTile();
                }
                final n = combined[i];
                return _NoticeCard(
                  title: n.title,
                  body: n.body,
                  date: dateFmt.format(n.createdAt),
                  pinned: n.pinned,
                  category: n.category,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  final String title;
  final String body;
  final String date;
  final bool pinned;
  final String? category;

  const _NoticeCard({
    required this.title,
    required this.body,
    required this.date,
    required this.pinned,
    this.category,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (pinned)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('Pinned', style: TextStyle(color: scheme.onPrimaryContainer, fontSize: 12)),
                ),
              if (category != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(category!, style: TextStyle(color: scheme.onSecondaryContainer, fontSize: 12)),
                ),
              const Spacer(),
              Text(date, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(body, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('No notices yet.', style: Theme.of(context).textTheme.bodyLarge),
        ),
      );
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: 8),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
}

class _SkeletonList extends StatelessWidget {
  const _SkeletonList();
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        height: 96,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class _LoadingTile extends StatelessWidget {
  const _LoadingTile();
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      );
}
