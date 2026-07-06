import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasources/landmark_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/scale_on_press.dart';
import 'category_selection_screen.dart';
import 'landmark_home_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final LandmarkApiService _apiService = LandmarkApiService();
  int _visitedCount = 0;
  final int _totalCount = 5;
  bool _isLoading = true;

  String _userName = "Voyageur";
  String _userAvatar = "";

  @override
  void initState() {
    super.initState();
    _loadProgress();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? "Voyageur";
      _userAvatar = prefs.getString('user_avatar') ?? "";
    });
  }

  Future<void> _loadProgress() async {
    try {
      final visited = await _apiService.getVisitedIds();
      if (mounted) {
        setState(() {
          _visitedCount = visited.length;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resetData() async {
    final prefs = await SharedPreferences.getInstance();

    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key == 'user_avatar' || key.startsWith('landmark_photo_')) {
        final path = prefs.getString(key);
        if (path != null && path.isNotEmpty) {
          try {
            final file = File(path);
            if (await file.exists()) {
              await file.delete();
            }
          } catch (_) {
            // Ignorer l'erreur pour ne pas bloquer la réinitialisation
          }
        }
      }
    }

    await prefs.clear();
    await _loadProgress();
    await _loadProfile();
  }

  void _showResetConfirmation() {
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
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_forever_outlined,
                  color: Colors.redAccent,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Tout réinitialiser ?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Cette action effacera définitivement votre progression (visites, photos) ainsi que votre profil.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    await _resetData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Toutes les données ont été réinitialisées."),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  child: const Text(
                    "Oui, réinitialiser",
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

  Widget _buildPlaceholderAvatar({double size = 48}) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3F51B5), Color(0xFF1A237E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person_rounded,
        color: Colors.white,
        size: size * 0.55,
      ),
    );
  }

  void _showProfileBottomSheet() {
    final TextEditingController nameController = TextEditingController(text: _userName);
    String? localAvatarPath = _userAvatar.isNotEmpty ? _userAvatar : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.borderLight,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Configurer votre Profil",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: localAvatarPath != null
                                  ? Image.file(
                                      File(localAvatarPath!),
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          _buildPlaceholderAvatar(size: 100),
                                    )
                                  : _buildPlaceholderAvatar(size: 100),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: ScaleOnPress(
                              onTap: () async {
                                final ImagePicker picker = ImagePicker();
                                final XFile? image = await picker.pickImage(
                                  source: ImageSource.gallery,
                                );
                                if (image != null) {
                                  setModalState(() {
                                    localAvatarPath = image.path;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF1A237E),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Votre prénom",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: "Entrez votre prénom",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.borderLight),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A237E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          final newName = nameController.text.trim();
                          if (newName.isNotEmpty) {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setString('user_name', newName);
                            if (localAvatarPath != null) {
                              await prefs.setString('user_avatar', localAvatarPath!);
                            } else {
                              await prefs.remove('user_avatar');
                            }
                            setState(() {
                              _userName = newName;
                              _userAvatar = localAvatarPath ?? "";
                            });
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          }
                        },
                        child: const Text(
                          "Enregistrer",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _navigateToLandmarks() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LandmarkHomeScreen()),
    );
    _loadProgress();
  }

  Future<void> _navigateToQuiz() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CategorySelectionScreen()),
    );
    _loadProgress();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Bonjour, $_userName",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "TravelQuizzie",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: _showProfileBottomSheet,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: _userAvatar.isNotEmpty
                            ? Image.file(
                                File(_userAvatar),
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildPlaceholderAvatar(size: 48),
                              )
                            : _buildPlaceholderAvatar(size: 48),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),
              const Text(
                "Vos applications",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 16),
              _buildMainCard(),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _buildQuizCard()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildProgressCard()),
                ],
              ),
              const SizedBox(height: 60),
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.15),
                      width: 1.5,
                    ),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 44),
                    tooltip: "Réinitialiser les données",
                    onPressed: _showResetConfirmation,
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainCard() {
    return ScaleOnPress(
      onTap: _navigateToLandmarks,
      child: Container(
        constraints: const BoxConstraints(minHeight: 180),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            alignment: Alignment.bottomLeft,
            children: [
              Positioned.fill(
                child: Image.network(
                  'https://images.unsplash.com/photo-1449034446853-66c86144b0ad?auto=format&fit=crop&w=800&q=80',
                  fit: BoxFit.cover,
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.1),
                        Colors.black.withValues(alpha: 0.85),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.cyan.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        "NATIVE & GPS",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Explorateur de Merveilles",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Parcourez le monde et validez votre présence sur les monuments historiques.",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Positioned(
                top: 20,
                right: 20,
                child: Icon(
                  Icons.explore_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuizCard() {
    return ScaleOnPress(
      onTap: _navigateToQuiz,
      child: Container(
        height: 160,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF3F51B5), Color(0xFF5C6BC0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3F51B5).withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(
              Icons.emoji_events_outlined,
              color: Colors.white,
              size: 28,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "TravelQuizzie",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Quiz de culture générale",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    final double progress = _totalCount > 0 ? _visitedCount / _totalCount : 0.0;
    return ScaleOnPress(
      onTap: _navigateToLandmarks,
      child: Container(
        height: 160,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Icon(
                  Icons.task_alt,
                  color: Color(0xFF10B981),
                  size: 24,
                ),
                Text(
                  "STATS",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _isLoading
                    ? const SizedBox(
                        height: 32,
                        width: 32,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10B981)),
                      )
                    : Text(
                        "$_visitedCount / $_totalCount",
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          letterSpacing: -1.0,
                        ),
                      ),
                const SizedBox(height: 2),
                const Text(
                  "Merveilles explorées",
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _isLoading ? 0.0 : progress,
                    backgroundColor: AppTheme.borderLight,
                    color: const Color(0xFF10B981),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
