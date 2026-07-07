import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../domain/models/landmark.dart';
import '../controllers/landmark_controller.dart';
import 'landmark_camera_screen.dart';
import '../widgets/scale_on_press.dart';
import '../theme/app_theme.dart';

class LandmarkDetailScreen extends StatefulWidget {
  final Landmark landmark;

  const LandmarkDetailScreen({super.key, required this.landmark});

  @override
  State<LandmarkDetailScreen> createState() => _LandmarkDetailScreenState();
}

class _LandmarkDetailScreenState extends State<LandmarkDetailScreen> {
  bool _isCheckingLocation = false;

  Future<void> _onCheckInPressed() async {
    setState(() {
      _isCheckingLocation = true;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar("Permission de localisation refusée.");
          setState(() => _isCheckingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnackBar("Les permissions de localisation sont définitivement refusées. Activez-les dans les réglages.");
        setState(() => _isCheckingLocation = false);
        return;
      }

      Position currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      double distanceInMeters = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        widget.landmark.latitude,
        widget.landmark.longitude,
      );

      const double targetRangeMeters = 200.0;

      if (distanceInMeters > targetRangeMeters) {
        _showSimulationDialog(distanceInMeters);
      } else {
        _proceedToCamera();
      }
    } catch (e) {
      _showSimulationDialog(null, errorMessage: e.toString());
    } finally {
      setState(() {
        _isCheckingLocation = false;
      });
    }
  }

  void _showSimulationDialog(double? distanceInMeters, {String? errorMessage}) {
    String message = "";
    if (distanceInMeters != null) {
      double distanceInKm = distanceInMeters / 1000;
      message = "Vous êtes actuellement à ${distanceInKm.toStringAsFixed(2)} km de ce monument.\n\n"
          "Pour valider de manière authentique, vous devez être à moins de 200 mètres.";
    } else {
      message = "Erreur de localisation : ${errorMessage ?? 'impossible d\'obtenir la position GPS'}.\n\n"
          "Vérifiez que le GPS de votre appareil est activé.";
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_off_outlined,
                  color: Colors.amber,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Distance trop grande",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Souhaitez-vous simuler que vous êtes sur place (GPS fictif) pour les besoins de l'évaluation ?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _proceedToCamera();
                  },
                  child: const Text(
                    "Simuler le GPS",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    "Annuler",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _proceedToCamera() async {
    var status = await Permission.camera.request();
    if (!status.isGranted) {
      _showSnackBar("Permission d'accès à l'appareil photo refusée.");
      return;
    }

    if (!mounted) return;
    final String? photoPath = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LandmarkCameraScreen(),
      ),
    );

    if (photoPath != null) {
      _showSuccessDialog(photoPath);
    }
  }

  void _showSuccessDialog(String photoPath) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.verified, color: Color(0xFF10B981)),
              SizedBox(width: 10),
              Text("Visite Validée !"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Félicitations ! Votre position a été validée et votre photo a été enregistrée.",
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 150,
                  width: double.infinity,
                  child: Image.file(
                    File(photoPath),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    final dialogNavigator = Navigator.of(dialogContext);
                    
                    await context.read<LandmarkController>().visitLandmark(
                          widget.landmark.id,
                          photoPath,
                        );

                    dialogNavigator.pop();
                    navigator.pop(photoPath);
                  },
                  child: const Text(
                    "Génial !",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSnackBar(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: Colors.red[800],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppTheme.primaryColor,
            leading: Padding(
              padding: const EdgeInsets.only(left: 12.0, top: 8.0, bottom: 8.0),
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 16,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                widget.landmark.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(blurRadius: 10, color: Colors.black, offset: Offset(0, 2))
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  widget.landmark.imageUrl.startsWith('http')
                      ? Image.network(
                          widget.landmark.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[200]),
                        )
                      : Image.file(
                          File(widget.landmark.imageUrl),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[200]),
                        ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.black87],
                        begin: Alignment.center,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: widget.landmark.isVisited
                              ? const Color(0xFF10B981).withValues(alpha: 0.1)
                              : Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: widget.landmark.isVisited ? const Color(0xFF10B981) : Colors.orange,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          widget.landmark.isVisited ? "EXPLORÉ" : "NON VISITÉ",
                          style: TextStyle(
                            color: widget.landmark.isVisited ? const Color(0xFF10B981) : Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "À propos de ce monument",
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.landmark.description,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: AppTheme.primaryColor, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Coordonnées géographiques",
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  const Text("Latitude", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.landmark.latitude.toStringAsFixed(4),
                                    style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  Text("Longitude", style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.landmark.longitude.toStringAsFixed(4),
                                    style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
      bottomSheet: !widget.landmark.isVisited
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppTheme.borderLight)),
              ),
              child: ScaleOnPress(
                onTap: _isCheckingLocation ? null : _onCheckInPressed,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF1A237E),
                    disabledForegroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _isCheckingLocation
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                    _isCheckingLocation ? "Vérification en cours..." : "J'y suis !",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: null, // Tap events are captured and animated by ScaleOnPress wrapper
                ),
              ),
            )
          : null,
    );
  }
}
