import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hello/core/services/api_service.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  _GlobalSearchScreenState createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  List<dynamic> _results = [];
  bool _isLoading = false;
  final List<String> _categories = [
    'All',
    'Meal',
    'Laundry',
    'Housing',
    'Maintenance',
  ];

  @override
  void initState() {
    super.initState();
    _performSearch('');
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isLoading = true);
    try {
      String? backendCategory;
      if (_selectedCategory == 'Meal') backendCategory = 'Meal Provider';
      if (_selectedCategory == 'Laundry') backendCategory = 'Laundry';
      if (_selectedCategory == 'Housing')
        backendCategory = 'Hostel/Flat Accommodation';
      if (_selectedCategory == 'Maintenance') backendCategory = 'Maintenance';

      final List<Map<String, dynamic>> searchResults =
          await ApiService.searchServices(query, backendCategory);

      if (mounted) {
        setState(() {
          _results = searchResults;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Search failed: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToResult(dynamic item) {
    final String type = item['serviceType'] ?? '';
    final String providerId = item['serviceProviderId']?.toString() ?? '';

    if (type == 'Meal Provider') {
      Navigator.pushNamed(context, '/meal_info', arguments: item);
    } else if (type == 'Laundry') {
      Navigator.pushNamed(context, '/laundry_info', arguments: item);
    } else if (type == 'Hostel/Flat Accommodation') {
      Navigator.pushNamed(context, '/accommodation_info', arguments: item);
    } else if (type == 'Maintenance') {
      Navigator.pushNamed(context, '/maintenance_info', arguments: item);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchHeader(),
            _buildCategoryFilters(),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF9D42),
                      ),
                    )
                  : _results.isEmpty
                  ? _buildEmptyState()
                  : _buildResultsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back Button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: Colors.black87,
                size: 20,
              ),
            ),
          ),
          SizedBox(height: 16),
          Text(
            "Search Services",
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 20,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _performSearch,
              decoration: InputDecoration(
                hintText: "Search for providers...",
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Color(0xFFFF9D42),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1, end: 0);
  }

  Widget _buildCategoryFilters() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        itemBuilder: (context, i) {
          bool isSelected = _selectedCategory == _categories[i];
          return GestureDetector(
            onTap: () {
              setState(() => _selectedCategory = _categories[i]);
              _performSearch(_searchController.text);
            },
            child: Container(
              margin: EdgeInsets.only(right: 12),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? Color(0xFFFF9D42) : Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Color(0xFFFF9D42).withOpacity(0.3),
                          blurRadius: 8,
                        ),
                      ]
                    : [],
              ),
              child: Text(
                _categories[i],
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.grey[600],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey[300]),
          SizedBox(height: 16),
          Text(
            "No services found",
            style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView.builder(
      padding: EdgeInsets.all(20),
      physics: BouncingScrollPhysics(),
      itemCount: _results.length,
      itemBuilder: (context, i) => _buildResultCard(_results[i], i),
    );
  }

  Widget _buildResultCard(dynamic item, int index) {
    String serviceName = item['serviceName'] ?? item['name'] ?? 'Service';
    String providerName =
        item['serviceProviderName'] ?? item['providerName'] ?? 'Provider';
    String type = item['serviceType'] ?? 'Service';
    String price = item['price']?.toString() ?? '0';
    String unit = item['unit'] ?? '';

    return GestureDetector(
      onTap: () => _navigateToResult(item),
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFFF9D42).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getCategoryIcon(type),
                color: Color(0xFFFF9D42),
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    serviceName,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "By $providerName",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "PKR $price",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF9D42),
                  ),
                ),
                if (unit.isNotEmpty)
                  Text(
                    "per $unit",
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: Colors.grey[400],
                    ),
                  ),
              ],
            ),
            SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: Colors.grey[300]),
          ],
        ),
      ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1, end: 0),
    );
  }

  IconData _getCategoryIcon(String type) {
    if (type.contains('Meal')) return Icons.restaurant_rounded;
    if (type.contains('Laundry')) return Icons.local_laundry_service_rounded;
    if (type.contains('Accommodation')) return Icons.home_work_rounded;
    return Icons.engineering_rounded;
  }
}
