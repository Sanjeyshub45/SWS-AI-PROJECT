// lib/providers/upload_provider.dart
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../models/upload_task_model.dart';
import '../core/services/upload_service.dart';

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

    // Create task entries
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
      _uploadBulk(files);
    } else {
      _uploadIndividual(files);
    }
  }

  void _uploadIndividual(List<MapEntry<String, File>> files) {
    for (int i = 0; i < files.length; i++) {
      final taskId = state.tasks[i].id;
      _updateTask(taskId, status: UploadStatus.uploading);

      UploadService.uploadFile(
        file: files[i].value,
        fileName: files[i].key,
        onProgress: (p) => _updateTask(taskId, progress: p),
        onComplete: (url) => _updateTask(
          taskId,
          status: UploadStatus.complete,
          progress: 1.0,
          downloadUrl: url,
        ),
        onError: (e) => _updateTask(
          taskId,
          status: UploadStatus.failed,
          error: e,
        ),
      );
    }
  }

  void _uploadBulk(List<MapEntry<String, File>> files) {
    final taskIds = state.tasks.map((t) => t.id).toList();
    for (final id in taskIds) {
      _updateTask(id, status: UploadStatus.uploading);
    }

    UploadService.uploadMultipleFiles(
      files: files.map((e) => e.value).toList(),
      fileNames: files.map((e) => e.key).toList(),
      onFileProgress: (fileId, p) {},
      onFileComplete: (fileId) {},
      onFileError: (fileId, error) {},
      onBatchComplete: (count) {
        for (final id in taskIds) {
          _updateTask(id, status: UploadStatus.complete, progress: 1.0);
        }
      },
    );
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
