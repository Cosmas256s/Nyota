// lib/screens/childdashboard.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nyota/theme.dart';
import '../services/storage_service.dart';

// Activity screens
import 'shapesactivity.dart';
import 'shapes_hub.dart';
import 'countingmath.dart';
import 'basicmath.dart';
import 'advancemath.dart';

class ChildDashboard extends StatefulWidget {
  const ChildDashboard({super.key});

  @override
  State<ChildDashboard> createState() => _ChildDashboardState();
}

class _ChildDashboardState extends State<ChildDashboard> {
  String? _childName;
  String? _avatarPath;
  bool _isLoading = true;
  bool _needsSetup = false;

  // Onboarding variables
  int _selectedAge = 6;
  String? _selectedAvatar;
  final TextEditingController _nameController = TextEditingController();

  Map<String, List<Map<String, dynamic>>> _activitySchedules = {};
  Map<String, String?> _rewardImages = {};
  Map<String, bool> _completedToday = {};

  final List<String> _activityNames = [
    'Shapes',
    'Counting',
    'Basic Math',
    'Advanced Math',
  ];

  @override
  void initState() {
    super.initState();
    _checkProfileAndLoad();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _checkProfileAndLoad() async {
    final prefs = await SharedPreferences.getInstance();

    _childName = prefs.getString('childName');
    _avatarPath = prefs.getString('avatarPath');

    if (_childName == null || _avatarPath == null) {
      setState(() {
        _needsSetup = true;
        _isLoading = false;
      });
      return;
    }

    await _loadProfileAndSchedule();
  }

  Future<void> _loadProfileAndSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    final storage = StorageService();
    await storage.init();

    try {
      final schedules = await storage.loadActivitySchedules();
      final rewards = await storage.loadRewardImages();

      final completedList = prefs.getStringList('completedToday') ?? [];
      final completedMap = {for (var name in completedList) name: true};

      setState(() {
        _activitySchedules = schedules;
        _rewardImages = rewards;
        _completedToday = completedMap;
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading child data: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markCompleted(String activityName) async {
    final prefs = await SharedPreferences.getInstance();
    _completedToday[activityName] = true;
    await prefs.setStringList('completedToday', _completedToday.keys.toList());
    setState(() {});
  }

  List<String> _getTodaysScheduledActivities() {
    final scheduled = <String>[];

    for (final name in _activityNames) {
      final sessions = _activitySchedules[name] ?? [];
      if (sessions.isNotEmpty) {
        scheduled.add(name);
      }
    }

    scheduled.sort((a, b) {
      final timesA = (_activitySchedules[a] ?? []).map((s) => s['startTime'] as String? ?? '99:99').toList();
      final timesB = (_activitySchedules[b] ?? []).map((s) => s['startTime'] as String? ?? '99:99').toList();
      final earliestA = timesA.isEmpty ? '99:99' : timesA.reduce((x, y) => x.compareTo(y) < 0 ? x : y);
      final earliestB = timesB.isEmpty ? '99:99' : timesB.reduce((x, y) => x.compareTo(y) < 0 ? x : y);
      return earliestA.compareTo(earliestB);
    });

    return scheduled;
  }

  String _getTimeHint(String activityName) {
    final sessions = _activitySchedules[activityName] ?? [];
    if (sessions.isEmpty) return 'Not scheduled';

    final earliest = sessions
        .map((s) => s['startTime'] as String? ?? '??:??')
        .reduce((a, b) => a.compareTo(b) < 0 ? a : b);

    final duration = sessions.isNotEmpty ? sessions.first['duration'] as int? ?? 15 : 15;
    return '$earliest • $duration min';
  }

  void _startActivity(String activityName) {
    print("startActivity called → $activityName");

    switch (activityName) {
      case 'Shapes':
        print("Launching ShapesHubScreen");
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ShapesHubScreen(
              onSessionComplete: () => _markCompleted(activityName),
              rewardImagePath: _rewardImages[activityName],
            ),
          ),
        );
        return;

      case 'Counting':
        print("Launching CountingActivityScreen");
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CountingActivityScreen(
              onSessionComplete: () => _markCompleted(activityName),
              rewardImagePath: _rewardImages[activityName],
            ),
          ),
        );
        return;

      case 'Basic Math':
        print("Launching BasicMathActivityScreen");
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BasicMathActivityScreen(
              onSessionComplete: () => _markCompleted(activityName),
              rewardImagePath: _rewardImages[activityName],
            ),
          ),
        );
        return;

      case 'Advanced Math':
        print("Launching AdvancedMathActivityScreen");
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdvancedMathActivityScreen(
              onSessionComplete: () => _markCompleted(activityName),
              rewardImagePath: _rewardImages[activityName],
            ),
          ),
        );
        return;

      default:
        print("Unknown activity name: $activityName");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Activity '$activityName' not implemented yet")),
        );
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_needsSetup) {
      return _buildOnboardingScreen();
    }

    final scheduledActivities = _getTodaysScheduledActivities();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header with avatar + greeting
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: colorScheme.surface,
                    backgroundImage: _avatarPath != null ? AssetImage(_avatarPath!) : null,
                    child: _avatarPath == null
                        ? const Icon(Icons.person, size: 40)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    "Hi ${_childName ?? 'Friend'}!",
                    style: GoogleFonts.fredoka(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: scheduledActivities.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: scheduledActivities.length,
                      itemBuilder: (context, index) {
                        final name = scheduledActivities[index];
                        final completed = _completedToday[name] == true;
                        return _buildActivityCard(name, completed);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingScreen() {
    final colorScheme = Theme.of(context).colorScheme;
    final List<String> avatarOptions = [
      'assets/images/avatar1.png',
      'assets/images/avatar2.png',
      'assets/images/avatar3.png',
      'assets/images/avatar4.png',
      'assets/images/avatar5.png',
      'assets/images/avatar6.png',
      'assets/images/avatar7.png',
      'assets/images/avatar8.png',
    ];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hi there! Let's get to know you",
                style: GoogleFonts.fredoka(fontSize: 28, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 32),

              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "Your name",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 24),

              Text("How old are you?", style: GoogleFonts.fredoka(fontSize: 18)),
              Slider(
                value: _selectedAge.toDouble(),
                min: 3,
                max: 13,
                divisions: 10,
                label: _selectedAge.toString(),
                onChanged: (v) {
                  setState(() => _selectedAge = v.round());
                },
              ),
              const SizedBox(height: 24),

              Text("Pick your avatar!", style: GoogleFonts.fredoka(fontSize: 18)),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: avatarOptions.length,
                  itemBuilder: (context, index) {
                    final path = avatarOptions[index];
                    final selected = _selectedAvatar == path;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedAvatar = path),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? colorScheme.primary : Colors.transparent,
                            width: 4,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundImage: AssetImage(path),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    if (_nameController.text.trim().isNotEmpty && _selectedAvatar != null) {
                      _saveProfile(
                        _nameController.text.trim(),
                        _selectedAge,
                        _selectedAvatar!,
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please fill everything!")),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary),
                  child: Text("Let's Start!", style: GoogleFonts.fredoka(fontSize: 20, color: colorScheme.onPrimary)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile(String name, int age, String avatar) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('childName', name);
    await prefs.setInt('childAge', age);
    await prefs.setString('avatarPath', avatar);

    setState(() {
      _childName = name;
      _avatarPath = avatar;
      _needsSetup = false;
    });

    await _loadProfileAndSchedule();
  }

  Widget _buildActivityCard(String activityName, bool completed) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = _getActivityColor(activityName);
    final timeHint = _getTimeHint(activityName);

    return GestureDetector(
      onTap: completed ? null : () => _startActivity(activityName),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: completed ? color.withOpacity(0.15) : colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: completed ? Border.all(color: AppTheme.success, width: 3) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: color.withOpacity(0.25),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                _getActivityIcon(activityName),
                size: 48,
                color: color,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activityName,
                    style: GoogleFonts.fredoka(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: completed ? AppTheme.success : colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeHint,
                    style: GoogleFonts.fredoka(
                      fontSize: 15,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (completed)
              const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 40),
          ],
        ),
      ),
    );
  }

  IconData _getActivityIcon(String name) {
    switch (name) {
      case 'Shapes': return Icons.category_rounded;
      case 'Counting': return Icons.calculate_rounded;
      case 'Basic Math': return Icons.add_circle_rounded;
      case 'Advanced Math': return Icons.grid_view_rounded;
      default: return Icons.star_rounded;
    }
  }

  Color _getActivityColor(String name) {
    switch (name) {
      case 'Shapes': return const Color(0xFFFF6B6B);
      case 'Counting': return const Color(0xFF4ECDC4);
      case 'Basic Math': return const Color(0xFF45B7D1);
      case 'Advanced Math': return const Color(0xFF96CEB4);
      default: return AppTheme.seedColor;
    }
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sentiment_satisfied_alt_rounded,
              size: 90,
              color: colorScheme.secondary.withOpacity(0.6),
            ),
            const SizedBox(height: 24),
            Text(
              "Nothing planned today",
              style: GoogleFonts.fredoka(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "Your parent will add some fun learning soon!",
              style: GoogleFonts.fredoka(
                fontSize: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}