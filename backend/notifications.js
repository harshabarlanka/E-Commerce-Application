const admin = require('firebase-admin');
const { db } = require("./firebase");
const serviceAccount = require('./serviceAccountKey.json'); // Update with your path
async function sendNotificationToUser(userId, title, body) {
  try {
    const userDoc = await db.collection('users').doc(userId).get();
    const token = userDoc.data()?.fcmToken;

    if (!token) {
      console.log('❌ No FCM token found for user:', userId);
      return;
    }

    const message = {
      token,
      notification: {
        title,
        body,
      },
    };

    const response = await admin.messaging().send(message);
    console.log('✅ Notification sent:', response);
  } catch (err) {
    console.error('❌ Error sending push:', err);
  }
}
module.exports = { sendNotificationToUser };
