import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shop/CheckoutScreen/checkout_screen.dart';
import 'package:shop/NavigationBar/ProfileScreen/shopping_discount.dart';
import 'package:shop/provider/bag_provider.dart';

class BagScreen extends StatefulWidget {
  const BagScreen({super.key});

  @override
  State<BagScreen> createState() => _BagScreenState();
}

class _BagScreenState extends State<BagScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<BagProvider>(context, listen: false).loadBag();
    });
  }

  void _handleCouponApplied(Coupon coupon) {
    Provider.of<BagProvider>(context, listen: false).applyCoupon(coupon);
  }

  Widget shimmerItem() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              width: 110,
              height: 140,
              decoration: const BoxDecoration(
                color: Colors.white,
                // borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 20, width: 150, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(height: 16, width: 200, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(height: 16, width: 100, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(height: 16, width: 180, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bagProvider = Provider.of<BagProvider>(context);
    final items = bagProvider.groupedBagItems;
    final total = bagProvider.totalPrice;
    final discountAmount =
        bagProvider.appliedCoupon != null ? bagProvider.discountAmount : 0.0;

    final totalAfterDiscount = bagProvider.totalAfterDiscount;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'SnenH',
          style: TextStyle(
            fontFamily: 'Serif',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: bagProvider.isLoading
                  ? ListView.builder(
                      itemCount: 3,
                      itemBuilder: (context, index) => shimmerItem(),
                    )
                  : items.isEmpty
                      ? const Center(child: Text("Your bag is empty"))
                      : ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final product = items[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 110,
                                    height: 140,
                                    decoration: BoxDecoration(
                                      // borderRadius: BorderRadius.circular(10),
                                      image: DecorationImage(
                                        image: NetworkImage(product.imageUrl),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    product.name,
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    product.description,
                                                    style: const TextStyle(
                                                        fontSize: 16),
                                                    maxLines: 2,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete),
                                              onPressed: () {
                                                bagProvider
                                                    .removeItem(product.id);
                                              },
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          "₹${(product.price * product.quantity).toStringAsFixed(2)}",
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          "Delivery by 4-5 days",
                                          style: TextStyle(
                                              fontSize: 13, color: Colors.grey),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            const Text("Size ",
                                                style: TextStyle(fontSize: 14)),
                                            Text(product.size),
                                            const Spacer(),
                                            GestureDetector(
                                              onTap: () => bagProvider
                                                  .decreaseQuantity(product.id),
                                              child: const Icon(Icons.remove),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(product.quantity.toString()),
                                            const SizedBox(width: 8),
                                            GestureDetector(
                                              onTap: () => bagProvider
                                                  .increaseQuantity(product.id),
                                              child: const Icon(Icons.add),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
            if (items.isNotEmpty && !bagProvider.isLoading)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CouponScreen(
                              onApply: _handleCouponApplied,
                              cartTotal: Provider.of<BagProvider>(context,
                                      listen: false)
                                  .totalPrice,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 18),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.local_offer,
                                  color: Colors.deepOrange),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                bagProvider.appliedCoupon != null
                                    ? "Coupon Applied :- ${bagProvider.appliedCoupon!.code}"
                                    : "View Coupons",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded,
                                size: 16, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Subtotal"),
                        Text("₹${total.toStringAsFixed(2)}"),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(bagProvider.appliedCoupon != null
                            ? "Discount (${bagProvider.appliedCoupon!.discountPercent}%)"
                            : "Discount"),
                        Text(
                          bagProvider.appliedCoupon != null
                              ? "-₹${discountAmount.toStringAsFixed(2)}"
                              : "-₹0.00",
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                    const Divider(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Total",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        Text("₹${totalAfterDiscount.toStringAsFixed(2)}",
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CheckoutScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text("CHECKOUT"),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
