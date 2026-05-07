// lib/providers/upload_provider.dart
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../models/upload_task_model.dart';
import '../core/services/upload_service.dart';
import '../core/services/notification_service.dart';
import '../core/services/fcm_service.dart';

class UploadState {
  final List<UploadTaskModel> tasks;
  final bool isBulkMode; // true when > 3 files
  final bool isPickingFiles;

  const UploadState({
    this.tasks = const [],
    this.isBulkMode = false,
    this.isPickingFiles = false,
  });

  UploadState copyWith({
    List<UploadTaskModel>? tasks,
    bool? isBulkMode,
    bool? isPickingFiles,
  }) {
    return UploadState(
      tasks: tasks ?? this.tasks,
      isBulkMode: isBulkMode ?? this.isBulkMode,
      isPickingFiles: isPickingFiles ?? this.isPickingFiles,
    );
  }
}

class UploadNotifier extends StateNotifier<UploadState> {
  UploadNotifier() : super(const UploadState());

  Future<void> pickAndUpload() async {
    state = state.copyWith(isPickingFiles: true);

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
    );

    state = state.copyWith(isPickingFiles: false);
    if (result == null || result.files.isEmpty) return;

    final files = result.files
        .where((f) => f.path != null)
        .map((f) => MapEntry(f.name, File(f.path!)))
        .toList();

    final isBulk = files.length > 3;

    // Create task entries — each gets a stable ID used throughout
    final tasks = files
        .map((e) => UploadTaskModel(
              id: e.key + DateTime.now().millisecondsSinceEpoch.toString(),
              fileName: e.key,
              fileSize: e.value.lengthSync(),
              status: UploadStatus.queued,
            ))
        .toList();

    state = state.copyWith(tasks: tasks, isBulkMode: isBulk);

    if (isBulk) {
      _uploadBulk(files, tasks);
    } else {
      _uploadIndividual(files, tasks);
    }
  }

  // ── ≤3 files: sequential with per-file progress ──────────────────────────
  void _uploadIndividual(
      List<MapEntry<String, File>> files, List<UploadTaskModel> tasks) {
    for (int i = 0; i < files.length; i++) {
      final taskId = tasks[i].id;
      final fileName = files[i].key;
      _updateTask(taskId, status: UploadStatus.uploading);

      UploadService.uploadFile(
        file: files[i].value,
        fileName: fileName,
        onProgress: (p) => _updateTask(taskId, progress: p),
        onComplete: (url) {
          _updateTask(
              taskId,
              status: UploadStatus.complete,
              progress: 1.0,
              downloadUrl: url);
          // Persist to Firestore
          NotificationService.save(
            message: '"$fileName" uploaded successfully.',
            type: 'upload_complete',
          );
          // Local push notification
          FCMService.showNotification(
            title: 'Upload Complete ✅',
            body: '"$fileName" uploaded successfully.',
            isSuccess: true,
          );
        },
        onError: (e) {
          _updateTask(taskId, status: UploadStatus.failed, error: e);
          // Persist to Firestore
          NotificationService.save(
            message: 'Upload failed: "$fileName". $e',
            type: 'upload_failed',
          );
          // Local push notification
          FCMService.showNotification(
            title: 'Upload Failed ❌',
            body: '"$fileName" could not be uploaded.',
            isSuccess: false,
          );
        },
      );
    }
  }

  // ── >3 files: parallel uploads with correct taskId mapping ───────────────
  void _uploadBulk(
      List<MapEntry<String, File>> files, List<UploadTaskModel> tasks) {
    // Mark all as uploading immediately
    for (final task in tasks) {
      _updateTask(task.id, status: UploadStatus.uploading);
    }

    int completedCount = 0;
    int failedCount = 0;
    final total = files.length;

    // FIX: Use individual uploadFile calls with matching taskIds
    // (not uploadMultipleFiles which generates its own internal IDs)
    Future.wait(
      List.generate(files.length, (i) async {
        final taskId = tasks[i].id;
        final fileName = files[i].key;

        await UploadService.uploadFile(
          file: files[i].value,
          fileName: fileName,
          onProgress: (p) => _updateTask(taskId, progress: p),
          onComplete: (url) {
            completedCount++;
            _updateTask(
                taskId,
                status: UploadStatus.complete,
                progress: 1.0,
                downloadUrl: url);
          },
          onError: (e) {
            failedCount++;
            _updateTask(taskId, status: UploadStatus.failed, error: e);
          },
        );
      }),
    ).then((_) {
      // Save a single batch-completion notification to Firestore
      final String message;
      final String type;

      if (failedCount == 0) {
        message =
            '$completedCount file${completedCount > 1 ? 's' : ''} uploaded successfully.';
        type = 'upload_complete';
      } else if (completedCount == 0) {
        message = 'All $total file uploads failed.';
        type = 'upload_failed';
      } else {
        message =
            '$completedCount of $total files uploaded ($failedCount failed).';
        type = 'upload_failed';
      }

      NotificationService.save(message: message, type: type);
      // Local push notification for bulk completion
      FCMService.showNotification(
        title: type == 'upload_complete'
            ? 'Batch Upload Complete ✅'
            : 'Batch Upload Finished ⚠️',
        body: message,
        isSuccess: type == 'upload_complete',
      );
    });
  }

  void _updateTask(
    String taskId, {
    double? progress,
    UploadStatus? status,
    String? downloadUrl,
    String? error,
  }) {
    state = state.copyWith(
      tasks: state.tasks.map((t) {
        if (t.id == taskId) {
          return t.copyWith(
            progress: progress,
            status: status,
            downloadUrl: downloadUrl,
            error: error,
          );
        }
        return t;
      }).toList(),
    );
  }

  void clearTasks() => state = const UploadState();
}

final uploadProvider =
    StateNotifierProvider<UploadNotifier, UploadState>(
  (_) => UploadNotifier(),
);
