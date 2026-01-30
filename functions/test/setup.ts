import * as admin from 'firebase-admin';

// Initialize Firebase Admin for tests
if (!admin.apps.length) {
  admin.initializeApp({
    projectId: 'hex-buzz-test',
  });
}
