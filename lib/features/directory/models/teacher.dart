import 'package:cloud_firestore/cloud_firestore.dart';

class Teacher {
  final String id;
  final String name;
  final String? designation;
  final double? rating;
  final String? imageUrl;

  Teacher({
    required this.id,
    required this.name,
    this.designation,
    this.rating,
    this.imageUrl,
  });

  factory Teacher.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    final r = d['rating'];
    return Teacher(
      id: doc.id,
      name: (d['name'] ?? '').toString(),
      designation: d['designation'] as String?,
      rating: r is num ? r.toDouble() : null,
      imageUrl: d['imageUrl'] as String?,
    );
  }
}
