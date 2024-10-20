import 'package:flutter/material.dart';

class HotkeyManagementScreen extends StatelessWidget {
  final List<Map<String, dynamic>> hotkeys;
  final Function(Map<String, dynamic>) addItemCallback;
  final Function(int) deleteHotkeyCallback; // Callback for deleting hotkeys

  HotkeyManagementScreen({
    required this.hotkeys,
    required this.addItemCallback,
    required this.deleteHotkeyCallback, // Accept delete callback
  });

  final TextEditingController hotkeyController = TextEditingController();
  final TextEditingController itemController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Hotkeys'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: hotkeyController,
              decoration: const InputDecoration(labelText: 'Hotkey (1-9)'),
            ),
            TextField(
              controller: itemController,
              decoration: const InputDecoration(labelText: 'Item Name'),
            ),
            ElevatedButton(
              onPressed: () {
                _addHotkey();
              },
              child: const Text('Add Hotkey'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Current Hotkeys:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: hotkeys.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text('${hotkeys[index]['hotkey']} - ${hotkeys[index]['item']}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        // Call the delete callback with the index
                        deleteHotkeyCallback(index);
                        Navigator.of(context).pop(); // Close the screen after deletion
                      },
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

  void _addHotkey() {
    String hotkey = hotkeyController.text.trim();
    String item = itemController.text.trim();

    if (hotkey.isNotEmpty && item.isNotEmpty) {
      addItemCallback({'hotkey': hotkey, 'item': item});
      hotkeyController.clear();
      itemController.clear();
    }
  }
}
