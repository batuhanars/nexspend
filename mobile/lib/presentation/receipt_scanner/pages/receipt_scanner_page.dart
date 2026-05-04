import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wallet_app/presentation/receipt_scanner/widgets/scanner/capture_button.dart';
import 'package:wallet_app/presentation/receipt_scanner/widgets/scanner/circle_button.dart';
import 'package:wallet_app/presentation/receipt_scanner/widgets/scanner/error_view.dart';
import 'package:wallet_app/presentation/receipt_scanner/widgets/scanner/scanner_overlay.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/di/injection.dart';
import '../../../data/repositories/receipt_repository.dart';
import 'receipt_preview_page.dart';

class ReceiptScannerPage extends StatefulWidget {
  const ReceiptScannerPage({super.key});

  @override
  State<ReceiptScannerPage> createState() => _ReceiptScannerPageState();
}

class _ReceiptScannerPageState extends State<ReceiptScannerPage>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitializing = true;
  bool _isProcessing = false;
  bool _flashOn = false;
  String? _initError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller!.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    setState(() {
      _isInitializing = true;
      _initError = null;
    });
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) throw Exception('Kamera bulunamadı');
      final back = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _controller = controller;
        _isInitializing = false;
      });
    } catch (e) {
      setState(() {
        _initError = e.toString();
        _isInitializing = false;
      });
    }
  }

  Future<void> _toggleFlash() async {
    if (_controller == null) return;
    final next = _flashOn ? FlashMode.off : FlashMode.torch;
    await _controller!.setFlashMode(next);
    setState(() => _flashOn = !_flashOn);
  }

  Future<void> _captureAndProcess() async {
    if (_controller == null || _isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final file = await _controller!.takePicture();
      await _processImage(file.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fotoğraf çekilemedi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null || !mounted) return;
    setState(() => _isProcessing = true);
    try {
      await _processImage(image.path);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _processImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    var rawText = '';
    var confidence = 0.0;

    try {
      final recognized = await recognizer.processImage(inputImage);
      rawText = recognized.text.trim();
      confidence = _estimateConfidence(rawText);
    } finally {
      recognizer.close();
    }

    if (!mounted) return;
    try {
      final result = await getIt<ReceiptRepository>().scan(
        imagePath,
        rawText: rawText.isNotEmpty ? rawText : null,
        confidence: confidence,
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              ReceiptPreviewPage(imagePath: imagePath, ocrResult: result),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fiş işlenemedi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  double _estimateConfidence(String text) {
    if (text.isEmpty) return 0.0;
    final hasAmount = RegExp(r'\d+[.,]\d{2}').hasMatch(text);
    final hasDate =
        RegExp(r'\d{2}[./]\d{2}[./]\d{4}').hasMatch(text);
    if (hasAmount && hasDate) return 0.7;
    if (hasAmount) return 0.5;
    return 0.3;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          if (_isInitializing)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          else if (_initError != null)
            ErrorView(error: _initError!, onRetry: _initCamera)
          else if (_controller != null && _controller!.value.isInitialized)
            Positioned.fill(child: CameraPreview(_controller!)),

          // Scanner overlay
          if (!_isInitializing && _initError == null) const ScannerOverlay(),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black38,
                    ),
                  ),
                  Text(
                    'Makbuz Tara',
                    style: AppTypography.titleSm.copyWith(color: Colors.white),
                  ),
                  IconButton(
                    onPressed: _controller != null ? _toggleFlash : null,
                    icon: Icon(
                      _flashOn ? Icons.flash_on : Icons.flash_off,
                      color: _flashOn ? Colors.yellow : Colors.white,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black38,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: AppSpacing.xl,
                bottom: MediaQuery.of(context).padding.bottom + AppSpacing.xl,
                left: AppSpacing.xl,
                right: AppSpacing.xl,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Gallery button
                  CircleButton(
                    icon: Icons.photo_library_outlined,
                    onTap: _isProcessing ? null : _pickFromGallery,
                    label: 'Galeri',
                  ),
                  // Capture button
                  CaptureButton(
                    isProcessing: _isProcessing,
                    onTap: _captureAndProcess,
                  ),
                  // Spacer to balance gallery
                  const SizedBox(width: 64),
                ],
              ),
            ),
          ),

          // Processing overlay
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: AppSpacing.md),
                    Text(
                      'Makbuz analiz ediliyor...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
