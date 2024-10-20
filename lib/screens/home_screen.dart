import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'flashcard/flashcard_dialog.dart';
import 'item_management_screen.dart';
import 'hotkey_management_screen.dart';
import '../widgets/cart_item_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Map<String, dynamic>> hotkeys = [];
  final List<Map<String, dynamic>> cartItems = [];
  final FocusNode _focusNode = FocusNode();
  bool _isFlashcardOpen = false; // Track the state of the flashcard

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent && !_isFlashcardOpen) { // Check if flashcard is not open
      String? hotkey;

      // Check for row number keys (1-9)
      if (event.logicalKey.keyLabel.isNotEmpty &&
          int.tryParse(event.logicalKey.keyLabel) != null &&
          int.parse(event.logicalKey.keyLabel) >= 1 &&
          int.parse(event.logicalKey.keyLabel) <= 9) {
        hotkey = event.logicalKey.keyLabel;
      }

      // Check for numpad number keys (1-9)
      if (event.logicalKey == LogicalKeyboardKey.numpad1) hotkey = '1';
      if (event.logicalKey == LogicalKeyboardKey.numpad2) hotkey = '2';
      if (event.logicalKey == LogicalKeyboardKey.numpad3) hotkey = '3';
      if (event.logicalKey == LogicalKeyboardKey.numpad4) hotkey = '4';
      if (event.logicalKey == LogicalKeyboardKey.numpad5) hotkey = '5';
      if (event.logicalKey == LogicalKeyboardKey.numpad6) hotkey = '6';
      if (event.logicalKey == LogicalKeyboardKey.numpad7) hotkey = '7';
      if (event.logicalKey == LogicalKeyboardKey.numpad8) hotkey = '8';
      if (event.logicalKey == LogicalKeyboardKey.numpad9) hotkey = '9';

      if (hotkey != null) {
        _showFlashcard(hotkey);
      }
    }
  }

  void _showFlashcard(String hotkey) {
    final selectedHotkeyData = hotkeys.firstWhere(
      (hotkeyData) => hotkeyData['hotkey'] == hotkey,
      orElse: () => {},
    );

    if (selectedHotkeyData.isNotEmpty && selectedHotkeyData['subItems'] != null) {
      final subItems = List<Map<String, dynamic>>.from(selectedHotkeyData['subItems']);
      _isFlashcardOpen = true; // Set flashcard open state

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return RawKeyboardListener(
            focusNode: FocusNode(), // Create a new focus node for the flashcard
            onKey: (event) {
              // Handle input for quantity adjustment or any specific functionality within the flashcard
              if (event is RawKeyDownEvent) {
                // Handle key events specific to the flashcard here
              }
            },
            child: FlashcardDialog(
              subItems: subItems,
              onAddToCart: (itemName, quantity, price) {
                _addToCart({
                  'name': itemName,
                  'price': price,
                  'quantity': quantity,
                });
              },
            ),
          );
        },
      ).then((_) {
        _isFlashcardOpen = false; // Reset flashcard open state when closed
      });
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Flashcard'),
            content: const Text('No sub-items found for this hotkey.'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    }
  }

  void _addToCart(Map<String, dynamic> item) {
    setState(() {
      cartItems.add(item);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chandu'),
      ),
      body: RawKeyboardListener(
        focusNode: _focusNode,
        onKey: _handleKeyEvent,
        autofocus: true,
        child: GestureDetector(
          onTap: () {
            _focusNode.requestFocus();
          },
          child: Row(
            children: [
              Expanded(
                flex: 5, // Change flex to adjust the ratio
                child: Container(
                  color: Colors.grey[850],
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Assigned Hotkeys:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: hotkeys.map((hotkey) {
                          return GestureDetector(
                            onTap: () => _showFlashcard(hotkey['hotkey']),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blueAccent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.black, width: 2),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                              child: Text(
                                '${hotkey['hotkey']} - ${hotkey['item']}',
                                style: const TextStyle(color: Colors.white, fontSize: 16),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _navigateToHotkeyManagement,
                        child: const Text('Manage Hotkeys'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _navigateToItemManagement,
                        child: const Text('Manage Items'),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 5, // Change flex to adjust the ratio
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  color: const Color.fromARGB(255, 233, 235, 230),
                  child: cartItems.isNotEmpty
                      ? SingleChildScrollView(
                          child: CartItemWidget(cartItems: cartItems),
                        )
                      : const Center(
                          child: Text(
                            'Cart is empty',
                            style: TextStyle(color: Colors.black, fontSize: 16),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToHotkeyManagement() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HotkeyManagementScreen(
          hotkeys: hotkeys,
          addItemCallback: (hotkey) {
            setState(() {
              hotkeys.add(hotkey);
            });
          },
          deleteHotkeyCallback: (index) {
            setState(() {
              // Check if index is within range and remove the hotkey
              if (index >= 0 && index < hotkeys.length) {
                hotkeys.removeAt(index);
              }
            });
          },
        ),
      ),
    );

    if (result != null) {
      setState(() {
        hotkeys.clear();
        hotkeys.addAll(List<Map<String, dynamic>>.from(result));
      });
    }
  }

  void _navigateToItemManagement() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ItemManagementScreen(hotkeys: hotkeys),
      ),
    );

    if (result != null) {
      // Handle item management result if needed
    }
  }
}
