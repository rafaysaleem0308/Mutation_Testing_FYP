import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hello/core/services/api_service.dart';
import 'package:hello/features/services/screens/laundry_provider_detail.dart';

class LaundryScreen extends StatefulWidget {
  const LaundryScreen({super.key});

  @override
  State<LaundryScreen> createState() => _LaundryScreenState();
}

class _LaundryScreenState extends State<LaundryScreen> {
  List<dynamic> allProviders = [];
  bool loading = true;
  String searchQuery = "";
  Timer? _refreshTimer;
  
  // Filters
  double minRating = 0;
  bool pickupAvailable = false;
  String selectedType = "All"; // All, Wash, Dry Clean
  
  @override
  void initState() {
    super.initState();
    _loadProviders();
    _refreshTimer = Timer.periodic(Duration(seconds: 15), (_) => _loadProviders(silent: true));
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadProviders({bool silent = false}) async {
    if (!silent) setState(() => loading = true);
    try {
      final result = await ApiService.getLaundryProviders();
      if (mounted) {
        setState(() {
          if (result['success'] == true) {
            allProviders = result['laundryProviders'] ?? [];
          }
          loading = false;
        });
      }
    } catch (e) {
      if (mounted && !silent) setState(() => loading = false);
    }
  }

  List<dynamic> get filteredProviders {
    return allProviders.where((p) {
      bool matchesSearch = (p['username'] ?? '').toLowerCase().contains(searchQuery.toLowerCase()) || 
                           (p['city'] ?? '').toLowerCase().contains(searchQuery.toLowerCase());
      bool matchesRating = (p['rating'] ?? 0) >= minRating;
      bool matchesPickup = !pickupAvailable || (p['pickupAvailable'] == true);
      // bool matchesType = selectedType == "All" || (p['services'] as List).any((s) => s['laundryType'] == selectedType); 
      // API currently doesn't return services list in the summary list, but let's assume if we filtered by backend index we'd get it.
      // For now ignore service type filter on client side as data structure is summary.
      
      return matchesSearch && matchesRating && matchesPickup;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(child: _buildSearchBar()),
          SliverToBoxAdapter(child: _buildFilters()),
          loading 
              ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Color(0xFF2196F3))))
              : filteredProviders.isEmpty 
                  ? SliverFillRemaining(child: Center(child: Text("No laundry service found", style: GoogleFonts.inter(color: Colors.grey))))
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildProviderCard(filteredProviders[index], index),
                          childCount: filteredProviders.length,
                        ),
                      ),
                    ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF2196F3),
      centerTitle: true,
      title: Text('Laundry Services', 
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF2196F3), Color(0xFF00BCD4)],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: TextField(
          onChanged: (val) => setState(() => searchQuery = val),
          decoration: InputDecoration(
            hintText: "Search laundry nearby...",
            prefixIcon: const Icon(Icons.search, color: Color(0xFF2196F3)),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1);
  }

  Widget _buildFilters() {
    return Container(
      height: 50,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        children: [
          _filterChip("Pickup Available", pickupAvailable, () => setState(() => pickupAvailable = !pickupAvailable)),
          SizedBox(width: 8),
          _filterChip("4.0+ Stars", minRating == 4.0, () => setState(() => minRating = minRating == 4.0 ? 0 : 4.0)),
          // Add more filters if needed
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF2196F3) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? const Color(0xFF2196F3) : Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Center(
          child: Text(label, style: GoogleFonts.inter(color: active ? Colors.white : Colors.black87, fontWeight: FontWeight.w500, fontSize: 13)),
        ),
      ),
    );
  }

  Widget _buildProviderCard(dynamic provider, int index) {
    bool isOpen = provider['isAvailable'] ?? true;
    final rating = (provider['rating'] ?? 0).toStringAsFixed(1);
    final verified = provider['isVerified'] == true;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => LaundryProviderDetailScreen(
            providerId: provider['_id'],
            initialData: provider,
          ))
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: Column(children: [
          // Banner
          Container(
            height: 140,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              color: Colors.grey[200],
              image: provider['profileImage'] != null && provider['profileImage'].toString().isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(provider['profileImage']),
                    fit: BoxFit.cover,
                  )
                : null,
            ),
            child: Stack(children: [
              if (provider['profileImage'] == null || provider['profileImage'].toString().isEmpty)
                Center(child: Icon(Icons.local_laundry_service, color: Colors.grey.withValues(alpha: 0.3), size: 60)),
              
              // Verify Badge
              if (verified)
                Positioned(top: 12, right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.verified, color: Colors.blue, size: 16),
                  )),

              // Status Badge
              Positioned(top: 12, left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isOpen ? Colors.green.withValues(alpha: 0.9) : Colors.red.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(10)),
                  child: Text(isOpen ? 'ACTIVE' : 'CLOSED',
                    style: GoogleFonts.inter(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                )),
            ]),
          ),
          // Info
    Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                ),
                child: Center(child: Text(
                  (provider['username'] ?? 'L')[0].toUpperCase(),
                  style: GoogleFonts.poppins(fontSize: 20,
                    fontWeight: FontWeight.bold, color: const Color(0xFF2196F3)),
                )),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(provider['username'] ?? 'Laundry Service',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(rating, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text('Premium Care', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
                  ]),
                ],
              )),
              if (provider['pickupAvailable'] == true)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delivery_dining, color: Colors.blue, size: 24),
                ),
            ]),
          ),
        ]),
      ).animate().fadeIn(delay: (index * 80).ms, duration: 400.ms)
          .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic),
    );
  }
}
