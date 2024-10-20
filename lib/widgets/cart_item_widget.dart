import 'package:flutter/material.dart';
import 'pdf_service.dart'; // Import the PdfService

class CartItemWidget extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;

  const CartItemWidget({Key? key, required this.cartItems}) : super(key: key);

  @override
  _CartItemWidgetState createState() => _CartItemWidgetState();
}

class _CartItemWidgetState extends State<CartItemWidget> {
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.cartItems; // Initially, show all items
  }

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = widget.cartItems;
      } else {
        _filteredItems = widget.cartItems
            .where((item) => item['name']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _generatePdf() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(child: CircularProgressIndicator()); // Show progress indicator
      },
    );

    PdfService pdfService = PdfService();
    await pdfService.generateBillPdf(widget.cartItems);

    // Dismiss the progress indicator
    Navigator.of(context).pop();

    // Show a success message or further handle the PDF file
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("PDF generated!")));
  }

  void _removeItem(int index) {
    setState(() {
      _filteredItems.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    double totalCost = _filteredItems.fold(0.0, (sum, item) => sum + (item['price'] * item['quantity'])); // Calculate total cost

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search bar
        TextField(
          controller: _searchController,
          onChanged: _filterItems,
          decoration: const InputDecoration(
            labelText: 'Search items',
            border: OutlineInputBorder(),
          ),
        ),
        // Total cost display
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Total: \$${totalCost.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        // Cart items list
        Container(
          height: 300, // Height for scrolling
          child: ListView.builder(
            itemCount: _filteredItems.length,
            itemBuilder: (context, index) {
              final item = _filteredItems[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0), // Reduced vertical padding
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Item name
                    Flexible(
                      child: Text(
                        item['name'].toString().toLowerCase(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          color: Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis, // Avoid overflow by adding ellipsis
                      ),
                    ),
                    // Quantity and action buttons
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Text(
                            '${item['quantity'].toString()}x',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Text(
                            '\$${(item['price'] * item['quantity']).toStringAsFixed(2)}', // Show the total price of the item
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeItem(index),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        ElevatedButton(
          onPressed: _generatePdf, // PDF generation button
          child: Text('Print Bill'),
        ),
      ],
    );
  }
}
