import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hello/core/services/api_service.dart';
import 'package:hello/core/services/stripe_service.dart';
import 'package:hello/features/home/screens/user_home.dart';
import 'package:intl/intl.dart';

class HousingDetailScreen extends StatefulWidget {
  final String propertyId;
  const HousingDetailScreen({super.key, required this.propertyId});

  @override
  State<HousingDetailScreen> createState() => _HousingDetailScreenState();
}

class _HousingDetailScreenState extends State<HousingDetailScreen> {
  Map<String, dynamic>? _property;
  bool _isLoading = true;
  bool _isFavorited = false;
  int _currentImageIndex = 0;
  final PageController _imagePageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadProperty();
    _checkFavorite();
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  Future<void> _loadProperty() async {
    final result = await ApiService.getHousingPropertyDetail(widget.propertyId);
    if (result['success'] == true && mounted) {
      setState(() {
        _property = result['property'];
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkFavorite() async {
    final isFav = await ApiService.checkHousingFavorite(widget.propertyId);
    if (mounted) setState(() => _isFavorited = isFav);
  }

  Future<void> _toggleFavorite() async {
    final result = await ApiService.toggleHousingFavorite(widget.propertyId);
    if (result['success'] == true && mounted) {
      setState(() => _isFavorited = result['isFavorited'] == true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isFavorited ? 'Added to favorites ❤️' : 'Removed from favorites',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF8E2DE2)),
        ),
      );
    }

    if (_property == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'Property not found',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final p = _property!;
    final images = List<String>.from(p['images'] ?? []);
    final facilities = p['facilities'] as Map<String, dynamic>? ?? {};
    final houseRules = List<String>.from(p['houseRules'] ?? []);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ─── Image Gallery ──────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: const Color(0xFF8E2DE2),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isFavorited ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorited ? Colors.red : Colors.white,
                    size: 20,
                  ),
                ),
                onPressed: _toggleFavorite,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: images.isNotEmpty
                  ? Stack(
                      children: [
                        PageView.builder(
                          controller: _imagePageController,
                          itemCount: images.length,
                          onPageChanged: (i) =>
                              setState(() => _currentImageIndex = i),
                          itemBuilder: (_, i) => Image.network(
                            images[i],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) => _placeholderImage(),
                          ),
                        ),
                        if (images.length > 1)
                          Positioned(
                            bottom: 16,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                images.length,
                                (i) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  width: _currentImageIndex == i ? 24 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _currentImageIndex == i
                                        ? const Color(0xFF8E2DE2)
                                        : Colors.white.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    )
                  : _placeholderImage(),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Title & Price ────────────────────────────────────────
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8E2DE2).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          p['propertyType'] ?? 'Property',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF4A00E0),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (p['genderPreference'] != null &&
                          p['genderPreference'] != 'Any')
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            p['genderPreference'],
                            style: GoogleFonts.inter(
                              color: Colors.purple,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      const Spacer(),
                      Icon(Icons.star, color: Colors.amber[600], size: 18),
                      Text(
                        ' ${(p['rating'] ?? 0).toStringAsFixed(1)}',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        ' (${p['totalReviews'] ?? 0})',
                        style: GoogleFonts.inter(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms),
                  const SizedBox(height: 12),
                  Text(
                    p['title'] ?? 'Untitled',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ).animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${p['address'] ?? ''}, ${p['city'] ?? ''}',
                          style: GoogleFonts.inter(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 150.ms),
                  const SizedBox(height: 16),

                  // ─── Price Card ───────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8E2DE2), Color(0xFF5C16C5)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Monthly Rent',
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Rs ${NumberFormat("#,###").format(num.tryParse(p['monthlyRent']?.toString() ?? '0') ?? 0)}',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (p['securityDeposit'] != null &&
                            (num.tryParse(p['securityDeposit'].toString()) ??
                                    0) >
                                0)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Security',
                                style: GoogleFonts.inter(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                'Rs ${NumberFormat("#,###").format(num.tryParse(p['securityDeposit'].toString()) ?? 0)}',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.05),
                  const SizedBox(height: 20),

                  // ─── Property Details ─────────────────────────────────────
                  _sectionTitle('Property Details'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _detailChip(Icons.bed, '${p['bedrooms'] ?? 1} Bedrooms'),
                      _detailChip(
                        Icons.bathtub_outlined,
                        '${p['bathrooms'] ?? 1} Bathrooms',
                      ),
                      _detailChip(
                        Icons.square_foot,
                        '${p['area_sqft'] ?? 0} sqft',
                      ),
                      _detailChip(
                        Icons.chair_outlined,
                        p['furnished'] ?? 'Unfurnished',
                      ),
                      _detailChip(Icons.groups, p['roomType'] ?? 'Private'),
                      if (p['floor'] != null &&
                          p['floor'].toString().isNotEmpty)
                        _detailChip(Icons.layers, 'Floor: ${p['floor']}'),
                      _detailChip(
                        Icons.people,
                        '${p['currentOccupants'] ?? 0}/${p['maxOccupants'] ?? 1} Occupants',
                      ),
                    ],
                  ).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 20),

                  // ─── Description ──────────────────────────────────────────
                  _sectionTitle('Description'),
                  const SizedBox(height: 8),
                  Text(
                    p['description'] ?? 'No description available.',
                    style: GoogleFonts.inter(
                      color: Colors.grey[700],
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ─── Facilities ───────────────────────────────────────────
                  if (facilities.isNotEmpty) ...[
                    _sectionTitle('Facilities'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: facilities.entries
                          .where((e) => e.value == true)
                          .map((e) => _facilityChip(e.key))
                          .toList(),
                    ).animate().fadeIn(delay: 400.ms),
                    const SizedBox(height: 20),
                  ],

                  // ─── House Rules ──────────────────────────────────────────
                  if (houseRules.isNotEmpty) ...[
                    _sectionTitle('House Rules'),
                    const SizedBox(height: 8),
                    ...houseRules.map(
                      (rule) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 16,
                              color: Color(0xFF8E2DE2),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                rule,
                                style: GoogleFonts.inter(
                                  color: Colors.grey[700],
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ─── Owner Info ───────────────────────────────────────────
                  _sectionTitle('Property Owner'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: const Color(
                            0xFF8E2DE2,
                          ).withOpacity(0.2),
                          backgroundImage:
                              (p['ownerImage'] ?? '').toString().isNotEmpty
                              ? NetworkImage(p['ownerImage'])
                              : null,
                          child: (p['ownerImage'] ?? '').toString().isEmpty
                              ? Text(
                                  (p['ownerName'] ?? 'O')[0].toUpperCase(),
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFF4A00E0),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p['ownerName'] ?? 'Owner',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    size: 14,
                                    color: Colors.amber[600],
                                  ),
                                  Text(
                                    ' ${(p['ownerRating'] ?? 0).toStringAsFixed(1)}',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8E2DE2).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chat_bubble_outline,
                              color: Color(0xFF8E2DE2),
                              size: 20,
                            ),
                          ),
                          onPressed: () {
                            // Navigate to chat with owner
                            Navigator.pushNamed(
                              context,
                              '/chat',
                              arguments: {
                                'receiverId': p['ownerId']?['_id'] ?? '',
                                'otherUserName': p['ownerName'] ?? 'Owner',
                                'serviceId': widget.propertyId,
                                'serviceName': p['title'] ?? 'Housing',
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 500.ms),
                  const SizedBox(height: 100), // Bottom padding for FAB
                ],
              ),
            ),
          ),
        ],
      ),

      // ─── Bottom Action Buttons ──────────────────────────────────────────
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showVisitDialog(context),
                icon: const Icon(Icons.calendar_today, size: 18),
                label: const Text('Schedule Visit'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF8E2DE2),
                  side: const BorderSide(color: Color(0xFF8E2DE2)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showBookingDialog(context),
                icon: const Icon(Icons.book_online, size: 18),
                label: const Text('Book Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8E2DE2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Schedule Visit Dialog ──────────────────────────────────────────────────
  void _showVisitDialog(BuildContext context) {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    String selectedTime = '10:00 AM';
    final messageController = TextEditingController();
    final times = [
      '9:00 AM',
      '10:00 AM',
      '11:00 AM',
      '12:00 PM',
      '2:00 PM',
      '3:00 PM',
      '4:00 PM',
      '5:00 PM',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Schedule a Visit',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select Date',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 60)),
                    );
                    if (picked != null)
                      setModalState(() => selectedDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 18,
                          color: Color(0xFF8E2DE2),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          DateFormat('EEE, MMM d, yyyy').format(selectedDate),
                          style: GoogleFonts.inter(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Select Time',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: times
                      .map(
                        (t) => ChoiceChip(
                          label: Text(
                            t,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: selectedTime == t
                                  ? Colors.white
                                  : Colors.grey[700],
                            ),
                          ),
                          selected: selectedTime == t,
                          selectedColor: const Color(0xFF8E2DE2),
                          onSelected: (_) =>
                              setModalState(() => selectedTime = t),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: messageController,
                  decoration: InputDecoration(
                    hintText: 'Optional message for the owner...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final result = await ApiService.scheduleHousingVisit({
                        'propertyId': widget.propertyId,
                        'visitDate': selectedDate.toIso8601String(),
                        'visitTime': selectedTime,
                        'message': messageController.text,
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              result['message'] ??
                                  (result['success'] == true
                                      ? 'Visit scheduled!'
                                      : 'Failed to schedule'),
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8E2DE2),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Confirm Visit',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── Booking Dialog (Stripe Payment) ────────────────────────────────────────
  void _showBookingDialog(BuildContext context) {
    DateTime moveInDate = DateTime.now().add(const Duration(days: 7));
    String duration = '1 Month';
    final durations = ['1 Month', '3 Months', '6 Months', '1 Year'];
    final notesController = TextEditingController();
    bool isProcessing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final rent = (_property?['monthlyRent'] ?? 0) as num;
          final deposit = (_property?['securityDeposit'] ?? 0) as num;
          final advance = (_property?['advanceRent'] ?? 0) as num;

          // Calculate rent multiplier based on duration
          int monthMultiplier = 1;
          if (duration == '3 Months')
            monthMultiplier = 3;
          else if (duration == '6 Months')
            monthMultiplier = 6;
          else if (duration == '1 Year')
            monthMultiplier = 12;

          final total = (rent * monthMultiplier) + deposit + advance;

          Future<void> handleBookingAndPay() async {
            if (isProcessing) return;
            setModalState(() => isProcessing = true);

            // Step 1: Create booking first
            final result = await ApiService.createHousingBooking({
              'propertyId': widget.propertyId,
              'moveInDate': moveInDate.toIso8601String(),
              'duration': duration,
              'paymentMethod': 'Credit Card',
              'notes': notesController.text,
            });

            if (result['success'] != true) {
              setModalState(() => isProcessing = false);
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text(
                      result['message'] ?? 'Booking creation failed',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              return;
            }

            final bookingId = result['booking']?['_id']?.toString();
            if (bookingId == null) {
              setModalState(() => isProcessing = false);
              return;
            }
            if (ctx.mounted) Navigator.pop(ctx);

            // Step 2: Process Stripe payment
            if (!mounted) return;
            final paymentResult = await StripePaymentService.processPayment(
              context: context,
              bookingId: bookingId,
              serviceType: 'Housing',
              displayAmount: total.toDouble(),
            );

            if (!mounted) return;
            if (paymentResult['success'] == true) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _HousingPaymentSuccessScreen(
                    booking: result['booking'],
                    amount: total.toDouble(),
                    propertyTitle: _property?['title'] ?? 'Property',
                  ),
                ),
              );
            } else if (paymentResult['canceled'] == true) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Payment cancelled. Booking is pending.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(paymentResult['message'] ?? 'Payment failed'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Book This Property',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Move-in Date',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: moveInDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 180)),
                      );
                      if (picked != null)
                        setModalState(() => moveInDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: Color(0xFF8E2DE2),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            DateFormat('EEE, MMM d, yyyy').format(moveInDate),
                            style: GoogleFonts.inter(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Duration',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: durations
                        .map(
                          (d) => ChoiceChip(
                            label: Text(
                              d,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: duration == d
                                    ? Colors.white
                                    : Colors.grey[700],
                              ),
                            ),
                            selected: duration == d,
                            selectedColor: const Color(0xFF8E2DE2),
                            onSelected: (_) =>
                                setModalState(() => duration = d),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _summaryRow(
                          monthMultiplier == 1
                              ? 'Monthly Rent'
                              : 'Rent ($monthMultiplier months)',
                          'Rs ${NumberFormat("#,###").format(rent * monthMultiplier)}',
                        ),
                        if (deposit > 0)
                          _summaryRow(
                            'Security Deposit',
                            'Rs ${NumberFormat("#,###").format(deposit)}',
                          ),
                        if (advance > 0)
                          _summaryRow(
                            'Advance Rent',
                            'Rs ${NumberFormat("#,###").format(advance)}',
                          ),
                        const Divider(),
                        _summaryRow(
                          'Total Due',
                          'Rs ${NumberFormat("#,###").format(total)}',
                          isBold: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Stripe secure badge
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF635BFF).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF635BFF).withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lock,
                          size: 18,
                          color: Color(0xFF635BFF),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Secure payment powered by Stripe',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF635BFF),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: notesController,
                    decoration: InputDecoration(
                      hintText: 'Any special notes...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isProcessing ? null : handleBookingAndPay,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF635BFF),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: isProcessing
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.lock,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Pay Rs ${NumberFormat("#,###").format(total)} via Stripe',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────
  Widget _sectionTitle(String title) => Text(
    title,
    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
  );

  Widget _detailChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF8E2DE2)),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _facilityChip(String facility) {
    final icons = {
      'wifi': Icons.wifi,
      'electricity': Icons.bolt,
      'gas': Icons.local_fire_department,
      'water': Icons.water_drop,
      'ac': Icons.ac_unit,
      'furniture': Icons.chair,
      'kitchen': Icons.kitchen,
      'parking': Icons.local_parking,
      'laundry': Icons.local_laundry_service,
      'security': Icons.security,
      'cctv': Icons.videocam,
      'generator': Icons.power,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icons[facility] ?? Icons.check,
            size: 16,
            color: Colors.green[700],
          ),
          const SizedBox(width: 6),
          Text(
            facility[0].toUpperCase() + facility.substring(1),
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.green[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.grey[700],
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              fontSize: isBold ? 16 : 13,
              color: isBold ? const Color(0xFF8E2DE2) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      color: const Color(0xFF8E2DE2).withOpacity(0.1),
      child: Center(
        child: Icon(
          Icons.home_work,
          size: 64,
          color: const Color(0xFF8E2DE2).withOpacity(0.3),
        ),
      ),
    );
  }
}

// ─── Housing Payment Success Screen ──────────────────────────────────────────
class _HousingPaymentSuccessScreen extends StatelessWidget {
  final Map<String, dynamic> booking;
  final double amount;
  final String propertyTitle;

  const _HousingPaymentSuccessScreen({
    required this.booking,
    required this.amount,
    required this.propertyTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.home_work, size: 72, color: Colors.white),
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 28),
            Text(
              'Booking Confirmed!',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 10),
            Text(
              propertyTitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 16),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 8),
            Text(
              'Rs ${amount.toStringAsFixed(0)} paid securely via Stripe',
              style: GoogleFonts.inter(color: Colors.white60, fontSize: 14),
            ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 48),
            SizedBox(
              width: 220,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => UserHome()),
                  (route) => false,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  'Back to Home',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF4A00E0),
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 500.ms),
          ],
        ),
      ),
    );
  }
}
