const { db } = require("./firebase");
const axios = require("axios");
const xml2js = require("xml2js");
const { sendNotificationToUser } = require("./notifications");
require("dotenv").config();

const useMock = process.env.USE_MOCK === "true";

// Ordered mock statuses for sequential testing
const mockStatuses = [
  "Shipment Created (Mock)",
  "In Transit (Mock)",
  "Out for Delivery (Mock)",
  "Delivered (Mock)",
];

// Helper to get next mock status
function getNextMockStatus(currentStatus) {
  const index = mockStatuses.indexOf(currentStatus);
  if (index === -1) return mockStatuses[0]; // Start fresh if no match
  if (index >= mockStatuses.length - 1) return mockStatuses[index]; // Already at final stage
  return mockStatuses[index + 1]; // Next status in sequence
}

async function trackShipment(orderId, awb) {
  const orderDoc = await db.collection("orders").doc(orderId).get();
  const order = orderDoc.data();
  const uid = order.userId;

  if (useMock) {
    console.log(`🔍 Mock tracking for order ${orderId} with AWB ${awb}`);
    const currentStatus = order.status;
    const nextStatus = getNextMockStatus(currentStatus);

    if (nextStatus !== currentStatus) {
      await db.collection("orders").doc(orderId).update({
        status: nextStatus,
      });

      // Send notification
      await sendNotificationToUser(
        uid,
        "Order Status Update",
        `Your order ${orderId} is now: ${nextStatus}`
      );

      console.log(`🔄 Mock status updated for order ${orderId}: ${nextStatus}`);
    } else {
      console.log(`✅ Order ${orderId} already at final mock status: ${currentStatus}`);
    }

    return;
  }

  // === Real Blue Dart Tracking ===
  const xml = `
    <TrackingRequest>
      <AWBNo>${awb}</AWBNo>
      <LoginID>${process.env.BLUEDART_LOGIN_ID}</LoginID>
      <LicenseKey>${process.env.BLUEDART_LICENSE_KEY}</LicenseKey>
    </TrackingRequest>
  `;

  try {
    const response = await axios.post(
      "https://netconnect.bluedart.com/TrackingAPI/TrackingService.svc/TrackShipment",
      xml,
      { headers: { "Content-Type": "application/xml" } }
    );

    const result = await xml2js.parseStringPromise(response.data);
    const status = result.TrackingResponse?.Status?.[0] || "In Transit";

    await db.collection("orders").doc(orderId).update({
      status: status,
    });

    await sendNotificationToUser(
      uid,
      "Order Status Update",
      `Your order ${orderId} is now: ${status}`
    );

    console.log(`🔄 Status updated for order ${orderId}: ${status}`);
  } catch (err) {
    console.error(`❌ Error tracking order ${orderId}:`, err.message);
  }
}

async function simulatePeriodicUpdates() {
  const ordersSnapshot = await db.collection("orders").get();

  ordersSnapshot.forEach(async (orderDoc) => {
    const order = orderDoc.data();
    const orderId = orderDoc.id;
    const awb = order.awb || order.shipping?.trackingId || "MOCK-AWB";
    await trackShipment(orderId, awb);
  });
}

// Run tracker (every 20s for testing; increase in production)
setInterval(simulatePeriodicUpdates,  30 * 60 * 1000);

module.exports = { trackShipment };
