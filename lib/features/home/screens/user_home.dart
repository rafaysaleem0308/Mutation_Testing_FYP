import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hello/core/services/api_service.dart';
import 'package:hello/core/services/chat_service.dart';
import 'package:hello/features/profile/screens/profile.dart';
import 'package:hello/features/home/screens/global_search.dart';
import 'package:hello/features/orders/screens/cart_screen.dart';
import 'package:hello/features/notifications/screens/notifications_screen.dart';
import 'package:hello/features/chat/screens/my_chats_screen.dart';
import 'package:hello/shared/widgets/home_header.dart';
import 'dart:async';

class UserHome extends StatefulWidget {
  const UserHome({super.key});

  @override
  _UserHomeState createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  Map<String, dynamic>? userData;
  int _currentIndex = 0;
  bool _isLoading = true;
  int _unreadNotifications = 0;
  final int _unreadChats = 0;
  final PageController _carouselController = PageController(
    viewportFraction: 0.9,
  );
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Timer? _badgeRefreshTimer;
  StreamSubscription? _chatMessageSubscription;
  StreamSubscription? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    ChatService.init();
    _loadUserData();
    _refreshBadges();

    // Refresh badges every 30 seconds
    _badgeRefreshTimer = Timer.periodic(Duration(seconds: 30), (_) {
      if (mounted) _refreshBadges();
    });

    // Listen for new chat messages to update badge
    _chatMessageSubscription = ChatService.messageStream.listen((_) {
      if (mounted) _refreshBadges();
    });

    // Listen for new push notifications to update badge and show alert
    _notificationSubscription = ChatService.notificationStream.listen((data) {
      if (mounted) {
        _refreshBadges();
        if (_currentIndex != 1) {
          // Don't show snackbar if already on notifications tab
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    Icons.notifications_active,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['title'] ?? 'New Notification',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          data['body'] ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: Color(0xFF1E293B),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: EdgeInsets.all(20),
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _badgeRefreshTimer?.cancel();
    _chatMessageSubscription?.cancel();
    _notificationSubscription?.cancel();
    _carouselController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getUserData();
      if (mounted)
        setState(() {
          userData = data;
          _isLoading = false;
        });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshBadges() async {
    try {
      final count = await ApiService.getUnreadNotificationCount();
      if (mounted) {
        setState(() {
          _unreadNotifications = count;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Color(0xFFF5F7FA),
      extendBody: true,
      drawer: _buildDrawer(),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFFFF9D42)))
          : _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return NotificationsScreen(
          onUnreadCountChanged: (count) {
            if (mounted) setState(() => _unreadNotifications = count);
          },
        );
      case 2:
        return MyChatsScreen();
      case 3:
        return CartScreen();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      padding: EdgeInsets.only(bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── New Modern Header ──
          HomeHeader(
            userData: userData,
            onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
            onProfileTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProfileScreen()),
            ),
            onSearchTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => GlobalSearchScreen()),
            ),
          ),
          SizedBox(height: 20),
          _buildWelcomeHeader(),
          SizedBox(height: 24),
          _buildPromoCarousel(),
          SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              "Explore Services",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 16),
          _buildServiceList(),
          SizedBox(height: 32),
          _buildSpecialOffers(),
        ],
      ),
    );
  }

  Widget _buildSpecialOffers() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Special Offers",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFff7e5f), Color(0xFFfeb47b)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFFff7e5f).withOpacity(0.4),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Get 20% Off",
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "On your first Laundry order",
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/laundry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Color(0xFFff7e5f),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          "Claim Now",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.discount_rounded,
                  size: 80,
                  color: Colors.white.withOpacity(0.3),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Hello, ${userData?['username'] ?? 'Friend'} 👋",
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "Your premium lifestyle assistant is ready.",
            style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 13),
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: -0.1, end: 0);
  }

  Widget _buildPromoCarousel() {
    final List<Map<String, dynamic>> banners = [
      {
        't': 'Fresh Meals',
        's': 'Healthy & Homemade',
        'img': 'assets/images/meal.png',
      },
      {
        't': 'Laundry Pro',
        's': 'Express 24h Service',
        'img': 'assets/images/laundry.png',
      },
      {
        't': 'Safe Housing',
        's': 'Hostels & Flats',
        'img': 'assets/images/accomodation.png',
      },
      {
        't': 'Quick Maintenance',
        's': 'Plumbing, Electrical & More',
        'img': 'assets/images/maintenance.png',
      },
    ];
    return SizedBox(
      height: 180,
      child: PageView.builder(
        controller: _carouselController,
        itemCount: banners.length,
        itemBuilder: (context, i) => Container(
          margin: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            image: DecorationImage(
              image: AssetImage(banners[i]['img']),
              fit: BoxFit.cover,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.5),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    banners[i]['t'],
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    banners[i]['s'],
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "Explore",
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceList() {
    final services = [
      {
        't': 'Meals',
        'desc': 'Fresh home-cooked food delivered to you',
        'r': '/meal',
        'c': [Color(0xFFFF9D42), Color(0xFFFF512F)],
        'i': Icons.restaurant_menu_rounded,
      },
      {
        't': 'Laundry',
        'desc': 'Wash, dry, and fold at your doorstep',
        'r': '/laundry',
        'c': [Color(0xFF2196F3), Color(0xFF00BCD4)],
        'i': Icons.local_laundry_service_outlined,
      },
      {
        't': 'Housing',
        'desc': 'Find the perfect hostel or flat safely',
        'r': '/housing',
        'c': [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
        'i': Icons.home_work_outlined,
      },
      {
        't': 'Maintenance',
        'desc': 'Plumbing, electrical, and rapid repairs',
        'r': '/maintenance',
        'c': [Color(0xFF11998e), Color(0xFF38ef7d)],
        'i': Icons.build_outlined,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: List.generate(services.length, (i) {
          final s = services[i];
          final gradientColors = s['c'] as List<Color>;
          return GestureDetector(
            onTap: () => Navigator.pushNamed(context, s['r'] as String),
            child: Container(
              margin: EdgeInsets.only(bottom: 16),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 15,
                    offset: Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: Colors.grey.withOpacity(0.08),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Hero(
                    tag: 'service_${s['t']}',
                    child: Container(
                      padding: EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: gradientColors[0].withOpacity(0.3),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        s['i'] as IconData,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s['t'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          s['desc'] as String,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade200, width: 1),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: (i * 100).ms).slideX(begin: 0.1, end: 0),
          );
        }),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  BOTTOM NAVIGATION BAR
  // ─────────────────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      margin: EdgeInsets.all(24),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.9),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.home_filled, 0, label: 'Home'),
          _navItemWithBadge(
            Icons.notifications_outlined,
            1,
            _unreadNotifications,
            label: 'Alerts',
          ),
          _navItemWithBadge(
            Icons.chat_bubble_outline_rounded,
            2,
            _unreadChats,
            label: 'Chats',
          ),
          _navItem(Icons.shopping_bag_outlined, 3, label: 'Cart'),
          _navItem(Icons.person_outline, 4, label: 'Profile'),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, int idx, {String? label}) {
    bool sel = _currentIndex == idx;
    return GestureDetector(
      onTap: () {
        if (idx == 4) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProfileScreen()),
          );
        } else {
          setState(() => _currentIndex = idx);
        }
      },
      child: AnimatedContainer(
        duration: 300.ms,
        padding: EdgeInsets.symmetric(horizontal: sel ? 16 : 12, vertical: 10),
        decoration: BoxDecoration(
          color: sel ? Color(0xFFFF9D42) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: sel ? Colors.white : Colors.white60, size: 22),
            if (sel && label != null) ...[
              SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _navItemWithBadge(
    IconData icon,
    int idx,
    int badgeCount, {
    String? label,
  }) {
    bool sel = _currentIndex == idx;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = idx),
      child: AnimatedContainer(
        duration: 300.ms,
        padding: EdgeInsets.symmetric(horizontal: sel ? 16 : 12, vertical: 10),
        decoration: BoxDecoration(
          color: sel ? Color(0xFFFF9D42) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: sel ? Colors.white : Colors.white60,
                  size: 22,
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Color(0xFFFF512F),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black87, width: 1.5),
                      ),
                      constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            if (sel && label != null) ...[
              SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() => Drawer(
    child: Container(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Colors.transparent),
              accountName: Text(
                userData?['username'] ?? "User",
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              accountEmail: Text(
                userData?['email'] ?? "",
                style: GoogleFonts.inter(color: Colors.grey),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Color(0xFFFF9D42),
                child: Text(
                  _getUserInitials(),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.chat_bubble_outline),
              title: Text("Messages"),
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 2);
              },
            ),
            ListTile(
              leading: Icon(Icons.notifications_outlined),
              title: Text("Notifications"),
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 1);
              },
            ),
            ListTile(
              leading: Icon(Icons.shopping_bag_outlined),
              title: Text("Cart"),
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 3);
              },
            ),
            ListTile(
              leading: Icon(Icons.map_outlined),
              title: Text("Track Orders"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/track_order');
              },
            ),
            ListTile(
              leading: Icon(Icons.history),
              title: Text("Order History"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/orders');
              },
            ),
            ListTile(
              leading: Icon(Icons.people_outline_rounded),
              title: Text("Community"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/community');
              },
            ),
            Divider(),
            Spacer(),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text("Logout", style: TextStyle(color: Colors.red)),
              onTap: () => ApiService.logout().then(
                (_) => Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (r) => false,
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    ),
  );

  String _getUserInitials() {
    final name = userData?['username'] ?? userData?['firstName'] ?? '';
    if (name.isEmpty) return 'U';
    final parts = name.toString().trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}
