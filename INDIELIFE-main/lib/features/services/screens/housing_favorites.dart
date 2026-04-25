import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hello/core/services/api_service.dart';
import 'package:hello/features/services/screens/housing_detail.dart';

class HousingFavoritesScreen extends StatefulWidget {
  const HousingFavoritesScreen({super.key});

  @override
  State<HousingFavoritesScreen> createState() => _HousingFavoritesScreenState();
}

class _HousingFavoritesScreenState extends State<HousingFavoritesScreen> {
  List<Map<String, dynamic>> _properties = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    final result = await ApiService.getMyHousingFavorites();
    if (result['success'] == true && mounted) {
      setState(() {
        _properties = List<Map<String, dynamic>>.from(result['properties'] ?? []);
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('Saved Properties', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, foregroundColor: Colors.black87, elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF8E2DE2)))
          : _properties.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.favorite_border, size: 80, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text('No saved properties yet', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[400])),
                    const SizedBox(height: 8),
                    Text('Tap ❤️ on a property to save it', style: GoogleFonts.inter(color: Colors.grey[400])),
                  ]),
                )
              : RefreshIndicator(
                  onRefresh: _loadFavorites,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _properties.length,
                    itemBuilder: (_, i) {
                      final p = _properties[i];
                      return _FavoriteCard(
                        property: p,
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => HousingDetailScreen(propertyId: p['_id']?.toString() ?? ''),
                        )).then((_) => _loadFavorites()),
                        onRemove: () async {
                          final result = await ApiService.toggleHousingFavorite(p['_id']?.toString() ?? '');
                          if (result['success'] == true) _loadFavorites();
                        },
                      ).animate().fadeIn(delay: (80 * i).ms, duration: 400.ms).slideX(begin: 0.05);
                    },
                  ),
                ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  final Map<String, dynamic> property;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _FavoriteCard({required this.property, required this.onTap, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final images = List<String>.from(property['images'] ?? []);
    final displayImage = images.isNotEmpty ? images[0] : (property['thumbnailImage'] ?? '');
    final hasImage = displayImage.toString().isNotEmpty && displayImage.toString().startsWith('http');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
            child: SizedBox(
              width: 110, height: 110,
              child: hasImage
                  ? Image.network(displayImage, fit: BoxFit.cover)
                  : Container(
                      color: const Color(0xFF8E2DE2).withOpacity(0.1),
                      child: const Icon(Icons.home_work, color: Color(0xFF8E2DE2), size: 36),
                    ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(property['title'] ?? 'Untitled', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.location_on, size: 12, color: Colors.grey[500]),
                  const SizedBox(width: 3),
                  Expanded(child: Text('${property['city'] ?? ''}', style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis)),
                ]),
                const SizedBox(height: 6),
                Text('Rs ${property['monthlyRent'] ?? 0}/mo',
                  style: GoogleFonts.poppins(color: const Color(0xFF8E2DE2), fontWeight: FontWeight.bold, fontSize: 15)),
              ]),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.favorite, color: Colors.red, size: 22),
            onPressed: onRemove,
          ),
        ]),
      ),
    );
  }
}
