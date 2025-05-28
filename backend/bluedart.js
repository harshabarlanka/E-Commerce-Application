const axios = require("axios");
const xml2js = require("xml2js");
require("dotenv").config();

const useMock = process.env.USE_MOCK === "true";

async function createShipment(orderId, order) {
  if (useMock) {
    console.log(`✅ Mocking Blue Dart shipment for order ${orderId}`);
    return {
      tracking_id: `BD-MOCK-${orderId}`,
      status: "Shipment Created (Mock)",
    };
  }
  const { shipping, items } = order;

  const xmlBuilder = new xml2js.Builder();
  const xmlPayload = xmlBuilder.buildObject({
    WayBillGenerationRequest: {
      LoginID: process.env.BLUEDART_LOGIN_ID,
      Password: process.env.BLUEDART_PASSWORD,
      Version: "1.8",
      ConsigneeName: shipping.name,
      ConsigneeAddress1: shipping.address,
      ConsigneeCity: shipping.city,
      ConsigneePincode: shipping.pincode,
      ConsigneeMobile: shipping.phone,
      ProductCode: "A",
      Pieces: items.length,
      ActualWeight: 0.5,
      CollectableAmount: 0,
      DeclaredValue: order.total,
      PickupDate: new Date().toISOString().split("T")[0],
      VendorCode: "YOUR_VENDOR_CODE", // Replace with real vendor code
      CustomerCode: process.env.BLUEDART_LOGIN_ID,
    },
  });

  try {
    const response = await axios.post(
      `${process.env.BLUEDART_API_URL}/GenerateWayBill`,
      xmlPayload,
      {
        headers: {
          "Content-Type": "application/xml",
        },
      }
    );

    const parsed = await xml2js.parseStringPromise(response.data);
    const awbNumber = parsed.WayBillGenerationResponse?.AWBNo?.[0] || "NA";

    return {
      tracking_id: awbNumber,
      status: "Shipment Created",
    };
  } catch (err) {
    console.error("❌ Blue Dart API error:", err.message);
    throw new Error("Failed to create shipment");
  }
}

module.exports = { createShipment };
