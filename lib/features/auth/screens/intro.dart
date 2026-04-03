import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'intro_screens/intro_page1.dart';
import 'intro_screens/intro_page2.dart';
import 'intro_screens/intro_page3.dart';
import 'intro_screens/intro_page5.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  IntroScreenState createState() => IntroScreenState();
}

class IntroScreenState extends State<IntroScreen> {
  PageController controller = PageController();
  int currentPage = 0;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          PageView(
            controller: controller,
            onPageChanged: (index) {
              setState(() {
                currentPage = index;
              });
            },
            children: [
              IntroPage1(),
              IntroPage2(),
              IntroPage3(),
              IntroPage5(),
            ],
          ),

          // Smooth Page Indicator
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: SmoothPageIndicator(
                controller: controller,
                count: 4,
                effect: ExpandingDotsEffect(
                  dotColor: Colors.white.withOpacity(0.5),
                  activeDotColor: Color(0xFFFF9D42),
                  dotHeight: 8,
                  dotWidth: 8,
                  expansionFactor: 4,
                ),
              ),
            ),
          ),

          // Skip button
          if (currentPage != 3)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              right: 20,
              child: TextButton(
                onPressed: () {
                  controller.animateToPage(
                    3,
                    duration: Duration(milliseconds: 600),
                    curve: Curves.easeInOut,
                  );
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  'Skip',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
