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
// HTTPS REST API
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
