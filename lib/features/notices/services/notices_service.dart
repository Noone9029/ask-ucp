import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notice.dart';

class NoticesService {
  NoticesService._();
  static final instance = NoticesService._();
  final _col = FirebaseFirestore.instance.collection('notices');

  Query<Map<String, dynamic>> _baseQuery() =>
      _col.orderBy('pinned', descending: true).orderBy('createdAt', descending: true);

  // Live stream (first page)
  Stream<List<Notice>> streamFirst({int limit = 20}) {
    return _baseQuery().limit(limit).snapshots().map(
      (snap) => snap.docs.map((d) => Notice.fromDoc(d)).toList(),
    );
  }

  // Page fetch for infinite scrolling
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> fetchPage({
    int limit = 20,
    QueryDocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    var q = _baseQuery().limit(limit);
    if (startAfter != null) q = q.startAfterDocument(startAfter);
    final snap = await q.get();
    return snap.docs;
  }
}
