const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");
const {logger} = require("firebase-functions");

initializeApp();
const db = getFirestore();
const messaging = getMessaging();

/**
 * Sends a push notification to [uid]'s registered device, if any.
 * Notification bodies deliberately never include message content —
 * only who it's from — so a locked phone's notification shade can't
 * leak a private conversation's text.
 */
async function sendToUser(uid, notification, data) {
  const tokenDoc = await db.collection("fcmTokens").doc(uid).get();
  const token = tokenDoc.exists ? tokenDoc.data().token : null;
  if (!token) return;

  try {
    await messaging.send({
      token,
      notification,
      data,
      android: {priority: "high"},
    });
  } catch (err) {
    // A dead token (app uninstalled, data cleared) fails every future
    // send the same way — delete it so this isn't retried forever.
    if (err.code === "messaging/registration-token-not-registered") {
      await tokenDoc.ref.delete();
    } else {
      logger.error("Failed to send notification", err);
    }
  }
}

async function displayNameFor(uid) {
  const doc = await db.collection("profiles").doc(uid).get();
  const name = doc.exists ? doc.data().displayName : null;
  return name && name.trim().length > 0 ? name : "Someone";
}

exports.onMessageCreated = onDocumentCreated("messages/{messageId}", async (event) => {
  const message = event.data && event.data.data();
  if (!message || !message.recipientId || !message.senderId) return;

  const senderName = await displayNameFor(message.senderId);
  await sendToUser(
      message.recipientId,
      {title: senderName, body: "Sent you a message"},
      {type: "message", otherUserId: message.senderId},
  );
});

exports.onCallCreated = onDocumentCreated("calls/{callId}", async (event) => {
  const call = event.data && event.data.data();
  if (!call || call.status !== "ringing" || !call.calleeId || !call.callerId) return;

  const callerName = await displayNameFor(call.callerId);
  await sendToUser(
      call.calleeId,
      {title: "Incoming call", body: `${callerName} is calling you`},
      {type: "call", callId: event.params.callId, callerId: call.callerId},
  );
});
