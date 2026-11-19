import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
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
  final MobileScannerController controller = MobileScannerController(
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
    ],
  );
  bool _hasScanned = false;

  void _onDetect(BarcodeCapture capture) {
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code != null && code.isNotEmpty) {
      _lookUpProduct(code);
    }
  }

  void _lookUpProduct(String code) {
    if (_hasScanned) return;
    setState(() {
      _hasScanned = true;
    });
    controller.stop();

    // The product screen looks the barcode up in Open Food Facts itself.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(upc: code),
      ),
    ).then((_) {
      if (!mounted) return;
      setState(() {
        _hasScanned = false;
      });
      controller.start();
    });
  }

  // For devices without a camera (or when camera access is denied)
  Future<void> _enterBarcodeManually() async {
    final codeController = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Barcode'),
        content: TextField(
          controller: codeController,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'UPC / EAN number'),
          onSubmitted: (value) => Navigator.pop(context, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, codeController.text.trim()),
            child: const Text('Look Up'),
          ),
        ],
      ),
    );
    if (code != null && code.isNotEmpty) {
      _lookUpProduct(code);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenLayout(
      body: Stack(
        children: [
          // Live camera feed
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) => Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('lib/assets/icons/scanner.png', width: 96, height: 96),
                    const SizedBox(height: 12),
                    Text(
                      "Camera unavailable. You can enter the barcode number instead.",
                      textAlign: TextAlign.center,
                      style: CanadianTheme.canadianText(
                        color: CanadianTheme.darkGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Scan area outline
          Center(
            child: FractionallySizedBox(
              widthFactor: 0.8,
              heightFactor: 0.3,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: CanadianTheme.canadianRed, width: 4),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
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
                  ValueListenableBuilder<MobileScannerState>(
                    valueListenable: controller,
                    builder: (context, state, _) => IconButton(
                      onPressed: state.torchState == TorchState.unavailable
                          ? null
                          : controller.toggleTorch,
                      icon: Icon(state.torchState == TorchState.on
                          ? Icons.flash_on
                          : Icons.flash_off),
                      iconSize: 28,
                      color: CanadianTheme.darkGrey,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _enterBarcodeManually,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CanadianTheme.canadianRed,
                      foregroundColor: Colors.white,
                    ),
                    icon: Image.asset('lib/assets/icons/barcode.png', width: 24, height: 24),
                    label: const Text('Enter Barcode'),
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
