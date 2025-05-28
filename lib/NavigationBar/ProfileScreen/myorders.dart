import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shop/NavigationBar/HomePage/mainScreen.dart';
import 'package:shop/product_details/reviewScreen/reviewSection.dart';

class MyOrderScreen extends StatelessWidget {
  const MyOrderScreen({super.key});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'returned':
        return Colors.blue;
      default:
        return Colors.orange; // processing
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Icons.check_circle_outline;
      case 'cancelled':
        return Icons.cancel_outlined;
      case 'returned':
        return Icons.undo_outlined;
      default:
        return Icons.access_time_outlined; // processing
    }
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
        'status': newStatus,
      });
    } catch (e) {
      print("Error updating order status: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Please log in to view your orders")),
      );
    }

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const MainScreen()),
              (route) => false,
            );
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: user.email == 'snenh2025@gmail.com'
            ? FirebaseFirestore.instance
                .collection('orders')
                .snapshots() // Admin sees all orders
            : FirebaseFirestore.instance
                .collection('orders')
                .where('userId',
                    isEqualTo: user.uid) // Regular user sees only their orders
                .orderBy('timestamp', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerEffect();
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("You have no orders."));
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index].data() as Map<String, dynamic>;
              final List<dynamic> items = order['items'] ?? [];
              final total = order['total'] ?? 0;
              final status = order['status'] ?? 'Processing';
              final shipping = order['shipping'];
              final billing = order['billing'];
              String shippingDetails;

              if (shipping != null && shipping['address'] != null) {
                shippingDetails =
                    "Shipping Details: ${shipping['name'] ?? ''}, ${shipping['address'] ?? ''}";
              } else if (billing != null && billing['address'] != null) {
                shippingDetails =
                    "Billing Details: ${billing['name'] ?? ''}, ${billing['address'] ?? ''}";
              } else {
                shippingDetails = "No address details available.";
              }
              return Card(
                margin: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order Info Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Order Tracking",
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status).withOpacity(0.1),
                              border: Border.all(
                                  color: _getStatusColor(status), width: 1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: _getStatusColor(status),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(shippingDetails),
                      if (order['trackingId'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            "Tracking ID: ${order['trackingId']}",
                            style: const TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ),

                      const SizedBox(height: 12),

                      // Order Item List (No scroll, showing all items)
                      // Order Item List (No scroll, showing all items)
                      Column(
                        children: items.map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        item['imageUrl'] ?? '',
                                        width: 60,
                                        height: 70,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(item['description'] ?? 'No Name',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 6),
                                          Text(
                                              "Size: ${item['size']}, Qty: ${item['quantity']}"),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text("₹${item['price']}",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),

                                // ✅ Show ReviewSection only if order is delivered & not admin
                                if (status == 'Delivered (Mock)' &&
                                    user.email != 'snenh2025@gmail.com') ...[
                                  const SizedBox(height: 8),
                                  ReviewSection(
                                    productId: item['originalId'] ??
                                        '', // ← Get correct product ID
                                    userId: user.uid,
                                  ),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                      ),

                      // Total Amount
                      Text("Total: ₹${total.toStringAsFixed(2)}",
                          style: const TextStyle(fontWeight: FontWeight.bold)),

                      // Admin status update button
                      if (user.email ==
                          'snenh2025@gmail.com') // Only for admin users
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: Icon(_getStatusIcon(status)),
                              onPressed: () {
                                // Display status update options
                                _showStatusDialog(
                                    context, orders[index].id, status);
                              },
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Admin dialog to update the status of the order
  void _showStatusDialog(
      BuildContext context, String orderId, String currentStatus) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String selectedStatus = currentStatus;
        return AlertDialog(
          title: const Text("Update Order Status"),
          content: DropdownButton<String>(
            value: selectedStatus,
            onChanged: (String? newValue) {
              if (newValue != null) {
                selectedStatus = newValue;
              }
            },
            items: <String>['Processing', 'Delivered', 'Cancelled', 'Returned']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _updateOrderStatus(orderId, selectedStatus);
                Navigator.of(context).pop();
              },
              child: const Text("Update"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  // Shimmer effect for loading state
  Widget _buildShimmerEffect() {
    return ListView.builder(
      itemCount: 3, // Show 3 shimmer loading rows
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Card(
            margin: const EdgeInsets.all(12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shimmer for order info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 100,
                        height: 12,
                        color: Colors.grey,
                      ),
                      Container(
                        width: 60,
                        height: 12,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 200,
                    height: 12,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 8),

                  // Shimmer for order items
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 70,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          height: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),

                  // Shimmer for total amount
                  Container(
                    width: 100,
                    height: 12,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
