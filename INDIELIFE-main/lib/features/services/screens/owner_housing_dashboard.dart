import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hello/core/services/api_service.dart';
import 'package:intl/intl.dart';

class OwnerHousingDashboard extends StatefulWidget {
  const OwnerHousingDashboard({super.key});

  @override
  State<OwnerHousingDashboard> createState() => _OwnerHousingDashboardState();
}

class _OwnerHousingDashboardState extends State<OwnerHousingDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _myProperties = [];
  List<Map<String, dynamic>> _ownerBookings = [];
  List<Map<String, dynamic>> _ownerVisits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadStats(),
      _loadProperties(),
      _loadBookings(),
      _loadVisits(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadStats() async {
    final result = await ApiService.getHousingOwnerStats();
    if (result['success'] == true && mounted) {
      setState(() => _stats = result['stats']);
    }
  }

  Future<void> _loadProperties() async {
    final result = await ApiService.getMyHousingProperties();
    if (result['success'] == true && mounted) {
      setState(
        () => _myProperties = List<Map<String, dynamic>>.from(
          result['properties'] ?? [],
        ),
      );
    }
  }

  Future<void> _loadBookings() async {
    final result = await ApiService.getOwnerHousingBookings();
    if (result['success'] == true && mounted) {
      setState(
        () => _ownerBookings = List<Map<String, dynamic>>.from(
          result['bookings'] ?? [],
        ),
      );
    }
  }

  Future<void> _loadVisits() async {
    final result = await ApiService.getOwnerHousingVisits();
    if (result['success'] == true && mounted) {
      setState(
        () => _ownerVisits = List<Map<String, dynamic>>.from(
          result['visits'] ?? [],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'Owner Dashboard',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF8E2DE2),
          unselectedLabelColor: Colors.grey[500],
          indicatorColor: const Color(0xFF8E2DE2),
          labelStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Properties'),
            Tab(text: 'Bookings'),
            Tab(text: 'Visits'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline,
              color: Color(0xFF8E2DE2),
            ),
            onPressed: () => Navigator.pushNamed(
              context,
              '/add-hostel-service',
            ).then((_) => _loadAll()),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF8E2DE2)),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildPropertiesTab(),
                _buildBookingsTab(),
                _buildVisitsTab(),
              ],
            ),
    );
  }

  // ─── Overview Tab ───────────────────────────────────────────────────────────
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _statCard(
                'Properties',
                '${_stats?['totalProperties'] ?? 0}',
                Icons.home_work,
                const Color(0xFF8E2DE2),
              ),
              _statCard(
                'Total Bookings',
                '${_stats?['totalBookings'] ?? 0}',
                Icons.book_online,
                Colors.blue,
              ),
              _statCard(
                'Total Visits',
                '${_stats?['totalVisits'] ?? 0}',
                Icons.calendar_today,
                Colors.purple,
              ),
              _statCard(
                'Earnings',
                'Rs ${NumberFormat("#,###").format(_stats?['totalEarnings'] ?? 0)}',
                Icons.monetization_on,
                Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Recent activity
          if (_ownerBookings.isNotEmpty) ...[
            Text(
              'Recent Bookings',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            ..._ownerBookings.take(3).map((b) => _miniBookingCard(b)),
          ],
        ],
      ).animate().fadeIn(duration: 500.ms),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ─── Properties Tab ─────────────────────────────────────────────────────────
  Widget _buildPropertiesTab() {
    if (_myProperties.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.home_work_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No properties yet',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(
                context,
                '/add-hostel-service',
              ).then((_) => _loadAll()),
              icon: const Icon(Icons.add),
              label: const Text('Add Property'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8E2DE2),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadProperties,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myProperties.length,
        itemBuilder: (_, i) {
          final p = _myProperties[i];
          final status = p['status'] ?? 'pending_approval';
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: p['images'] != null && (p['images'] as List).isNotEmpty
                      ? Image.network(
                          p['images'][0],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                ),
              ),
              title: Text(
                p['title'] ?? 'Untitled',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rs ${NumberFormat("#,###").format(p['monthlyRent'] ?? 0)}/mo',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF8E2DE2),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _statusBadge(status),
                ],
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'delete') {
                    final res = await ApiService.deleteHousingProperty(
                      p['_id'],
                    );
                    if (res['success'] == true) _loadProperties();
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: (80 * i).ms, duration: 400.ms);
        },
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'approved':
        color = Colors.green;
        label = 'Approved';
        break;
      case 'pending_approval':
        color = Colors.orange;
        label = 'Pending';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'Rejected';
        break;
      case 'suspended':
        color = Colors.grey;
        label = 'Suspended';
        break;
      default:
        color = Colors.grey;
        label = status;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ─── Bookings Tab ───────────────────────────────────────────────────────────
  Widget _buildBookingsTab() {
    if (_ownerBookings.isEmpty) {
      return Center(
        child: Text(
          'No booking requests yet',
          style: GoogleFonts.poppins(color: Colors.grey[400]),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _ownerBookings.length,
        itemBuilder: (_, i) => _bookingCard(_ownerBookings[i], i),
      ),
    );
  }

  Widget _bookingCard(Map<String, dynamic> b, int index) {
    final status = b['status'] ?? 'Pending';
    Color statusColor;
    switch (status) {
      case 'Pending':
        statusColor = Colors.orange;
        break;
      case 'Accepted':
        statusColor = Colors.blue;
        break;
      case 'Confirmed':
        statusColor = Colors.green;
        break;
      case 'Rejected':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  b['propertyTitle'] ?? 'Property',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.inter(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Tenant: ${b['tenantName'] ?? 'N/A'}',
            style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 12),
          ),
          Text(
            'Move-in: ${b['moveInDate'] != null ? DateFormat('MMM d, yyyy').format(DateTime.parse(b['moveInDate'])) : 'N/A'}',
            style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 12),
          ),
          Text(
            'Amount: Rs ${NumberFormat("#,###").format(b['totalAmount'] ?? 0)}',
            style: GoogleFonts.inter(
              color: const Color(0xFF8E2DE2),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          if (status == 'Pending') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final res = await ApiService.updateHousingBookingStatus(
                        b['_id'],
                        'Rejected',
                      );
                      if (res['success'] == true) _loadBookings();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final res = await ApiService.updateHousingBookingStatus(
                        b['_id'],
                        'Accepted',
                      );
                      if (res['success'] == true) _loadBookings();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: (80 * index).ms, duration: 400.ms);
  }

  Widget _miniBookingCard(Map<String, dynamic> b) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.book_online, color: const Color(0xFF8E2DE2), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              b['propertyTitle'] ?? 'Property',
              style: GoogleFonts.inter(fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            b['status'] ?? '',
            style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // ─── Visits Tab ─────────────────────────────────────────────────────────────
  Widget _buildVisitsTab() {
    if (_ownerVisits.isEmpty) {
      return Center(
        child: Text(
          'No visit requests yet',
          style: GoogleFonts.poppins(color: Colors.grey[400]),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadVisits,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _ownerVisits.length,
        itemBuilder: (_, i) {
          final v = _ownerVisits[i];
          final status = v['status'] ?? 'Pending';

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        v['propertyTitle'] ?? 'Property',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    _statusBadge(
                      status == 'Pending'
                          ? 'pending_approval'
                          : status.toLowerCase(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Visitor: ${v['userName'] ?? 'N/A'}',
                  style: GoogleFonts.inter(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Date: ${v['visitDate'] != null ? DateFormat('MMM d, yyyy').format(DateTime.parse(v['visitDate'])) : 'N/A'} at ${v['visitTime'] ?? ''}',
                  style: GoogleFonts.inter(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                if (status == 'Pending') ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final res =
                                await ApiService.updateHousingVisitStatus(
                                  v['_id'],
                                  'Rejected',
                                );
                            if (res['success'] == true) _loadVisits();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                          child: const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final res =
                                await ApiService.updateHousingVisitStatus(
                                  v['_id'],
                                  'Accepted',
                                );
                            if (res['success'] == true) _loadVisits();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Accept'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ).animate().fadeIn(delay: (80 * i).ms, duration: 400.ms);
        },
      ),
    );
  }

  Widget _placeholder() => Container(
    color: const Color(0xFF8E2DE2).withOpacity(0.1),
    child: const Center(
      child: Icon(Icons.home_work, size: 24, color: Color(0xFF8E2DE2)),
    ),
  );
}
