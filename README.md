# SWS AI Docs 📄

> A smart PDF document manager built with Flutter and Firebase — upload, manage, and get notified, all in one place.

---

## 📸 App Screenshots

> **Paste your screenshot image links below:**

| Upload Screen | Documents Library | Notifications |
|:---:|:---:|:---:|
| ![Upload](https://res.cloudinary.com/djmywmg2m/image/upload/v1778143604/uploading_screen_nftaio.jpg) | ![Documents](YOUR_DOCUMENTS_SCREEN_IMAGE_URL) | ![Notifications](YOUR_NOTIFICATIONS_SCREEN_IMAGE_URL) |

---

## 📥 Download the App

> **[⬇️ Download APK — Click Here](YOUR_APK_DOWNLOAD_LINK)**


---

## What is this app?

**SWS AI Docs** is a mobile app for students and staff to upload and manage PDF documents from their phone. Think of it like a personal cloud drive, but only for PDFs — fast, simple, and with real-time notifications.

---

## ✨ Features

### 📤 Upload PDFs
- Tap **Browse Files** to pick one or multiple PDFs from your phone
- For **1–3 files**: see each file's upload progress in real time
- For **4+ files**: a banner shows "Uploading X files in background..." so you can keep using the app
- Each file shows its upload status: **Uploading → Complete / Failed**

### 📁 Document Library
- All uploaded files appear in the **Documents** tab automatically
- See file name, size, and upload date
- Tap the open icon to **view the PDF** in your browser
- Tap the delete icon to **permanently remove** a file

### 🔔 Notifications
- Every upload result (success or failure) is **saved as a notification**
- Notifications **persist after app restart** — they're stored in the cloud
- A **red badge** on the bell icon shows how many unread notifications you have
- Tap a notification to **mark it as read**
- Swipe left to **dismiss** a notification
- Use **Mark all read** or **Clear all** buttons in the Notifications screen
- You also get an **on-device push notification** the moment an upload finishes

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile Framework | Flutter (Dart) |
| State Management | Riverpod |
| Backend / Database | Firebase Firestore |
| File Storage | Firebase Storage |
| Push Notifications | flutter_local_notifications + FCM |
| File Picker | file_picker |
| Fonts | Livvic (Google Fonts) |

---

## 🚀 How to Run Locally

**Prerequisites:** Flutter SDK, Android Studio, Firebase account

```bash
# 1. Clone the repo
git clone https://github.com/Sanjeyshub45/SWS-AI-PROJECT.git
cd SWS-AI-PROJECT/sws_ai_docs

# 2. Install dependencies
flutter pub get

# 3. Connect your Android device (USB debugging ON)
flutter run
```

> **Note:** You need to add your own `google-services.json` from your Firebase project inside `android/app/`.

---

## 📂 Project Structure

```
lib/
├── core/
│   ├── constants/        # App colors, theme
│   └── services/         # Upload, FCM, Notification services
├── models/               # Data models (Document, Notification, UploadTask)
├── providers/            # Riverpod state providers
├── screens/
│   ├── home/             # Upload screen + widgets
│   ├── documents/        # Document library screen
│   └── notifications/    # Notifications screen
└── widgets/              # Shared widgets (AppShell, nav bar)
```

---

## 🔐 Firebase Setup

This app uses:
- **Firestore** — stores document metadata and notifications
- **Firebase Storage** — stores the actual PDF files
- **Firebase Cloud Messaging** — optional server-side push notifications

Security rules are set to open for development. Tighten them before going to production.

---

## 👨‍💻 Built by

**Sanjey S** — [GitHub @Sanjeyshub45](https://github.com/Sanjeyshub45)

---

*Made with ❤️ using Flutter & Firebase*
