// lib/models/document_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class DocumentModel {
  final String id;
  final String name;
  final int size;
  final String downloadUrl;
  final String storagePath;
  final DateTime uploadedAt;
  final String status;

  const DocumentModel({
    required this.id,
    required this.name,
    required this.size,
    required this.downloadUrl,
    required this.storagePath,
    required this.uploadedAt,
    required this.status,
  });

  factory DocumentModel.fromMap(Map<String, dynamic> map, String id) {
    return DocumentModel(
      id: id,
      name: map['name'] as String? ?? 'Unknown',
      size: (map['size'] as num?)?.toInt() ?? 0,
      downloadUrl: map['downloadUrl'] as String? ?? '',
      storagePath: map['storagePath'] as String? ?? '',
      uploadedAt: map['uploadedAt'] != null
          ? (map['uploadedAt'] as Timestamp).toDate()
          : DateTime.now(),
      status: map['status'] as String? ?? 'complete',
    );
  }
}
