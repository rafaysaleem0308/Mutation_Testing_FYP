import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hello/core/services/api_service.dart';
import 'package:intl/intl.dart';

class MyHousingBookingsScreen extends StatefulWidget {
  const MyHousingBookingsScreen({super.key});

  @override
  State<MyHousingBookingsScreen> createState() => _MyHousingBookingsScreenState();
}

class _MyHousingBookingsScreenState extends State<MyHousingBookingsScreen> {
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadBookings();
    _refreshTimer = Timer.periodic(Duration(seconds: 15), (_) => _loadBookings(silent: true));
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadBookings({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    final result = await ApiService.getMyHousingBookings();
    if (result['success'] == true && mounted) {
      setState(() {
        _bookings = List<Map<String, dynamic>>.from(result['bookings'] ?? []);
        _isLoading = false;
      });
    } else if (mounted) {
      if (!silent) setState(() => _isLoading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Pending': return Colors.orange;
      case 'Accepted': return Colors.blue;
      case 'Confirmed': return Colors.green;
      case 'Rejected': return Colors.red;
      case 'Cancelled': return Colors.grey;
      case 'Completed': return Colors.teal;
      default: return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Pending': return Icons.hourglass_empty;
      case 'Accepted': return Icons.check_circle_outline;
      case 'Confirmed': return Icons.done_all;
      case 'Rejected': return Icons.cancel_outlined;
      case 'Cancelled': return Icons.block;
      case 'Completed': return Icons.verified;
      default: return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('My Bookings', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, foregroundColor: Colors.black87, elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF8E2DE2)))
          : _bookings.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.book_outlined, size: 80, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text('No bookings yet', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[400])),
                    const SizedBox(height: 8),
                    Text("Your booking requests will appear here", style: GoogleFonts.inter(color: Colors.grey[400])),
                  ]),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                    itemCount: _bookings.length,
                    itemBuilder: (_, i) {
                      final b = _bookings[i];
                      final status = b['status'] ?? 'Pending';
                      final property = b['propertyId'] as Map<String, dynamic>?;
                      final images = List<String>.from(property?['images'] ?? []);
                      final displayImage = images.isNotEmpty ? images[0] : (property?['thumbnailImage'] ?? '');
                      final hasImage = displayImage.toString().isNotEmpty && displayImage.toString().startsWith('http');

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: Colors.white, borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16)),
                              child: SizedBox(
                                width: 90, height: 90,
                                child: hasImage
                                    ? Image.network(displayImage, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder())
                                    : _placeholder(),
                              ),
                            ),
                            Expanded(child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(b['propertyTitle'] ?? property?['title'] ?? 'Property',
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Text(b['propertyAddress'] ?? property?['address'] ?? '',
                                  style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 6),
                                Row(children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(color: _statusColor(status).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                                      Icon(_statusIcon(status), size: 12, color: _statusColor(status)),
                                      const SizedBox(width: 4),
                                      Text(status, style: GoogleFonts.inter(color: _statusColor(status), fontSize: 11, fontWeight: FontWeight.w600)),
                                    ]),
                                  ),
                                ]),
                              ]),
                            )),
                          ]),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('Move-in: ${b['moveInDate'] != null ? DateFormat('MMM d, yyyy').format(DateTime.parse(b['moveInDate'])) : 'N/A'}',
                                  style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600])),
                                Text('Duration: ${b['duration'] ?? 'N/A'}',
                                  style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600])),
                              ]),
                              Text('Rs ${NumberFormat("#,###").format(b['totalAmount'] ?? 0)}',
                                style: GoogleFonts.poppins(color: const Color(0xFF8E2DE2), fontWeight: FontWeight.bold, fontSize: 16)),
                            ]),
                          ),
                        ]),
                      ).animate().fadeIn(delay: (80 * i).ms, duration: 400.ms).slideY(begin: 0.05);
                    },
                  ),
    );
  }

  Widget _placeholder() => Container(
    color: const Color(0xFF8E2DE2).withOpacity(0.1),
    child: const Center(child: Icon(Icons.home_work, size: 30, color: Color(0xFF8E2DE2))),
  );
}
