// lib/screens/home/widgets/upload_queue_item.dart
import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../../../models/upload_task_model.dart';
import '../../../core/constants/app_colors.dart';

class UploadQueueItem extends StatelessWidget {
  final UploadTaskModel task;
  const UploadQueueItem({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: _borderColor().withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.picture_as_pdf,
                    color: Color(0xFFE53935), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.fileName,
                      style: const TextStyle(
                        fontFamily: 'Livvic',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _formatBytes(task.fileSize),
                      style: TextStyle(
                        fontFamily: 'Livvic',
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              _StatusChip(status: task.status),
            ],
          ),
          if (task.status == UploadStatus.uploading ||
              task.status == UploadStatus.complete) ...[
            const SizedBox(height: 12),
            LinearPercentIndicator(
              percent: task.progress.clamp(0.0, 1.0),
              lineHeight: 6,
              backgroundColor: Colors.grey[200]!,
              progressColor: task.status == UploadStatus.complete
                  ? AppColors.success
                  : AppColors.primary,
              barRadius: const Radius.circular(4),
              padding: EdgeInsets.zero,
              trailing: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  '${(task.progress * 100).toInt()}%',
                  style: const TextStyle(
                    fontFamily: 'Livvic',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
          if (task.status == UploadStatus.failed && task.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Error: ${task.error}',
                style: const TextStyle(
                  fontFamily: 'Livvic',
                  fontSize: 12,
                  color: Color(0xFFE53935),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _borderColor() {
    return switch (task.status) {
      UploadStatus.queued => Colors.grey,
      UploadStatus.uploading => AppColors.primary,
      UploadStatus.complete => AppColors.success,
      UploadStatus.failed => AppColors.error,
    };
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }
}

class _StatusChip extends StatelessWidget {
  final UploadStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      UploadStatus.queued => ('Queued', Colors.grey),
      UploadStatus.uploading => ('Uploading', AppColors.primary),
      UploadStatus.complete => ('Done', AppColors.success),
      UploadStatus.failed => ('Failed', AppColors.error),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Livvic',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
