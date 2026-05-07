// lib/screens/documents/document_library_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/upload_service.dart';
import '../../models/document_model.dart';

final documentsStreamProvider = StreamProvider<List<DocumentModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('documents')
      .orderBy('uploadedAt', descending: true)
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => DocumentModel.fromMap(d.data(), d.id)).toList());
});

class DocumentLibraryScreen extends ConsumerWidget {
  const DocumentLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDocs = ref.watch(documentsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Documents',
          style: TextStyle(
            fontFamily: 'Livvic',
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        actions: [
          asyncDocs.when(
            data: (docs) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${docs.length} file${docs.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontFamily: 'Livvic',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
      body: asyncDocs.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(fontFamily: 'Livvic'))),
        data: (docs) {
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child:
                        Icon(Icons.folder_open, size: 48, color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'No documents yet',
                    style: TextStyle(
                      fontFamily: 'Livvic',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload PDFs from the Upload tab',
                    style: TextStyle(
                      fontFamily: 'Livvic',
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _DocumentCard(doc: docs[i]),
          );
        },
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final DocumentModel doc;
  const _DocumentCard({required this.doc});

  String _formatBytes(int bytes) {
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.picture_as_pdf,
                color: Color(0xFFE53935), size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.name,
                  style: const TextStyle(
                    fontFamily: 'Livvic',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${_formatBytes(doc.size)} · '
                  '${DateFormat('MMM d, yyyy').format(doc.uploadedAt)}',
                  style: TextStyle(
                    fontFamily: 'Livvic',
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new,
                color: AppColors.primary, size: 20),
            onPressed: () async {
              if (doc.downloadUrl.isNotEmpty) {
                await launchUrl(Uri.parse(doc.downloadUrl),
                    mode: LaunchMode.externalApplication);
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.red[300], size: 20),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  title: const Text('Delete document?',
                      style: TextStyle(
                          fontFamily: 'Livvic', fontWeight: FontWeight.w700)),
                  content: Text(
                      'This will permanently delete "${doc.name}".',
                      style: const TextStyle(fontFamily: 'Livvic')),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel',
                          style: TextStyle(fontFamily: 'Livvic')),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete',
                          style: TextStyle(
                              fontFamily: 'Livvic', color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await UploadService.deleteDocument(doc.id, doc.storagePath);
              }
            },
          ),
        ],
      ),
    );
  }
}
