import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FlashcardDialog extends StatefulWidget {
  final List<Map<String, dynamic>> subItems;
  final Function(String name, double quantity, double price) onAddToCart;

  const FlashcardDialog({
    Key? key,
    required this.subItems,
    required this.onAddToCart,
  }) : super(key: key);

  @override
  _FlashcardDialogState createState() => _FlashcardDialogState();
}

class _FlashcardDialogState extends State<FlashcardDialog> {
  int selectedItemIndex = 0; // Track the currently selected sub-item
  List<double> quantities = []; // List to track quantities for each sub-item
  TextEditingController searchController = TextEditingController(); // Search input controller
  List<Map<String, dynamic>> filteredSubItems = []; // List for filtered items

  @override
  void initState() {
    super.initState();
    // Initialize quantity for each sub-item to 1
    quantities = List<double>.filled(widget.subItems.length, 1.0);
    filteredSubItems = widget.subItems; // Initially, all items are filtered
    // Add a listener for keyboard events
    RawKeyboard.instance.addListener(_handleKeyPress);
    // Add a listener for the search text field
    searchController.addListener(_filterSubItems);
  }

  @override
  void dispose() {
    // Remove the listener when the dialog is disposed
    RawKeyboard.instance.removeListener(_handleKeyPress);
    searchController.dispose(); // Dispose of the search controller
    super.dispose();
  }

  void _filterSubItems() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredSubItems = widget.subItems.where((item) {
        return item['name'].toLowerCase().contains(query) || // Filter by name
               item['price'].toString().contains(query); // Filter by price
      }).toList();
      // Reset selected index if the new list is empty
      if (filteredSubItems.isEmpty) {
        selectedItemIndex = 0;
      } else {
        selectedItemIndex = selectedItemIndex >= filteredSubItems.length ? 0 : selectedItemIndex;
      }
    });
  }

  void _handleKeyPress(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      // Check for arrow key presses to navigate between sub-items
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() {
          if (selectedItemIndex > 0) {
            selectedItemIndex--; // Move to the previous sub-item
          }
        });
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          if (selectedItemIndex < filteredSubItems.length - 1) {
            selectedItemIndex++; // Move to the next sub-item
          }
        });
      }
      // Use "+" on numpad to increase quantity
      else if (event.logicalKey == LogicalKeyboardKey.numpadAdd) {
        setState(() {
          quantities[selectedItemIndex]++; // Increase quantity for the selected sub-item
        });
      }
      // Use "-" on numpad to decrease quantity
      else if (event.logicalKey == LogicalKeyboardKey.numpadSubtract) {
        setState(() {
          if (quantities[selectedItemIndex] > 1) {
            quantities[selectedItemIndex]--; // Decrease quantity for the selected sub-item
          }
        });
      }
      // Use Enter key to add sub-item to cart
      else if (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.numpadEnter) {
        _addToCart(); // Add to cart without closing the dialog
      }
      // Use Escape key to close the flashcard dialog
      else if (event.logicalKey == LogicalKeyboardKey.escape) {
        Navigator.of(context).pop(); // Close the dialog when Esc is pressed
      }
    }
  }

  void _addToCart() {
    // Check if requested quantity exceeds available stock
    if (quantities[selectedItemIndex] > filteredSubItems[selectedItemIndex]['stock']) {
      // Show an error message for insufficient stock
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Insufficient stock available for ${filteredSubItems[selectedItemIndex]['name']}'),
        backgroundColor: Colors.red,
      ));
    } else {
      // Decrease stock based on quantity
      setState(() {
        filteredSubItems[selectedItemIndex]['stock'] -= quantities[selectedItemIndex];
      });

      // Call the onAddToCart function with the selected item's name, quantity, and price
      widget.onAddToCart(
        filteredSubItems[selectedItemIndex]['name'],
        quantities[selectedItemIndex],
        filteredSubItems[selectedItemIndex]['price'] * quantities[selectedItemIndex], // Calculate price based on quantity
      );

      // Show a success message for adding the item to the cart
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${filteredSubItems[selectedItemIndex]['name']} added to cart!'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sub-Items'), // Title for the dialog
      content: SizedBox(
        width: 400, // Adjust width as needed
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search bar
            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: 'Search',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Display the selected sub-item with quantity adjustment
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(filteredSubItems.isNotEmpty ? filteredSubItems[selectedItemIndex]['name'] : 'No items found'),
                Text('Stock: ${filteredSubItems.isNotEmpty ? filteredSubItems[selectedItemIndex]['stock'] : 0}'),
                Text('Price: \$${(filteredSubItems.isNotEmpty ? (filteredSubItems[selectedItemIndex]['price'] * quantities[selectedItemIndex]) : 0).toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 16),
            // Quantity adjustment for the selected sub-item
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    if (quantities[selectedItemIndex] > 1) {
                      setState(() {
                        quantities[selectedItemIndex]--; // Decrease quantity for the selected sub-item
                      });
                    }
                  },
                ),
                // Manual entry for quantity
                Container(
                  width: 80, // Adjust width as needed to display the number
                  child: TextField(
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(vertical: 5.0),
                    ),
                    onChanged: (value) {
                      // Parse the value and update quantity
                      double parsedValue = double.tryParse(value) ?? 1.0;
                      setState(() {
                        quantities[selectedItemIndex] = parsedValue.clamp(1.0, double.infinity);
                      });
                    },
                    controller: TextEditingController(text: quantities[selectedItemIndex].toString()),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    setState(() {
                      quantities[selectedItemIndex]++; // Increase quantity for the selected sub-item
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Display sub-item navigation instructions
            const Text('Use the up and down arrows to navigate through the sub-items.'),
            const SizedBox(height: 8),
            // Show all filtered sub-items with highlighting the selected one
            Expanded(
              child: ListView.builder(
                itemCount: filteredSubItems.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(filteredSubItems[index]['name']),
                        Text('Price: \$${(filteredSubItems[index]['price'] * quantities[index]).toStringAsFixed(2)}'),
                      ],
                    ),
                    tileColor: selectedItemIndex == index ? Colors.blue[100] : null, // Highlight selected item
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
