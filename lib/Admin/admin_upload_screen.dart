// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class AdminUploadScreen extends StatefulWidget {
  const AdminUploadScreen({super.key});

  @override
  State<AdminUploadScreen> createState() => _AdminUploadScreenState();
}

class _AdminUploadScreenState extends State<AdminUploadScreen> {
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _imageUrl1Controller = TextEditingController();
  final TextEditingController _imageUrl2Controller = TextEditingController();
  final TextEditingController _imageUrl3Controller = TextEditingController();

  final List<String> _genderOptions = [
    'Women',
    'Men',
    'Kids',
    'Jewellery',
    'Shoes'
  ];
  String? _selectedGender;

  final List<String> _categoryOptions = [
    'jeans',
    'shoes',
    'tshirts',
    'shirts',
    'saree',
    'kurta',
    'sweater',
    'jacket',
    'hoodies',
    'trousers',
    'leggings',
    'shorts',
    'default',
  ];
  String? _selectedCategory;

  final Map<String, List<String>> _sizeOptions = {
    'jeans': ['28', '30', '32', '34', '36', '38', '40', '42', '44'],
    'shoes': ['4', '5', '6', '7', '8', '9', '10', '11', '12'],
    'tshirts': ['XS', 'S', 'M', 'L', 'XL', 'XXL', '3XL'],
    'shirts': ['38', '39', '40', '42', '44', '46', '48', '50'],
    'saree': ['Free Size'],
    'kurta': ['S', 'M', 'L', 'XL', 'XXL', '3XL'],
    'sweater': ['S', 'M', 'L', 'XL', 'XXL', '3XL'],
    'jacket': ['S', 'M', 'L', 'XL', 'XXL', '3XL'],
    'hoodies': ['S', 'M', 'L', 'XL', 'XXL', '3XL'],
    'trousers': ['28', '30', '32', '34', '36', '38', '40', '42', '44'],
    'leggings': ['M', 'L', 'XL', '2XL', '3XL', '4XL', '5XL', '6XL'],
    'shorts': ['28', '30', '32', '34', '36', '38', '40', '42', '44'],
    'default': ['S', 'M', 'L', 'XL', 'XXL'],
  };

  List<String> _availableSizes = [];
  Map<String, bool> _selectedSizes = {};
  final Map<String, TextEditingController> _stockControllers = {};

  bool _loading = false;

  // Reels
  List<Map<String, dynamic>> _reels = [];
  String? _selectedReelId;

  @override
  void initState() {
    super.initState();
    _fetchReels();
  }

  Future<void> _fetchReels() async {
    final snapshot = await FirebaseFirestore.instance.collection('reels').get();
    setState(() {
      _reels = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? 'Untitled',
        };
      }).toList();
    });
  }

  void _updateSizeOptions(String category) {
    String key = _sizeOptions.containsKey(category.toLowerCase())
        ? category.toLowerCase()
        : 'default';
    _availableSizes = _sizeOptions[key]!;
    _selectedSizes = {for (var size in _availableSizes) size: false};
    _stockControllers.clear();
    setState(() {});
  }

  Future<void> _uploadProduct() async {
    if (_brandController.text.isEmpty ||
        _descController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _selectedCategory == null ||
        _selectedGender == null ||
        _colorController.text.isEmpty ||
        _imageUrl1Controller.text.isEmpty ||
        _imageUrl2Controller.text.isEmpty ||
        _imageUrl3Controller.text.isEmpty ||
        !_selectedSizes.containsValue(true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please fill all fields and select sizes")),
      );
      return;
    }

    for (var entry in _selectedSizes.entries.where((e) => e.value)) {
      final controller = _stockControllers[entry.key];
      if (controller == null ||
          controller.text.isEmpty ||
          int.tryParse(controller.text) == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Please enter valid stock for size ${entry.key}")),
        );
        return;
      }
    }

    setState(() => _loading = true);

    try {
      String id = const Uuid().v4();

      await FirebaseFirestore.instance.collection('products').doc(id).set({
        'id': id,
        'brand': _brandController.text.trim(),
        'description': _descController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'category': _selectedCategory!,
        'color': _colorController.text.trim(),
        'gender': _selectedGender!,
        'sizes': _selectedSizes.entries
            .where((e) => e.value)
            .map((e) => {
                  'size': e.key,
                  'stock': int.parse(_stockControllers[e.key]!.text),
                })
            .toList(),
        'imageUrls': [
          _imageUrl1Controller.text.trim(),
          _imageUrl2Controller.text.trim(),
          _imageUrl3Controller.text.trim()
        ],
        'reelId': _selectedReelId,
        'timestamp': Timestamp.now(),
        'purchaseCount': 0
      });

      if (_selectedReelId != null && _selectedReelId!.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('reels')
            .doc(_selectedReelId)
            .update({
          'productIds': FieldValue.arrayUnion([id]),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Product uploaded successfully!")),
      );

      _brandController.clear();
      _descController.clear();
      _priceController.clear();
      _imageUrl1Controller.clear();
      _imageUrl2Controller.clear();
      _imageUrl3Controller.clear();
      _colorController.clear();
      _selectedCategory = null;
      _selectedGender = null;
      _selectedReelId = null;
      _selectedSizes.clear();
      _availableSizes.clear();
      _stockControllers.clear();

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: $e")),
      );
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Enter Product Details",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildTextField(_imageUrl1Controller, "Image URL 1"),
            _buildTextField(_imageUrl2Controller, "Image URL 2"),
            _buildTextField(_imageUrl3Controller, "Image URL 3"),
            _buildReelDropdown(),
            _buildTextField(_brandController, "Brand Name"),
            _buildTextField(_descController, "Description", maxLines: 3),
            _buildTextField(_priceController, "Price",
                keyboardType: TextInputType.number),
            _buildCategoryDropdown(),
            _buildTextField(_colorController, "Color (e.g. Red, Blue, Black)"),
            _buildGenderDropdown(),
            const SizedBox(height: 10),
            if (_availableSizes.isNotEmpty) _buildSizeSelection(),
            const SizedBox(height: 30),
            _loading
                ? const Center(child: CircularProgressIndicator())
                : Center(
                    child: ElevatedButton(
                      onPressed: _uploadProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 15, horizontal: 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text("Upload Product"),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    void Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        value: _selectedCategory,
        decoration: const InputDecoration(
          labelText: "Category",
          border: OutlineInputBorder(),
        ),
        items: _categoryOptions.map((category) {
          return DropdownMenuItem<String>(
            value: category,
            child: Text(category),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedCategory = value;
            _updateSizeOptions(value ?? 'default');
          });
        },
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        value: _selectedGender,
        decoration: const InputDecoration(
          labelText: "Gender",
          border: OutlineInputBorder(),
        ),
        items: _genderOptions.map((gender) {
          return DropdownMenuItem<String>(
            value: gender,
            child: Text(gender),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedGender = value;
          });
        },
      ),
    );
  }

  Widget _buildReelDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        value: _selectedReelId,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: "Reel (optional)",
          border: OutlineInputBorder(),
        ),
        items: _reels.map((reel) {
          return DropdownMenuItem<String>(
            value: reel['id'],
            child: Text('${reel['title']} (${reel['id']})'),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedReelId = value;
          });
        },
      ),
    );
  }

  Widget _buildSizeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Available Sizes",
            style: TextStyle(fontWeight: FontWeight.bold)),
        Wrap(
          spacing: 10,
          children: _availableSizes.map((size) {
            return FilterChip(
              label: Text(size),
              selected: _selectedSizes[size]!,
              onSelected: (selected) {
                setState(() {
                  _selectedSizes[size] = selected;
                  if (selected) {
                    _stockControllers[size] ??= TextEditingController();
                  } else {
                    _stockControllers.remove(size);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        if (_selectedSizes.containsValue(true))
          ..._selectedSizes.entries.where((e) => e.value).map((e) => Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: TextField(
                  controller: _stockControllers[e.key],
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Stock for size ${e.key}',
                    border: const OutlineInputBorder(),
                  ),
                ),
              )),
      ],
    );
  }
}
