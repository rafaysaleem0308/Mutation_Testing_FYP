import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class OrderConfirmationScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  final Map<String, dynamic> provider;

  const OrderConfirmationScreen({
    super.key,
    required this.order,
    required this.provider,
  });

  @override
  _OrderConfirmationScreenState createState() => _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_rounded, size: 60, color: Colors.green),
              ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
              SizedBox(height: 32),
              Text(
                "Order Confirmed!",
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ).animate().fadeIn().slideY(begin: 0.2, end: 0),
              SizedBox(height: 16),
              Text(
                "Your order has been placed successfully. You can track its status in the 'My Orders' section.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ).animate().fadeIn(delay: 200.ms),
              SizedBox(height: 48),
              
              // Order ID Pill
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  "Order #${widget.order['_id']?.toString().substring(0, 8).toUpperCase() ?? 'ID'}",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              ),
              
              Spacer(),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(context, '/user-home', (route) => false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFF9D42),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    "Back to Home",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
              SizedBox(height: 16),
              TextButton(
                onPressed: () {
                   Navigator.pushNamedAndRemoveUntil(context, '/user-home', (route) => false);
                   // Then push track order
                   // Note: This is a bit hacky, normally we'd pass existing order object
                   // For now, let's just go home or maybe directly to track order if we can
                   Navigator.pushNamed(context, '/track_order', arguments: widget.order);
                },
                child: Text(
                  "Track Order",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFF9D42),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
