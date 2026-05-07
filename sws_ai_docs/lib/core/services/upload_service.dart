// lib/core/services/upload_service.dart
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class UploadService {
  static final _storage = FirebaseStorage.instance;
  static final _firestore = FirebaseFirestore.instance;
  static const _uuid = Uuid();

  /// Upload a single file. Calls [onProgress] with 0.0→1.0.
  /// Returns the Firestore document ID on success.
  static Future<String> uploadFile({
    required File file,
    required String fileName,
    required void Function(double) onProgress,
    required void Function(String) onComplete,
    required void Function(String) onError,
  }) async {
    final docId = _uuid.v4();
    final storagePath = 'documents/$docId/$fileName';
    final ref = _storage.ref(storagePath);

    try {
      final uploadTask = ref.putFile(
        file,
        SettableMetadata(contentType: 'application/pdf'),
      );

      // Listen to per-byte progress
      uploadTask.snapshotEvents.listen((snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      });

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Save document metadata to Firestore
      await _firestore.collection('documents').doc(docId).set({
        'id': docId,
        'name': fileName,
        'size': file.lengthSync(),
        'downloadUrl': downloadUrl,
        'storagePath': storagePath,
        'uploadedAt': FieldValue.serverTimestamp(),
        'status': 'complete',
      });

      onComplete(downloadUrl);
      return docId;
    } catch (e) {
      onError(e.toString());
      // Do NOT rethrow — caller does not await this Future, so
      // rethrowing would produce an unhandled exception in the isolate.
      return ''; // satisfy non-null Future<String> return type
    }
  }

  /// Upload multiple files. Triggers batch completion logic if count > 3.
  static Future<void> uploadMultipleFiles({
    required List<File> files,
    required List<String> fileNames,
    required void Function(String fileId, double progress) onFileProgress,
    required void Function(String fileId) onFileComplete,
    required void Function(String fileId, String error) onFileError,
    required void Function(int successCount) onBatchComplete,
  }) async {
    final batchId = _uuid.v4();
    int completedCount = 0;
    int failedCount = 0;

    // Write batch record to Firestore
    await _firestore.collection('batches').doc(batchId).set({
      'id': batchId,
      'totalFiles': files.length,
      'completedFiles': 0,
      'status': 'uploading',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Upload all files in parallel
    await Future.wait(
      List.generate(files.length, (i) async {
        final fileId = _uuid.v4();
        try {
          await uploadFile(
            file: files[i],
            fileName: fileNames[i],
            onProgress: (p) => onFileProgress(fileId, p),
            onComplete: (_) {
              completedCount++;
              onFileComplete(fileId);
            },
            onError: (e) {
              failedCount++;
              onFileError(fileId, e);
            },
          );
        } catch (_) {}
      }),
    );

    // Update batch status → triggers Cloud Function
    await _firestore.collection('batches').doc(batchId).update({
      'completedFiles': completedCount,
      'failedFiles': failedCount,
      'status': 'complete',
      'completedAt': FieldValue.serverTimestamp(),
    });

    onBatchComplete(completedCount);
  }

  static Future<void> deleteDocument(String docId, String storagePath) async {
    try {
      await _storage.ref(storagePath).delete();
    } catch (_) {}
    await _firestore.collection('documents').doc(docId).delete();
  }
}
