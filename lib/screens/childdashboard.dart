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
  int _onboardingStep = 0;
  int _selectedAge = 6;
  String? _selectedAvatar;
  String? _selectedHand;
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

    if (_childName == null || _avatarPath == null) {
      setState(() { _needsSetup = true; _isLoading = false; });
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
          .map((s) => s['startTime'] as String? ?? '99:99').toList();
      final timesB = (_activitySchedules[b] ?? [])
          .map((s) => s['startTime'] as String? ?? '99:99').toList();
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
    return '$earliest · $duration min';
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_needsSetup) {
      return _onboardingStep == 0 ? _buildAvatarPage() : _buildHandPreferencePage();
    }
    return _buildDashboard();
  }

  // ─── STEP 1: NAME + AVATAR ──────────────────────────────────────────────────
  Widget _buildAvatarPage() {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (_, __) => Scaffold(
        resizeToAvoidBottomInset: false,
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
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                final isWide = constraints.maxWidth >= 600;
                return isWide
                    ? _avatarPageWide(constraints)
                    : _avatarPageNarrow(constraints);
              },
            ),
          ),
        ),
      ),
    );
  }

  // Wide layout: left branding panel + right form
  Widget _avatarPageWide(BoxConstraints c) {
    const accent = Color(0xFFE8724A);
    final leftW = c.maxWidth * 0.36;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── LEFT: branding + avatar preview ─────────────────────────────────
        Container(
          width: leftW,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [accent.withOpacity(0.22), accent.withOpacity(0.06)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Step pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text('Step 1 of 2',
                    style: GoogleFonts.fredoka(fontSize: 12, color: accent, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 18),
              const Text('🌟', style: TextStyle(fontSize: 42)),
              const SizedBox(height: 10),
              Text(
                'Pick Your\nAvatar!',
                textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(
                  fontSize: 26, fontWeight: FontWeight.w700, color: const Color(0xFF444444)),
              ),
              const SizedBox(height: 28),
              // Selected avatar live preview
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.70),
                  border: Border.all(
                    color: _selectedAvatar != null ? accent : Colors.black12,
                    width: 3.5,
                  ),
                  boxShadow: _selectedAvatar != null
                      ? [BoxShadow(color: accent.withOpacity(0.30), blurRadius: 22, spreadRadius: 1)]
                      : [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 12)],
                ),
                child: ClipOval(
                  child: _selectedAvatar != null
                      ? Image.asset(_selectedAvatar!, fit: BoxFit.cover)
                      : Center(child: Text('👤', style: TextStyle(fontSize: 44))),
                ),
              ),
              const SizedBox(height: 10),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _selectedAvatar != null ? '✓ Looking great!' : 'Tap an avatar →',
                  key: ValueKey(_selectedAvatar),
                  style: GoogleFonts.fredoka(
                    fontSize: 13,
                    color: accent.withOpacity(0.80),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Thin separator
        Container(width: 1, color: Colors.black.withOpacity(0.07)),

        // ── RIGHT: form ──────────────────────────────────────────────────────
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _fieldLabel("Your name"),
                const SizedBox(height: 8),
                _nameField(),
                const SizedBox(height: 18),
                _fieldLabel('Age'),
                const SizedBox(height: 8),
                _ageWidget(),
                const SizedBox(height: 18),
                _fieldLabel('Choose your avatar'),
                const SizedBox(height: 8),
                SizedBox(height: 84, child: _avatarScroll()),
                const Spacer(),
                _navBar(
                  onBack: null,
                  onNext: _avatarNext,
                  nextLabel: 'Next  →',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Narrow layout: compact single column
  Widget _avatarPageNarrow(BoxConstraints c) {
    const accent = Color(0xFFE8724A);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Compact header bar
        Container(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.10),
          ),
          child: Row(
            children: [
              Text('🌟', style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Pick your avatar!',
                  style: GoogleFonts.fredoka(
                    fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFF444444)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text('1 / 2',
                    style: GoogleFonts.fredoka(fontSize: 12, color: accent, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _fieldLabel('Your name'),
                const SizedBox(height: 6),
                _nameField(compact: true),
                const SizedBox(height: 12),
                _fieldLabel('Age'),
                const SizedBox(height: 6),
                _ageWidget(compact: true),
                const SizedBox(height: 12),
                _fieldLabel('Choose your avatar'),
                const SizedBox(height: 6),
                SizedBox(height: 76, child: _avatarScroll(itemSize: 68)),
                const Spacer(),
              ],
            ),
          ),
        ),

        _navBar(onBack: null, onNext: _avatarNext, nextLabel: 'Next  →'),
      ],
    );
  }

  void _avatarNext() {
    if (_nameController.text.trim().isEmpty || _selectedAvatar == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please enter your name and pick an avatar!', style: GoogleFonts.fredoka()),
        backgroundColor: const Color(0xFFE8724A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }
    setState(() => _onboardingStep = 1);
  }

  // ── Shared form sub-widgets ─────────────────────────────────────────────────
  Widget _fieldLabel(String text) => Text(
        text,
        style: GoogleFonts.fredoka(
          fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF555555)),
      );

  Widget _nameField({bool compact = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.80),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: const Color(0xFFE8A07A).withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 3)),
        ],
      ),
      child: TextField(
        controller: _nameController,
        style: GoogleFonts.fredoka(fontSize: compact ? 16 : 17),
        decoration: InputDecoration(
          hintText: 'Type your name here...',
          hintStyle: GoogleFonts.fredoka(fontSize: 15, color: Colors.black26),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: EdgeInsets.symmetric(
              horizontal: 18, vertical: compact ? 12 : 15),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 14, right: 6),
            child: Text('👤', style: TextStyle(fontSize: 20)),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        ),
      ),
    );
  }

  Widget _ageWidget({bool compact = false}) {
    const accent = Color(0xFFE8724A);
    return Container(
      padding: EdgeInsets.fromLTRB(16, compact ? 8 : 10, 16, compact ? 4 : 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text('3', style: GoogleFonts.fredoka(fontSize: 13, color: Colors.black38)),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: accent,
                inactiveTrackColor: accent.withOpacity(0.18),
                thumbColor: accent,
                overlayColor: accent.withOpacity(0.12),
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              ),
              child: Slider(
                value: _selectedAge.toDouble(),
                min: 3, max: 13, divisions: 10,
                onChanged: (v) => setState(() => _selectedAge = v.round()),
              ),
            ),
          ),
          Text('13', style: GoogleFonts.fredoka(fontSize: 13, color: Colors.black38)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: accent, borderRadius: BorderRadius.circular(50)),
            child: Text(
              '$_selectedAge yrs',
              style: GoogleFonts.fredoka(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarScroll({double itemSize = 76}) {
    const accent = Color(0xFFE8724A);
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: _avatarOptions.length,
      itemBuilder: (context, index) {
        final path = _avatarOptions[index];
        final selected = _selectedAvatar == path;
        return GestureDetector(
          onTap: () => setState(() => _selectedAvatar = path),
          child: Padding(
            padding: EdgeInsets.only(left: index == 0 ? 0 : 10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: itemSize,
              height: itemSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? accent : Colors.black12,
                  width: selected ? 3.5 : 1.5,
                ),
                boxShadow: selected
                    ? [BoxShadow(color: accent.withOpacity(0.40), blurRadius: 14, spreadRadius: 1)]
                    : [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: ClipOval(child: Image.asset(path, fit: BoxFit.cover)),
            ),
          ),
        );
      },
    );
  }

  // ─── STEP 2: HAND PREFERENCE ────────────────────────────────────────────────
  Widget _buildHandPreferencePage() {
    const accent = Color(0xFF5A8A5A);
    return AnimatedBuilder(
      animation: _bgController,
      builder: (_, __) => Scaffold(
        resizeToAvoidBottomInset: false,
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
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                final isWide = constraints.maxWidth >= 600;
                return Column(
                  children: [
                    // ── Header ─────────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _onboardingStep = 0),
                            child: Container(
                              width: 38, height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.65),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.arrow_back_ios_new_rounded,
                                  size: 16, color: Color(0xFF666666)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text('✋', style: const TextStyle(fontSize: 26)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Which hand do you use?',
                              style: GoogleFonts.fredoka(
                                  fontSize: 19, fontWeight: FontWeight.w700,
                                  color: const Color(0xFF3A5A3A)),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Text('2 / 2',
                                style: GoogleFonts.fredoka(
                                    fontSize: 12, color: accent, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),

                    // ── Subtitle ─────────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.50),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          'We\'ll personalise the experience for your choice',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.fredoka(
                            fontSize: 13, color: const Color(0xFF4A7A4A)),
                        ),
                      ),
                    ),

                    // ── Hand cards ───────────────────────────────────────────
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isWide ? 48 : 20, vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: _buildHandCard(hand: 'left', compact: !isWide)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildHandCard(hand: 'right', compact: !isWide)),
                          ],
                        ),
                      ),
                    ),

                    // ── Selection indicator ──────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 4),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: _selectedHand != null
                            ? Container(
                                key: ValueKey(_selectedHand),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                decoration: BoxDecoration(
                                  color: accent.withOpacity(0.14),
                                  borderRadius: BorderRadius.circular(50),
                                  border: Border.all(color: accent.withOpacity(0.25)),
                                ),
                                child: Text(
                                  _selectedHand == 'left'
                                      ? '🎉 Left hand selected!'
                                      : '🎉 Right hand selected!',
                                  style: GoogleFonts.fredoka(
                                      fontSize: 14, color: const Color(0xFF3A6A3A),
                                      fontWeight: FontWeight.w600),
                                ),
                              )
                            : const SizedBox(key: ValueKey('empty'), height: 36),
                      ),
                    ),

                    // ── Nav bar ──────────────────────────────────────────────
                    _navBar(
                      onBack: () => setState(() => _onboardingStep = 0),
                      onNext: () {
                        if (_selectedHand == null) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Please choose your favourite hand!', style: GoogleFonts.fredoka()),
                            backgroundColor: accent,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ));
                          return;
                        }
                        _saveProfile();
                      },
                      nextLabel: "Let's Start! 🚀",
                      nextColor: accent,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHandCard({required String hand, bool compact = false}) {
    final isLeft = hand == 'left';
    final isSelected = _selectedHand == hand;
    final label = isLeft ? 'Left Hand' : 'Right Hand';
    final accentColor = isLeft ? const Color(0xFF6AADDA) : const Color(0xFFE8724A);
    final handSize = compact ? 72.0 : 88.0;

    return GestureDetector(
      onTap: () => setState(() => _selectedHand = hand),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          vertical: compact ? 16 : 22, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: isSelected ? accentColor.withOpacity(0.12) : Colors.white.withOpacity(0.65),
          border: Border.all(
            color: isSelected ? accentColor : Colors.transparent, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: isSelected ? accentColor.withOpacity(0.28) : Colors.black.withOpacity(0.06),
              blurRadius: isSelected ? 22 : 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _handPulseAnim,
              builder: (_, __) => Transform.scale(
                scale: isSelected ? _handPulseAnim.value : 1.0,
                child: _HandIllustration(
                  isLeft: isLeft,
                  color: isSelected ? accentColor : const Color(0xFF9E9E9E),
                  size: handSize,
                ),
              ),
            ),
            SizedBox(height: compact ? 10 : 14),
            Text(
              label,
              style: GoogleFonts.fredoka(
                fontSize: compact ? 17 : 20,
                fontWeight: FontWeight.w700,
                color: isSelected ? accentColor : const Color(0xFF666666),
              ),
            ),
            SizedBox(height: compact ? 2 : 4),
            Text(
              isLeft ? 'I write with my left' : 'I write with my right',
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                fontSize: compact ? 11 : 13,
                color: isSelected ? accentColor.withOpacity(0.70) : const Color(0xFF999999),
              ),
            ),
            SizedBox(height: compact ? 8 : 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 26, height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? accentColor : Colors.transparent,
                border: Border.all(
                    color: isSelected ? accentColor : const Color(0xFFCCCCCC), width: 2.5),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared nav bar ──────────────────────────────────────────────────────────
  Widget _navBar({
    required VoidCallback? onBack,
    required VoidCallback onNext,
    required String nextLabel,
    Color nextColor = const Color(0xFFE8724A),
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Row(
        children: [
          if (onBack != null) ...[
            GestureDetector(
              onTap: onBack,
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: Color(0xFF666666)),
                    const SizedBox(width: 5),
                    Text('Back',
                        style: GoogleFonts.fredoka(
                            fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF666666))),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: GestureDetector(
              onTap: onNext,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: nextColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: nextColor.withOpacity(0.38),
                        blurRadius: 14, offset: const Offset(0, 5)),
                  ],
                ),
                child: Center(
                  child: Text(
                    nextLabel,
                    style: GoogleFonts.fredoka(
                        fontSize: 16, fontWeight: FontWeight.w700,
                        color: Colors.white, letterSpacing: 0.2),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── MAIN DASHBOARD ─────────────────────────────────────────────────────────
  Widget _buildDashboard() {
    final scheduledActivities = _getTodaysScheduledActivities();

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (ctx, constraints) {
            final isWide = constraints.maxWidth >= 600;
            return Column(
              children: [
                // ── Greeting header ─────────────────────────────────────────
                Container(
                  padding: EdgeInsets.fromLTRB(
                      isWide ? 28 : 18, isWide ? 18 : 14,
                      isWide ? 28 : 18, isWide ? 18 : 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFFF0E8),
                        const Color(0xFFFDE8D8),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: isWide ? 52 : 44,
                        height: isWide ? 52 : 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE8724A), width: 2.5),
                          boxShadow: [
                            BoxShadow(
                                color: const Color(0xFFE8724A).withOpacity(0.25),
                                blurRadius: 10),
                          ],
                        ),
                        child: ClipOval(
                          child: _avatarPath != null
                              ? Image.asset(_avatarPath!, fit: BoxFit.cover)
                              : const Icon(Icons.person, size: 28, color: Color(0xFFE8724A)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hi, ${_childName ?? 'Friend'}! 👋',
                              style: GoogleFonts.fredoka(
                                fontSize: isWide ? 24 : 20,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF3D3D3D),
                              ),
                            ),
                            Text(
                              scheduledActivities.isEmpty
                                  ? 'Nothing planned today'
                                  : "${scheduledActivities.length} activit${scheduledActivities.length == 1 ? 'y' : 'ies'} today",
                              style: GoogleFonts.fredoka(
                                fontSize: 13, color: const Color(0xFF888888)),
                            ),
                          ],
                        ),
                      ),
                      // Nyota star badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8724A).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text('⭐ NYOTA',
                            style: GoogleFonts.fredoka(
                                fontSize: 13, color: const Color(0xFFE8724A),
                                fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                      ),
                    ],
                  ),
                ),

                // ── Activity list / grid ────────────────────────────────────
                Expanded(
                  child: scheduledActivities.isEmpty
                      ? _buildEmptyState()
                      : isWide
                          ? _buildActivityGrid(scheduledActivities)
                          : _buildActivityList(scheduledActivities),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Wide: 2×2 grid
  Widget _buildActivityGrid(List<String> activities) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 3.0,
        ),
        itemCount: activities.length,
        itemBuilder: (ctx, i) {
          final name = activities[i];
          return _buildActivityCard(name, _completedToday[name] == true, wide: true);
        },
      ),
    );
  }

  // Narrow: vertical list
  Widget _buildActivityList(List<String> activities) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: activities.length,
      itemBuilder: (ctx, i) {
        final name = activities[i];
        return _buildActivityCard(name, _completedToday[name] == true);
      },
    );
  }

  Widget _buildActivityCard(String activityName, bool completed, {bool wide = false}) {
    final color = _getActivityColor(activityName);
    final timeHint = _getTimeHint(activityName);
    final iconSize = wide ? 36.0 : 40.0;
    final boxSize = wide ? 56.0 : 64.0;

    return GestureDetector(
      onTap: completed ? null : () => _startActivity(activityName),
      child: Container(
        margin: EdgeInsets.only(bottom: wide ? 0 : 12),
        padding: EdgeInsets.all(wide ? 14 : 14),
        decoration: BoxDecoration(
          color: completed ? color.withOpacity(0.10) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: completed
              ? Border.all(color: AppTheme.success, width: 2.5)
              : Border.all(color: color.withOpacity(0.12), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: completed
                  ? AppTheme.success.withOpacity(0.10)
                  : color.withOpacity(0.14),
              blurRadius: 12, offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: boxSize, height: boxSize,
              decoration: BoxDecoration(
                color: color.withOpacity(0.18),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(_getActivityIcon(activityName), size: iconSize, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    activityName,
                    style: GoogleFonts.fredoka(
                      fontSize: wide ? 17 : 19,
                      fontWeight: FontWeight.w700,
                      color: completed ? AppTheme.success : const Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeHint,
                    style: GoogleFonts.fredoka(
                        fontSize: 13, color: const Color(0xFF999999)),
                  ),
                ],
              ),
            ),
            if (completed)
              Icon(Icons.check_circle_rounded, color: AppTheme.success, size: wide ? 28 : 34)
            else
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.play_arrow_rounded, color: color, size: 20),
              ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📚', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 18),
            Text(
              'Nothing planned today',
              style: GoogleFonts.fredoka(
                  fontSize: 22, fontWeight: FontWeight.w600, color: const Color(0xFF555555)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Your parent will add some fun learning soon!',
              style: GoogleFonts.fredoka(fontSize: 15, color: const Color(0xFF999999)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── HAND ILLUSTRATION ──────────────────────────────────────────────────────
class _HandIllustration extends StatelessWidget {
  final bool isLeft;
  final Color color;
  final double size;

  const _HandIllustration({required this.isLeft, required this.color, required this.size});

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
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final w = size.width; final h = size.height;

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

    final thumbPath = Path()
      ..moveTo(w * 0.20, h * 0.55)
      ..quadraticBezierTo(w * 0.08, h * 0.48, w * 0.05, h * 0.40)
      ..quadraticBezierTo(w * 0.02, h * 0.28, w * 0.08, h * 0.22)
      ..quadraticBezierTo(w * 0.14, h * 0.16, w * 0.22, h * 0.20)
      ..quadraticBezierTo(w * 0.28, h * 0.24, w * 0.28, h * 0.32)
      ..quadraticBezierTo(w * 0.28, h * 0.44, w * 0.22, h * 0.50)
      ..close();
    canvas.drawPath(thumbPath, paint);

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
