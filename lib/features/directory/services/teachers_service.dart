import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/teacher.dart';

class TeachersService {
  TeachersService._();
  static final instance = TeachersService._();

  final _col = FirebaseFirestore.instance.collection('teachers');

  Query<Map<String, dynamic>> _baseQuery() =>
      _col.orderBy('rating', descending: true);

  // Live stream, enough for your current dataset size
  Stream<List<Teacher>> streamAll({int limit = 300}) {
    return _baseQuery().limit(limit).snapshots().map(
      (snap) => snap.docs.map((d) => Teacher.fromDoc(d)).toList(),
    );
  }
}
