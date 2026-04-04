import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hello/features/auth/screens/login.dart';
import 'package:hello/core/services/api_service.dart';
import 'package:hello/features/home/screens/user_home.dart';
import 'package:hello/features/home/screens/service_provider_home.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  SignupScreenState createState() => SignupScreenState();
}

class SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String? selectedRole;
  bool passwordVisible = false;
  bool confirmPasswordVisible = false;
  bool _isSignupLoading = false;
  bool _isOtpLoading = false;
  bool otpSent = false;
  bool otpVerified = false;

  // Password regex
  final RegExp passwordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*()_+\-=\[\]{};:"\\|,.<>\/?]).{8,}$',
  );

  // List of major Pakistani cities
  final List<String> pakistaniCities = [
    'Karachi',
    'Lahore',
    'Islamabad',
    'Rawalpindi',
    'Faisalabad',
    'Multan',
    'Peshawar',
    'Quetta',
    'Gujranwala',
    'Sialkot',
    'Sargodha',
    'Bahawalpur',
    'Sukkur',
    'Larkana',
    'Hyderabad',
    'Abbottabad',
    'Mardan',
    'Mingora',
    'Gujrat',
    'Sheikhupura',
    'Rahim Yar Khan',
    'Jhang',
    'Sahiwal',
    'Wah Cantonment',
    'Chiniot',
    'Kamoke',
    'Mandi Bahauddin',
    'Kasur',
    'Okara',
    'Dera Ghazi Khan',
    'Mirpur Khas',
    'Chishtian',
    'Taxila',
    'Nowshera',
    'Swabi',
    'Bannu',
    'Kohat',
    'Mianwali',
    'Kharian',
    'Muzaffargarh',
    'Jacobabad',
    'Shikarpur',
    'Khanewal',
    'Hafizabad',
    'Khushab',
    'Charsadda',
    'Thatta',
    'Haripur',
    'Pakpattan',
    'Tando Adam',
    'Jhelum',
    'Badin',
    'Rohri',
    'Dadu',
    'Kandhkot',
    'Chakwal',
    'Gojra',
    'Matiari',
    'Tando Allahyar',
    'Vehari',
    'Narowal',
    'Pasrur',
    'Jaranwala',
    'Ahmedpur East',
    'Kot Abdul Malik',
    'Bhakkar',
    'Khairpur',
    'Daska',
    'Lodhran',
    'Hasilpur',
    'Sadiqabad',
    'Shahdadkot',
    'Mian Channu',
    'Bhalwal',
    'Jamshoro',
    'Pattoki',
    'Haroonabad',
    'Kahror Pakka',
    'Ghotki',
    'Nankana Sahib',
    'Muridke',
    'Kabirwala',
    'Moro',
    'Kandiaro',
    'Chichawatni',
    'Turbat',
  ];

  // Selected cities for User and Service Provider
  String userSelectedCity = 'Karachi';
  String spSelectedCity = 'Karachi';

  // User Controllers
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController familyNameController = TextEditingController();
  TextEditingController familyPhoneController = TextEditingController();
  TextEditingController roommateNameController = TextEditingController();
  TextEditingController roommatePhoneController = TextEditingController();

  // SP Controllers
  TextEditingController spFirstNameController = TextEditingController();
  TextEditingController spLastNameController = TextEditingController();
  TextEditingController spEmailController = TextEditingController();
  TextEditingController spPasswordController = TextEditingController();
  TextEditingController spConfirmPasswordController = TextEditingController();
  TextEditingController spPhoneController = TextEditingController();
  TextEditingController spAddressController = TextEditingController();
  TextEditingController spDistrictNameController = TextEditingController();
  TextEditingController spDistrictNazimController = TextEditingController();
  String spSubRole = 'Meal Provider';

  // OTP Controller
  TextEditingController otpController = TextEditingController();

  // Password strength variables
  double passwordStrength = 0.0;
  String passwordText = '';
  Color strengthColor = Colors.red;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Add listener for password strength
    passwordController.addListener(updatePasswordStrength);
    spPasswordController.addListener(updatePasswordStrength);

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.1), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutQuart,
          ),
        );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();

    // Remove listeners
    passwordController.removeListener(updatePasswordStrength);
    spPasswordController.removeListener(updatePasswordStrength);

    // Dispose all controllers
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    phoneController.dispose();
    addressController.dispose();
    familyNameController.dispose();
    familyPhoneController.dispose();
    roommateNameController.dispose();
    roommatePhoneController.dispose();
    spFirstNameController.dispose();
    spLastNameController.dispose();
    spEmailController.dispose();
    spPasswordController.dispose();
    spConfirmPasswordController.dispose();
    spPhoneController.dispose();
    spAddressController.dispose();
    spDistrictNameController.dispose();
    spDistrictNazimController.dispose();
    otpController.dispose();

    super.dispose();
  }

  // Password strength calculator
  void updatePasswordStrength() {
    String password = selectedRole == 'User'
        ? passwordController.text
        : spPasswordController.text;

    double strength = 0.0;
    String text = '';
    Color color = Colors.red;

    if (password.length >= 6) strength += 0.2;
    if (password.length >= 8) strength += 0.2;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.2;
    if (RegExp(r'[a-z]').hasMatch(password)) strength += 0.2;
    if (RegExp(r'[0-9]').hasMatch(password)) strength += 0.1;
    if (RegExp(r'[!@#$%^&*()_+\-=\[\]{};:"\\|,.<>\/?]').hasMatch(password))
      strength += 0.1;

    // Set strength text and color
    if (strength < 0.4) {
      text = 'Weak';
      color = Colors.red;
    } else if (strength < 0.7) {
      text = 'Fair';
      color = Colors.orange;
    } else if (strength < 0.9) {
      text = 'Good';
      color = Colors.blue;
    } else {
      text = 'Strong';
      color = Colors.green;
    }

    if (mounted) {
      setState(() {
        passwordStrength = strength;
        passwordText = text;
        strengthColor = color;
      });
    }
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  Future<Map<String, dynamic>> sendOtp() async {
    if (selectedRole == null) {
      _showSnackBar("Please select a role first", true);
      return {'status': 'error', 'message': 'Please select a role first'};
    }

    String email = selectedRole == 'User'
        ? emailController.text
        : spEmailController.text;

    if (email.isEmpty || !email.contains('@gmail.com')) {
      _showSnackBar("Please enter a valid Gmail address", true);
      return {
        'status': 'error',
        'message': 'Please enter a valid Gmail address',
      };
    }

    _safeSetState(() => _isOtpLoading = true);

    try {
      final result = await ApiService.sendOtpSignup(email, selectedRole!);
      if (!mounted) return {'status': 'error', 'message': 'Widget disposed'};

      _safeSetState(() {
        _isOtpLoading = false;
        if (result['status'] == 'success') {
          otpSent = true;
        }
      });

      // Handle account already exists error with better UI
      if (result['status'] != 'success' &&
          result['message']?.contains('already exists') == true) {
        _showAccountExistsErrorDialog(
          result['suggestion'] ?? result['message'] ?? 'Account already exists',
        );
      } else {
        _showSnackBar(result['message'], result['status'] != 'success');
      }
      return result;
    } catch (e) {
      _safeSetState(() => _isOtpLoading = false);
      _showSnackBar("Failed to send OTP: $e", true);
      return {'status': 'error', 'message': 'Failed to send OTP'};
    }
  }

  Future<Map<String, dynamic>> verifyOtp() async {
    if (otpController.text.isEmpty || otpController.text.length != 6) {
      _showSnackBar("Please enter a valid 6-digit OTP", true);
      return {'status': 'error', 'message': 'Please enter a valid 6-digit OTP'};
    }

    String email = selectedRole == 'User'
        ? emailController.text
        : spEmailController.text;

    _safeSetState(() => _isOtpLoading = true);

    try {
      final result = await ApiService.verifyOtpSignup(
        email,
        otpController.text,
      );
      if (!mounted) return {'status': 'error', 'message': 'Widget disposed'};

      _safeSetState(() {
        _isOtpLoading = false;
        if (result['status'] == 'verified') {
          otpVerified = true;
        }
      });

      _showSnackBar(result['message'], result['status'] != 'verified');
      return result;
    } catch (e) {
      _safeSetState(() => _isOtpLoading = false);
      _showSnackBar("Failed to verify OTP: $e", true);
      return {'status': 'error', 'message': 'Failed to verify OTP'};
    }
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    if (!otpSent) {
      final otpResult = await sendOtp();
      if (otpResult['status'] != 'success') return;
      return;
    }

    if (otpSent && !otpVerified) {
      final verifyResult = await verifyOtp();
      if (verifyResult['status'] != 'verified') return;
      await _completeSignup();
      return;
    }

    if (otpVerified) {
      await _completeSignup();
    }
  }

  Future<void> _completeSignup() async {
    _safeSetState(() => _isSignupLoading = true);

    try {
      Map<String, dynamic> data;

      if (selectedRole == 'User') {
        data = {
          "role": "user",
          "firstName": firstNameController.text,
          "lastName": lastNameController.text,
          "email": emailController.text,
          "password": passwordController.text,
          "phone": phoneController.text,
          "city": userSelectedCity,
          "address": addressController.text,
          "familyName": familyNameController.text,
          "familyPhone": familyPhoneController.text,
          "roommateName": roommateNameController.text.trim().isEmpty
              ? null
              : roommateNameController.text,
          "roommatePhone": roommatePhoneController.text.trim().isEmpty
              ? null
              : roommatePhoneController.text,
        };
      } else {
        data = {
          "role": "service_provider",
          "firstName": spFirstNameController.text,
          "lastName": spLastNameController.text,
          "email": spEmailController.text,
          "password": spPasswordController.text,
          "phone": spPhoneController.text,
          "city": spSelectedCity,
          "address": spAddressController.text,
          "districtName": spDistrictNameController.text,
          "districtNazim": spDistrictNazimController.text,
          "spSubRole": spSubRole,
        };
      }

      final response = await ApiService.signup(data, selectedRole!);
      if (!mounted) return;

      _safeSetState(() => _isSignupLoading = false);

      if (response['success']) {
        // Check if this is a service provider approval request
        if (selectedRole == 'Service Provider' &&
            response['status'] == 'pending') {
          // Show approval popup
          _showApprovalPopup(response['spId']);
        } else {
          _showSnackBar('Signup Successful!', false);
          final userData = response['user'];

          // Validate response data before accessing
          if (userData == null) {
            _showSnackBar(
              'Signup successful but account data missing. Please login manually.',
              true,
            );
            Navigator.pushReplacementNamed(context, '/login');
            return;
          }

          await Future.delayed(Duration(seconds: 1));
          if (!mounted) return;

          final role = userData['role']?.toString().toLowerCase() ?? 'user';

          if (role == 'user') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => UserHome()),
            );
          } else if (role == 'service_provider' || role == 'serviceprovider') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => ServiceProviderHome()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => UserHome()),
            );
          }
        }
      } else {
        // Handle different error types
        final errorMsg =
            response['error'] ?? response['message'] ?? 'Signup Failed';

        if (errorMsg.contains('already exists')) {
          _showAccountExistsErrorDialog(errorMsg);
        } else {
          _showSnackBar(errorMsg, true);
        }
      }
    } catch (e) {
      _safeSetState(() => _isSignupLoading = false);
      _showSnackBar("Signup failed: $e", true);
    }
  }

  void _showSnackBar(String message, bool isError) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(fontSize: 14)),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(20),
      ),
    );
  }

  void _showAccountExistsErrorDialog(String errorMessage) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'Account Already Exists',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, color: Colors.orange, size: 40),
            SizedBox(height: 16),
            Text(
              'An account with this email already exists in our system.',
              style: GoogleFonts.inter(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'The account might be from a previous signup or registration as a different account type.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.blue.shade700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'What would you like to do?',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              'Try Different Email',
              style: GoogleFonts.inter(color: Colors.grey),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to login
              Navigator.pushReplacementNamed(context, '/login');
            },
            icon: Icon(Icons.login),
            label: Text(
              'Go to Login',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF635BFF),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showApprovalPopup(String spId) {
    Timer? pollingTimer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Start polling for approval status
          pollingTimer = Timer.periodic(Duration(seconds: 10), (_) async {
            if (!mounted) return;

            try {
              final response = await ApiService.get(
                '/signup/service-provider/check-approval/$spId',
              );

              if (response['isApproved'] == true) {
                pollingTimer?.cancel();
                if (mounted) Navigator.pop(context);
                _showSnackBar(
                  'Account approved! Redirecting to login...',
                  false,
                );
                await Future.delayed(Duration(seconds: 1));
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              } else if (response['isRejected'] == true) {
                pollingTimer?.cancel();
                if (mounted) Navigator.pop(context);
                _showSnackBar(
                  'Your account was rejected. Please try again.',
                  true,
                );
              }
            } catch (e) {
              print('Error checking approval status: $e');
            }
          });

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
            child: Container(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFFF9D42).withOpacity(0.1),
                    ),
                    child: Icon(
                      Icons.pending_actions,
                      size: 40,
                      color: Color(0xFFFF9D42),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Approval Request Submitted',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Our admin team will verify your credentials and approve your account shortly.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Color(0xFF2196F3).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '⏱️ Typically approved within 30 minutes',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Color(0xFF2196F3),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'What happens next:',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 12),
                  _approvalStep(
                    '1',
                    'Verification',
                    'We\'ll verify your information',
                  ),
                  SizedBox(height: 8),
                  _approvalStep(
                    '2',
                    'Approval',
                    'Admin will approve your account',
                  ),
                  SizedBox(height: 8),
                  _approvalStep('3', 'Login', 'You\'ll be redirected to login'),
                  SizedBox(height: 24),
                  Text(
                    'We\'re reviewing your application...',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      pollingTimer?.cancel();
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.grey.shade800,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      'Go to Login',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).then((value) => pollingTimer?.cancel());
  }

  Widget _approvalStep(String number, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFFF9D42),
          ),
          child: Center(
            child: Text(
              number,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                description,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Animated Gradient Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Color(0xFFFF9D42), // Primary Orange
                  Color(0xFFFF512F), // Deep Orange/Red
                ],
              ),
            ),
          ),

          // 2. Deco circles
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            right: -60,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),

          // 3. Glassmorphic Form
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 40),
              physics: BouncingScrollPhysics(),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                "Create Account ✨",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Join the community today",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 24),

                              Row(
                                children: [
                                  roleButton("User"),
                                  SizedBox(width: 12),
                                  roleButton("Service Provider"),
                                ],
                              ),
                              SizedBox(height: 24),

                              if (selectedRole == "User") userForm(),
                              if (selectedRole == "Service Provider")
                                serviceProviderForm(),

                              // OTP Section
                              if (otpSent && !otpVerified) ...[
                                SizedBox(height: 20),
                                Container(
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFFF9D42).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Color(0xFFFF9D42).withOpacity(0.3),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        "OTP Verification",
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFFF9D42),
                                        ),
                                      ),
                                      SizedBox(height: 10),
                                      TextFormField(
                                        controller: otpController,
                                        keyboardType: TextInputType.number,
                                        maxLength: 6,
                                        decoration:
                                            inputDecoration(
                                              hint: "Enter 6-digit OTP",
                                              isOutline: true,
                                            ).copyWith(
                                              counterText: "",
                                              prefixIcon: Icon(
                                                Icons.lock_clock,
                                                color: Color(0xFFFF9D42),
                                              ),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              if (otpVerified) ...[
                                SizedBox(height: 20),
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.green),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        "Email Verified!",
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              SizedBox(height: 30),

                              if (selectedRole != null)
                                SizedBox(
                                  height: 55,
                                  child: ElevatedButton(
                                    onPressed:
                                        (_isSignupLoading || _isOtpLoading)
                                        ? null
                                        : _handleSignup,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFFFF9D42),
                                      foregroundColor: Colors.white,
                                      elevation: 4,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: (_isSignupLoading || _isOtpLoading)
                                        ? SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(
                                            otpVerified
                                                ? "COMPLETE SIGNUP"
                                                : (otpSent
                                                      ? "VERIFY OTP"
                                                      : "SIGN UP & VERIFY"),
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                  ),
                                ),

                              SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Already have an account? ",
                                    style: GoogleFonts.inter(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => LoginScreen(),
                                      ),
                                    ),
                                    child: Text(
                                      "Login",
                                      style: GoogleFonts.inter(
                                        color: Color(0xFFFF9D42),
                                        fontWeight: FontWeight.bold,
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
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget roleButton(String role) {
    final isSelected = selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => _safeSetState(() {
          selectedRole = role;
          otpSent = false;
          otpVerified = false;
          otpController.clear();
        }),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? Color(0xFFFF9D42) : Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? Color(0xFFFF9D42) : Colors.transparent,
              width: 2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Color(0xFFFF9D42).withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            role,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget userForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: input(
                firstNameController,
                "First Name",
                icon: Icons.person_outline,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: input(
                lastNameController,
                "Last Name",
                icon: Icons.person_outline,
              ),
            ),
          ],
        ),
        input(
          emailController,
          "Email",
          isEmail: true,
          icon: Icons.email_outlined,
        ),
        passwordSection(passwordController),
        input(
          confirmPasswordController,
          "Confirm Password",
          isPassword: true,
          original: passwordController,
          icon: Icons.lock_outline,
        ),
        input(
          phoneController,
          "Phone",
          isPhone: true,
          icon: Icons.phone_android,
        ),
        dropdown(
          userSelectedCity,
          pakistaniCities,
          (v) => _safeSetState(() => userSelectedCity = v!),
          "City",
          Icons.location_city,
        ),
        input(addressController, "Address", icon: Icons.home_outlined),
        SizedBox(height: 12),
        Text(
          "Family info (Required)",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Colors.grey[700],
          ),
        ),
        input(
          familyNameController,
          "Family Member Name",
          icon: Icons.people_outline,
        ),
        input(
          familyPhoneController,
          "Family Phone",
          isPhone: true,
          icon: Icons.phone,
        ),
        SizedBox(height: 12),
        Text(
          "Roommate info (Optional)",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Colors.grey[700],
          ),
        ),
        input(
          roommateNameController,
          "Roommate Name",
          isRequired: false,
          icon: Icons.person,
        ),
        input(
          roommatePhoneController,
          "Roommate Phone",
          isPhone: true,
          isRequired: false,
          icon: Icons.phone,
        ),
      ],
    );
  }

  Widget serviceProviderForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: input(
                spFirstNameController,
                "First Name",
                icon: Icons.person_outline,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: input(
                spLastNameController,
                "Last Name",
                icon: Icons.person_outline,
              ),
            ),
          ],
        ),
        input(
          spEmailController,
          "Email",
          isEmail: true,
          icon: Icons.email_outlined,
        ),
        passwordSection(spPasswordController),
        input(
          spConfirmPasswordController,
          "Confirm Password",
          isPassword: true,
          original: spPasswordController,
          icon: Icons.lock_outline,
        ),
        input(
          spPhoneController,
          "Phone",
          isPhone: true,
          icon: Icons.phone_android,
        ),
        dropdown(
          spSelectedCity,
          pakistaniCities,
          (v) => _safeSetState(() => spSelectedCity = v!),
          "City",
          Icons.location_city,
        ),
        input(spAddressController, "Address", icon: Icons.home_outlined),
        input(spDistrictNameController, "District Name", icon: Icons.map),
        input(
          spDistrictNazimController,
          "District Nazim Name",
          icon: Icons.person_pin,
        ),
        dropdown(
          spSubRole,
          [
            'Meal Provider',
            'Hostel/Flat Accommodation',
            'Laundry',
            'Maintenance',
          ],
          (v) => _safeSetState(() => spSubRole = v!),
          "Service Type",
          Icons.work_outline,
        ),
      ],
    );
  }

  Widget input(
    TextEditingController controller,
    String label, {
    bool isEmail = false,
    bool isPhone = false,
    bool isRequired = true,
    bool isPassword = false,
    TextEditingController? original,
    IconData? icon,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword
            ? (original != null ? !confirmPasswordVisible : !passwordVisible)
            : false,
        keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
        inputFormatters: isPhone
            ? [FilteringTextInputFormatter.digitsOnly]
            : [],
        style: GoogleFonts.inter(fontSize: 14),
        decoration: inputDecoration(hint: label, isOutline: false).copyWith(
          prefixIcon: icon != null
              ? Icon(icon, color: Colors.grey[500], size: 20)
              : null,
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    original != null
                        ? (confirmPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off)
                        : (passwordVisible
                              ? Icons.visibility
                              : Icons.visibility_off),
                    color: Colors.grey,
                  ),
                  onPressed: () => _safeSetState(() {
                    if (original != null) {
                      confirmPasswordVisible = !confirmPasswordVisible;
                    } else {
                      passwordVisible = !passwordVisible;
                    }
                  }),
                )
              : null,
        ),
        validator: isRequired
            ? (value) {
                if (value == null || value.isEmpty) return "$label is required";
                if (isEmail && !value.endsWith('@gmail.com'))
                  return "Only Gmail allowed";
                if (isPhone && !RegExp(r'^\d{11}$').hasMatch(value))
                  return "Phone must be 11 digits";
                if (isPassword && original != null && value != original.text)
                  return "Passwords do not match";
                return null;
              }
            : null,
      ),
    );
  }

  Widget dropdown(
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
    String label,
    IconData icon,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        items: items
            .map(
              (e) => DropdownMenuItem(
                value: e,
                child: Text(e, style: GoogleFonts.inter(fontSize: 14)),
              ),
            )
            .toList(),
        onChanged: onChanged,
        decoration: inputDecoration(
          hint: label,
          isOutline: false,
        ).copyWith(prefixIcon: Icon(icon, color: Colors.grey[500], size: 20)),
      ),
    );
  }

  Widget passwordSection(TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        input(
          controller,
          "Password",
          isPassword: true,
          icon: Icons.lock_outline,
        ),
        if (controller.text.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(bottom: 16, left: 4, right: 4),
            child: Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: passwordStrength,
                    backgroundColor: Colors.grey[200],
                    color: strengthColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  passwordText,
                  style: GoogleFonts.inter(
                    color: strengthColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  InputDecoration inputDecoration({
    required String hint,
    required bool isOutline,
  }) {
    return InputDecoration(
      labelText: hint,
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Color(0xFFFF9D42), width: 1.5),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: GoogleFonts.inter(color: Colors.grey[600], fontSize: 14),
    );
  }
}
