const { onRequest } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendPush = onRequest(
  { cors: true, region: "asia-northeast3" },
  async (req, res) => {
    if (req.method !== "POST") {
      return res.status(405).send("Method Not Allowed");
    }

    const authHeader = req.headers.authorization;
    const expectedToken = process.env.WEBHOOK_SECRET;

    if (expectedToken && authHeader !== `Bearer ${expectedToken}`) {
      return res.status(401).send("Unauthorized");
    }

    const { fcmToken, title, body, data } = req.body;

    if (!fcmToken) {
      return res.status(400).send("fcmToken is required");
    }

    try {
      const message = {
        token: fcmToken,
        notification: {
          title: title || "Oomool",
          body: body || "",
        },
        data: data || {},
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
        android: {
          priority: "high",
          notification: {
            sound: "default",
          },
        },
      };

      const response = await admin.messaging().send(message);
      console.log("Successfully sent message:", response);
      return res.status(200).json({ success: true, messageId: response });
    } catch (error) {
      console.error("Error sending message:", error);
      return res.status(500).json({ success: false, error: error.message });
    }
  }
);
