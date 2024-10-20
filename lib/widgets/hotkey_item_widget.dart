import 'package:flutter/material.dart';

class HotkeyItemWidget extends StatelessWidget {
  final String hotkey;
  final String itemName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const HotkeyItemWidget({
    super.key,
    required this.hotkey,
    required this.itemName,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: ListTile(
        title: Text(
          'Hotkey: $hotkey',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Item: $itemName'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: onEdit,
              tooltip: 'Edit Hotkey',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: onDelete,
              tooltip: 'Delete Hotkey',
            ),
          ],
        ),
      ),
    );
  }
}
