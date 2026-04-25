import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hello/core/services/api_service.dart';

class LaundryProviderDetailScreen extends StatefulWidget {
  final String providerId;
  final Map<String, dynamic>? initialData;

  const LaundryProviderDetailScreen({
    super.key,
    required this.providerId,
    this.initialData,
  });

  @override
  _LaundryProviderDetailScreenState createState() =>
      _LaundryProviderDetailScreenState();
}

class _LaundryProviderDetailScreenState
    extends State<LaundryProviderDetailScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? provider;
  List<Map<String, dynamic>> services = [];
  bool loading = true;
  late TabController _tabController;
  List<String> categories = ["All", "Wash", "Dry Clean", "Iron", "Wash & Iron"];
  Map<String, int> cartCounts = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: categories.length, vsync: this);
    if (widget.initialData != null) {
      provider = widget.initialData;
      loading = false;
    }
    _loadDetails();
    _loadCart();
  }

  Future<void> _loadCart() async {
    final result = await ApiService.getCart();
    if (result['success'] == true && result['cart'] != null) {
      final items = result['cart']['items'] as List;
      final Map<String, int> counts = {};
      for (var item in items) {
        counts[item['serviceId']['_id'] ?? item['serviceId']] =
            (item['quantity'] ?? 0).toInt();
      }
      if (mounted) setState(() => cartCounts = counts);
    } else if (mounted) {
      setState(() => cartCounts = {});
    }
  }

  Future<void> _loadDetails() async {
    final result = await ApiService.getLaundryProviderDetails(
      widget.providerId,
    );
    if (mounted) {
      setState(() {
        if (result['success'] == true) {
          provider = result['provider'];
          services = List<Map<String, dynamic>>.from(result['services']);
        }
        loading = false;
      });
    }
  }

  void _addToCart(Map<String, dynamic> service, int quantity) async {
    final providerId = provider?['userId'] ?? provider?['_id'];
    if (providerId == null) return;

    final cartItemData = {
      'serviceId': service['_id'],
      'providerId': providerId,
      'providerName': provider?['username']?.toString() ?? 'Laundry Shop',
      'serviceType': 'Laundry',
      'quantity': quantity,
      'name': service['serviceName']?.toString() ?? 'Laundry Item',
      'price': double.tryParse(service['price'].toString()) ?? 0.0,
      'image':
          '', // Laundry items usually don't have individual images in the snippet
      'instructions': '',
      'selectedOptions': {'laundryType': service['laundryType'] ?? 'Wash'},
    };

    final result = await ApiService.addToCart(cartItemData);

    if (result['success'] == true) {
      _loadCart();
      _showSnack('${cartItemData['name']} updated in cart!', Colors.green);
    } else if (result['conflict'] == true) {
      _showConflictDialog(cartItemData);
    } else {
      _showSnack(result['message'] ?? 'Failed to add', Colors.red);
    }
  }

  void _showConflictDialog(Map<String, dynamic> pendingItem) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          "Clear Cart?",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Your cart contains items from another provider. Clear it to continue?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ApiService.clearCart();
              final result = await ApiService.addToCart(pendingItem);
              if (result['success'] == true) {
                _loadCart();
                _showSnack(
                  '${pendingItem['name']} updated in cart!',
                  Colors.green,
                );
              } else {
                _showSnack(result['message'] ?? 'Failed to add', Colors.red);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text("Clear & Add"),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading)
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    if (provider == null)
      return Scaffold(body: Center(child: Text("Provider not found")));

    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(child: _buildInfoCard()),
          SliverPersistentHeader(
            delegate: _SliverAppBarDelegate(_buildTabBar()),
            pinned: true,
          ),
          _buildServiceList(),
          SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ), // Space for bottom bar
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildSliverAppBar() {
    final provName = provider?['username'] ?? 'Laundry';
    final verified = (provider?['isVerified'] ?? false) == true;
    final profileImage = provider?['profileImage']?.toString() ?? '';
    final bool hasImage = profileImage.isNotEmpty;

    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: Colors.blue,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        IconButton(
          icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
          onPressed: () {
            Navigator.pushNamed(
              context,
              '/chat',
              arguments: {
                'receiverId': provider?['userId'] ?? provider?['_id'],
                'otherUserName': provName,
                'serviceName': 'Laundry Service',
              },
            );
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            hasImage
                ? Image.network(profileImage, fit: BoxFit.cover)
                : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF2196F3),
                          Color(0xFF00BCD4),
                          Color(0xFFB3E5FC),
                        ],
                      ),
                    ),
                  ),
            Container(color: Colors.black.withOpacity(0.4)),
            if (!hasImage)
              const Center(
                child: Icon(
                  Icons.local_laundry_service,
                  size: 80,
                  color: Colors.white24,
                ),
              ),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: (provider?['isAvailable'] ?? true)
                              ? Colors.green
                              : Colors.red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          (provider?['isAvailable'] ?? true)
                              ? "OPEN"
                              : "CLOSED",
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (verified) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.verified,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "VERIFIED",
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provName,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statCol(
                Icons.star_rounded,
                '${provider?['rating'] ?? 0.0}',
                'Rating',
                Colors.amber,
              ),
              _divider(),
              _statCol(
                Icons.local_laundry_service,
                '${services.length}',
                'Services',
                Colors.blue,
              ),
              _divider(),
              _statCol(
                Icons.door_front_door_outlined,
                (provider?['isAvailable'] ?? true) ? 'Open' : 'Close',
                'Status',
                (provider?['isAvailable'] ?? true) ? Colors.green : Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 18,
                color: Colors.grey,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  provider?['address'] ??
                      provider?['city'] ??
                      "Unknown Location",
                  style: GoogleFonts.inter(color: Colors.grey[700]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _featureBadge(
                "Pickup Options",
                provider?['pickupAvailable'] ?? false,
                Icons.delivery_dining,
              ),
              const SizedBox(width: 8),
              _featureBadge(
                "Delivery Added",
                provider?['deliveryAvailable'] ?? false,
                Icons.inventory,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCol(IconData icon, String val, String label, Color c) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: c, size: 20),
            const SizedBox(width: 6),
            Text(
              val,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _divider() => Container(width: 1, height: 35, color: Colors.grey[300]);

  Widget _featureBadge(String label, bool active, IconData icon) {
    if (!active) return const SizedBox();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.blue),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.blue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  TabBar _buildTabBar() {
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      labelColor: Colors.blue,
      unselectedLabelColor: Colors.grey,
      indicatorColor: Colors.blue,
      labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      onTap: (index) {
        setState(() {});
      },
      tabs: categories.map((c) => Tab(text: c)).toList(),
    );
  }

  Widget _buildServiceList() {
    String currentCat = categories[_tabController.index];
    List<Map<String, dynamic>> filtered = services;
    if (currentCat != "All") {
      filtered = services
          .where(
            (s) =>
                (s['laundryType'] ?? '') == currentCat ||
                (s['serviceType'] == 'Laundry' && currentCat == 'All'),
          )
          .toList();
    }

    if (filtered.isEmpty) {
      return SliverFillRemaining(
        child: Center(child: Text("No services in this category")),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final service = filtered[index];
          return _buildServiceItem(service);
        }, childCount: filtered.length),
      ),
    );
  }

  Widget _buildServiceItem(Map<String, dynamic> service) {
    String id = service['_id'];
    int count = cartCounts[id] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.withOpacity(0.15),
                  Colors.lightBlue.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(
                Icons.local_laundry_service,
                color: Colors.blue,
                size: 32,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service['serviceName'] ?? "",
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    service['laundryType'] ?? "Laundry",
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "PKR ${service['price']}",
                  style: GoogleFonts.poppins(
                    color: Colors.blue[700],
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (count == 0)
            GestureDetector(
              onTap: () => _addToCart(service, 1),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 24),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.remove,
                      color: Colors.blue,
                      size: 20,
                    ),
                    onPressed: () => _addToCart(service, count - 1),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      "$count",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.blue, size: 20),
                    onPressed: () => _addToCart(service, count + 1),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    int totalItems = cartCounts.values.fold(0, (sum, c) => sum + c);
    if (totalItems == 0) return SizedBox();

    double totalPrice = 0;
    cartCounts.forEach((id, count) {
      final s = services.firstWhere((s) => s['_id'] == id, orElse: () => {});
      if (s.isNotEmpty) totalPrice += (s['price'] ?? 0) * count;
    });

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$totalItems items in cart",
                  style: GoogleFonts.inter(fontSize: 12),
                ),
                Text(
                  "PKR ${totalPrice.toStringAsFixed(0)}",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            Spacer(),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/cart'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: StadiumBorder(),
              ),
              child: Text(
                "View Cart",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _SliverAppBarDelegate(this._tabBar);
  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => Container(color: Colors.white, child: _tabBar);
  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
