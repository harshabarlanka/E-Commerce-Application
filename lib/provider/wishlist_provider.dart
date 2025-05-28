import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WishlistProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _wishlist = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false; // Add a loading state
  List<Map<String, dynamic>> get wishlist => _wishlist;
  bool get isLoading => _isLoading; // Getter for isLoading

  // Load wishlist from Firestore
  Future<void> loadWishlist() async {
    _isLoading = true; // Set loading to true when starting to load
    notifyListeners();

    final user = _auth.currentUser;
    if (user == null) {
      _isLoading = false; // Set loading to false if no user is found
      notifyListeners();
      return;
    }

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('wishlist')
        .get();

    _wishlist.clear();
    for (var doc in snapshot.docs) {
      _wishlist.add(doc.data());
    }

    _isLoading = false; // Set loading to false once data is fetched
    notifyListeners();
  }

  // Add product to wishlist
  Future<void> addToWishlist(Map<String, dynamic> product) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('wishlist')
        .doc(product['id']);

    await docRef.set(product);

    // Prevent duplicate in local list
    if (!_wishlist.any((item) => item['id'] == product['id'])) {
      _wishlist.add(product);
      notifyListeners();
    }
  }

  // Remove product from wishlist
  Future<void> removeFromWishlist(String productId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('wishlist')
        .doc(productId)
        .delete();

    _wishlist.removeWhere((item) => item['id'] == productId);
    notifyListeners();
  }

  // Check if product is in wishlist
  bool isInWishlist(String productId) {
    return _wishlist.any((item) => item['id'] == productId);
  }
}
