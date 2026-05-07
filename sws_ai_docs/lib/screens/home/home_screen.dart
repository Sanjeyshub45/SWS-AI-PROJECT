// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/upload_provider.dart';
import '../../models/upload_task_model.dart';
import '../../core/constants/app_colors.dart';
import 'widgets/upload_zone.dart';
import 'widgets/upload_queue_item.dart';
import 'widgets/bulk_upload_banner.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(uploadProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.description, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'SWS AI Docs',
              style: TextStyle(
                fontFamily: 'Livvic',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        actions: [
          if (state.tasks.isNotEmpty)
            TextButton.icon(
              onPressed: () =>
                  ref.read(uploadProvider.notifier).clearTasks(),
              icon: const Icon(Icons.clear_all,
                  size: 18, color: AppColors.primary),
              label: const Text(
                'Clear',
                style: TextStyle(
                    fontFamily: 'Livvic', color: AppColors.primary),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // ── Header text ───────────────────────────
            const Text(
              'Upload Documents',
              style: TextStyle(
                fontFamily: 'Livvic',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Select one or more PDF files to upload',
              style: TextStyle(
                fontFamily: 'Livvic',
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 20),

            // ── Upload zone ──────────────────────────
            const UploadZone(),
            const SizedBox(height: 24),

            // ── Bulk banner (>3 files) ────────────────
            if (state.isBulkMode && state.tasks.isNotEmpty) ...[
              BulkUploadBanner(
                fileCount: state.tasks.length,
                completedCount: state.tasks
                    .where((t) => t.status == UploadStatus.complete)
                    .length,
              ),
              const SizedBox(height: 20),
            ],

            // ── Per-file progress (≤3 files) ──────────
            if (!state.isBulkMode && state.tasks.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Upload Progress',
                    style: TextStyle(
                      fontFamily: 'Livvic',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    '${state.tasks.where((t) => t.status == UploadStatus.complete).length}/${state.tasks.length} done',
                    style: TextStyle(
                      fontFamily: 'Livvic',
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...state.tasks.map((task) => UploadQueueItem(task: task)),
            ],

            // ── Also show individual cards in bulk mode ──
            if (state.isBulkMode && state.tasks.isNotEmpty) ...[
              const Text(
                'File Queue',
                style: TextStyle(
                  fontFamily: 'Livvic',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              ...state.tasks.map((task) => UploadQueueItem(task: task)),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
