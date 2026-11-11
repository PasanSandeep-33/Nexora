import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class PresidentQrScannerScreen extends StatefulWidget {
  final Future<void> Function(String qrCode) onCheckIn;

  const PresidentQrScannerScreen({super.key, required this.onCheckIn});

  @override
  State<PresidentQrScannerScreen> createState() =>
      _PresidentQrScannerScreenState();
}

class _PresidentQrScannerScreenState extends State<PresidentQrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    formats: [BarcodeFormat.qrCode],
  );
  bool _processing = false;

  Future<void> _handleScan(BarcodeCapture capture) async {
    if (_processing) return;
    String? qrCode;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();
      if (value != null && value.isNotEmpty) {
        qrCode = value;
        break;
      }
    }
    if (qrCode == null) return;
    setState(() => _processing = true);
    await _controller.stop();
    try {
      await widget.onCheckIn(qrCode);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student checked in successfully')),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
      setState(() => _processing = false);
      await _controller.start();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF050B25),
    appBar: AppBar(
      backgroundColor: const Color(0xFF050B25),
      foregroundColor: Colors.white,
      title: const Text('Scan Student QR Ticket'),
    ),
    body: Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(controller: _controller, onDetect: _handleScan),
        Center(
          child: IgnorePointer(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF19D9ED), width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
        Positioned(
          left: 16, right: 16, bottom: 36,
          child: Text(
            _processing ? 'Verifying ticket...' : 'Align the student QR code in the frame',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
        if (_processing)
          const ColoredBox(
            color: Colors.black54,
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    ),
  );
}
