// lib/screens/childdashboard.dart
import 'dart:math' as math;
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

class _ChildDashboardState extends State<ChildDashboard>
    with TickerProviderStateMixin {
  String? _childName;
  String? _avatarPath;
  bool _isLoading = true;
  bool _needsSetup = false;

  // Onboarding state
  int _onboardingStep = 0; // 0 = name/avatar, 1 = hand preference
  int _selectedAge = 6;
  String? _selectedAvatar;
  String? _selectedHand; // 'left' or 'right'
  final TextEditingController _nameController = TextEditingController();

  // Animation controllers
  late AnimationController _pageController;
  late AnimationController _handPulseController;
  late Animation<double> _handPulseAnim;
  late AnimationController _bgController;

  Map<String, List<Map<String, dynamic>>> _activitySchedules = {};
  Map<String, String?> _rewardImages = {};
  Map<String, bool> _completedToday = {};

  final List<String> _activityNames = [
    'Shapes',
    'Counting',
    'Basic Math',
    'Advanced Math',
  ];

  final List<String> _avatarOptions = [
    'assets/images/avatar1.png',
    'assets/images/avatar2.png',
    'assets/images/avatar3.png',
    'assets/images/avatar4.png',
    'assets/images/avatar5.png',
    'assets/images/avatar6.png',
    'assets/images/avatar7.png',
    'assets/images/avatar8.png',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    )..forward();

    _handPulseController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat(reverse: true);

    _handPulseAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _handPulseController, curve: Curves.easeInOut),
    );

    _bgController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);

    _checkProfileAndLoad();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pageController.dispose();
    _handPulseController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  Future<void> _checkProfileAndLoad() async {
    final prefs = await SharedPreferences.getInstance();
    _childName = prefs.getString('childName');
    _avatarPath = prefs.getString('avatarPath');

    // Only new users (no profile) go through onboarding
    if (_childName == null || _avatarPath == null) {
      setState(() {
        _needsSetup = true;
        _isLoading = false;
      });
      return;
    }

    // Existing users with an established profile skip onboarding entirely
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
      if (sessions.isNotEmpty) scheduled.add(name);
    }
    scheduled.sort((a, b) {
      final timesA = (_activitySchedules[a] ?? [])
          .map((s) => s['startTime'] as String? ?? '99:99')
          .toList();
      final timesB = (_activitySchedules[b] ?? [])
          .map((s) => s['startTime'] as String? ?? '99:99')
          .toList();
      final earliestA =
          timesA.isEmpty ? '99:99' : timesA.reduce((x, y) => x.compareTo(y) < 0 ? x : y);
      final earliestB =
          timesB.isEmpty ? '99:99' : timesB.reduce((x, y) => x.compareTo(y) < 0 ? x : y);
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
    switch (activityName) {
      case 'Shapes':
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => ShapesHubScreen(
            onSessionComplete: () => _markCompleted(activityName),
            rewardImagePath: _rewardImages[activityName],
          ),
        ));
        break;
      case 'Counting':
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => CountingActivityScreen(
            onSessionComplete: () => _markCompleted(activityName),
            rewardImagePath: _rewardImages[activityName],
          ),
        ));
        break;
      case 'Basic Math':
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => BasicMathActivityScreen(
            onSessionComplete: () => _markCompleted(activityName),
            rewardImagePath: _rewardImages[activityName],
          ),
        ));
        break;
      case 'Advanced Math':
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => AdvancedMathActivityScreen(
            onSessionComplete: () => _markCompleted(activityName),
            rewardImagePath: _rewardImages[activityName],
          ),
        ));
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Activity '$activityName' not implemented yet")),
        );
    }
  }

  // ─── SAVE ───────────────────────────────────────────────────────────────────
  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('childName', _nameController.text.trim());
    await prefs.setInt('childAge', _selectedAge);
    await prefs.setString('avatarPath', _selectedAvatar!);
    if (_selectedHand != null) {
      await prefs.setString('dominantHand', _selectedHand!);
    }

    setState(() {
      _childName = _nameController.text.trim();
      _avatarPath = _selectedAvatar;
      _needsSetup = false;
    });

    await _loadProfileAndSchedule();
  }

  // ─── ONBOARDING ENTRY ───────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_needsSetup) {
      return _onboardingStep == 0
          ? _buildAvatarPage()
          : _buildHandPreferencePage();
    }

    return _buildDashboard();
  }

  // ─── STEP 1: NAME + AVATAR ──────────────────────────────────────────────────
  Widget _buildAvatarPage() {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (_, __) => Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(const Color(0xFFFFF0E8), const Color(0xFFFFE4D6), _bgController.value)!,
                Color.lerp(const Color(0xFFFDE8D8), const Color(0xFFF5C9B0), _bgController.value)!,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildOnboardingHeader('Step 1 of 2', 'Pick your avatar!', '🌟', canGoBack: false),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name field
                        _label("What's your name?"),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.75),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE8A07A).withOpacity(0.18),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _nameController,
                            style: GoogleFonts.fredoka(fontSize: 18),
                            decoration: InputDecoration(
                              hintText: 'Type your name here...',
                              hintStyle: GoogleFonts.fredoka(
                                fontSize: 16,
                                color: Colors.black26,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.transparent,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              prefixIcon: const Padding(
                                padding: EdgeInsets.only(left: 14, right: 8),
                                child: Text('👤', style: TextStyle(fontSize: 22)),
                              ),
                              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Age slider
                        _label('How old are you?'),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.75),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('3', style: GoogleFonts.fredoka(fontSize: 14, color: Colors.black38)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8724A),
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    child: Text(
                                      '$_selectedAge years old',
                                      style: GoogleFonts.fredoka(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  Text('13', style: GoogleFonts.fredoka(fontSize: 14, color: Colors.black38)),
                                ],
                              ),
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: const Color(0xFFE8724A),
                                  inactiveTrackColor: const Color(0xFFE8724A).withOpacity(0.2),
                                  thumbColor: const Color(0xFFE8724A),
                                  overlayColor: const Color(0xFFE8724A).withOpacity(0.15),
                                ),
                                child: Slider(
                                  value: _selectedAge.toDouble(),
                                  min: 3,
                                  max: 13,
                                  divisions: 10,
                                  onChanged: (v) => setState(() => _selectedAge = v.round()),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Avatar picker
                        _label('Choose your avatar!'),
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                          ),
                          itemCount: _avatarOptions.length,
                          itemBuilder: (context, index) {
                            final path = _avatarOptions[index];
                            final selected = _selectedAvatar == path;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedAvatar = path),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: selected ? const Color(0xFFE8724A) : Colors.transparent,
                                    width: 3.5,
                                  ),
                                  boxShadow: selected
                                      ? [BoxShadow(color: const Color(0xFFE8724A).withOpacity(0.35), blurRadius: 12)]
                                      : [],
                                ),
                                child: ClipOval(
                                  child: Image.asset(path, fit: BoxFit.cover),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
                // Next button
                _buildNavBar(
                  onBack: null,
                  onNext: () {
                    if (_nameController.text.trim().isEmpty || _selectedAvatar == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please enter your name and pick an avatar!',
                              style: GoogleFonts.fredoka()),
                          backgroundColor: const Color(0xFFE8724A),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                      return;
                    }
                    setState(() => _onboardingStep = 1);
                  },
                  nextLabel: 'Next  →',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── STEP 2: HAND PREFERENCE ────────────────────────────────────────────────
  Widget _buildHandPreferencePage() {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (_, __) => Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(const Color(0xFFE8F4E8), const Color(0xFFD4EDD4), _bgController.value)!,
                Color.lerp(const Color(0xFFD4EDD4), const Color(0xFFC8E4C8), _bgController.value)!,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildOnboardingHeader('Step 2 of 2', 'Which hand do you use?', '✋', canGoBack: true),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        // Subtitle
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Text(
                            'We\'ll personalise the experience for this choice',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.fredoka(
                              fontSize: 15,
                              color: const Color(0xFF4A7A4A),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Hand cards
                        Row(
                          children: [
                            Expanded(child: _buildHandCard(hand: 'left')),
                            const SizedBox(width: 16),
                            Expanded(child: _buildHandCard(hand: 'right')),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Selected indicator
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _selectedHand != null
                              ? Container(
                                  key: ValueKey(_selectedHand),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF5A8A5A).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(50),
                                    border: Border.all(
                                      color: const Color(0xFF5A8A5A).withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    _selectedHand == 'left'
                                        ? '🎉 Great! Left hand selected'
                                        : '🎉 Great! Right hand selected',
                                    style: GoogleFonts.fredoka(
                                      fontSize: 15,
                                      color: const Color(0xFF3A6A3A),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )
                              : const SizedBox(key: ValueKey('empty'), height: 44),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                _buildNavBar(
                  onBack: () => setState(() => _onboardingStep = 0),
                  onNext: () {
                    if (_selectedHand == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please choose your favourite hand!',
                              style: GoogleFonts.fredoka()),
                          backgroundColor: const Color(0xFF5A8A5A),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                      return;
                    }
                    _saveProfile();
                  },
                  nextLabel: "Let's Start! 🚀",
                  nextColor: const Color(0xFF5A8A5A),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHandCard({required String hand}) {
    final isLeft = hand == 'left';
    final isSelected = _selectedHand == hand;
    final label = isLeft ? 'Left Hand' : 'Right Hand';
    final accentColor = isLeft ? const Color(0xFF6AADDA) : const Color(0xFFE8724A);

    return GestureDetector(
      onTap: () => setState(() => _selectedHand = hand),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: isSelected ? accentColor.withOpacity(0.12) : Colors.white.withOpacity(0.65),
          border: Border.all(
            color: isSelected ? accentColor : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? accentColor.withOpacity(0.30)
                  : Colors.black.withOpacity(0.06),
              blurRadius: isSelected ? 24 : 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // Hand illustration
            AnimatedBuilder(
              animation: _handPulseAnim,
              builder: (_, __) => Transform.scale(
                scale: isSelected ? _handPulseAnim.value : 1.0,
                child: _HandIllustration(
                  isLeft: isLeft,
                  color: isSelected ? accentColor : const Color(0xFF8B8B8B),
                  size: 100,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: GoogleFonts.fredoka(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isSelected ? accentColor : const Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isLeft ? 'I write with\nmy left' : 'I write with\nmy right',
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                fontSize: 13,
                color: isSelected
                    ? accentColor.withOpacity(0.75)
                    : const Color(0xFF999999),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? accentColor : Colors.transparent,
                border: Border.all(
                  color: isSelected ? accentColor : const Color(0xFFCCCCCC),
                  width: 2.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ─── SHARED ONBOARDING WIDGETS ──────────────────────────────────────────────
  Widget _buildOnboardingHeader(String stepLabel, String title, String emoji, {required bool canGoBack}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      child: Column(
        children: [
          Row(
            children: [
              if (canGoBack)
                GestureDetector(
                  onTap: () => setState(() => _onboardingStep = 0),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.65),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF666666)),
                  ),
                )
              else
                const SizedBox(width: 40),
              Expanded(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      stepLabel,
                      style: GoogleFonts.fredoka(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF888888),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 40),
            ],
          ),
          const SizedBox(height: 16),
          Text(emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.fredoka(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF444444),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNavBar({
    required VoidCallback? onBack,
    required VoidCallback onNext,
    required String nextLabel,
    Color nextColor = const Color(0xFFE8724A),
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      child: Row(
        children: [
          if (onBack != null) ...[
            GestureDetector(
              onTap: onBack,
              child: Container(
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFF666666)),
                    const SizedBox(width: 6),
                    Text(
                      'Back',
                      style: GoogleFonts.fredoka(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: GestureDetector(
              onTap: onNext,
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  color: nextColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: nextColor.withOpacity(0.40),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    nextLabel,
                    style: GoogleFonts.fredoka(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.fredoka(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF555555),
        ),
      );

  // ─── MAIN DASHBOARD ─────────────────────────────────────────────────────────
  Widget _buildDashboard() {
    final colorScheme = Theme.of(context).colorScheme;
    final scheduledActivities = _getTodaysScheduledActivities();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: colorScheme.surface,
                    backgroundImage:
                        _avatarPath != null ? AssetImage(_avatarPath!) : null,
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
              child: Icon(_getActivityIcon(activityName), size: 48, color: color),
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
            Icon(Icons.sentiment_satisfied_alt_rounded,
                size: 90, color: colorScheme.secondary.withOpacity(0.6)),
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

// ─── HAND ILLUSTRATION ─────────────────────────────────────────────────────────
class _HandIllustration extends StatelessWidget {
  final bool isLeft;
  final Color color;
  final double size;

  const _HandIllustration({
    required this.isLeft,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scaleX: isLeft ? -1.0 : 1.0,
      child: CustomPaint(
        size: Size(size, size * 1.1),
        painter: _HandPainter(color: color),
      ),
    );
  }
}

class _HandPainter extends CustomPainter {
  final Color color;
  _HandPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Palm
    final palmPath = Path()
      ..moveTo(w * 0.20, h * 0.55)
      ..quadraticBezierTo(w * 0.10, h * 0.50, w * 0.12, h * 0.38)
      ..quadraticBezierTo(w * 0.14, h * 0.28, w * 0.22, h * 0.28)
      ..quadraticBezierTo(w * 0.28, h * 0.28, w * 0.30, h * 0.36)
      ..lineTo(w * 0.30, h * 0.55)
      ..quadraticBezierTo(w * 0.35, h * 0.42, w * 0.40, h * 0.38)
      ..quadraticBezierTo(w * 0.45, h * 0.35, w * 0.50, h * 0.38)
      ..lineTo(w * 0.50, h * 0.55)
      ..quadraticBezierTo(w * 0.54, h * 0.40, w * 0.59, h * 0.38)
      ..quadraticBezierTo(w * 0.64, h * 0.36, w * 0.68, h * 0.40)
      ..lineTo(w * 0.68, h * 0.56)
      ..quadraticBezierTo(w * 0.72, h * 0.44, w * 0.76, h * 0.44)
      ..quadraticBezierTo(w * 0.84, h * 0.44, w * 0.84, h * 0.54)
      ..quadraticBezierTo(w * 0.84, h * 0.64, w * 0.78, h * 0.68)
      ..lineTo(w * 0.76, h * 0.72)
      ..quadraticBezierTo(w * 0.72, h * 0.82, w * 0.60, h * 0.88)
      ..quadraticBezierTo(w * 0.46, h * 0.96, w * 0.32, h * 0.92)
      ..quadraticBezierTo(w * 0.18, h * 0.88, w * 0.14, h * 0.74)
      ..quadraticBezierTo(w * 0.10, h * 0.62, w * 0.20, h * 0.55)
      ..close();

    canvas.drawPath(palmPath, paint);

    // Thumb
    final thumbPath = Path()
      ..moveTo(w * 0.20, h * 0.55)
      ..quadraticBezierTo(w * 0.08, h * 0.48, w * 0.05, h * 0.40)
      ..quadraticBezierTo(w * 0.02, h * 0.28, w * 0.08, h * 0.22)
      ..quadraticBezierTo(w * 0.14, h * 0.16, w * 0.22, h * 0.20)
      ..quadraticBezierTo(w * 0.28, h * 0.24, w * 0.28, h * 0.32)
      ..quadraticBezierTo(w * 0.28, h * 0.44, w * 0.22, h * 0.50)
      ..close();

    canvas.drawPath(thumbPath, paint);

    // Finger dividers (subtle lines)
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(w * 0.30, h * 0.55), Offset(w * 0.30, h * 0.36), linePaint);
    canvas.drawLine(Offset(w * 0.50, h * 0.55), Offset(w * 0.50, h * 0.38), linePaint);
    canvas.drawLine(Offset(w * 0.68, h * 0.56), Offset(w * 0.68, h * 0.40), linePaint);
  }

  @override
  bool shouldRepaint(_HandPainter old) => old.color != color;
}
