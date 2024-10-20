// lib/models/cart.dart

class CartItem {
  final String id;
  final String name;
  final double price;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
  });
}

class Cart {
  List<CartItem> items = []; // List to store cart items

  // Method to add an item to the cart
  void addItem(CartItem item) {
    items.add(item);
  }

  // Method to remove an item from the cart by its ID
  void removeItem(String id) {
    items.removeWhere((item) => item.id == id);
  }

  // Method to calculate the total price of items in the cart
  double getTotalPrice() {
    double total = 0;
    for (var item in items) {
      total += item.price;
    }
    return total;
  }

  // Method to clear the cart
  void clear() {
    items.clear();
  }
}
