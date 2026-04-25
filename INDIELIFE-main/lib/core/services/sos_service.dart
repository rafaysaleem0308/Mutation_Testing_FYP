import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hello/core/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class SOSService {
  static final SOSService _instance = SOSService._internal();
  factory SOSService() => _instance;
  SOSService._internal();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  int _pressCount = 0;
  Timer? _countResetTimer;
  bool _isSOSInProgress = false;
  OverlayEntry? _overlayEntry;

  BuildContext? get _context => navigatorKey.currentContext;

  void initialize() {
    HardwareKeyboard.instance.addHandler((KeyEvent event) {
      if (event is KeyDownEvent) {
        if (event.physicalKey == PhysicalKeyboardKey.audioVolumeDown || 
            event.physicalKey == PhysicalKeyboardKey.keyS) {
          
          print("SOS Key Detected: ${event.physicalKey}");
          _handleVolumeDownPress();
          return true; // We handled it
        }
      }
      return false;
    });
  }

  void _handleVolumeDownPress() {
    if (_isSOSInProgress || _context == null) return;

    HapticFeedback.vibrate();
    _pressCount++;
    print("SOS Press count: $_pressCount");

    // Reset count if no press within 3 seconds
    _countResetTimer?.cancel();
    _countResetTimer = Timer(Duration(seconds: 3), () {
      _pressCount = 0;
    });

    if (_pressCount >= 5) {
      _triggerSOS();
    } else {
      _showFeedback();
    }
  }

  void _showFeedback() {
    final overlayState = navigatorKey.currentState?.overlay;
    if (overlayState == null) {
      print("SOS Feedback Error: Could not find overlay state.");
      return;
    }
    
    // Show a subtle toast/overlay to tell user we are counting
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        top: 100,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.8),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                "SOS Trigger: $_pressCount/5",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ).animate().fadeIn().scale().then(delay: 1.seconds).fadeOut(),
          ),
        ),
      ),
    );

    overlayState.insert(entry);
    Timer(Duration(seconds: 2), () => entry.remove());
  }

  Future<void> _triggerSOS() async {
    _pressCount = 0;
    _isSOSInProgress = true;

    // Show SOS Action Dialog with Countdown
    _showSOSOverlay();
  }

  void _showSOSOverlay() {
    final overlayState = navigatorKey.currentState?.overlay;
    if (overlayState == null) {
      print("SOS Overlay Error: Could not find overlay state.");
      return;
    }
    
    _overlayEntry = OverlayEntry(
      builder: (context) => SOSCountdownOverlay(
        onCancel: () {
          _isSOSInProgress = false;
          _overlayEntry?.remove();
          _overlayEntry = null;
        },
        onConfirmed: () async {
          _overlayEntry?.remove();
          _overlayEntry = null;
          await _executeSOSCall();
          _isSOSInProgress = false;
        },
      ),
    );

    overlayState.insert(_overlayEntry!);
  }

  Future<void> _executeSOSCall() async {
    try {
      final userData = await ApiService.getUserData();
      final familyPhone = userData['familyPhone'];

      if (familyPhone != null && familyPhone.toString().isNotEmpty) {
        final Uri telUri = Uri(scheme: 'tel', path: familyPhone.toString());
        if (await canLaunchUrl(telUri)) {
          await launchUrl(telUri);
        } else {
          print("Could not launch SOS call to $familyPhone");
        }
      } else {
        print("No family contact found for SOS");
      }
    } catch (e) {
      print("SOS Execution Error: $e");
    }
  }
}

class SOSCountdownOverlay extends StatefulWidget {
  final VoidCallback onCancel;
  final VoidCallback onConfirmed;

  const SOSCountdownOverlay({super.key, required this.onCancel, required this.onConfirmed});

  @override
  _SOSCountdownOverlayState createState() => _SOSCountdownOverlayState();
}

class _SOSCountdownOverlayState extends State<SOSCountdownOverlay> {
  int _secondsRemaining = 5;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 1) {
          _secondsRemaining--;
        } else {
          _timer?.cancel();
          widget.onConfirmed();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 150, height: 150,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.5), blurRadius: 30, spreadRadius: 10)],
              ),
              child: Center(
                child: Text(
                  "$_secondsRemaining",
                  style: GoogleFonts.poppins(fontSize: 60, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ).animate(onPlay: (c) => c.repeat()).scale(begin: Offset(1, 1), end: Offset(1.1, 1.1), duration: 500.ms, curve: Curves.easeInOut).then().scale(begin: Offset(1.1, 1.1), end: Offset(1, 1)),
            SizedBox(height: 40),
            Text(
              "EMERGENCY SOS",
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
            ),
            SizedBox(height: 10),
            Text(
              "Calling Family Representative...",
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 16),
            ),
            SizedBox(height: 60),
            GestureDetector(
              onTap: widget.onCancel,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  "CANCEL",
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn();
  }
}
