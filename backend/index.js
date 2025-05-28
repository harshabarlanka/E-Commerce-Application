const express = require("express");
const cors = require("cors");
require("dotenv").config();
const admin = require("firebase-admin");

const { createShipment } = require("./bluedart");
const { trackShipment } = require("./tracker");
const { sendNotificationToUser } = require("./notifications"); // Notification function
const { updatePurchaseCount } = require("./updatePurchaseCount");

// Firebase Admin Initialization
// admin.initializeApp();
const db = admin.firestore();

const app = express();
app.use(cors());
app.use(express.json());

// ✅ Listen for new orders with status "Processing"
db.collection("orders")
  .where("status", "==", "Processing")
  .onSnapshot((snapshot) => {
    snapshot.docChanges().forEach(async (change) => {
      if (change.type === "added") {
        const orderId = change.doc.id;
        const orderData = change.doc.data();

        // ✅ Update purchase count in 'products' collection
        await updatePurchaseCount(orderData.items);

        // ✅ Create shipment if not already created
        if (!orderData.shipping?.trackingId) {
          try {
            const shipment = await createShipment(orderId, orderData);

            await db
              .collection("orders")
              .doc(orderId)
              .update({
                status: shipment.status,
                trackingId: shipment.tracking_id,
                shipping: {
                  ...orderData.shipping,
                  trackingId: shipment.tracking_id,
                },
              });

            console.log(
              `🚚 Shipment created for ${orderId}: ${shipment.tracking_id}`
            );
          } catch (error) {
            console.error(
              `❌ Failed to create shipment for ${orderId}:`,
              error.message
            );
          }
        } else {
          console.log(`🚚 Shipment already exists for ${orderId}`);
        }
      }
    });
  });

// ✅ Listen for order status changes to send user notifications
db.collection("orders")
  .where("status", "in", [
    "Shipped",
    "In Transit",
    "Out for Delivery",
    "Delivered",
  ])
  .onSnapshot((snapshot) => {
    snapshot.docChanges().forEach(async (change) => {
      if (change.type === "modified") {
        const orderId = change.doc.id;
        const orderData = change.doc.data();
        const status = orderData.status;
        const userId = orderData.userId;

        try {
          await sendNotificationToUser(
            userId,
            "Order Status Update",
            `Your package status is now: ${status}`
          );
          console.log(
            `📲 Notification sent to user ${userId} for order ${orderId}`
          );
        } catch (error) {
          console.error(
            `❌ Failed to send notification for order ${orderId}:`,
            error.message
          );
        }
      }
    });
  });

// ✅ Poll tracking status every 30 minutes
setInterval(async () => {
  try {
    const snapshot = await db
      .collection("orders")
      .where("status", "in", ["Shipped", "In Transit"])
      .get();

    snapshot.forEach((doc) => {
      const data = doc.data();
      if (data.shipping?.trackingId) {
        trackShipment(doc.id, data.shipping.trackingId);
      }
    });

    console.log("📦 Tracking update cycle complete");
  } catch (error) {
    console.error("❌ Error during tracking status polling:", error.message);
  }
}, 1000 * 60 * 30); // Every 30 minutes

// ✅ Start Express server
app.listen(3000, () => {
  console.log("🚀 Server started on http://localhost:3000");
});
