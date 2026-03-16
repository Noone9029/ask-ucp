import 'package:cloud_firestore/cloud_firestore.dart';

class Notice {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool pinned;
  final String? category;

  Notice({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.pinned = false,
    this.category,
  });

  factory Notice.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    final ts = d['createdAt'];
    return Notice(
      id: doc.id,
      title: (d['title'] ?? '').toString(),
      body: (d['body'] ?? '').toString(),
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.fromMillisecondsSinceEpoch(0),
      pinned: (d['pinned'] ?? false) as bool,
      category: d['category'] as String?,
    );
  }
}
