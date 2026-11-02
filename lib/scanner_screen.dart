import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool _isProcessing = false;
  final TextEditingController _allergensController = TextEditingController(text: "");
  final TextEditingController _manualBarcodeController = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController();

  final String backendUrl = "http://127.0.0.1:8000/check-product";

  @override
  void dispose() {
    _allergensController.dispose();
    _manualBarcodeController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _checkProduct(String codeOrName) async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
    });

    try {
      List<String> allergensList = _allergensController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "barcode": codeOrName,
          "allergens": allergensList,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        _showProductDialog(data);
      } else {
        _showErrorDialog("لم يتم العثور على المنتج");
      }
    } catch (e) {
      _showErrorDialog("حدث خطأ في الاتصال بالخادم");
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showProductDialog(Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext context) {
        bool hasRisk = data['has_allergy_risk'] ?? false;
        String message = data['message'] ?? '';
        bool isUnverified = message.contains("غير موثّق") || message.contains("غير مسجل");

        String caloriesRaw = data['calories']?.toString() ?? '0';
        String caloriesNum = caloriesRaw.replaceAll(RegExp(r'[^0-9]'), '');
        if (caloriesNum.isEmpty) caloriesNum = "0";

        String proteins = data['proteins']?.toString() ?? '-';
        String carbs = data['carbs']?.toString() ?? '-';
        String fats = data['fats']?.toString() ?? '-';

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.fastfood, color: Colors.orange, size: 28),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            data['product_name'] ?? 'منتج غير معروف',
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.right,
                          ),
                          const SizedBox(height: 4),
                          Text('$caloriesNum سعرة لكل 100غ', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: isUnverified 
                        ? Colors.amber.withValues(alpha: 0.15) 
                        : (hasRisk ? Colors.red.withValues(alpha: 0.15) : Colors.green.withValues(alpha: 0.15)),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isUnverified ? Colors.amber : (hasRisk ? Colors.red : Colors.green), width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        message.isNotEmpty ? message : "غير موثّق بعد – راجع الملصق",
                        style: TextStyle(
                          color: isUnverified ? Colors.amberAccent : (hasRisk ? Colors.redAccent : Colors.greenAccent),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isUnverified ? Icons.qr_code_scanner : (hasRisk ? Icons.warning_amber_rounded : Icons.check_circle),
                        color: isUnverified ? Colors.amberAccent : (hasRisk ? Colors.redAccent : Colors.greenAccent),
                        size: 18,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Column(
                    children: [
                      Text(caloriesNum, style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
                      const Text('سعرة حرارية', style: TextStyle(color: Colors.grey, fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMacroItem('البروتين', proteins, '-', Colors.pinkAccent),
                      _buildMacroItem('الكربوهيدرات', carbs, '-', Colors.blueAccent),
                      _buildMacroItem('الدهون', fats, '-', Colors.tealAccent),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text('المكونات:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 6),
                Text(data['ingredients'] ?? 'غير متوفرة', style: TextStyle(color: Colors.grey[400], fontSize: 13), textAlign: TextAlign.right),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMacroItem(String label, String value, String percentage, Color color) {
    return Column(
      children: [
        Icon(Icons.circle, size: 10, color: color),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        const SizedBox(height: 4),
        Text(percentage, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تنبيه'),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('حسناً'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MobileScanner(
          controller: _scannerController,
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              if (barcode.rawValue != null && !_isProcessing) {
                _checkProduct(barcode.rawValue!);
                break;
              }
            }
          },
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextField(
                  controller: _allergensController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'المواد التي تحسس منها (مفصولة بفواصل)',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.black54,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                if (_isProcessing) const CircularProgressIndicator(color: Colors.green),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _manualBarcodeController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'أدخل رقم الباركود يدوياً...',
                          hintStyle: const TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: Colors.black54,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
                      ),
                      onPressed: () {
                        if (_manualBarcodeController.text.trim().isNotEmpty) {
                          _checkProduct(_manualBarcodeController.text.trim());
                        }
                      },
                      child: const Text('بحث يدوي', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}