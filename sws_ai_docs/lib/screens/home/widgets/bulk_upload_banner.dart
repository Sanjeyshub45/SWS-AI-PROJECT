// lib/screens/home/widgets/bulk_upload_banner.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class BulkUploadBanner extends StatefulWidget {
  final int fileCount;
  final int completedCount;

  const BulkUploadBanner({
    super.key,
    required this.fileCount,
    required this.completedCount,
  });

  @override
  State<BulkUploadBanner> createState() => _BulkUploadBannerState();
}

class _BulkUploadBannerState extends State<BulkUploadBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isComplete = widget.completedCount >= widget.fileCount;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isComplete
              ? [const Color(0xFF2E7D32), const Color(0xFF43A047)]
              : [AppColors.primary, const Color(0xFF3D8BFF)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: (isComplete ? AppColors.success : AppColors.primary)
                .withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (!isComplete)
            RotationTransition(
              turns: _controller,
              child: const Icon(Icons.sync, color: Colors.white, size: 22),
            )
          else
            const Icon(Icons.check_circle, color: Colors.white, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isComplete
                      ? '✓ All ${widget.completedCount} files uploaded!'
                      : 'Uploading ${widget.fileCount} files in background…',
                  style: const TextStyle(
                    fontFamily: 'Livvic',
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (!isComplete)
                  Text(
                    '${widget.completedCount} of ${widget.fileCount} complete',
                    style: TextStyle(
                      fontFamily: 'Livvic',
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
