import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/models/landmark.dart';
import '../controllers/landmark_controller.dart';
import '../widgets/landmark_card.dart';
import '../theme/app_theme.dart';
import 'landmark_detail_screen.dart';

class LandmarkHomeScreen extends StatefulWidget {
  const LandmarkHomeScreen({super.key});

  @override
  State<LandmarkHomeScreen> createState() => _LandmarkHomeScreenState();
}

class _LandmarkHomeScreenState extends State<LandmarkHomeScreen> {
  @override
  void initState() {
    super.initState();
    // Le contrôleur a déjà chargé les landmarks au démarrage de l'app,
    // mais on peut forcer un rafraîchissement au besoin si nécessaire, ou ne rien faire si déjà chargé.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<LandmarkController>();
      if (controller.landmarks.isEmpty && controller.state != LandmarkState.loading) {
        controller.loadLandmarks();
      }
    });
  }

  Future<void> _refreshLandmarks() async {
    await context.read<LandmarkController>().loadLandmarks();
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isTablet = width >= 600;
    final controller = context.watch<LandmarkController>();
    final landmarks = controller.landmarks;
    final isLoading = controller.state == LandmarkState.loading;
    final errorMessage = controller.errorMessage;
    final visitedCount = controller.visitedCount;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Merveilles du Monde',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$visitedCount / ${landmarks.length} explorés',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshLandmarks,
            tooltip: 'Rafraîchir les lieux',
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 60, color: AppTheme.errorColor),
                      const SizedBox(height: 16),
                      Text(
                        errorMessage,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _refreshLandmarks,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : landmarks.isEmpty
                  ? const Center(
                      child: Text(
                        'Aucun monument trouvé.',
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _refreshLandmarks,
                      color: AppTheme.primaryColor,
                      backgroundColor: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: isTablet
                            ? _buildTabletGrid(context, landmarks)
                            : _buildMobileList(context, landmarks),
                      ),
                    ),
    );
  }

  Widget _buildMobileList(BuildContext context, List<Landmark> landmarks) {
    return ListView.builder(
      itemCount: landmarks.length,
      itemBuilder: (context, index) {
        final landmark = landmarks[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: SizedBox(
            height: 200,
            child: LandmarkCard(
              landmark: landmark,
              onTap: () => _navigateToDetail(landmark),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabletGrid(BuildContext context, List<Landmark> landmarks) {
    final double width = MediaQuery.of(context).size.width;
    int crossAxisCount = 2;
    if (width >= 900) {
      crossAxisCount = 3;
    }
    if (width >= 1200) {
      crossAxisCount = 4;
    }

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemCount: landmarks.length,
      itemBuilder: (context, index) {
        final landmark = landmarks[index];
        return LandmarkCard(
          landmark: landmark,
          onTap: () => _navigateToDetail(landmark),
        );
      },
    );
  }

  Future<void> _navigateToDetail(Landmark landmark) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LandmarkDetailScreen(landmark: landmark),
      ),
    );
  }
}
