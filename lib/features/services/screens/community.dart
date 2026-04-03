import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  _CommunityScreenState createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'News', 'Offers', 'Social', 'Buy/Sell'];

  final List<Map<String, dynamic>> _posts = [
    {
      'user': 'IndieLife Official',
      'role': 'Admin',
      'content': 'Welcome to the new Neighborhood Hub! 🏠 Stay connected with your local community, find exclusive offers, and share updates.',
      'time': '2h ago',
      'type': 'News',
      'likes': 124,
      'comments': 12,
      'color': Color(0xFF4AC29A)
    },
    {
      'user': 'Spice Kitchen',
      'role': 'Meal Provider',
      'content': 'Flash Sale! 🥗 Get 20% off on all healthy bowls for the next 3 hours. Use code: NEIGHBOR20',
      'time': '1h ago',
      'type': 'Offers',
      'likes': 45,
      'comments': 5,
      'color': Color(0xFFFF9D42)
    },
    {
      'user': 'Express Clean',
      'role': 'Laundry Pro',
      'content': 'Rainy season special: 24h express delivery at regular prices starting this weekend! 🌧️👕',
      'time': '4h ago',
      'type': 'Social',
      'likes': 89,
      'comments': 18,
      'color': Color(0xFF2196F3)
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      body: CustomScrollView(
        physics: BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(child: _buildCategoryFilters()),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _buildPostCard(_posts[i], i),
                childCount: _posts.length,
              ),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: Colors.black,
        icon: Icon(Icons.add, color: Colors.white),
        label: Text("Post Something", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
      ).animate().scale(delay: 500.ms),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87), onPressed: () => Navigator.pop(context)),
      flexibleSpace: FlexibleSpaceBar(
        title: Text("Neighborhood Hub", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 18)),
        background: Stack(
          children: [
            Positioned(top: -50, right: -50, child: _blob(Color(0xFF4AC29A).withOpacity(0.1), 200)),
            Positioned(bottom: 20, left: 30, child: _blob(Color(0xFFBDFFF3).withOpacity(0.2), 100)),
            Center(child: Icon(Icons.forum_rounded, size: 80, color: Color(0xFF4AC29A).withOpacity(0.2))),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return Container(
      height: 60,
      margin: EdgeInsets.only(top: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 24),
        itemCount: _categories.length,
        itemBuilder: (context, i) {
          bool isSelected = _selectedCategory == _categories[i];
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = _categories[i]),
            child: AnimatedContainer(
              duration: 200.ms,
              margin: EdgeInsets.only(right: 12),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected ? [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))] : [],
              ),
              child: Center(
                child: Text(_categories[i], style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.grey[600])),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 24),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(backgroundColor: (post['color'] as Color).withOpacity(0.1), child: Icon(Icons.person_rounded, color: post['color'])),
              SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(post['user'], style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(post['role'], style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500])),
                ]),
              ),
              _typeBadge(post['type'], post['color']),
            ],
          ),
          SizedBox(height: 16),
          Text(post['content'], style: GoogleFonts.inter(fontSize: 14, color: Colors.black87, height: 1.5)),
          SizedBox(height: 20),
          Row(
            children: [
              _interaction(Icons.favorite_border_rounded, post['likes'].toString()),
              SizedBox(width: 20),
              _interaction(Icons.chat_bubble_outline_rounded, post['comments'].toString()),
              Spacer(),
              Text(post['time'], style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[400])),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.1, end: 0);
  }

  Widget _typeBadge(String t, Color c) => Container(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Text(t, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: c)));
  
  Widget _interaction(IconData icon, String count) => Row(children: [Icon(icon, size: 18, color: Colors.grey[400]), SizedBox(width: 6), Text(count, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54))]);

  Widget _blob(Color c, double s) => Container(width: s, height: s, decoration: BoxDecoration(color: c, shape: BoxShape.circle));
}
