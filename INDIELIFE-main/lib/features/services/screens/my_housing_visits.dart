import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hello/core/services/api_service.dart';
import 'package:intl/intl.dart';

class MyHousingVisitsScreen extends StatefulWidget {
  const MyHousingVisitsScreen({super.key});

  @override
  State<MyHousingVisitsScreen> createState() => _MyHousingVisitsScreenState();
}

class _MyHousingVisitsScreenState extends State<MyHousingVisitsScreen> {
  List<Map<String, dynamic>> _visits = [];
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadVisits();
    _refreshTimer = Timer.periodic(Duration(seconds: 15), (_) => _loadVisits(silent: true));
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadVisits({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    final result = await ApiService.getMyHousingVisits();
    if (result['success'] == true && mounted) {
      setState(() {
        _visits = List<Map<String, dynamic>>.from(result['visits'] ?? []);
        _isLoading = false;
      });
    } else if (mounted) {
      if (!silent) setState(() => _isLoading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Pending': return Colors.orange;
      case 'Accepted': return Colors.green;
      case 'Rejected': return Colors.red;
      case 'Rescheduled': return Colors.blue;
      case 'Completed': return Colors.teal;
      case 'Cancelled': return Colors.grey;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('My Visits', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, foregroundColor: Colors.black87, elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF8E2DE2)))
          : _visits.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.calendar_month, size: 80, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text('No scheduled visits', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[400])),
                    const SizedBox(height: 8),
                    Text('Your visit requests will appear here', style: GoogleFonts.inter(color: Colors.grey[400])),
                  ]),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                    itemCount: _visits.length,
                    itemBuilder: (_, i) {
                      final v = _visits[i];
                      final status = v['status'] ?? 'Pending';
                      final property = v['propertyId'] as Map<String, dynamic>?;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white, borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8E2DE2).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.home_work, color: Color(0xFF8E2DE2), size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(v['propertyTitle'] ?? property?['title'] ?? 'Property',
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text(v['propertyAddress'] ?? '', style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 11)),
                            ])),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(color: _statusColor(status).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                              child: Text(status, style: GoogleFonts.inter(color: _statusColor(status), fontSize: 11, fontWeight: FontWeight.w600)),
                            ),
                          ]),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(10)),
                            child: Row(children: [
                              Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Text(
                                v['visitDate'] != null ? DateFormat('EEE, MMM d, yyyy').format(DateTime.parse(v['visitDate'])) : 'N/A',
                                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(width: 16),
                              Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 6),
                              Text(v['visitTime'] ?? 'N/A', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
                            ]),
                          ),
                          if (status == 'Rescheduled' && v['rescheduledDate'] != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.blue.withOpacity(0.2))),
                              child: Row(children: [
                                const Icon(Icons.update, size: 16, color: Colors.blue),
                                const SizedBox(width: 8),
                                Text('Rescheduled to: ${DateFormat('MMM d').format(DateTime.parse(v['rescheduledDate']))} at ${v['rescheduledTime'] ?? ''}',
                                  style: GoogleFonts.inter(fontSize: 12, color: Colors.blue[700], fontWeight: FontWeight.w500)),
                              ]),
                            ),
                          ],
                          if (v['ownerNotes'] != null && v['ownerNotes'].toString().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text('Owner note: ${v['ownerNotes']}', style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic)),
                          ],
                          const SizedBox(height: 8),
                          Row(children: [
                            Icon(Icons.person, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text('Owner: ${v['ownerName'] ?? 'N/A'}', style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 12)),
                          ]),
                        ]),
                      ).animate().fadeIn(delay: (80 * i).ms, duration: 400.ms).slideY(begin: 0.05);
                    },
                  ),
    );
  }
}
