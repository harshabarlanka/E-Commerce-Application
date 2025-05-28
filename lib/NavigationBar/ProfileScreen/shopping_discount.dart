// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';

class Coupon {
  final String code;
  final int discountPercent;
  final double minAmount;

  Coupon({
    required this.code,
    required this.discountPercent,
    required this.minAmount,
  });

  factory Coupon.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Coupon(
      code: data['code'] ?? '',
      discountPercent: data['discountPercent'] ?? 0,
      minAmount: (data['minAmount'] ?? 0).toDouble(),
    );
  }
}

class CouponScreen extends StatefulWidget {
  final double? cartTotal;
  final Function(Coupon)? onApply;

  const CouponScreen({super.key, this.cartTotal, this.onApply});

  @override
  _CouponScreenState createState() => _CouponScreenState();
}

class _CouponScreenState extends State<CouponScreen> {
  final TextEditingController _controller = TextEditingController();
  String? _errorMessage;

  void _applyEnteredCoupon() async {
    final code = _controller.text.trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a coupon code'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('coupons')
        .where('code', isEqualTo: code)
        .get();

    if (snapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid coupon code: $code'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final coupon = Coupon.fromFirestore(snapshot.docs.first);
      if (widget.cartTotal != null && widget.cartTotal! >= coupon.minAmount) {
        widget.onApply?.call(coupon);
        if (mounted) Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Cart total does not meet minimum ₹${coupon.minAmount.toInt()} for coupon $code'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "COUPONS",
          style: TextStyle(
            fontFamily: 'Serif',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 45, // slightly taller for better touch target
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        hintText: 'ENTER COUPON CODE',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.black),
                        ),
                        errorText: _errorMessage,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 45,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    onPressed: _applyEnteredCoupon,
                    child: const Text(
                      'APPLY',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('AVAILABLE FOR YOU',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('coupons')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return ListView.builder(
                      itemCount: 4,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                          child: Shimmer.fromColors(
                            baseColor: Colors.grey.shade300,
                            highlightColor: Colors.grey.shade100,
                            child: Container(
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                        child: Text('No coupons available right now.'));
                  }

                  final coupons = snapshot.data!.docs
                      .map((doc) => Coupon.fromFirestore(doc))
                      .toList();

                  return ListView.builder(
                    itemCount: coupons.length,
                    itemBuilder: (context, index) {
                      final coupon = coupons[index];
                      final bool meetsCriteria = widget.cartTotal != null &&
                          widget.cartTotal! >= coupon.minAmount;
                      final bool showSavings =
                          widget.cartTotal != null && meetsCriteria;
                      final bool showShopMore = widget.cartTotal != null &&
                          widget.cartTotal! < coupon.minAmount;
                      final savings = widget.cartTotal != null
                          ? (widget.cartTotal! * coupon.discountPercent ~/ 100)
                          : null;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        shadowColor: Colors.black26,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    coupon.code,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () {
                                      if (meetsCriteria &&
                                          widget.onApply != null) {
                                        widget.onApply!(coupon);
                                        if (mounted) Navigator.pop(context);
                                      } else {
                                        Clipboard.setData(
                                            ClipboardData(text: coupon.code));
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content:
                                                  Text('Copied ${coupon.code}'),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              backgroundColor: Colors.black87,
                                              duration:
                                                  const Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    child: const Text(
                                      'APPLY',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (showSavings)
                                Text(
                                  'YOU SAVE ₹$savings',
                                  style: const TextStyle(
                                    color: Colors.deepOrange,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              if (coupon.minAmount > 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    'Flat ${coupon.discountPercent}% OFF On Purchases Above ₹${coupon.minAmount.toInt()}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              if (showShopMore)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    'SHOP FOR ₹${(coupon.minAmount - widget.cartTotal!).toInt()} MORE TO APPLY',
                                    style: const TextStyle(
                                      color: Colors.deepOrange,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
