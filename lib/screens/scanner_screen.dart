import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_detail_screen.dart';
import '../widgets/page_title.dart';
import '../widgets/screen_layout.dart';
import '../colours/colour_system.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _isFlashOn = false;
  bool _hasScanned = false;

  // Function to fetch and update UPC data from Firestore (Use the UPC code as the document ID)
  Future<Map<String, dynamic>?> fetchUPCData(String upcCode) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .doc(upcCode)
          .get();

      if (snapshot.exists) {
        return snapshot.data() as Map<String, dynamic>?;
      } else {

        // If the UPC code is not found, prompt user to enter data
        return await _getNewProductDetails(upcCode);
      }
    } catch (e) {
      print('Error fetching or creating UPC data: $e');
      return null;
    }
  }

  // Prompt the user for new product details
  Future<Map<String, dynamic>?> _getNewProductDetails(String upcCode) async {

    // Declare controllers to collect user input
    TextEditingController nameController = TextEditingController();
    TextEditingController priceController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();
    TextEditingController imageController = TextEditingController();

    // Show a dialog to get the product details
    Map<String, dynamic>? productData = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter Product Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: imageController,
                decoration: const InputDecoration(labelText: 'Image URL'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null); 
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                
                // Create the product map and return it
                Map<String, dynamic> newProduct = {
                  'upcCode': upcCode,
                  'name': nameController.text,
                  'price': double.tryParse(priceController.text) ?? 0.0,
                  'description': descriptionController.text,
                  'image': imageController.text,
                };
                Navigator.of(context).pop(newProduct);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    // If product data is provided, store it in Firestore
    if (productData != null) {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(upcCode)
          .set(productData);
      return productData;
    }
    return null;
  }

  @override
  void reassemble() {
    super.reassemble();
    if (controller != null) {
      controller!.pauseCamera();
      controller!.resumeCamera();
    }
  }

  void _onQRViewCreated(QRViewController ctrl) {
    controller = ctrl;

    controller!.scannedDataStream.listen((scanData) {
      if (!_hasScanned) {
        setState(() {
          _hasScanned = true;
        });
        controller?.pauseCamera();

        // Fetch UPC data from Firestore
        fetchUPCData(scanData.code ?? '').then((data) {
          if (data != null) {
            // Pass UPC data to ProductDetailScreen if data is available
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailScreen(
                  upc: scanData.code ?? '',
                ),
              ),
            ).then((_) {
              setState(() {
                _hasScanned = false;
              });
              controller?.resumeCamera();
            });
          } else {
            // Show an error or prompt if UPC is not found
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error with UPC: $scanData')),
            );
            setState(() {
              _hasScanned = false;
            });
            controller?.resumeCamera();
          }
        });
      }
    });
  }

  void _toggleFlash() async {
    await controller?.toggleFlash();
    bool? flashStatus = await controller?.getFlashStatus();
    setState(() {
      _isFlashOn = flashStatus ?? false;
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenLayout(
      body: Stack(
        children: [
          // Live camera feed
          QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: CanadianTheme.canadianRed,
              borderRadius: 10,
              borderLength: 30,
              borderWidth: 8,
              cutOutSize: MediaQuery.of(context).size.width * 0.8,
            ),
          ),

          // Overlay UI
          Column(
            children: [
              const SizedBox(height: 40),
              buildTitle("Barcode Scanner"),
              const SizedBox(height: 12),
              Text(
                "Please Centre Barcode Between Lines",
                style: CanadianTheme.canadianText(
                  fontWeight: FontWeight.bold,
                  color: CanadianTheme.darkGrey,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _toggleFlash,
                    icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off),
                    iconSize: 28,
                    color: CanadianTheme.darkGrey,
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ],
      ),
    );
  }
}
