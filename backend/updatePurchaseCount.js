const admin = require("firebase-admin");
const db = admin.firestore();

const updatePurchaseCount = async (items) => {
  if (!Array.isArray(items)) return;

  const batch = db.batch();

  for (const item of items) {
    const productId = item.originalId;
    const quantity = item.quantity || 1;
    const selectedSize = item.size;

    if (!productId || !selectedSize) continue;

    const productRef = db.collection("products").doc(productId);

    try {
      const doc = await productRef.get();
      if (!doc.exists) {
        console.warn(`Product ${productId} does not exist`);
        continue;
      }

      const data = doc.data();
      const sizes = data.sizes || [];

      console.log(`Before update - Product: ${productId}, sizes:`, sizes);

      const updatedSizes = sizes.map((sizeObj) => {
        if (sizeObj.size.toString().trim() === selectedSize.toString().trim()) {
          const currentStock = sizeObj.stock || 0;
          if (currentStock < quantity) {
            console.warn(
              `Insufficient stock for product ${productId}, size ${selectedSize}. Current: ${currentStock}, requested: ${quantity}`
            );
          }
          return {
            ...sizeObj,
            stock: Math.max(0, currentStock - quantity),
          };
        }
        return sizeObj;
      });

      console.log(`After update - Product: ${productId}, sizes:`, updatedSizes);

      batch.update(productRef, {
        purchaseCount: admin.firestore.FieldValue.increment(quantity),
        sizes: updatedSizes,
      });
    } catch (error) {
      console.error(`❌ Failed updating product ${productId}:`, error.message);
    }
  }

  try {
    await batch.commit();
    console.log("✅ Stock and purchaseCount updated successfully.");
  } catch (error) {
    console.error("❌ Batch commit failed:", error.message);
  }
};

module.exports = {
  updatePurchaseCount,
};
