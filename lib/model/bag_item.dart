class BagItem {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double price;
  final int quantity;
  final String size;

  BagItem({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.quantity,
    required this.size,
  });

  factory BagItem.fromMap(Map<String, dynamic> map) {
    return BagItem(
      id: map['id'] ?? '', // Provide a default empty string if id is null
      name: map['name'] ?? 'Unnamed Product', // Default name if null
      description: map['description'] ?? 'No description available', // Default description if null
      imageUrl: map['imageUrl'] ?? '', // Default empty string if imageUrl is null
      price: map['price'] ?? 0.0, // Default price if null
      quantity: map['quantity'] ?? 1, // Default quantity if null
      size: map['size'] ?? 'N/A', // Default size if null
    );
  }
}
