import 'package:flutter/material.dart';
import 'dart:math'; // For generating random IDs

class ItemManagementScreen extends StatefulWidget {
  final List<Map<String, dynamic>> hotkeys;

  ItemManagementScreen({required this.hotkeys});

  @override
  _ItemManagementScreenState createState() => _ItemManagementScreenState();
}

class _ItemManagementScreenState extends State<ItemManagementScreen> {
  String? selectedHotkey;
  List<Map<String, dynamic>> subItems = [];
  String? selectedSubItemId; // Track item by ID

  // Controllers for item details
  final TextEditingController itemNameController = TextEditingController();
  final TextEditingController itemPriceController = TextEditingController();
  final TextEditingController itemStockController = TextEditingController();

  @override
  void dispose() {
    // Dispose of controllers
    itemNameController.dispose();
    itemPriceController.dispose();
    itemStockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Items'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<String>(
              hint: const Text("Select Hotkey"),
              value: selectedHotkey,
              onChanged: (String? newValue) {
                setState(() {
                  selectedHotkey = newValue;
                  // Load existing subItems for the selected hotkey
                  final selectedHotkeyData = widget.hotkeys.firstWhere(
                    (hotkey) => hotkey['hotkey'] == selectedHotkey,
                    orElse: () => {'subItems': []},
                  );
                  subItems = List<Map<String, dynamic>>.from(
                    selectedHotkeyData['subItems'] ?? [],
                  );
                });
              },
              items: widget.hotkeys.map<DropdownMenuItem<String>>((hotkey) {
                return DropdownMenuItem<String>(
                  value: hotkey['hotkey'],
                  child: Text('${hotkey['hotkey']} - ${hotkey['item']}'),
                );
              }).toList(),
            ),
            TextField(
              controller: itemNameController,
              decoration: const InputDecoration(labelText: "Item Name"),
            ),
            TextField(
              controller: itemPriceController,
              decoration: const InputDecoration(labelText: "Item Price"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: itemStockController,
              decoration: const InputDecoration(labelText: "Stock"),
              keyboardType: TextInputType.number,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _addOrUpdateSubItem,
                  child: Text(selectedSubItemId == null ? 'Add Sub-Item' : 'Update Sub-Item'),
                ),
                if (selectedSubItemId != null)
                  ElevatedButton(
                    onPressed: _cancelUpdate,
                    child: const Text('Cancel Update'),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Sub-Items:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: subItems.length,
                itemBuilder: (context, index) {
                  final subItem = subItems[index];
                  return ListTile(
                    title: Text(
                      '${subItem['name']} - \$${subItem['price'].toStringAsFixed(2)} (Stock: ${subItem['stock']})',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            setState(() {
                              selectedSubItemId = subItem['id']; // Use item ID
                              itemNameController.text = subItem['name'];
                              itemPriceController.text = subItem['price'].toString();
                              itemStockController.text = subItem['stock'].toString();
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            _deleteSubItem(subItem['id']); // Delete by ID
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Generate a unique item ID
  String _generateUniqueId() {
    return Random().nextInt(1000000).toString(); // Simple random ID generator
  }

  void _addOrUpdateSubItem() {
    if (selectedHotkey != null &&
        itemNameController.text.isNotEmpty &&
        itemPriceController.text.isNotEmpty &&
        double.tryParse(itemPriceController.text) != null) {
      
      int stock = itemStockController.text.isNotEmpty
          ? int.tryParse(itemStockController.text) ?? 0
          : 0;

      setState(() {
        final newItem = {
          'id': selectedSubItemId ?? _generateUniqueId(), // Add unique ID
          'name': itemNameController.text,
          'price': double.parse(itemPriceController.text),
          'stock': stock,
        };

        if (selectedSubItemId == null) {
          // Add new sub-item
          subItems.add(newItem);
        } else {
          // Update existing sub-item by ID
          final index = subItems.indexWhere((item) => item['id'] == selectedSubItemId);
          if (index != -1) {
            subItems[index] = newItem;
          }
          selectedSubItemId = null; // Reset after update
        }

        // Clear input fields
        itemNameController.clear();
        itemPriceController.clear();
        itemStockController.clear();

        _updateHotkeySubItems();
      });
    } else {
      // Handle invalid input case
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Invalid Input'),
            content: const Text('Please select a hotkey, provide a valid name, and enter a valid price.'),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                },
              ),
            ],
          );
        },
      );
    }
  }

  void _cancelUpdate() {
    setState(() {
      selectedSubItemId = null; // Cancel the update mode
      itemNameController.clear();
      itemPriceController.clear();
      itemStockController.clear();
    });
  }

  // Delete sub-item by ID
  void _deleteSubItem(String id) {
    setState(() {
      subItems.removeWhere((item) => item['id'] == id); // Remove by ID
      _updateHotkeySubItems();
    });
  }

  void _updateHotkeySubItems() {
    final hotkeyIndex = widget.hotkeys.indexWhere((hotkey) => hotkey['hotkey'] == selectedHotkey);
    if (hotkeyIndex != -1) {
      widget.hotkeys[hotkeyIndex]['subItems'] = subItems; // Update sub-items
    }
  }
}
