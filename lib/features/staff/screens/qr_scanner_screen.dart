import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/receipt_provider.dart';
import '../../shared/widgets/loading_indicator.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController? _scannerController;
  bool _isProcessing = false;
  bool _hasScanned = false;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  Future<void> _processQRCode(String qrData) async {
    if (_isProcessing || _hasScanned) return;

    setState(() {
      _isProcessing = true;
      _hasScanned = true;
    });

    try {
      // Parse QR data: LAVENDIA:receiptId:receiptNumber
      final parts = qrData.split(':');

      if (parts.length < 3 || parts[0] != 'LAVENDIA') {
        _showError('Invalid QR code format');
        return;
      }

      final receiptId = int.tryParse(parts[1]);
      if (receiptId == null) {
        _showError('Invalid receipt ID');
        return;
      }

      // Fetch receipt details
      final receiptProvider = Provider.of<ReceiptProvider>(context, listen: false);
      final success = await receiptProvider.fetchReceiptDetail(receiptId);

      if (!success || receiptProvider.selectedReceipt == null) {
        _showError('Receipt not found');
        return;
      }

      final receipt = receiptProvider.selectedReceipt!;

      if (!mounted) return;

      // Show confirmation dialog
      _showPickupConfirmation(receipt.id, receipt.receiptNumber, receipt.statusDisplay);

    } catch (e) {
      _showError('Error processing QR code: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );

    // Allow scanning again after error
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _hasScanned = false);
      }
    });
  }

  void _showPickupConfirmation(int receiptId, String receiptNumber, String currentStatus) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.qr_code_scanner, color: AppColors.primary),
            const SizedBox(width: 12),
            const Text('Receipt Found'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Receipt #', receiptNumber),
            const SizedBox(height: 8),
            _buildInfoRow('Status', currentStatus),
            const SizedBox(height: 16),
            const Text(
              'Mark this order as completed?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() => _hasScanned = false);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _completePickup(receiptId),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusReady,
            ),
            child: const Text('Complete Pickup'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Future<void> _completePickup(int receiptId) async {
    Navigator.of(context).pop(); // Close dialog

    setState(() => _isProcessing = true);

    try {
      final receiptProvider = Provider.of<ReceiptProvider>(context, listen: false);
      final success = await receiptProvider.completeReceipt(receiptId);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order marked as completed!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(); // Return to previous screen
      } else if (mounted) {
        _showError(receiptProvider.errorMessage ?? 'Failed to complete pickup');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        actions: [
          IconButton(
            icon: Icon(
              _scannerController?.torchEnabled == true
                  ? Icons.flash_on
                  : Icons.flash_off,
            ),
            onPressed: () => _scannerController?.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Scanner
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _processQRCode(barcode.rawValue!);
                  break;
                }
              }
            },
          ),

          // Overlay
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
            ),
            child: Stack(
              children: [
                // Cutout for scan area
                Center(
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(color: AppColors.primary, width: 3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                // Clear the center
                ClipPath(
                  clipper: _ScannerOverlayClipper(),
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ],
            ),
          ),

          // Instructions
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Icon(
                  Icons.qr_code_scanner,
                  size: 48,
                  color: AppColors.white.withValues(alpha: 0.8),
                ),
                const SizedBox(height: 16),
                Text(
                  'Point camera at customer\'s QR code',
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Loading overlay
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: const Center(
                child: LoadingIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}

class _ScannerOverlayClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    const scanSize = 280.0;

    final scanRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, centerY),
        width: scanSize,
        height: scanSize,
      ),
      const Radius.circular(16),
    );

    path.addRRect(scanRect);
    path.fillType = PathFillType.evenOdd;

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
