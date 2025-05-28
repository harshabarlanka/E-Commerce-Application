import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shop/NavigationBar/ProfileScreen/shopping_discount.dart';
import 'package:shop/model/bag_item.dart';

class BagProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _bag = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  List<Map<String, dynamic>> get bag => _bag;
  bool get isLoading => _isLoading;
  Coupon? _appliedCoupon;
  Coupon? get appliedCoupon => _appliedCoupon;

  void applyCoupon(Coupon coupon) {
    _appliedCoupon = coupon;
    notifyListeners();
  }

  double get discountAmount {
    if (_appliedCoupon != null) {
      return (totalPrice * _appliedCoupon!.discountPercent) / 100;
    }
    return 0;
  }

  double get totalAfterDiscount {
    return totalPrice - discountAmount;
  }

  void clearCoupon() {
    _appliedCoupon = null;
    notifyListeners();
  }

  double get totalPrice {
    return _bag.fold(
      0.0,
      (sum, item) => sum + (item['price'] * item['quantity']),
    );
  }

  void validateAppliedCoupon() {
    if (_appliedCoupon != null && totalPrice < _appliedCoupon!.minAmount) {
      _appliedCoupon = null;
      notifyListeners();
    }
  }

  List<BagItem> get groupedBagItems {
    return _bag.map((item) => BagItem.fromMap(item)).toList();
  }

  // Load bag from Firestore
  Future<void> loadBag() async {
    final user = _auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('bag')
        .get();

    _bag.clear();
    for (var doc in snapshot.docs) {
      _bag.add(doc.data());
    }

    _isLoading = false;
    notifyListeners();
  }

  // Add product to bag
  Future<void> addToBag(Map<String, dynamic> product) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('bag')
        .doc(product['id']);

    // Check if the product already exists in the bag
    final existingProductDoc = await docRef.get();
    if (existingProductDoc.exists) {
      // If product exists, update the quantity
      int newQuantity = existingProductDoc['quantity'] + 1;

      // Update Firestore and local bag list
      await docRef.update({'quantity': newQuantity});
      final index = _bag.indexWhere((item) => item['id'] == product['id']);
      if (index != -1) {
        _bag[index]['quantity'] = newQuantity;
      }
    } else {
      // If product doesn't exist, add it
      await docRef.set(product);
      _bag.add(product);
    }
    validateAppliedCoupon();
    notifyListeners();
  }

  // Remove product from bag
  Future<void> removeItem(String productId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('bag')
        .doc(productId)
        .delete();

    _bag.removeWhere((item) => item['id'] == productId);
    validateAppliedCoupon();
    notifyListeners();
  }

  // Increase quantity of a product in the bag
  Future<void> increaseQuantity(String productId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final index = _bag.indexWhere((item) => item['id'] == productId);
    if (index != -1) {
      _bag[index]['quantity'] += 1;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('bag')
          .doc(productId)
          .update({'quantity': _bag[index]['quantity']});

      notifyListeners();
    }
  }

  // Decrease quantity of a product in the bag
  Future<void> decreaseQuantity(String productId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final index = _bag.indexWhere((item) => item['id'] == productId);
    if (index != -1 && _bag[index]['quantity'] > 1) {
      _bag[index]['quantity'] -= 1;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('bag')
          .doc(productId)
          .update({'quantity': _bag[index]['quantity']});

      notifyListeners();
    }
  }

  // Clear the cart after placing an order
  Future<void> clearCart() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Delete all products from Firestore bag collection
    final batch = _firestore.batch();
    final bagCollection =
        _firestore.collection('users').doc(user.uid).collection('bag');
    final snapshot = await bagCollection.get();

    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    // Commit the batch operation
    await batch.commit();

    // Clear local bag list
    _bag.clear();
    _appliedCoupon = null;
    notifyListeners();
  }
}
