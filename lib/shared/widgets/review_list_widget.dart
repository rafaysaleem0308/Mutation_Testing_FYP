import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hello/core/services/api_service.dart';
import 'package:intl/intl.dart';

class ReviewListWidget extends StatefulWidget {
  final String spId;
  final Color themeColor;

  const ReviewListWidget({super.key, required this.spId, this.themeColor = const Color(0xFFFF9D42)});

  @override
  _ReviewListWidgetState createState() => _ReviewListWidgetState();
}

class _ReviewListWidgetState extends State<ReviewListWidget> {
  List<dynamic> _reviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    setState(() => _isLoading = true);
    final reviews = await ApiService.getProviderReviews(widget.spId);
    if (mounted) {
      setState(() {
        _reviews = reviews;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return Center(child: CircularProgressIndicator(color: widget.themeColor));
    
    if (_reviews.isEmpty) {
      return Column(
        children: [
          Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey[300]),
          SizedBox(height: 12),
          Text("No reviews yet. Be the first to rate!", style: GoogleFonts.inter(color: Colors.grey, fontSize: 13)),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Reviews (${_reviews.length})", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton(onPressed: _fetchReviews, child: Text("Refresh", style: TextStyle(color: widget.themeColor, fontSize: 12))),
          ],
        ),
        SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _reviews.length,
          itemBuilder: (context, index) => _buildReviewItem(_reviews[index]),
        ),
      ],
    );
  }

  Widget _buildReviewItem(dynamic review) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: widget.themeColor.withOpacity(0.1),
                child: Text(review['customerName']?[0].toUpperCase() ?? 'U', style: TextStyle(color: widget.themeColor, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review['customerName'] ?? "Anonymous", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(review['createdAt'] != null ? DateFormat.yMMMd().format(DateTime.parse(review['createdAt'])) : "Recently", style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (index) => Icon(
                  index < (review['rating'] ?? 5) ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: Colors.amber,
                  size: 14,
                )),
              ),
            ],
          ),
          if (review['comment'] != null && review['comment'].toString().isNotEmpty) ...[
            SizedBox(height: 12),
            Text(review['comment'], style: GoogleFonts.inter(fontSize: 13, color: Colors.black87, height: 1.5)),
          ]
        ],
      ),
    );
  }
}
