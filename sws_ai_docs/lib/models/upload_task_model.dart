// lib/models/upload_task_model.dart
enum UploadStatus { queued, uploading, complete, failed }

class UploadTaskModel {
  final String id;
  final String fileName;
  final int fileSize;
  double progress; // 0.0 → 1.0
  UploadStatus status;
  String? downloadUrl;
  String? error;

  UploadTaskModel({
    required this.id,
    required this.fileName,
    required this.fileSize,
    this.progress = 0.0,
    this.status = UploadStatus.queued,
    this.downloadUrl,
    this.error,
  });

  UploadTaskModel copyWith({
    double? progress,
    UploadStatus? status,
    String? downloadUrl,
    String? error,
  }) {
    return UploadTaskModel(
      id: id,
      fileName: fileName,
      fileSize: fileSize,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      error: error ?? this.error,
    );
  }
}
