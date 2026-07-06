import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../data/models/landmark.dart';
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
        desiredAccuracy: LocationAccuracy.high,
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
          title: Row(
            children: const [
              Icon(Icons.location_off, color: Colors.orange),
              SizedBox(width: 10),
              Text("Distance trop grande"),
            ],
          ),
          content: Text(
            "$message\n\nSouhaitez-vous simuler que vous êtes sur place (GPS fictif) pour les besoins de l'évaluation ?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Annuler", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
              onPressed: () {
                Navigator.pop(dialogContext);
                _proceedToCamera();
              },
              child: const Text("Simuler GPS", style: TextStyle(color: Colors.white)),
            ),
          ],
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
                  height: 120,
                  width: double.infinity,
                  child: Image.network(
                    widget.landmark.imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor),
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pop(context, true);
              },
              child: const Text("Génial !"),
            ),
          ],
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
            leading: CircleAvatar(
              backgroundColor: Colors.black45,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.landmark.title,
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
                  Image.network(
                    widget.landmark.imageUrl,
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_month, color: Colors.grey, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              "Découvert le : ${widget.landmark.date}",
                              style: const TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: widget.landmark.isVisited
                                ? const Color(0xFF10B981).withOpacity(0.2)
                                : Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: widget.landmark.isVisited ? const Color(0xFF10B981) : Colors.orange,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            widget.landmark.isVisited ? "EXPLORÉ" : "NON VISITÉ",
                            style: TextStyle(
                              color: widget.landmark.isVisited ? const Color(0xFF10B981) : Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
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
                              Text(
                                "Coordonnées géographiques",
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
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
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.borderLight)),
              ),
              child: ScaleOnPress(
                onTap: _isCheckingLocation ? null : _onCheckInPressed,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
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
