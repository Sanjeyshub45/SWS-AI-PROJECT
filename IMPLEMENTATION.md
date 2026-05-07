# 📱 SWS AI — Document Management App
## Implementation Guide: Flutter + Firebase + FCM

> **Tech Stack:** Flutter · Firebase Auth-free · Firestore · Firebase Storage · Cloud Functions · FCM  
> **Estimated Build Time:** 3–4 hours  
> **Assessment Rules:** Commit every 15 minutes. Build Features 1 → 2 → 3 → Optional.

---

## Table of Contents

1. [Project Architecture](#1-project-architecture)
2. [Prerequisites & Setup](#2-prerequisites--setup)
3. [Firebase Console Setup](#3-firebase-console-setup)
4. [Flutter Project Bootstrap](#4-flutter-project-bootstrap)
5. [Folder Structure](#5-folder-structure)
6. [pubspec.yaml — All Dependencies](#6-pubspecyaml--all-dependencies)
7. [Firebase Configuration Files](#7-firebase-configuration-files)
8. [Feature 1 — File Upload (Individual & Bulk)](#8-feature-1--file-upload-individual--bulk)
9. [Feature 2 — Smart Bulk Notifications (WebSocket/Polling)](#9-feature-2--smart-bulk-notifications)
10. [Feature 3 — Notification Center](#10-feature-3--notification-center)
11. [Feature 4 (Optional) — FCM Push Notifications](#11-feature-4-optional--fcm-push-notifications)
12. [Firebase Cloud Functions Backend](#12-firebase-cloud-functions-backend)
13. [Firestore Data Models](#13-firestore-data-models)
14. [Firebase Security Rules](#14-firebase-security-rules)
15. [UI Design System (White + Blue + Livvic)](#15-ui-design-system)
16. [Screen-by-Screen Implementation](#16-screen-by-screen-implementation)
17. [State Management (Riverpod)](#17-state-management-riverpod)
18. [Git Commit Schedule](#18-git-commit-schedule)
19. [README Template](#19-readme-template)
20. [Environment Variables & Secrets](#20-environment-variables--secrets)

---

## 1. Project Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Flutter App                            │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌───────────┐  │
│  │  Upload  │  │ Document │  │Notif.    │  │   Nav     │  │
│  │  Screen  │  │ Library  │  │Center    │  │   Bar     │  │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └───────────┘  │
│       │              │              │                        │
│  ┌────▼──────────────▼──────────────▼──────────────────┐   │
│  │              Riverpod State Management               │   │
│  │    UploadProvider · DocumentProvider · NotifProvider │   │
│  └────┬──────────────┬──────────────┬───────────────────┘  │
│       │              │              │                        │
│  ┌────▼──────┐  ┌────▼─────┐  ┌────▼─────┐                 │
│  │ Firebase  │  │Firestore │  │   FCM    │                 │
│  │ Storage   │  │    DB    │  │ Service  │                 │
│  └───────────┘  └──────────┘  └──────────┘                 │
└─────────────────────────────────────────────────────────────┘
                         │
              ┌──────────▼──────────┐
              │  Firebase Cloud     │
              │  Functions          │
              │  (Node.js 20)       │
              │  - onUploadComplete │
              │  - sendFCM          │
              └─────────────────────┘
```

### Data Flow: Bulk Upload

```
User picks >3 files
       │
       ▼
Show banner: "Uploading X files in background…"
       │
       ▼
Upload files to Firebase Storage (parallel, per-file progress)
       │
       ▼
Write upload metadata to Firestore (uploads/{uploadId})
       │
       ▼
Cloud Function triggers on last file complete
       │
       ├─── Writes to notifications/{notifId} in Firestore
       │
       ├─── Sends FCM push to device token
       │
       └─── App listens via Firestore real-time snapshot
                  │
                  ▼
            Show in-app notification + badge update
```

---

## 2. Prerequisites & Setup

### Tools Required

```bash
# 1. Flutter SDK (3.19+)
flutter --version   # must be ≥ 3.19.0

# 2. Firebase CLI
npm install -g firebase-tools
firebase --version  # must be ≥ 13.x

# 3. FlutterFire CLI
dart pub global activate flutterfire_cli
flutterfire --version

# 4. Node.js (for Cloud Functions)
node --version      # must be ≥ 20.x

# 5. Android Studio / Xcode (for emulators)
```

### Platform Requirements

| Platform | Minimum Version |
|----------|----------------|
| Android  | API 21 (Android 5.0) |
| iOS      | iOS 13.0 |
| Flutter  | 3.19.0 |
| Dart     | 3.3.0 |

---

## 3. Firebase Console Setup

### Step 1 — Create Firebase Project

1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. Click **"Add project"** → Name it `sws-ai-docs`
3. Disable Google Analytics (not needed) → **Create project**

### Step 2 — Enable Firebase Services

#### Firestore Database
```
Firebase Console → Build → Firestore Database
→ Create database → Start in TEST MODE → Choose region (us-central1)
```

#### Firebase Storage
```
Firebase Console → Build → Storage
→ Get started → Start in TEST MODE → Done
```

#### Firebase Cloud Messaging (FCM)
```
Firebase Console → Project Settings → Cloud Messaging
→ Note your Server Key (needed for Cloud Functions)
```

#### Cloud Functions
```
Firebase Console → Build → Functions
→ Upgrade to Blaze plan (required for outbound network calls)
```

### Step 3 — Register Apps

#### Android App
```
Firebase Console → Project Settings → Add app → Android
Package name: com.swsai.docmanager
App nickname: SWS AI Docs Android
→ Download google-services.json → Place in android/app/
```

#### iOS App
```
Firebase Console → Project Settings → Add app → iOS
Bundle ID: com.swsai.docmanager
App nickname: SWS AI Docs iOS
→ Download GoogleService-Info.plist → Place in ios/Runner/
```

---

## 4. Flutter Project Bootstrap

```bash
# Create project
flutter create sws_ai_docs --org com.swsai --platforms android,ios
cd sws_ai_docs

# Initialize Firebase in project
flutterfire configure --project=sws-ai-docs

# Initialize Cloud Functions
firebase init functions
# → Choose: TypeScript or JavaScript (choose JavaScript)
# → Install dependencies: Yes
```

---

## 5. Folder Structure

```
sws_ai_docs/
├── android/
│   └── app/
│       ├── google-services.json          ← Downloaded from Firebase
│       └── src/main/AndroidManifest.xml
├── ios/
│   └── Runner/
│       └── GoogleService-Info.plist      ← Downloaded from Firebase
├── functions/                            ← Cloud Functions (Node.js)
│   ├── index.js
│   └── package.json
├── lib/
│   ├── main.dart                         ← App entry point
│   ├── firebase_options.dart             ← Auto-generated by FlutterFire CLI
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart           ← Blue/white design tokens
│   │   │   └── app_text_styles.dart      ← Livvic font styles
│   │   ├── services/
│   │   │   ├── upload_service.dart       ← Firebase Storage upload logic
│   │   │   ├── firestore_service.dart    ← Firestore CRUD
│   │   │   └── fcm_service.dart          ← FCM token + listener
│   │   └── utils/
│   │       ├── file_size_formatter.dart
│   │       └── date_formatter.dart
│   ├── models/
│   │   ├── document_model.dart
│   │   ├── upload_task_model.dart
│   │   └── notification_model.dart
│   ├── providers/
│   │   ├── upload_provider.dart          ← Riverpod: upload state
│   │   ├── document_provider.dart        ← Riverpod: document list
│   │   └── notification_provider.dart    ← Riverpod: notifications + badge
│   ├── screens/
│   │   ├── home/
│   │   │   ├── home_screen.dart          ← Upload + document library tabs
│   │   │   └── widgets/
│   │   │       ├── upload_zone.dart      ← File picker drop zone
│   │   │       ├── upload_queue_item.dart← Per-file progress row
│   │   │       └── bulk_upload_banner.dart
│   │   ├── documents/
│   │   │   ├── document_library_screen.dart
│   │   │   └── widgets/
│   │   │       └── document_card.dart
│   │   └── notifications/
│   │       ├── notifications_screen.dart
│   │       └── widgets/
│   │           └── notification_tile.dart
│   └── widgets/
│       ├── app_shell.dart                ← Bottom nav + badge
│       └── loading_skeleton.dart
├── pubspec.yaml
├── firebase.json
├── .firebaserc
└── README.md
```

---

## 6. pubspec.yaml — All Dependencies

```yaml
name: sws_ai_docs
description: SWS AI Document Management App
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.3.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # Firebase
  firebase_core: ^3.1.0
  firebase_storage: ^12.1.0
  cloud_firestore: ^5.1.0
  firebase_messaging: ^15.0.0

  # File Picker
  file_picker: ^8.0.3

  # State Management
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5

  # UI
  google_fonts: ^6.2.1
  flutter_local_notifications: ^17.1.1
  cached_network_image: ^3.3.1
  shimmer: ^3.0.0                    # Skeleton loading
  percent_indicator: ^4.2.3          # Progress bars
  badges: ^3.1.2                     # Bell badge
  intl: ^0.19.0                      # Date formatting
  gap: ^3.0.1                        # Spacing

  # Utils
  uuid: ^4.4.0
  path: ^1.9.0
  mime: ^1.0.5

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  build_runner: ^2.4.11
  riverpod_generator: ^2.4.0

flutter:
  uses-material-design: true
  fonts:
    - family: Livvic
      fonts:
        - asset: assets/fonts/Livvic-Regular.ttf
        - asset: assets/fonts/Livvic-Medium.ttf
          weight: 500
        - asset: assets/fonts/Livvic-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Livvic-Bold.ttf
          weight: 700
  assets:
    - assets/fonts/
    - assets/images/
```

> **Download Livvic font:** [fonts.google.com/specimen/Livvic](https://fonts.google.com/specimen/Livvic) → Download → place TTF files in `assets/fonts/`

---

## 7. Firebase Configuration Files

### lib/main.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'core/services/fcm_service.dart';
import 'widgets/app_shell.dart';

// Background FCM handler — must be top-level
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Background FCM: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
    const ProviderScope(
      child: SWSDocApp(),
    ),
  );
}

class SWSDocApp extends StatefulWidget {
  const SWSDocApp({super.key});

  @override
  State<SWSDocApp> createState() => _SWSDocAppState();
}

class _SWSDocAppState extends State<SWSDocApp> {
  @override
  void initState() {
    super.initState();
    FCMService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SWS AI Docs',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E6BFF),
          brightness: Brightness.light,
        ),
        fontFamily: 'Livvic',
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1A1A2E),
          elevation: 0,
          shadowColor: Color(0x1A000000),
        ),
      ),
      home: const AppShell(),
    );
  }
}
```

---

## 8. Feature 1 — File Upload (Individual & Bulk)

### 8.1 — Upload Task Model

```dart
// lib/models/upload_task_model.dart
enum UploadStatus { queued, uploading, complete, failed }

class UploadTaskModel {
  final String id;
  final String fileName;
  final int fileSize;
  double progress;        // 0.0 → 1.0
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
```

### 8.2 — Upload Service (Firebase Storage)

```dart
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
      rethrow;
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
    await _storage.ref(storagePath).delete();
    await _firestore.collection('documents').doc(docId).delete();
  }
}
```

### 8.3 — Upload Provider (Riverpod)

```dart
// lib/providers/upload_provider.dart
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../models/upload_task_model.dart';
import '../core/services/upload_service.dart';

class UploadState {
  final List<UploadTaskModel> tasks;
  final bool isBulkMode;          // true when > 3 files
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
    final tasks = files.map((e) => UploadTaskModel(
      id: e.key + DateTime.now().millisecondsSinceEpoch.toString(),
      fileName: e.key,
      fileSize: e.value.lengthSync(),
      status: UploadStatus.queued,
    )).toList();

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
```

### 8.4 — Upload Zone Widget

```dart
// lib/screens/home/widgets/upload_zone.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/upload_provider.dart';
import '../../../core/constants/app_colors.dart';

class UploadZone extends ConsumerWidget {
  const UploadZone({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(uploadProvider);

    return GestureDetector(
      onTap: state.isPickingFiles
          ? null
          : () => ref.read(uploadProvider.notifier).pickAndUpload(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
            width: 2,
            style: BorderStyle.solid,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_upload_outlined,
                size: 48,
                color: AppColors.primary,
              ),
              const SizedBox(height: 12),
              Text(
                state.isPickingFiles
                    ? 'Opening file picker…'
                    : 'Tap to select PDF files',
                style: const TextStyle(
                  fontFamily: 'Livvic',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height(4),
              Text(
                'Supports multiple PDF files',
                style: TextStyle(
                  fontFamily: 'Livvic',
                  fontSize: 13,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### 8.5 — Per-File Progress Row

```dart
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.picture_as_pdf, color: Color(0xFFE53935), size: 22),
              const SizedBox(width: 10),
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
            const SizedBox(height: 10),
            LinearPercentIndicator(
              percent: task.progress.clamp(0.0, 1.0),
              lineHeight: 6,
              backgroundColor: Colors.grey[200]!,
              progressColor: task.status == UploadStatus.complete
                  ? AppColors.success
                  : AppColors.primary,
              barRadius: const Radius.circular(4),
              padding: EdgeInsets.zero,
              trailing: Text(
                '${(task.progress * 100).toInt()}%',
                style: const TextStyle(
                  fontFamily: 'Livvic',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
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
      UploadStatus.queued    => ('Queued',    Colors.grey),
      UploadStatus.uploading => ('Uploading', AppColors.primary),
      UploadStatus.complete  => ('Done',      AppColors.success),
      UploadStatus.failed    => ('Failed',    Colors.red),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
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
```

---

## 9. Feature 2 — Smart Bulk Notifications

### 9.1 — Bulk Upload Banner

```dart
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
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isComplete ? AppColors.success : AppColors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (!isComplete)
            RotationTransition(
              turns: _controller,
              child: const Icon(Icons.sync, color: Colors.white, size: 20),
            )
          else
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isComplete
                  ? '✓ ${widget.completedCount} files uploaded successfully'
                  : 'Uploading ${widget.fileCount} files in background…',
              style: const TextStyle(
                fontFamily: 'Livvic',
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

### 9.2 — Firestore Real-Time Listener for Batch Completion

```dart
// In notification_provider.dart — Firestore snapshot listener
// Listens for new notifications written by the Cloud Function

Stream<List<NotificationModel>> watchNotifications() {
  return FirebaseFirestore.instance
      .collection('notifications')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs
          .map((d) => NotificationModel.fromMap(d.data(), d.id))
          .toList());
}
```

---

## 10. Feature 3 — Notification Center

### 10.1 — Notification Model

```dart
// lib/models/notification_model.dart
class NotificationModel {
  final String id;
  final String message;
  final String type;        // 'upload_complete' | 'upload_failed'
  final DateTime createdAt;
  final bool isRead;

  const NotificationModel({
    required this.id,
    required this.message,
    required this.type,
    required this.createdAt,
    required this.isRead,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      message: map['message'] as String,
      type: map['type'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isRead: map['isRead'] as bool? ?? false,
    );
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      message: message,
      type: type,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
```

### 10.2 — Notification Provider

```dart
// lib/providers/notification_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

final notificationsStreamProvider =
    StreamProvider<List<NotificationModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('notifications')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs
          .map((d) => NotificationModel.fromMap(d.data(), d.id))
          .toList());
});

final unreadCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsStreamProvider).valueOrNull ?? [];
  return notifications.where((n) => !n.isRead).length;
});

class NotificationActions {
  static final _firestore = FirebaseFirestore.instance;

  static Future<void> markAsRead(String notifId) async {
    await _firestore
        .collection('notifications')
        .doc(notifId)
        .update({'isRead': true});
  }

  static Future<void> markAllAsRead() async {
    final batch = _firestore.batch();
    final unread = await _firestore
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  static Future<void> clearAll() async {
    final batch = _firestore.batch();
    final all = await _firestore.collection('notifications').get();
    for (final doc in all.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
```

### 10.3 — Notifications Screen

```dart
// lib/screens/notifications/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/notification_provider.dart';
import '../../core/constants/app_colors.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncNotifications = ref.watch(notificationsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontFamily: 'Livvic', fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton(
            onPressed: NotificationActions.markAllAsRead,
            child: const Text(
              'Mark all read',
              style: TextStyle(fontFamily: 'Livvic', color: AppColors.primary),
            ),
          ),
          TextButton(
            onPressed: NotificationActions.clearAll,
            child: Text(
              'Clear all',
              style: TextStyle(
                fontFamily: 'Livvic',
                color: Colors.red[400],
              ),
            ),
          ),
        ],
      ),
      body: asyncNotifications.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none,
                      size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontFamily: 'Livvic',
                      fontSize: 16,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final notif = notifications[i];
              return _NotificationTile(notification: notif);
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final dynamic notification;
  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      onDismissed: (_) => NotificationActions.markAsRead(notification.id),
      child: GestureDetector(
        onTap: () => NotificationActions.markAsRead(notification.id),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: notification.isRead
                ? Colors.white
                : AppColors.primary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: notification.isRead
                  ? Colors.grey[200]!
                  : AppColors.primary.withOpacity(0.2),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  notification.type == 'upload_complete'
                      ? Icons.check_circle_outline
                      : Icons.error_outline,
                  color: notification.type == 'upload_complete'
                      ? AppColors.success
                      : Colors.red,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontFamily: 'Livvic',
                        fontSize: 14,
                        fontWeight: notification.isRead
                            ? FontWeight.w400
                            : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM d, h:mm a').format(notification.createdAt),
                      style: TextStyle(
                        fontFamily: 'Livvic',
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### 10.4 — App Shell with Bell Badge

```dart
// lib/widgets/app_shell.dart
import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notification_provider.dart';
import '../screens/home/home_screen.dart';
import '../screens/documents/document_library_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../core/constants/app_colors.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _currentIndex = 0;

  final _screens = const [
    HomeScreen(),
    DocumentLibraryScreen(),
    NotificationsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final unreadCount = ref.watch(unreadCountProvider);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary.withOpacity(0.1),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.upload_file_outlined),
            selectedIcon: Icon(Icons.upload_file),
            label: 'Upload',
          ),
          const NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Documents',
          ),
          NavigationDestination(
            icon: badges.Badge(
              showBadge: unreadCount > 0,
              badgeContent: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              badgeStyle: const badges.BadgeStyle(
                badgeColor: Color(0xFFE53935),
              ),
              child: const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: const Icon(Icons.notifications),
            label: 'Notifications',
          ),
        ],
      ),
    );
  }
}
```

---

## 11. Feature 4 (Optional) — FCM Push Notifications

### 11.1 — FCM Service

```dart
// lib/core/services/fcm_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FCMService {
  static final _fcm = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Request permission (iOS)
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialize local notifications plugin
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    // High importance channel for Android
    const channel = AndroidNotificationChannel(
      'sws_uploads',
      'Upload Notifications',
      description: 'Notifications for file upload completion',
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Get and save device token
    final token = await _fcm.getToken();
    if (token != null) await _saveToken(token);

    // Listen for token refresh
    _fcm.onTokenRefresh.listen(_saveToken);

    // Foreground messages → show local notification
    FirebaseMessaging.onMessage.listen((message) {
      _showLocalNotification(message);
    });
  }

  static Future<void> _saveToken(String token) async {
    await FirebaseFirestore.instance
        .collection('devices')
        .doc('current_device')   // In production: use user ID
        .set({'token': token, 'updatedAt': FieldValue.serverTimestamp()});
  }

  static void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'sws_uploads',
          'Upload Notifications',
          channelDescription: 'File upload completion alerts',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }
}
```

### 11.2 — Android Manifest Additions

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<!-- Add inside <manifest> tag -->
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

<!-- Add inside <application> tag -->
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="sws_uploads" />
```

---

## 12. Firebase Cloud Functions Backend

### functions/index.js — Complete Backend

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

// ─────────────────────────────────────────────
// TRIGGER: When a batch document is marked complete,
// write a notification and send FCM push
// ─────────────────────────────────────────────
exports.onBatchComplete = functions.firestore
  .document('batches/{batchId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // Only trigger when status changes to 'complete'
    if (before.status === 'complete' || after.status !== 'complete') return;

    const { totalFiles, completedFiles, failedFiles = 0 } = after;
    const timestamp = new Date().toLocaleString('en-US', {
      month: 'short', day: 'numeric',
      hour: 'numeric', minute: '2-digit',
    });

    const message = failedFiles > 0
      ? `${completedFiles} of ${totalFiles} files uploaded (${failedFiles} failed) — ${timestamp}`
      : `${completedFiles} files uploaded successfully — ${timestamp}`;

    const type = failedFiles > 0 ? 'upload_failed' : 'upload_complete';

    // 1. Write notification to Firestore
    await db.collection('notifications').add({
      message,
      type,
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      batchId: context.params.batchId,
    });

    // 2. Send FCM push to all registered devices
    const deviceSnap = await db.collection('devices').get();
    const tokens = deviceSnap.docs
      .map(d => d.data().token)
      .filter(Boolean);

    if (tokens.length === 0) return;

    await messaging.sendEachForMulticast({
      tokens,
      notification: {
        title: 'SWS AI Docs',
        body: message,
      },
      android: {
        notification: {
          channelId: 'sws_uploads',
          priority: 'high',
        },
      },
      apns: {
        payload: {
          aps: { sound: 'default', badge: 1 },
        },
      },
    });

    console.log(`Batch ${context.params.batchId} complete. Notified ${tokens.length} devices.`);
  });

// ─────────────────────────────────────────────
// CALLABLE: Get unread notification count
// ─────────────────────────────────────────────
exports.getUnreadCount = functions.https.onCall(async () => {
  const snap = await db.collection('notifications')
    .where('isRead', '==', false)
    .count()
    .get();
  return { count: snap.data().count };
});

// ─────────────────────────────────────────────
// HTTPS: REST-style endpoints (optional, Firestore SDK preferred)
// ─────────────────────────────────────────────
exports.api = functions.https.onRequest(async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');

  const path = req.path;
  const method = req.method;

  // GET /notifications
  if (method === 'GET' && path === '/notifications') {
    const snap = await db.collection('notifications')
      .orderBy('createdAt', 'desc').get();
    return res.json(snap.docs.map(d => ({ id: d.id, ...d.data() })));
  }

  // PATCH /notifications/:id/read
  if (method === 'PATCH' && path.match(/^\/notifications\/[^/]+\/read$/)) {
    const id = path.split('/')[2];
    await db.collection('notifications').doc(id).update({ isRead: true });
    return res.json({ success: true });
  }

  // PATCH /notifications/read-all
  if (method === 'PATCH' && path === '/notifications/read-all') {
    const batch = db.batch();
    const snap = await db.collection('notifications')
      .where('isRead', '==', false).get();
    snap.docs.forEach(d => batch.update(d.ref, { isRead: true }));
    await batch.commit();
    return res.json({ success: true, updated: snap.size });
  }

  // GET /documents
  if (method === 'GET' && path === '/documents') {
    const snap = await db.collection('documents')
      .orderBy('uploadedAt', 'desc').get();
    return res.json(snap.docs.map(d => ({ id: d.id, ...d.data() })));
  }

  // DELETE /documents/:id
  if (method === 'DELETE' && path.match(/^\/documents\/[^/]+$/)) {
    const id = path.split('/')[2];
    const doc = await db.collection('documents').doc(id).get();
    if (doc.exists) {
      const { storagePath } = doc.data();
      await admin.storage().bucket().file(storagePath).delete().catch(() => {});
      await db.collection('documents').doc(id).delete();
    }
    return res.json({ success: true });
  }

  return res.status(404).json({ error: 'Not found' });
});
```

### Deploy Cloud Functions

```bash
cd functions
npm install firebase-admin firebase-functions
cd ..
firebase deploy --only functions
```

---

## 13. Firestore Data Models

### Collections Schema

```
firestore/
├── documents/
│   └── {docId}/
│       ├── id: string
│       ├── name: string
│       ├── size: number          (bytes)
│       ├── downloadUrl: string
│       ├── storagePath: string
│       ├── uploadedAt: timestamp
│       └── status: string       ('complete' | 'failed')
│
├── batches/
│   └── {batchId}/
│       ├── id: string
│       ├── totalFiles: number
│       ├── completedFiles: number
│       ├── failedFiles: number
│       ├── status: string        ('uploading' | 'complete')
│       ├── createdAt: timestamp
│       └── completedAt: timestamp
│
├── notifications/
│   └── {notifId}/
│       ├── message: string
│       ├── type: string          ('upload_complete' | 'upload_failed')
│       ├── isRead: boolean
│       ├── createdAt: timestamp
│       └── batchId: string
│
└── devices/
    └── {deviceId}/
        ├── token: string         (FCM token)
        └── updatedAt: timestamp
```

---

## 14. Firebase Security Rules

### Firestore Rules

```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow all reads/writes during assessment (tighten for production)
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

### Storage Rules

```javascript
// storage.rules
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /documents/{allPaths=**} {
      allow read, write: if true;
    }
  }
}
```

---

## 15. UI Design System

### App Colors

```dart
// lib/core/constants/app_colors.dart
import 'package:flutter/material.dart';

abstract class AppColors {
  static const primary   = Color(0xFF1E6BFF);    // Blue accent
  static const secondary = Color(0xFF0D47A1);    // Dark blue
  static const surface   = Color(0xFFFFFFFF);    // White cards
  static const background= Color(0xFFF5F7FA);    // Light grey bg
  static const success   = Color(0xFF2E7D32);    // Green
  static const error     = Color(0xFFE53935);    // Red
  static const textDark  = Color(0xFF1A1A2E);    // Near-black
  static const textGrey  = Color(0xFF9E9E9E);    // Muted
}
```

### Text Styles

```dart
// lib/core/constants/app_text_styles.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract class AppTextStyles {
  static const heading1 = TextStyle(
    fontFamily: 'Livvic',
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  );

  static const heading2 = TextStyle(
    fontFamily: 'Livvic',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );

  static const body = TextStyle(
    fontFamily: 'Livvic',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textDark,
  );

  static const caption = TextStyle(
    fontFamily: 'Livvic',
    fontSize: 12,
    color: AppColors.textGrey,
  );

  static const buttonLabel = TextStyle(
    fontFamily: 'Livvic',
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}
```

---

## 16. Screen-by-Screen Implementation

### Home Screen (Upload + Queue)

```dart
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
      appBar: AppBar(
        title: const Text(
          'SWS AI Docs',
          style: TextStyle(
            fontFamily: 'Livvic',
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (state.tasks.isNotEmpty)
            TextButton(
              onPressed: () => ref.read(uploadProvider.notifier).clearTasks(),
              child: const Text(
                'Clear',
                style: TextStyle(fontFamily: 'Livvic', color: AppColors.primary),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
              const SizedBox(height: 16),
            ],

            // ── Per-file progress (≤3 files) ──────────
            if (!state.isBulkMode && state.tasks.isNotEmpty) ...[
              const Text(
                'Upload Progress',
                style: TextStyle(
                  fontFamily: 'Livvic',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              ...state.tasks.map((task) => UploadQueueItem(task: task)),
            ],
          ],
        ),
      ),
    );
  }
}
```

### Document Library Screen

```dart
// lib/screens/documents/document_library_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/upload_service.dart';

final documentsStreamProvider = StreamProvider((ref) {
  return FirebaseFirestore.instance
      .collection('documents')
      .orderBy('uploadedAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((d) => d.data()..['id'] = d.id).toList());
});

class DocumentLibraryScreen extends ConsumerWidget {
  const DocumentLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDocs = ref.watch(documentsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Documents',
          style: TextStyle(fontFamily: 'Livvic', fontWeight: FontWeight.w700),
        ),
      ),
      body: asyncDocs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (docs) {
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No documents yet',
                    style: TextStyle(
                      fontFamily: 'Livvic',
                      fontSize: 16,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload PDFs from the Upload tab',
                    style: TextStyle(
                      fontFamily: 'Livvic',
                      fontSize: 13,
                      color: Colors.grey[400],
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
            itemBuilder: (context, i) {
              final doc = docs[i];
              return _DocumentCard(doc: doc);
            },
          );
        },
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final Map<String, dynamic> doc;
  const _DocumentCard({required this.doc});

  String _formatBytes(dynamic bytes) {
    final b = (bytes as num).toInt();
    if (b < 1048576) return '${(b / 1024).toStringAsFixed(1)} KB';
    return '${(b / 1048576).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final uploadedAt = doc['uploadedAt'] != null
        ? (doc['uploadedAt'] as Timestamp).toDate()
        : DateTime.now();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.picture_as_pdf,
                color: Color(0xFFE53935), size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc['name'] ?? 'Unknown',
                  style: const TextStyle(
                    fontFamily: 'Livvic',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatBytes(doc['size'] ?? 0)} · '
                  '${DateFormat('MMM d, yyyy').format(uploadedAt)}',
                  style: TextStyle(
                    fontFamily: 'Livvic',
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          // View button
          IconButton(
            icon: const Icon(Icons.open_in_new,
                color: AppColors.primary, size: 20),
            onPressed: () async {
              final url = doc['downloadUrl'];
              if (url != null) await launchUrl(Uri.parse(url));
            },
          ),
          // Delete button
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.red[300], size: 20),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Delete document?',
                      style: TextStyle(fontFamily: 'Livvic')),
                  content: Text('This will permanently delete "${doc['name']}".',
                      style: const TextStyle(fontFamily: 'Livvic')),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await UploadService.deleteDocument(
                    doc['id'], doc['storagePath'] ?? '');
              }
            },
          ),
        ],
      ),
    );
  }
}
```

---

## 17. State Management (Riverpod)

```
Provider Graph:

uploadProvider (StateNotifierProvider)
    └── UploadNotifier
         ├── pickAndUpload()        → file picker → UploadService
         ├── _uploadIndividual()    → per-file progress updates
         └── _uploadBulk()         → batch mode, shows banner

notificationsStreamProvider (StreamProvider)
    └── Firestore 'notifications' collection real-time stream

unreadCountProvider (Provider)
    └── derived from notificationsStreamProvider
         └── filters isRead == false → int

documentsStreamProvider (StreamProvider)
    └── Firestore 'documents' collection real-time stream
```

---

## 18. Git Commit Schedule

Follow this schedule during the 3–4 hour build window:

| Time   | Commit Message                                         |
|--------|--------------------------------------------------------|
| 0:00   | `chore: init flutter project + firebase config`        |
| 0:15   | `feat: add pubspec dependencies + folder structure`    |
| 0:30   | `feat: upload zone widget + file picker integration`   |
| 0:45   | `feat: upload service with firebase storage + progress`|
| 1:00   | `feat: per-file progress row + status chips`           |
| 1:15   | `feat: upload provider with riverpod state management` |
| 1:30   | `feat: bulk upload mode + banner widget (>3 files)`    |
| 1:45   | `feat: firestore batch tracking + cloud function stub` |
| 2:00   | `feat: notification model + firestore stream provider` |
| 2:15   | `feat: notification center screen + bell badge`        |
| 2:30   | `feat: mark as read + clear all notifications`         |
| 2:45   | `feat: document library screen with delete + view`     |
| 3:00   | `feat: app shell + bottom nav with badge count`        |
| 3:15   | `feat: cloud functions — onBatchComplete + FCM push`   |
| 3:30   | `feat: fcm service + local notifications (optional)`   |
| 3:45   | `fix: ui polish + skeleton loaders`                    |
| 4:00   | `docs: add readme + environment variable docs`         |

---

## 19. README Template

```markdown
# SWS AI — Document Management App

A Flutter + Firebase mobile app for uploading, managing, and monitoring company PDFs.

## Tech Stack
- **Mobile:** Flutter 3.19 (Dart 3.3)
- **Backend:** Firebase Cloud Functions (Node.js 20)
- **Database:** Cloud Firestore
- **Storage:** Firebase Storage
- **Push:** Firebase Cloud Messaging (FCM)
- **State:** Riverpod

## Features
- ✅ PDF upload (single & bulk) with per-file progress
- ✅ Bulk mode banner for >3 files
- ✅ Real-time notifications via Firestore stream
- ✅ Notification center with badge, mark-as-read, clear-all
- ✅ Document library with view & delete
- ✅ FCM push notifications (foreground + background)

## Setup Instructions

### Prerequisites
- Flutter 3.19+
- Firebase CLI 13+
- FlutterFire CLI
- Node.js 20+

### 1. Clone the repository
```bash
git clone https://github.com/your-username/sws-ai-docs.git
cd sws-ai-docs
```

### 2. Firebase setup
1. Create a Firebase project at console.firebase.google.com
2. Enable Firestore, Storage, FCM, and Cloud Functions
3. Run: `flutterfire configure --project=YOUR_PROJECT_ID`
4. Place `google-services.json` in `android/app/`
5. Place `GoogleService-Info.plist` in `ios/Runner/`

### 3. Install Flutter dependencies
```bash
flutter pub get
```

### 4. Download Livvic font
Download from fonts.google.com/specimen/Livvic and place TTF files in `assets/fonts/`

### 5. Deploy Cloud Functions
```bash
cd functions && npm install && cd ..
firebase deploy --only functions
```

### 6. Run the app
```bash
flutter run
```

## Environment Variables
No `.env` file needed — Firebase config is auto-generated by FlutterFire CLI into `lib/firebase_options.dart`.

Cloud Functions use Firebase default admin credentials (no manual config required).

## FCM Setup
- Android: FCM works out of the box with `google-services.json`
- iOS: Requires an APNs Auth Key uploaded to Firebase Console → Project Settings → Cloud Messaging → iOS App Configuration

## Firestore Collections
- `documents` — uploaded PDFs metadata
- `batches` — batch upload tracking
- `notifications` — all user notifications
- `devices` — FCM token per device
```

---

## 20. Environment Variables & Secrets

| Variable | Location | How to Set |
|----------|----------|------------|
| Firebase config | `lib/firebase_options.dart` | Auto-generated by `flutterfire configure` |
| `google-services.json` | `android/app/` | Downloaded from Firebase Console |
| `GoogleService-Info.plist` | `ios/Runner/` | Downloaded from Firebase Console |
| FCM Server Key | Cloud Functions env | Auto-available via `admin.messaging()` |
| Storage bucket | `firebase_options.dart` | Auto-generated |

### Add to .gitignore

```gitignore
# Firebase secrets
android/app/google-services.json
ios/Runner/GoogleService-Info.plist
lib/firebase_options.dart

# Flutter
.dart_tool/
build/
*.g.dart

# Functions
functions/node_modules/
```

> ⚠️ **Commit `firebase_options.dart` for the assessment** so reviewers can run the project. In production, use environment-specific configs instead.

---

*Built for SWS AI Technical Assessment · Mobile App Developer Track*
