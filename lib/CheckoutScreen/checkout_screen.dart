// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop/NavigationBar/ProfileScreen/myorders.dart';
import 'package:shop/provider/bag_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

enum PaymentMethod { cod, razorpay }

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cod;
  final _formKey = GlobalKey<FormState>();
  late Razorpay _razorpay;
  Map<String, dynamic> _savedAddresses = {};
  String? _selectedAddressType;

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final countryController = TextEditingController();
  final pincodeController = TextEditingController();
  @override
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _razorpay = Razorpay();
      _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
      _fetchSavedAddresses();
    });
  }

  @override
  void dispose() {
    _razorpay.clear();
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    cityController.dispose();
    stateController.dispose();
    countryController.dispose();
    pincodeController.dispose();
    super.dispose();
  }

  bool isLoading = false; // Control visibility of the progress indicator
  Future<void> _fetchSavedAddresses() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final addressCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('address');

    final snapshot = await addressCollection.get();

    if (snapshot.docs.isNotEmpty) {
      setState(() {
        _savedAddresses = {
          for (var doc in snapshot.docs) doc.id: doc.data(),
        };
      });
    }
  }

  Future<void> placeOrder() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    if (!_formKey.currentState!.validate()) {
      setState(() => isLoading = false);
      return;
    }

    final cartProvider = Provider.of<BagProvider>(context, listen: false);
    final List<Map<String, dynamic>> cartItems = cartProvider.bag;
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No user is logged in")),
      );
      setState(() => isLoading = false);
      return;
    }
    final totalAfterDiscount = cartProvider.totalAfterDiscount;

    // Calculate total
    double totalAfterShipping =
        totalAfterDiscount + (cartItems.isNotEmpty ? 50.0 : 0.0);

    if (_selectedPaymentMethod == PaymentMethod.cod) {
      // Place order directly for COD
      await placeOrderToFirestore(
        user: user,
        cartItems: cartItems,
        total: totalAfterShipping,
        paymentMethod: "Cash on Delivery",
        paymentId: "",
      );
      setState(() => isLoading = false);
    } else {
      // Razorpay online payment
      var options = {
        'key': 'rzp_test_9fM9gBezvFg6fe', // your key
        'amount': (totalAfterShipping * 100).toInt(),
        'name': 'SNENH',
        'description': 'Shopping Payment',
        'prefill': {
          'contact': phoneController.text,
          'email': user.email ?? '',
        },
        'currency': 'INR',
      };

      try {
        _razorpay.open(options);
      } catch (e) {
        debugPrint('Error opening Razorpay: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment initiation failed')),
        );
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> placeOrderToFirestore({
    required User user,
    required List<Map<String, dynamic>> cartItems,
    required double total,
    required String paymentMethod,
    required String paymentId,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final Map<String, dynamic> orderData = {
        'userId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'Processing',
        'paymentMethod': paymentMethod,
        'payment_id': paymentId,
        'items': cartItems.map((item) {
          final newItem = Map<String, dynamic>.from(item);
          if (newItem['color'] is Color) {
            newItem['color'] =
                '#${(newItem['color'] as Color).value.toRadixString(16).padLeft(8, '0')}';
          }
          return newItem;
        }).toList(),
        'total': total,
      };
      orderData['shipping'] = {
        'name': nameController.text,
        'phone': phoneController.text,
        'address': addressController.text,
        'city': cityController.text,
        'state': stateController.text,
        'country': countryController.text,
        'pincode': pincodeController.text,
      };

      await FirebaseFirestore.instance.collection('orders').add(orderData);

      // Clear cart
      final cartProvider = Provider.of<BagProvider>(context, listen: false);
      await cartProvider.clearCart();

      if (context.mounted) Navigator.pop(context); // close loading dialog

      // Navigate to confirmation screen
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MyOrderScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to place order: $e")),
        );
      }
    }
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final cartProvider = Provider.of<BagProvider>(context, listen: false);
    final List<Map<String, dynamic>> cartItems = cartProvider.bag;
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) return;
    final totalAfterDiscount = cartProvider.totalAfterDiscount;
    // Calculate total again (or store in state)
    double total = totalAfterDiscount + (cartItems.isNotEmpty ? 50.0 : 0.0);

    await placeOrderToFirestore(
      user: user,
      cartItems: cartItems,
      total: total,
      paymentMethod: "Razorpay",
      paymentId: response.paymentId ?? "",
    );

    setState(() => isLoading = false);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Payment failed. Please try again.")),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("External Wallet: ${response.walletName}")),
    );
  }

  Widget buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: (value) => value!.isEmpty ? 'Please enter $label' : null,
        style: const TextStyle(fontSize: 14), // Optional: smaller text
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          border:
              const OutlineInputBorder(), // Make sure there's a consistent border
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "SnenH",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 80),
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                "Shipping Address",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),

// Dropdown for saved addresses
            if (_savedAddresses.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: "Select Saved Address",
                    isDense: true, // reduces height
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 12),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  value: _selectedAddressType,
                  items: _savedAddresses.keys.map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type[0].toUpperCase() + type.substring(1)),
                    );
                  }).toList(),
                  onChanged: (selected) {
                    setState(() {
                      _selectedAddressType = selected;
                      final selectedAddress = _savedAddresses[selected];

                      nameController.text = selectedAddress?['name'] ?? '';
                      phoneController.text = selectedAddress?['phone'] ?? '';
                      addressController.text =
                          selectedAddress?['address'] ?? '';
                      cityController.text = selectedAddress?['city'] ?? '';
                      stateController.text = selectedAddress?['state'] ?? '';
                      countryController.text =
                          selectedAddress?['country'] ?? '';
                      pincodeController.text =
                          selectedAddress?['pincode'] ?? '';
                    });
                  },
                ),
              ),
            const SizedBox(height: 10),

            buildTextField(label: 'Full Name', controller: nameController),
            buildTextField(
              label: 'Phone Number',
              controller: phoneController,
              keyboardType: TextInputType.phone,
            ),
            buildTextField(label: 'Address', controller: addressController),
            buildTextField(label: 'City', controller: cityController),
            buildTextField(label: 'State', controller: stateController),
            buildTextField(label: 'Country', controller: countryController),
            buildTextField(
              label: 'Pincode',
              controller: pincodeController,
              keyboardType: TextInputType.number,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                "Order Summary",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            Consumer<BagProvider>(
              builder: (context, cartProvider, child) {
                final products = cartProvider.bag;
                final totalAfterDiscount = cartProvider.totalAfterDiscount;
                double subtotal = totalAfterDiscount;
                double shipping = products.isNotEmpty ? 50.0 : 0.0;
                double total = subtotal + shipping;
                return Column(
                  children: [
                    ...products.map((product) => Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                child: Image.network(
                                  product['imageUrl'],
                                  height: 60,
                                  width: 60,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(product['description'] ?? '',
                                        style: const TextStyle(fontSize: 14)),
                                    const SizedBox(height: 4),
                                    Text('Size: ${product['size']}',
                                        style: const TextStyle(fontSize: 12)),
                                    Text('Qty: ${product['quantity']}',
                                        style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ),
                              Text(
                                '₹${totalAfterDiscount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(height: 7),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          _summaryRow("Items", "${products.length}"),
                          _summaryRow(
                              "Subtotal", "₹${subtotal.toStringAsFixed(2)}"),
                          _summaryRow(
                              "Shipping", "₹${shipping.toStringAsFixed(2)}"),
                          const Divider(),
                          _summaryRow("Total", "₹${total.toStringAsFixed(2)}",
                              isBold: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Column(
                      children: [
                        ListTile(
                          title: const Text('Cash on Delivery'),
                          leading: Radio<PaymentMethod>(
                            value: PaymentMethod.cod,
                            groupValue: _selectedPaymentMethod,
                            onChanged: (val) {
                              setState(() => _selectedPaymentMethod = val!);
                            },
                          ),
                        ),
                        ListTile(
                          title: const Text('UPI / Cards (Online Payment)'),
                          leading: Radio<PaymentMethod>(
                            value: PaymentMethod.razorpay,
                            groupValue: _selectedPaymentMethod,
                            onChanged: (val) {
                              setState(() => _selectedPaymentMethod = val!);
                            },
                          ),
                        ),
                        // Your existing Place Order button here
                      ],
                    )
                  ],
                );
              },
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: placeOrder,
            child: const Text(
              "Place Order",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String title, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
