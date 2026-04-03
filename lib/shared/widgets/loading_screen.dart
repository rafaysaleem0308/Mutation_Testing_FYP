import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    _startNavigation();
  }

  void _startNavigation() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/intro');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/5.gif'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          color: Colors.white.withOpacity(0.4), // Light overlay to help text pop
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Main Loading GIF
                Image.asset(
                  "assets/images/loading2.gif",
                  width: 320,
                  height: 200,
                ).animate().scale(duration: 800.ms, curve: Curves.easeOutBack).fadeIn(),

                const SizedBox(height: 40),

                // Text + Status Spinner
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Loading",
                      style: GoogleFonts.poppins(
                        color: Colors.black87,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                     ).animate(onPlay: (controller) => controller.repeat())
                      .shimmer(duration: 2.seconds, color: Color(0xFFFF9D42).withOpacity(0.5)),

                    const SizedBox(width: 12),

                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF9D42)),
                      ),
                    ).animate().fadeIn(delay: 500.ms),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                Text(
                  "Setting things up for you...",
                  style: GoogleFonts.inter(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ).animate().fadeIn(delay: 800.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
