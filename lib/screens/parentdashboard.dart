// lib/screens/parentdashboard.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:nyota/theme.dart';
import '../services/storage_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';  
import 'package:nyota/screens/theme_provider.dart';  // ← ADD THIS - adjust path as needed

// Import child activity screens so we can navigate with duration
import 'shapesactivity.dart';
import 'countingmath.dart';
import 'basicmath.dart';
import 'advancemath.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  bool _isLoading = true;
  bool _isAuthenticatedLocally = false;

  Map<String, List<Map<String, dynamic>>> _schedules = {
    'Shapes': [],
    'Counting': [],
    'Basic Math': [],
    'Advanced Math': [],
  };

  Map<String, String?> _rewardImages = {};

  final List<String> _activities = [
    'Shapes',
    'Counting',
    'Basic Math',
    'Advanced Math',
  ];

  bool _soundEnabled = true;
  // REMOVE: bool _isDarkMode = false;  // ← Remove this line

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  Future<void> _checkAccess() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasPin = prefs.containsKey('parent_pin');

      if (!hasPin) {
        final bool? pinSet = await _showPinSetupDialog();
        if (pinSet == true && mounted) {
          setState(() {
            _isAuthenticatedLocally = true;
            _isLoading = false;
          });
          _loadData();
        } else if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        setState(() => _isLoading = false);
        final bool? verified = await _showPinPromptDialog();
        if (verified == true && mounted) {
          setState(() => _isAuthenticatedLocally = true);
          _loadData();
        } else if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    } catch (e) {
      print("Error in _checkAccess: $e");
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<bool?> _showPinSetupDialog() async {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();
    final colorScheme = Theme.of(context).colorScheme;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          title: Text('Set Up Parent PIN', style: GoogleFonts.fredoka(fontWeight: FontWeight.w700, fontSize: 22.sp)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Please set a 4-6 digit PIN to secure the parent dashboard.', style: GoogleFonts.fredoka(fontSize: 15.sp, height: 1.4)),
              SizedBox(height: 20.h),
              TextField(
                controller: pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(labelText: 'Enter PIN', counterText: '', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r)), filled: true, fillColor: colorScheme.surfaceVariant),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: confirmController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(labelText: 'Confirm PIN', counterText: '', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r)), filled: true, fillColor: colorScheme.surfaceVariant),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text('Cancel', style: GoogleFonts.fredoka(color: AppTheme.error))),
            ElevatedButton(
              onPressed: () async {
                if (pinController.text.length < 4) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: const Text('PIN must be at least 4 digits'), backgroundColor: AppTheme.error));
                  return;
                }
                if (pinController.text != confirmController.text) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: const Text('PINs do not match'), backgroundColor: AppTheme.error));
                  return;
                }
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('parent_pin', pinController.text);
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r))),
              child: Text('Save PIN', style: GoogleFonts.fredoka(fontWeight: FontWeight.w600)),
            ),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        ),
      ),
    );
  }

  Future<bool?> _showPinPromptDialog() async {
    final pinController = TextEditingController();
    bool isRetry = false;
    final colorScheme = Theme.of(context).colorScheme;

    while (mounted) {
      final String? enteredPin = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            title: Text(isRetry ? 'Incorrect PIN' : 'Parent Verification Required', style: GoogleFonts.fredoka(fontWeight: FontWeight.w700, fontSize: 22.sp)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Enter your PIN to access the parent dashboard.', style: GoogleFonts.fredoka(fontSize: 15.sp, height: 1.4)),
                SizedBox(height: 20.h),
                TextField(
                  controller: pinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  autofocus: true,
                  decoration: InputDecoration(labelText: 'Enter PIN', counterText: '', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r)), filled: true, fillColor: colorScheme.surfaceVariant),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, 'logout'), child: Text('Log out', style: GoogleFonts.fredoka(color: AppTheme.error))),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, pinController.text.trim()),
                style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r))),
                child: Text('Verify', style: GoogleFonts.fredoka(fontWeight: FontWeight.w600)),
              ),
            ],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
          ),
        ),
      );

      if (enteredPin == 'logout') return false;

      if (enteredPin != null && enteredPin.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final storedPin = prefs.getString('parent_pin');
        if (storedPin != null && storedPin == enteredPin) return true;
      }

      isRetry = true;
      pinController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Incorrect PIN'), backgroundColor: AppTheme.error, duration: const Duration(seconds: 2)));
      }
    }
    return false;
  }

  Future<void> _loadData() async {
    try {
      final storage = StorageService();
      await storage.init();

      final loadedSchedules = await storage.loadActivitySchedules();
      final loadedRewards = await storage.loadRewardImages();
      final prefs = await SharedPreferences.getInstance();

      if (!mounted) return;

      setState(() {
        _schedules = loadedSchedules;
        _rewardImages = loadedRewards;
        _soundEnabled = prefs.getBool('sound_enabled') ?? true;
        // REMOVE: _isDarkMode = prefs.getBool('dark_mode') ?? false;
      });
    } catch (e) {
      print("Error loading data: $e");
    }
  }

  Future<void> _saveData() async {
    try {
      final storage = StorageService();
      await storage.saveActivitySchedules(_schedules);
      await storage.saveRewardImages(_rewardImages);
    } catch (e) {
      print("Error saving data: $e");
    }
  }

  void _openScheduleEditor(String activity) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28.r))),
      builder: (context) => _ScheduleEditorBottomSheet(
        activityName: activity,
        currentSessions: _schedules[activity] ?? [],
        onSave: (newSessions) {
          setState(() {
            _schedules[activity] = newSessions;
          });
          _saveData();
        },
      ),
    );
  }

  void _pickRewardImage(String activity) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null && mounted) {
      setState(() => _rewardImages[activity] = picked.path);
      _saveData();
    }
  }

  void _downloadReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: const Text('Report downloaded (placeholder)'), backgroundColor: AppTheme.success),
    );
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Get the theme provider
    final themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_isAuthenticatedLocally) {
      return const Scaffold(body: Center(child: Text('Verifying...')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Parent Dashboard", style: GoogleFonts.fredoka(fontWeight: FontWeight.w700, fontSize: 22.sp)),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.logout), tooltip: 'Log out', onPressed: _logout),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 80.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: 20.h),
                child: Text("Hi! Let's plan today's learning", style: GoogleFonts.fredoka(fontSize: 24.sp, fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
              ),

              Text("Daily Schedule", style: GoogleFonts.fredoka(fontSize: 20.sp, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant)),
              SizedBox(height: 12.h),
              ..._activities.map((act) => _buildSchedulerCard(act)),

              SizedBox(height: 40.h),
              Text("Reward Settings", style: GoogleFonts.fredoka(fontSize: 20.sp, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant)),
              SizedBox(height: 12.h),
              ..._activities.map((act) => _buildRewardCard(act)),

              SizedBox(height: 40.h),
              Text("App Settings", style: GoogleFonts.fredoka(fontSize: 20.sp, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant)),
              SizedBox(height: 12.h),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text("Sound Effects", style: GoogleFonts.fredoka(fontSize: 16.sp, fontWeight: FontWeight.w500)),
                      subtitle: Text("Play voice instructions during activities", style: GoogleFonts.fredoka(fontSize: 13.sp, color: colorScheme.onSurfaceVariant)),
                      value: _soundEnabled,
                      activeColor: colorScheme.secondary,
                      onChanged: (v) async {
                        setState(() => _soundEnabled = v);
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('sound_enabled', v);
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: Text("Dark Mode", style: GoogleFonts.fredoka(fontSize: 16.sp, fontWeight: FontWeight.w500)),
                      subtitle: Text("Reduce eye strain at night", style: GoogleFonts.fredoka(fontSize: 13.sp, color: colorScheme.onSurfaceVariant)),
                      value: themeProvider.isDarkMode,  // ← Use themeProvider
                      activeColor: colorScheme.secondary,
                      onChanged: (value) async {
                        // Update the global theme provider
                        themeProvider.toggleDarkMode(value);
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.lock_reset),
                      title: Text("Change PIN", style: GoogleFonts.fredoka(fontSize: 16.sp, fontWeight: FontWeight.w500)),
                      onTap: _showChangePinDialog,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 40.h),
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.download_rounded),
                  label: Text("Download Progress Report", style: GoogleFonts.fredoka(fontSize: 16.sp)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
                  ),
                  onPressed: _downloadReport,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSchedulerCard(String activity) {
    final colorScheme = Theme.of(context).colorScheme;
    final sessions = _schedules[activity] ?? [];
    final sessionCount = sessions.length;
    final totalMinutes = sessions.fold<int>(0, (sum, s) => sum + (s['duration'] as int? ?? 15));

    String timeText = "Not scheduled";
    if (sessionCount > 0) {
      timeText = "$sessionCount session${sessionCount == 1 ? '' : 's'} • $totalMinutes min total";
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primary.withOpacity(0.15),
          radius: 28.r,
          child: Icon(_getActivityIcon(activity), color: colorScheme.primary, size: 32.w),
        ),
        title: Text(activity, style: GoogleFonts.fredoka(fontSize: 18.sp, fontWeight: FontWeight.w700)),
        subtitle: Text(timeText, style: GoogleFonts.fredoka(fontSize: 14.sp, color: colorScheme.onSurfaceVariant)),
        trailing: IconButton(
          icon: Icon(Icons.edit_calendar_rounded, color: colorScheme.primary, size: 28.w),
          onPressed: () => _openScheduleEditor(activity),
        ),
      ),
    );
  }

  Widget _buildRewardCard(String activity) {
    final colorScheme = Theme.of(context).colorScheme;
    final path = _rewardImages[activity];
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            Container(
              width: 64.w,
              height: 64.h,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Icon(_getActivityIcon(activity), color: colorScheme.primary, size: 32.w),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(activity, style: GoogleFonts.fredoka(fontSize: 18.sp, fontWeight: FontWeight.w700)),
                  SizedBox(height: 4.h),
                  Text(
                    path == null ? "No reward set" : "Reward ready",
                    style: GoogleFonts.fredoka(fontSize: 14.sp, color: path == null ? colorScheme.onSurfaceVariant : AppTheme.success),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.image_rounded, size: 18.w),
              label: Text("Set", style: GoogleFonts.fredoka(fontSize: 14.sp)),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              ),
              onPressed: () => _pickRewardImage(activity),
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

  void _showChangePinDialog() async {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();
    final colorScheme = Theme.of(context).colorScheme;

    final bool? changed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change Parent PIN', style: GoogleFonts.fredoka(fontWeight: FontWeight.w700, fontSize: 22.sp)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(labelText: 'New PIN', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r))),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: confirmController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(labelText: 'Confirm New PIN', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r))),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (pinController.text.length < 4) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('PIN must be at least 4 digits'), backgroundColor: AppTheme.error));
                return;
              }
              if (pinController.text != confirmController.text) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('PINs do not match'), backgroundColor: AppTheme.error));
                return;
              }
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('parent_pin', pinController.text);
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary),
            child: Text('Save'),
          ),
        ],
      ),
    );

    if (changed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('PIN changed successfully'), backgroundColor: AppTheme.success),
      );
    }
  }
}

// Schedule Editor Bottom Sheet (unchanged)
class _ScheduleEditorBottomSheet extends StatefulWidget {
  final String activityName;
  final List<Map<String, dynamic>> currentSessions;
  final ValueChanged<List<Map<String, dynamic>>> onSave;

  const _ScheduleEditorBottomSheet({
    required this.activityName,
    required this.currentSessions,
    required this.onSave,
  });

  @override
  State<_ScheduleEditorBottomSheet> createState() => _ScheduleEditorBottomSheetState();
}

class _ScheduleEditorBottomSheetState extends State<_ScheduleEditorBottomSheet> {
  late List<Map<String, dynamic>> _sessions;

  @override
  void initState() {
    super.initState();
    _sessions = List.from(widget.currentSessions);
  }

  void _addSession() {
    setState(() {
      _sessions.add({'startTime': '09:00', 'duration': 15});
    });
  }

  void _removeSession(int index) {
    setState(() => _sessions.removeAt(index));
  }

  Future<void> _pickTime(int index) async {
    final parts = (_sessions[index]['startTime'] as String).split(':');
    final initial = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    final colorScheme = Theme.of(context).colorScheme;

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: colorScheme.primary, onPrimary: Colors.white)),
        child: child!,
      ),
    );

    if (picked != null && mounted) {
      setState(() {
        _sessions[index]['startTime'] = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  void _changeDuration(int index, int newDuration) {
    setState(() => _sessions[index]['duration'] = newDuration);
  }

  int _calculateTotalMinutes() {
    return _sessions.fold(0, (sum, s) => sum + (s['duration'] as int? ?? 15));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final totalMin = _calculateTotalMinutes();

    return Container(
      padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, MediaQuery.of(context).viewInsets.bottom + 24.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Schedule ${widget.activityName}", style: GoogleFonts.fredoka(fontSize: 22.sp, fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
          SizedBox(height: 8.h),
          Text("Set times and duration for today's session", style: GoogleFonts.fredoka(fontSize: 15.sp, color: colorScheme.onSurfaceVariant)),
          SizedBox(height: 16.h),

          if (_sessions.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Total planned time", style: GoogleFonts.fredoka(fontSize: 16.sp, fontWeight: FontWeight.w500)),
                  Text("$totalMin minutes", style: GoogleFonts.fredoka(fontSize: 16.sp, color: colorScheme.primary, fontWeight: FontWeight.w600)),
                ],
              ),
            ),

          if (_sessions.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40.h),
                child: Text("No sessions yet\nTap + to add one", textAlign: TextAlign.center, style: GoogleFonts.fredoka(fontSize: 16.sp, color: colorScheme.onSurfaceVariant)),
              ),
            )
          else
            ...List.generate(_sessions.length, (i) {
              final s = _sessions[i];
              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: InkWell(
                        onTap: () => _pickTime(i),
                        borderRadius: BorderRadius.circular(16.r),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
                          decoration: BoxDecoration(color: colorScheme.surfaceVariant, borderRadius: BorderRadius.circular(16.r)),
                          child: Row(
                            children: [
                              Icon(Icons.access_time_rounded, size: 20.w, color: colorScheme.primary),
                              SizedBox(width: 8.w),
                              Text(s['startTime'], style: GoogleFonts.fredoka(fontSize: 18.sp, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      flex: 2,
                      child: DropdownButton<int>(
                        value: s['duration'],
                        isExpanded: true,
                        items: List.generate(12, (i) => (i + 1) * 5)
                            .map((min) => DropdownMenuItem(value: min, child: Text('$min min', style: GoogleFonts.fredoka(fontSize: 16.sp))))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) _changeDuration(i, v);
                        },
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.redAccent, size: 24.w),
                      onPressed: () => _removeSession(i),
                    ),
                  ],
                ),
              );
            }),

          SizedBox(height: 24.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: Icon(Icons.add_rounded, size: 20.w),
                  label: Text("Add Session", style: GoogleFonts.fredoka(fontSize: 16.sp)),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    side: BorderSide(color: colorScheme.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
                  ),
                  onPressed: _addSession,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onSave(_sessions);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
                  ),
                  child: Text("Save", style: GoogleFonts.fredoka(fontSize: 16.sp, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}