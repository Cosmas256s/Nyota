// lib/screens/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nyota/theme.dart';
import 'package:nyota/widgets/nav_buttons.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _agreedToTerms = false;
  bool _obscurePassword = true;
  bool _isLoading = false;

  String _passwordStrength = '';

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updatePasswordStrength);
  }

  void _updatePasswordStrength() {
    final pwd = _passwordController.text;
    String strength = '';

    if (pwd.isNotEmpty) {
      if (pwd.length < 6) {
        strength = 'Weak';
      } else if (pwd.length < 8 ||
          !RegExp(r'(?=.*[A-Z])').hasMatch(pwd) ||
          !RegExp(r'(?=.*[0-9])').hasMatch(pwd)) {
        strength = 'Medium';
      } else {
        strength = 'Strong';
      }
    }

    setState(() => _passwordStrength = strength);
  }

  Future<void> _showTermsDialog() async {
    final colorScheme = Theme.of(context).colorScheme;
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Terms & Conditions',
          style: GoogleFonts.fredoka(fontWeight: FontWeight.w700, fontSize: 20.sp),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Welcome to NYOTA – Math is Easy!\n\n'
                'This app is made for young children (3+ years) to learn counting, shapes, and basic math in a fun, safe way.\n\n'
                'By creating an account, you (the parent or guardian) agree that:\n\n'
                '1. This app is for your child’s personal learning at home.\n'
                '2. You will supervise your child while they use the app.\n'
                '3. We do not collect personal information from children under 13 without parental consent.\n'
                '4. We may collect your email and phone number only to help you manage your child’s learning progress.\n'
                '5. Your data will be handled securely and never shared with third parties for advertising.\n'
                '6. You can delete your account and data at any time from the settings.\n'
                '7. The app is provided "as is" – we are not responsible for any issues from misuse.\n\n'
                'We want every child to love learning math!\n'
                'Thank you for being part of NYOTA.\n\n'
                'Last updated: March 2026',
                style: GoogleFonts.fredoka(fontSize: 15.sp, height: 1.4, color: colorScheme.onSurface),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: GoogleFonts.fredoka(fontSize: 16.sp)),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        contentPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
      ),
    );
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please agree to the Terms & Conditions', style: GoogleFonts.fredoka()),
          backgroundColor: AppTheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/main-dashboard',
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;

      switch (e.code) {
        case 'weak-password':
          errorMessage = 'The password is too weak. Try a stronger one.';
          break;
        case 'email-already-in-use':
          errorMessage = 'This email is already registered. Please log in instead.';
          break;
        case 'invalid-email':
          errorMessage = 'Please enter a valid email address.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Account creation is currently disabled.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many attempts. Please try again later.';
          break;
        default:
          errorMessage = e.message ?? 'Signup failed. Please try again.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage, style: GoogleFonts.fredoka()),
            backgroundColor: AppTheme.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred', style: GoogleFonts.fredoka()),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 16.h),
            child: Container(
              padding: EdgeInsets.fromLTRB(24.w, 40.h, 24.w, 32.h),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(32.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 20.r,
                    offset: Offset(0, 8.h),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Create Parent Account',
                      style: GoogleFonts.fredoka(fontSize: 30.sp, fontWeight: FontWeight.w800, color: colorScheme.onSurface),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'For your child’s safe learning journey',
                      style: GoogleFonts.fredoka(fontSize: 16.sp, color: colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 40.h),

                    _buildTextField(
                      controller: _emailController,
                      icon: Icons.email_outlined,
                      label: 'Parent Email',
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Email is required';
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20.h),

                    _buildTextField(
                      controller: _phoneController,
                      icon: Icons.phone_outlined,
                      label: 'Phone Number (optional)',
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        if (!RegExp(r'^\+?[1-9]\d{1,14}$').hasMatch(v.trim())) {
                          return 'Invalid phone number format';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20.h),

                    _buildTextField(
                      controller: _passwordController,
                      icon: Icons.lock_outline,
                      label: 'Password',
                      isPassword: true,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Password is required';
                        if (v.length < 6) return 'At least 6 characters';
                        if (!RegExp(r'(?=.*[A-Z])').hasMatch(v)) return 'Add at least one uppercase letter';
                        if (!RegExp(r'(?=.*[0-9])').hasMatch(v)) return 'Add at least one number';
                        return null;
                      },
                    ),

                    if (_passwordStrength.isNotEmpty) ...[
                      SizedBox(height: 8.h),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Password strength: $_passwordStrength',
                          style: GoogleFonts.fredoka(
                            fontSize: 14.sp,
                            color: _passwordStrength == 'Strong'
                                ? AppTheme.success
                                : _passwordStrength == 'Medium'
                                    ? AppTheme.warning
                                    : AppTheme.error,
                          ),
                        ),
                      ),
                    ],

                    SizedBox(height: 24.h),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _agreedToTerms,
                          activeColor: colorScheme.secondary,
                          onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'I agree to the ',
                                style: GoogleFonts.fredoka(fontSize: 14.sp, color: colorScheme.onSurfaceVariant),
                              ),
                              GestureDetector(
                                onTap: _showTermsDialog,
                                child: Text(
                                  'Terms & Conditions',
                                  style: GoogleFonts.fredoka(
                                    fontSize: 14.sp,
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 32.h),

                    SizedBox(
                      width: double.infinity,
                      height: 60.h,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSignup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 24.h,
                                width: 24.w,
                                child: const CircularProgressIndicator(strokeWidth: 3),
                              )
                            : Text(
                                "LET'S GET STARTED",
                                style: GoogleFonts.fredoka(fontSize: 18.sp, fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),

                    SizedBox(height: 24.h),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Already have an account? ', style: GoogleFonts.fredoka(fontSize: 15.sp, color: colorScheme.onSurfaceVariant)),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/login'),
                          child: Text(
                            'Log in',
                            style: GoogleFonts.fredoka(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 12.h,
          left: 16.w,
          child: const AnimatedBackButton(),
        ),
      ],
    ),
  ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    TextInputType? keyboardType,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: isPassword ? _obscurePassword : false,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: GoogleFonts.fredoka(fontSize: 16.sp, color: colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: GoogleFonts.fredoka(fontSize: 16.sp, color: colorScheme.onSurfaceVariant),
        prefixIcon: Icon(icon, color: colorScheme.onSurfaceVariant, size: 24.w),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: colorScheme.onSurfaceVariant,
                  size: 24.w,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              )
            : null,
        filled: true,
        fillColor: colorScheme.surfaceVariant,
        contentPadding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 16.w),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20.r), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20.r), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20.r), borderSide: BorderSide(color: colorScheme.primary, width: 2.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20.r), borderSide: const BorderSide(color: AppTheme.error)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20.r), borderSide: const BorderSide(color: AppTheme.error, width: 2.5)),
      ),
    );
  }
}