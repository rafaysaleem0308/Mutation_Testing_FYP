import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hello/core/services/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final emailController = TextEditingController();
  final otpController = TextEditingController();
  final newPassController = TextEditingController();
  final confirmPassController = TextEditingController();

  bool otpSent = false;
  bool otpVerified = false;
  bool isLoading = false;
  bool _isDisposed = false;

  String passwordStrength = "";
  Color strengthColor = Colors.red;

  final RegExp passwordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*()_+\-=\[\]{};:"\\|,.<>\/?]).{6,}$',
  );

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _animationController.dispose();
    emailController.dispose();
    otpController.dispose();
    newPassController.dispose();
    confirmPassController.dispose();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted) {
      setState(fn);
    }
  }

  void checkPasswordStrength(String pass) {
    if (pass.isEmpty) {
      _safeSetState(() => passwordStrength = "");
      return;
    }
    if (pass.length < 6) {
      _safeSetState(() {
        passwordStrength = "Weak";
        strengthColor = Colors.red;
      });
      return;
    }
    if (passwordRegex.hasMatch(pass)) {
      _safeSetState(() {
        passwordStrength = "Strong";
        strengthColor = Colors.green;
      });
    } else {
      _safeSetState(() {
        passwordStrength = "Medium";
        strengthColor = Colors.orange;
      });
    }
  }

  Future<void> sendOtp() async {
    if (emailController.text.isEmpty || !emailController.text.contains('@')) {
      _showMsg("Please enter a valid email address", true);
      return;
    }
    _safeSetState(() => isLoading = true);
    try {
      final result = await ApiService.sendOtp(emailController.text);
      _safeSetState(() => isLoading = false);
      if (result['success'] == true) {
        _safeSetState(() => otpSent = true);
        _showMsg(result['message'], false);
      } else {
        _showMsg(result['message'], true);
      }
    } catch (error) {
      _safeSetState(() => isLoading = false);
      _showMsg("Failed to send OTP. Please try again.", true);
    }
  }

  Future<void> verifyOtp() async {
    if (otpController.text.isEmpty || otpController.text.length != 6) {
      _showMsg("Please enter a valid 6-digit OTP", true);
      return;
    }
    _safeSetState(() => isLoading = true);
    try {
      final result = await ApiService.verifyOtp(emailController.text, otpController.text);
      _safeSetState(() => isLoading = false);
      if (result['success'] == true) {
        _safeSetState(() => otpVerified = true);
        _showMsg(result['message'], false);
      } else {
        _showMsg(result['message'], true);
      }
    } catch (error) {
      _safeSetState(() => isLoading = false);
      _showMsg("Failed to verify OTP. Please try again.", true);
    }
  }

  Future<void> changePassword() async {
    if (newPassController.text.isEmpty || confirmPassController.text.isEmpty) {
      _showMsg("Please fill all password fields", true);
      return;
    }
    if (newPassController.text != confirmPassController.text) {
      _showMsg("Passwords do not match", true);
      return;
    }
    if (!passwordRegex.hasMatch(newPassController.text)) {
      _showMsg("Weak password", true);
      return;
    }
    _safeSetState(() => isLoading = true);
    try {
      final result = await ApiService.resetPassword(emailController.text, newPassController.text);
      _safeSetState(() => isLoading = false);
      if (result['success'] == true) {
        _showMsg(result['message'], false);
        Future.delayed(Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      } else {
        _showMsg(result['message'], true);
      }
    } catch (error) {
      _safeSetState(() => isLoading = false);
      _showMsg("Failed to reset password. Please try again.", true);
    }
  }

  void _showMsg(String msg, bool error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter()),
        backgroundColor: error ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("Recover Account", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Animated Background
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFF9D42),
                      Color(0xFFFF512F),
                      Color(0xFFDD2476).withOpacity(0.8),
                    ],
                    stops: [0, _animationController.value, 1],
                  ),
                ),
              );
            },
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white.withOpacity(0.5)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            otpVerified ? "New Password" : (otpSent ? "Verify OTP" : "Reset Password"),
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            otpVerified 
                              ? "Setup a strong new password for your account."
                              : (otpSent ? "We've sent a 6-digit code to your email." : "Enter your email to receive a recovery code."),
                            style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 14),
                          ),
                          SizedBox(height: 32),

                          if (!otpSent) ...[
                            _buildField("Email Address", emailController, Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                            SizedBox(height: 24),
                            _buildActionButton("Send Recovery Code", sendOtp),
                          ] else if (!otpVerified) ...[
                            _buildField("Verification Code", otpController, Icons.lock_clock_outlined, keyboardType: TextInputType.number, maxLength: 6),
                            SizedBox(height: 24),
                            _buildActionButton("Verify & Continue", verifyOtp),
                          ] else ...[
                            _buildField("New Password", newPassController, Icons.vpn_key_outlined, obscureText: true, onChanged: checkPasswordStrength),
                            if (passwordStrength.isNotEmpty) ...[
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Text("Strength: ", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
                                  Text(passwordStrength, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: strengthColor)),
                                ],
                              ),
                            ],
                            SizedBox(height: 16),
                            _buildField("Confirm Password", confirmPassController, Icons.check_circle_outline, obscureText: true),
                            SizedBox(height: 24),
                            _buildActionButton("Update Password", changePassword),
                          ],
                        ],
                      ),
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

  Widget _buildField(String label, TextEditingController controller, IconData icon, {TextInputType? keyboardType, bool obscureText = false, int? maxLength, Function(String)? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLength: maxLength,
          onChanged: onChanged,
          style: GoogleFonts.inter(fontSize: 15),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Color(0xFFFF9D42), size: 20),
            hintText: "Enter your ${label.toLowerCase()}",
            hintStyle: GoogleFonts.inter(color: Colors.grey[400], fontSize: 14),
            filled: true,
            fillColor: Colors.grey[100],
            counterText: "",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFFFF9D42), Color(0xFFFF512F)]),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Color(0xFFFF9D42).withOpacity(0.3),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          child: isLoading 
            ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(label, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
    );
  }
}
