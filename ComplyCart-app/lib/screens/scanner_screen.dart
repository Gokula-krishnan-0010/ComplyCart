import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'capture_preview_screen.dart';
import '../services/camera_service.dart';
import '../theme/app_theme.dart';

class LabelScannerView extends StatefulWidget {
  final bool isActive;
  const LabelScannerView({super.key, this.isActive = false});

  @override
  State<LabelScannerView> createState() => _LabelScannerViewState();
}

class _LabelScannerViewState extends State<LabelScannerView> with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isPermissionDenied = false;
  bool _isCapturing = false;
  bool _showFlash = false;
  FlashMode _flashMode = FlashMode.off;
  final List<String> _recentCaptures = [];

  late AnimationController _scanLineController;
  late Animation<double> _scanLineAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    if (widget.isActive) {
      _initCamera();
    }

    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _scanLineAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(LabelScannerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _initCamera();
    } else if (!widget.isActive && oldWidget.isActive) {
      _disposeCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeCamera();
    _scanLineController.dispose();
    super.dispose();
  }

  Future<void> _disposeCamera() async {
    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
      if (mounted) {
        setState(() {
          _isInitialized = false;
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.isActive) return;

    final CameraController? cameraController = _controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    
    if (status.isPermanentlyDenied || status.isDenied) {
      if (mounted) setState(() => _isPermissionDenied = true);
      return;
    }

    if (CameraService.cameras.isEmpty) {
      await CameraService.initialize();
    }

    if (CameraService.cameras.isNotEmpty) {
      _controller = CameraController(
        CameraService.cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      try {
        await _controller?.initialize();
        if (mounted) {
          setState(() {
            _isInitialized = true;
            _isPermissionDenied = false;
          });
        }
      } catch (e) {
        debugPrint('Camera init error: $e');
      }
    }
  }

  Future<void> _toggleFlash() async {
    if (_controller == null) return;
    
    final newMode = _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    try {
      await _controller!.setFlashMode(newMode);
      setState(() => _flashMode = newMode);
    } catch (e) {
      debugPrint('Flash error: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null && mounted) {
      _processCapturedImage(image.path);
    }
  }

  Future<void> _processCapturedImage(String path) async {
    final bool? usePhoto = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CapturePreviewScreen(imagePath: path),
      ),
    );

    if (usePhoto == true && mounted) {
      // Add to recent captures
      setState(() {
        _recentCaptures.insert(0, path);
        if (_recentCaptures.length > 6) _recentCaptures.removeLast();
      });

      // Save to gallery if it's not already from gallery
      if (!path.contains('cache')) { // Simple check for camera captures
        final hasAccess = await Gal.hasAccess();
        if (!hasAccess) await Gal.requestAccess();
        await Gal.putImage(path);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Label captured and saved to history!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _captureImage() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCapturing) return;

    try {
      setState(() {
        _isCapturing = true;
        _showFlash = true;
      });
      
      // Haptic feedback
      await HapticFeedback.mediumImpact();
      
      final XFile image = await _controller!.takePicture();
      
      // Turn off flash after a short delay
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) setState(() => _showFlash = false);

      if (mounted) {
        _processCapturedImage(image.path);
      }
    } catch (e) {
      debugPrint('Capture error: $e');
      if (mounted) {
        setState(() => _showFlash = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error capturing image: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          // 1. Camera Preview with small margin
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, 0),
                child: AnimatedScale(
                  scale: _showFlash ? 0.98 : 1.0,
                  duration: const Duration(milliseconds: 100),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppRadius.xxl),
                      topRight: Radius.circular(AppRadius.xxl),
                    ),
                    child: Container(
                      color: Colors.black,
                      child: _buildCameraPreview(),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 2. Scan Overlay (Frame & Line)
          Positioned.fill(
            top: 80, // Offset to center better vertically between UI elements
            bottom: 180,
            child: Center(
              child: (_isInitialized && !_isPermissionDenied)
                  ? _buildScanOverlay()
                  : const SizedBox.shrink(),
            ),
          ),

          // 3. Transparent Custom Header
          _buildTransparentHeader(),

          // 4. Action Button & Tip
          _buildBottomControls(),

          // 5. Flash Overlay
          if (_showFlash)
            Positioned.fill(
              child: Container(
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_isPermissionDenied) {
      return _buildPermissionDeniedUI();
    }

    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return CameraPreview(_controller!);
  }

  Widget _buildScanOverlay() {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.75,
      height: MediaQuery.of(context).size.width * 0.75,
      child: Stack(
        children: [
          // Corner Brackets
          CustomPaint(
            size: Size.infinite,
            painter: ScannerFramePainter(),
          ),
          
          // Moving Scan Line
          AnimatedBuilder(
            animation: _scanLineAnimation,
            builder: (context, child) {
              return Positioned(
                top: _scanLineAnimation.value * (MediaQuery.of(context).size.width * 0.75),
                left: 10,
                right: 10,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0),
                        AppColors.primary,
                        AppColors.primary.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTransparentHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppColors.secondary, blurRadius: 6, spreadRadius: 2)],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Label Scanner',
                style: AppTextStyles.h3.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                onPressed: _toggleFlash,
                icon: Icon(
                  _flashMode == FlashMode.torch ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white10,
                child: const Icon(Icons.person_outline_rounded, size: 22, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(seconds: 1),
                builder: (context, value, child) => Opacity(
                  opacity: value,
                  child: Text(
                    'Align label within frame • Ensure good lighting',
                    style: AppTextStyles.caption.copyWith(color: Colors.white70),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (_recentCaptures.isNotEmpty) _buildRecentCaptures(),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: _pickFromGallery,
                    icon: const Icon(Icons.photo_library_rounded, color: Colors.white, size: 28),
                  ),
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: FloatingActionButton(
                      onPressed: (_isInitialized && !_isCapturing) ? _captureImage : null,
                      backgroundColor: AppColors.primary,
                      shape: const CircleBorder(),
                      child: _isCapturing 
                          ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                          : const Icon(Icons.camera_alt_rounded, size: 32, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 48), // Spacer to balance gallery icon
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentCaptures() {
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        itemCount: _recentCaptures.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _processCapturedImage(_recentCaptures[index]),
            child: Container(
              width: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: Colors.white24),
                image: DecorationImage(
                  image: FileImage(File(_recentCaptures[index])),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPermissionDeniedUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_enhance_outlined, size: 64, color: Colors.white24),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Camera Access Denied',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'We need camera access to scan product labels for compliance checking.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: () => openAppSettings(),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      ),
    );
  }
}

class ScannerFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    const cornerLength = 30.0;
    const radius = 12.0;

    // Top Left
    canvas.drawArc(Rect.fromLTWH(0, 0, radius * 2, radius * 2), 3.14, 1.57, false, paint);
    canvas.drawLine(const Offset(radius, 0), const Offset(cornerLength, 0), paint);
    canvas.drawLine(const Offset(0, radius), const Offset(0, cornerLength), paint);

    // Top Right
    canvas.drawArc(Rect.fromLTWH(size.width - radius * 2, 0, radius * 2, radius * 2), -1.57, 1.57, false, paint);
    canvas.drawLine(Offset(size.width - radius, 0), Offset(size.width - cornerLength, 0), paint);
    canvas.drawLine(Offset(size.width, radius), Offset(size.width, cornerLength), paint);

    // Bottom Left
    canvas.drawArc(Rect.fromLTWH(0, size.height - radius * 2, radius * 2, radius * 2), 1.57, 1.57, false, paint);
    canvas.drawLine(Offset(radius, size.height), Offset(cornerLength, size.height), paint);
    canvas.drawLine(Offset(0, size.height - radius), Offset(0, size.height - cornerLength), paint);

    // Bottom Right
    canvas.drawArc(Rect.fromLTWH(size.width - radius * 2, size.height - radius * 2, radius * 2, radius * 2), 0, 1.57, false, paint);
    canvas.drawLine(Offset(size.width - radius, size.height), Offset(size.width - cornerLength, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height - radius), Offset(size.width, size.height - cornerLength), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
