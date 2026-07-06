import 'package:flutter/material.dart';
import '../../data/models/landmark.dart';
import '../../data/datasources/landmark_api_service.dart';
import '../widgets/landmark_card.dart';
import '../theme/app_theme.dart';
import 'landmark_detail_screen.dart';

class LandmarkHomeScreen extends StatefulWidget {
  const LandmarkHomeScreen({super.key});

  @override
  State<LandmarkHomeScreen> createState() => _LandmarkHomeScreenState();
}

class _LandmarkHomeScreenState extends State<LandmarkHomeScreen> {
  final LandmarkApiService _apiService = LandmarkApiService();
  List<Landmark> _landmarks = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLandmarks();
  }

  Future<void> _loadLandmarks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _apiService.fetchLandmarks();
      setState(() {
        _landmarks = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Impossible de charger les données.";
        _isLoading = false;
      });
    }
  }

  int get _visitedCount => _landmarks.where((l) => l.isVisited).length;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isTablet = width >= 600;

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
              '$_visitedCount / ${_landmarks.length} explorés',
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
            onPressed: _loadLandmarks,
            tooltip: 'Rafraîchir les lieux',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 60, color: AppTheme.errorColor),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadLandmarks,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _landmarks.isEmpty
                  ? const Center(
                      child: Text(
                        'Aucun monument trouvé.',
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadLandmarks,
                      color: AppTheme.primaryColor,
                      backgroundColor: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: isTablet
                            ? _buildTabletGrid(context)
                            : _buildMobileList(context),
                      ),
                    ),
    );
  }

  Widget _buildMobileList(BuildContext context) {
    return ListView.builder(
      itemCount: _landmarks.length,
      itemBuilder: (context, index) {
        final landmark = _landmarks[index];
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

  Widget _buildTabletGrid(BuildContext context) {
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
      itemCount: _landmarks.length,
      itemBuilder: (context, index) {
        final landmark = _landmarks[index];
        return LandmarkCard(
          landmark: landmark,
          onTap: () => _navigateToDetail(landmark),
        );
      },
    );
  }

  Future<void> _navigateToDetail(Landmark landmark) async {
    final dynamic result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LandmarkDetailScreen(landmark: landmark),
      ),
    );

    if (result is String) {
      setState(() {
        landmark.isVisited = true;
        landmark.imageUrl = result;
      });
    }
  }
}
