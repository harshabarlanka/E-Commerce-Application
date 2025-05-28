// ignore_for_file: file_names, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddressInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;

  const AddressInputField({
    super.key,
    required this.label,
    required this.controller,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: validator,
      ),
    );
  }
}

class SavedAddressScreen extends StatefulWidget {
  const SavedAddressScreen({super.key});

  @override
  State<SavedAddressScreen> createState() => _SavedAddressScreenState();
}

class _SavedAddressScreenState extends State<SavedAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController pincodeController = TextEditingController();
  final TextEditingController countryController = TextEditingController();

  String? selectedType;
  Map<String, Map<String, dynamic>> allSavedAddresses = {};

  @override
  void initState() {
    super.initState();
    _fetchAllSavedAddresses();
  }

  Future<void> _fetchAllSavedAddresses() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('address')
          .get();

      final addresses = <String, Map<String, dynamic>>{};
      for (var doc in snapshot.docs) {
        addresses[doc.id] = doc.data();
      }

      setState(() {
        allSavedAddresses = addresses;
      });
    }
  }

  Future<void> _saveAddress() async {
    if (selectedType == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final addressData = {
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'address': addressController.text.trim(),
        'city': cityController.text.trim(),
        'state': stateController.text.trim(),
        'pincode': pincodeController.text.trim(),
        'country': countryController.text.trim(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('address')
          .doc(selectedType!.toLowerCase())
          .set(addressData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$selectedType address saved successfully!')),
      );

      setState(() {
        allSavedAddresses[selectedType!.toLowerCase()] = addressData;
        selectedType = null;
      });

      _clearFields();
    }
  }

  Future<void> _deleteAddress(String type) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('address')
          .doc(type.toLowerCase())
          .delete();

      setState(() {
        allSavedAddresses.remove(type.toLowerCase());
        if (selectedType?.toLowerCase() == type.toLowerCase()) {
          selectedType = null;
          _clearFields();
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$type address deleted')),
      );
    }
  }

  void _clearFields() {
    nameController.clear();
    phoneController.clear();
    addressController.clear();
    cityController.clear();
    stateController.clear();
    pincodeController.clear();
    countryController.clear();
  }

  void _prefillFields(Map<String, dynamic> data) {
    nameController.text = data['name'] ?? '';
    phoneController.text = data['phone'] ?? '';
    addressController.text = data['address'] ?? '';
    cityController.text = data['city'] ?? '';
    stateController.text = data['state'] ?? '';
    pincodeController.text = data['pincode'] ?? '';
    countryController.text = data['country'] ?? '';
  }

  Widget _buildSavedAddressCard(String type, Map<String, dynamic> data) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "$type Address",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.black),
                  onPressed: () => _deleteAddress(type),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildAddressRow("Name", data['name']),
            _buildAddressRow("Phone", data['phone']),
            _buildAddressRow("Address", data['address']),
            _buildAddressRow("City", data['city']),
            _buildAddressRow("State", data['state']),
            _buildAddressRow("Postal Code", data['pincode']),
            _buildAddressRow("Country", data['country']),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressRow(String label, String? value) {
    return value != null
        ? Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Text("$label: $value"),
          )
        : const SizedBox.shrink();
  }

  Widget _buildTypeButton(String type, IconData icon) {
    final typeKey = type.toLowerCase();
    final isSaved = allSavedAddresses.containsKey(typeKey);
    final isSelected = selectedType?.toLowerCase() == typeKey;

    return Expanded(
      child: ElevatedButton.icon(
        onPressed: () {
          setState(() {
            selectedType = type;
            if (isSaved) {
              _prefillFields(allSavedAddresses[typeKey]!);
            } else {
              _clearFields();
            }
          });
        },
        icon: Icon(icon),
        label: Text(type),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSaved
              ? Colors.grey.shade400
              : (isSelected ? Colors.black : Colors.black54),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildAddressForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AddressInputField(
          label: 'Name',
          controller: nameController,
          validator: (val) => val == null || val.isEmpty ? 'Name is required' : null,
        ),
        AddressInputField(
          label: 'Phone Number',
          controller: phoneController,
          validator: (val) => val == null || val.isEmpty ? 'Phone is required' : null,
        ),
        AddressInputField(
          label: 'Address Line 1',
          controller: addressController,
          validator: (val) => val == null || val.isEmpty ? 'Address is required' : null,
        ),
        AddressInputField(
          label: 'City',
          controller: cityController,
          validator: (val) => val == null || val.isEmpty ? 'City is required' : null,
        ),
        AddressInputField(
          label: 'State',
          controller: stateController,
          validator: (val) => val == null || val.isEmpty ? 'State is required' : null,
        ),
        AddressInputField(
          label: 'Postal Code',
          controller: pincodeController,
          validator: (val) =>
              val == null || val.isEmpty ? 'Postal Code is required' : null,
        ),
        AddressInputField(
          label: 'Country',
          controller: countryController,
          validator: (val) => val == null || val.isEmpty ? 'Country is required' : null,
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _saveAddress();
              }
            },
            icon: Icon(
              selectedType == 'Home'
                  ? Icons.home
                  : selectedType == 'Work'
                      ? Icons.work
                      : Icons.location_on,
              color: Colors.white,
            ),
            label: Text(
              'Save $selectedType Address',
              style: const TextStyle(
                fontFamily: 'Serif',
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
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
          "Saved Address",
          style: TextStyle(
            fontFamily: 'Serif',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (allSavedAddresses.containsKey("home"))
                  _buildSavedAddressCard("Home", allSavedAddresses["home"]!),
                if (allSavedAddresses.containsKey("work"))
                  _buildSavedAddressCard("Work", allSavedAddresses["work"]!),
                if (allSavedAddresses.containsKey("other"))
                  _buildSavedAddressCard("Other", allSavedAddresses["other"]!),
                Row(
                  children: [
                    _buildTypeButton('Home', Icons.home),
                    const SizedBox(width: 10),
                    _buildTypeButton('Work', Icons.work),
                    const SizedBox(width: 10),
                    _buildTypeButton('Other', Icons.location_on),
                  ],
                ),
                const SizedBox(height: 20),
                if (selectedType != null) _buildAddressForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
