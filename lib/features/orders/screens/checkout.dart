import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hello/core/services/api_service.dart';
import 'package:hello/core/services/stripe_service.dart';
import 'package:hello/features/home/screens/user_home.dart';

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final Map<String, dynamic> provider;

  const CheckoutScreen({
    super.key,
    required this.cartItems,
    required this.provider,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isLoading = false;
  final _deliveryAddressController = TextEditingController();
  final _instructionsController = TextEditingController();
  final phoneController = TextEditingController();
  final _notesController = TextEditingController();

  Map<int, int> itemQuantities = {};
  String _selectedPaymentMethod = 'Cash on Delivery'; // Default to COD

  // Laundry specific
  DateTime? pickupDate;
  TimeOfDay? pickupTime;
  DateTime? deliveryDate;
  TimeOfDay? deliveryTime;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.cartItems.length; i++) {
      itemQuantities[i] = (widget.cartItems[i]['quantity'] ?? 1).toInt();
    }
    phoneController.text = '+92';
    if (isLaundry) {
      pickupDate = DateTime.now().add(const Duration(hours: 2));
      pickupTime = TimeOfDay.now();
      deliveryDate = DateTime.now().add(const Duration(days: 2));
      deliveryTime = const TimeOfDay(hour: 10, minute: 0);
    }
  }

  bool get isLaundry {
    if (widget.cartItems.isEmpty) return false;
    final type =
        widget.cartItems[0]['serviceType']?.toString().toLowerCase() ?? '';
    return type.contains('laundry');
  }

  @override
  void dispose() {
    _deliveryAddressController.dispose();
    _instructionsController.dispose();
    phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double _getItemPrice(Map<String, dynamic> item) =>
      double.tryParse(item['price'].toString()) ?? 0.0;

  double get subtotal {
    double total = 0.0;
    for (int i = 0; i < widget.cartItems.length; i++) {
      total += _getItemPrice(widget.cartItems[i]) * (itemQuantities[i] ?? 1);
    }
    return total;
  }

  double get total => subtotal + 50 + (subtotal * 0.13);

  // ─── STRIPE PAYMENT FLOW ─────────────────────────────────────────────────────
  Future<void> placeOrder() async {
    // ─── VALIDATION ───────────────────────────────────────────────────────────
    if (_deliveryAddressController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        (isLaundry && (pickupDate == null || deliveryDate == null))) {
      _showValidationError(
        "Please fill in all required fields (Address, Phone, and Schedule if applicable).",
      );
      return;
    }

    if (phoneController.text.trim().length < 5) {
      _showValidationError("Please enter a valid phone number.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Step 1: Create the order on backend FIRST (booking must exist before payment)
      final userData = await ApiService.getUserData();
      final userId = userData['_id'] ?? userData['id'];
      final providerId = widget.provider['_id']?.toString() ?? '';
      final providerUserId =
          widget.provider['userId']?.toString() ?? providerId;

      final orderData = {
        'userId': userId,
        'serviceProviderId': providerUserId.isNotEmpty
            ? providerUserId
            : providerId,
        'serviceProviderSpId': providerId,
        'serviceProviderName':
            widget.provider['username']?.toString() ??
            widget.provider['serviceName']?.toString() ??
            'Provider',
        'items': widget.cartItems.asMap().entries.map((e) {
          final item = e.value;
          dynamic sid = item['serviceId'];
          String actualServiceId = '';

          if (sid is Map && sid.containsKey('_id')) {
            actualServiceId = sid['_id'].toString();
          } else if (sid != null) {
            actualServiceId = sid.toString();
          } else {
            actualServiceId = item['_id']?.toString() ?? '';
          }

          return {
            'serviceId': actualServiceId,
            'name':
                item['name']?.toString() ??
                item['serviceName']?.toString() ??
                'Item',
            'quantity': itemQuantities[e.key] ?? 1,
            'price': _getItemPrice(item),
          };
        }).toList(),
        'subtotal': subtotal,
        'deliveryFee': 50,
        'tax': subtotal * 0.13,
        'totalAmount': total,
        'deliveryAddress': _deliveryAddressController.text,
        'deliveryInstructions': _instructionsController.text,
        'specialInstructions': _notesController.text,
        'phone': phoneController.text,
        'paymentMethod': _selectedPaymentMethod,
        'paymentStatus': _selectedPaymentMethod == 'Cash on Delivery'
            ? 'Pending'
            : 'Completed', // Update based on path
      };

      if (isLaundry) {
        orderData['pickupDate'] = pickupDate?.toIso8601String();
        orderData['pickupTime'] = pickupTime != null
            ? "${pickupTime!.hour}:${pickupTime!.minute.toString().padLeft(2, '0')}"
            : null;
        orderData['deliveryDate'] = deliveryDate?.toIso8601String();
        orderData['deliveryTime'] = deliveryTime != null
            ? "${deliveryTime!.hour}:${deliveryTime!.minute.toString().padLeft(2, '0')}"
            : null;
      }

      final orderResult = await ApiService.placeOrder(orderData);

      if (orderResult['success'] != true) {
        if (mounted) setState(() => _isLoading = false);
        if (mounted)
          _showValidationError(
            orderResult['message'] ?? "Failed to create order",
          );
        return;
      }

      final orderId = orderResult['order']?['_id']?.toString();
      if (orderId == null) {
        if (mounted) setState(() => _isLoading = false);
        if (mounted) _showValidationError("Order ID not received from server");
        return;
      }

      // Step 2: Handle Payment
      if (_selectedPaymentMethod == 'Cash on Delivery') {
        // COD path
        await ApiService.clearCart();
        if (mounted) setState(() => _isLoading = false);
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => StripeOrderConfirmationScreen(
              order: orderResult['order'],
              provider: widget.provider,
              amount: total,
              isCOD: true,
            ),
          ),
        );
      } else {
        // Stripe Card path
        if (!mounted) return;
        final paymentResult = await StripePaymentService.processPayment(
          context: context,
          bookingId: orderId,
          serviceType: isLaundry ? 'Laundry' : 'Meal Provider',
          displayAmount: total,
        );

        if (mounted) setState(() => _isLoading = false);
        if (!mounted) return;

        if (paymentResult['success'] == true) {
          await ApiService.clearCart();
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => StripeOrderConfirmationScreen(
                order: orderResult['order'],
                provider: widget.provider,
                amount: total,
              ),
            ),
          );
        } else if (paymentResult['canceled'] == true) {
          _showMsg(
            "Payment cancelled. Your order was created but not paid.",
            false,
          );
        } else {
          _showValidationError(
            paymentResult['message'] ?? "Payment failed. Please try again.",
          );
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      if (mounted) _showMsg("An error occurred: ${e.toString()}", true);
    }
  }

  void _showValidationError(String msg) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 28,
            ),
            const SizedBox(width: 10),
            Text(
              "Attention",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(msg, style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "OK",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMsg(String msg, bool error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Checkout",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF1E293B), Colors.black]),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 120, 20, 100),
        child: Column(
          children: [
            _buildSectionCard("Order Details", [
              ...widget.cartItems.asMap().entries.map(
                (e) => _buildCartItem(e.value, e.key),
              ),
              const Divider(height: 32),
              _row("Subtotal", "PKR ${subtotal.toStringAsFixed(2)}"),
              _row("Delivery Fee", "PKR 50.00"),
              _row("Tax (13%)", "PKR ${(subtotal * 0.13).toStringAsFixed(2)}"),
            ]),
            const SizedBox(height: 24),
            _buildSectionCard("Delivery Details", [
              _field(
                "Address",
                _deliveryAddressController,
                Icons.location_on_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              _field(
                "Phone",
                phoneController,
                Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
            ]),
            if (isLaundry) ...[
              const SizedBox(height: 24),
              _buildSectionCard("Schedule (Laundry)", [
                _buildScheduleRow(
                  "Pickup",
                  pickupDate,
                  pickupTime,
                  (d) => setState(() => pickupDate = d),
                  (t) => setState(() => pickupTime = t),
                ),
                const Divider(height: 32),
                _buildScheduleRow(
                  "Delivery",
                  deliveryDate,
                  deliveryTime,
                  (d) => setState(() => deliveryDate = d),
                  (t) => setState(() => deliveryTime = t),
                ),
              ]),
            ],
            const SizedBox(height: 24),

            // ─── Payment Method Selection ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Payment Method",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Card Option
                  _buildPaymentOption(
                    id: 'Credit Card',
                    title: 'Credit / Debit Card',
                    subtitle: 'Secure payment via Stripe',
                    icon: Icons.credit_card,
                    color: const Color(0xFF635BFF),
                  ),
                  const SizedBox(height: 12),

                  // COD Option
                  _buildPaymentOption(
                    id: 'Cash on Delivery',
                    title: 'Cash on Delivery',
                    subtitle: 'Pay when you receive your order',
                    icon: Icons.payments_outlined,
                    color: Colors.green,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _buildBottomBar(),
    );
  }

  Widget _buildPaymentOption({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    bool isSelected = _selectedPaymentMethod == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.05)
              : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isSelected ? color : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 24)
            else
              const Icon(Icons.circle_outlined, color: Colors.grey, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item['name']?.toString() ?? 'Service',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            "${itemQuantities[index]}x",
            style: GoogleFonts.inter(color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Text(
            "PKR ${(_getItemPrice(item) * itemQuantities[index]!).toStringAsFixed(2)}",
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String val) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(color: Colors.grey[600])),
        Text(val, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ],
    ),
  );

  Widget _buildScheduleRow(
    String label,
    DateTime? date,
    TimeOfDay? time,
    Function(DateTime) onDate,
    Function(TimeOfDay) onTime,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: date ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (picked != null) onDate(picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Color(0xFF1E293B),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        date == null
                            ? "Select Date"
                            : "${date.day}/${date.month}/${date.year}",
                        style: GoogleFonts.inter(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: time ?? TimeOfDay.now(),
                  );
                  if (picked != null) onTime(picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: Color(0xFF1E293B),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        time == null ? "Select Time" : time.format(context),
                        style: GoogleFonts.inter(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF1E293B), size: 20),
        hintText: label,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, -5),
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
                  "Total Amount",
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  "PKR ${total.toStringAsFixed(2)}",
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),
            Expanded(
              child: SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : placeOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF635BFF),
                    shape: const StadiumBorder(),
                  ),
                  child: _isLoading
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
                              Icons.lock_clock_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _selectedPaymentMethod == 'Cash on Delivery'
                                  ? "Confirm Order (COD)"
                                  : "Pay with Card",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Order Confirmation Screen ────────────────────────────────────────────────
class StripeOrderConfirmationScreen extends StatelessWidget {
  final Map<String, dynamic> order;
  final Map<String, dynamic> provider;
  final double amount;
  final bool isCOD;

  const StripeOrderConfirmationScreen({
    super.key,
    required this.order,
    required this.provider,
    required this.amount,
    this.isCOD = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(32),
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF635BFF), Color(0xFF1E293B)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline,
                size: 80,
                color: Colors.white,
              ),
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 32),
            Text(
              isCOD ? "Order Received!" : "Payment Successful!",
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 12),
            Text(
              isCOD
                  ? "Cash on Delivery confirmed"
                  : "PKR ${amount.toStringAsFixed(2)} paid via Stripe",
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 16),
            ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 8),
            Text(
              isCOD
                  ? "Please keep PKR ${amount.toStringAsFixed(0)} ready at delivery."
                  : "Order #${order['_id']?.toString().substring(0, 8) ?? 'ID'}\nhas been confirmed.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white60, fontSize: 14),
            ).animate().fadeIn(delay: 500.ms),
            const SizedBox(height: 48),
            SizedBox(
              width: 220,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => UserHome()),
                  (route) => false,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  "Back to Home",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF635BFF),
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 600.ms),
          ],
        ),
      ),
    );
  }
}

// Keep old class name for compatibility with routes
class OrderConfirmationScreen extends StatelessWidget {
  final Map<String, dynamic> order;
  final Map<String, dynamic> provider;
  const OrderConfirmationScreen({
    super.key,
    required this.order,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) => StripeOrderConfirmationScreen(
    order: order,
    provider: provider,
    amount: (order['totalAmount'] as num?)?.toDouble() ?? 0,
  );
}
