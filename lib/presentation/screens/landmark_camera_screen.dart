import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class LandmarkCameraScreen extends StatefulWidget {
  const LandmarkCameraScreen({super.key});

  @override
  State<LandmarkCameraScreen> createState() => _LandmarkCameraScreenState();
}

class _LandmarkCameraScreenState extends State<LandmarkCameraScreen> {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  bool _isInitializing = true;
  bool _isMockCamera = false;
  bool _isTakingPicture = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _isInitializing = true;
    });

    try {
      _cameras = await availableCameras();

      if (_cameras.isEmpty) {
        setState(() {
          _isMockCamera = true;
          _isInitializing = false;
        });
        return;
      }

      _controller = CameraController(
        _cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();

      if (!mounted) return;

      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isMockCamera = true;
          _isInitializing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_isMockCamera) {
      setState(() => _isTakingPicture = true);
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      Navigator.pop(context, "mock_image_path.jpg");
      return;
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    if (_controller!.value.isTakingPicture) {
      return;
    }

    try {
      setState(() => _isTakingPicture = true);
      final XFile file = await _controller!.takePicture();
      if (!mounted) return;
      Navigator.pop(context, file.path);
    } catch (e) {
      setState(() => _isTakingPicture = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur de capture : $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Prendre une photo", style: TextStyle(color: Colors.white)),
      ),
      body: _isInitializing
          ? const Center(
              child: CircularProgressIndicator(color: Colors.indigo),
            )
          : _isMockCamera
              ? _buildMockCameraLayout()
              : _buildCameraPreviewLayout(),
    );
  }

  Widget _buildCameraPreviewLayout() {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(
        child: Text(
          "Erreur d'initialisation de l'appareil photo.",
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final double scale = 1 / (_controller!.value.aspectRatio * MediaQuery.of(context).size.aspectRatio);

    return Stack(
      children: [
        Positioned.fill(
          child: Transform.scale(
            scale: scale > 1 ? scale : 1,
            alignment: Alignment.center,
            child: CameraPreview(_controller!),
          ),
        ),
        _buildViewfinderOverlay(),
        _buildBottomShutterBar(),
      ],
    );
  }

  Widget _buildMockCameraLayout() {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            color: Colors.grey[900],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.camera_alt,
                  size: 80,
                  color: Colors.white24,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Mode Simulateur d'Appareil Photo",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "Aucune caméra matérielle détectée.\n"
                  "La capture d'image va être simulée pour l'évaluation.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        _buildViewfinderOverlay(),
        _buildBottomShutterBar(),
      ],
    );
  }

  Widget _buildViewfinderOverlay() {
    return Positioned.fill(
      child: Center(
        child: Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white54, width: 2),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomShutterBar() {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Center(
        child: _isTakingPicture
            ? const CircularProgressIndicator(color: Colors.white)
            : GestureDetector(
                onTap: _takePicture,
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
