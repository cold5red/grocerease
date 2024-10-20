import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class PdfService {
  Future<void> generateBillPdf(List<Map<String, dynamic>> cartItems) async {
    final pdf = pw.Document();

    double totalCost = cartItems.fold(0.0, (sum, item) => sum + item['price'] * item['quantity']);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Bill Receipt', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Text('Items:', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headers: ['Item', 'Quantity', 'Price'],
                data: cartItems.map((item) {
                  return [
                    item['name'],
                    '${item['quantity']}',
                    '\$${(item['price'] * item['quantity']).toStringAsFixed(2)}'
                  ];
                }).toList(),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Total: \$${totalCost.toStringAsFixed(2)}',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            ],
          );
        },
      ),
    );

    // Get the directory to save the PDF
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/bill.pdf');
    
    // Save the PDF file
    await file.writeAsBytes(await pdf.save());
    
    // Print confirmation or handle the file further as needed
    print('PDF saved at: ${file.path}');
  }
}
