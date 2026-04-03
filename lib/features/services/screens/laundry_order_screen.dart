import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:hello/core/services/api_service.dart';

class LaundryOrderScreen extends StatefulWidget {
  final Map<String, dynamic> provider;
  final List<Map<String, dynamic>> initialCart;

  const LaundryOrderScreen({super.key, required this.provider, required this.initialCart});

  @override
  _LaundryOrderScreenState createState() => _LaundryOrderScreenState();
}

class _LaundryOrderScreenState extends State<LaundryOrderScreen> {
  int _currentStep = 0;
  List<Map<String, dynamic>> cartItems = [];
  
  // Scheduling
  DateTime? pickupDate;
  TimeOfDay? pickupTime;
  DateTime? deliveryDate;
  TimeOfDay? deliveryTime;
  
  // Addresses
  String deliveryAddress = "";
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    cartItems = List.from(widget.initialCart);
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    final user = await ApiService.getUserData();
    if (user['address'] != null) {
      if (mounted) {
        setState(() {
        _addressController.text = user['address'];
      });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text("Place Laundry Order", style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: PageView(
              physics: NeverScrollableScrollPhysics(),
              controller: PageController(initialPage: _currentStep),
              children: [
                _buildReviewCartStep(),
                _buildSchedulingStep(),
                _buildReviewOrderStep(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _stepIcon(0, "Items"),
          _stepLine(0),
          _stepIcon(1, "Schedule"),
          _stepLine(1),
          _stepIcon(2, "Confirm"),
        ],
      ),
    );
  }

  Widget _stepIcon(int step, String label) {
    bool isActive = _currentStep >= step;
    return Column(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: isActive ? Color(0xFF2196F3) : Colors.grey[300],
          child: isActive 
              ? Icon(Icons.check, size: 16, color: Colors.white)
              : Text("${step + 1}", style: TextStyle(color: Colors.white, fontSize: 12)),
        ),
        SizedBox(height: 4),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: isActive ? Color(0xFF2196F3) : Colors.grey)),
      ],
    );
  }

  Widget _stepLine(int step) {
    return Container(
      width: 40,
      height: 2,
      color: _currentStep > step ? Color(0xFF2196F3) : Colors.grey[300],
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 10), // align with circle center roughly
    );
  }

  Widget _buildReviewCartStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Selected Items", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          if (cartItems.isEmpty) 
            Center(child: Text("No items selected", style: GoogleFonts.inter(color: Colors.grey))),
          ...cartItems.map((item) => _buildCartItem(item)),
          SizedBox(height: 20),
          _buildPriceSummary(),
        ],
      ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.local_laundry_service, color: Colors.blue),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['name'], style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                Text("PKR ${item['price']}", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(icon: Icon(Icons.remove_circle_outline), onPressed: () => _updateQty(item, -1)),
              Text("${item['quantity']}", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              IconButton(icon: Icon(Icons.add_circle_outline), onPressed: () => _updateQty(item, 1)),
            ],
          )
        ],
      ),
    );
  }

  void _updateQty(Map<String, dynamic> item, int change) {
    setState(() {
      item['quantity'] += change;
      if (item['quantity'] <= 0) {
        cartItems.remove(item);
      }
    });
  }

  Widget _buildSchedulingStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.provider['pickupAvailable'] == true) ...[
            Text("Pickup Schedule", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            _buildDateTimePicker(
              "Pickup Date", 
              pickupDate, 
              (date) => setState(() => pickupDate = date)
            ),
            SizedBox(height: 8),
            _buildTimePicker(
              "Pickup Time", 
              pickupTime, 
              (time) => setState(() => pickupTime = time)
            ),
            SizedBox(height: 24),
          ],
          
          Text("Delivery Schedule", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          _buildDateTimePicker(
            "Delivery Date", 
            deliveryDate, 
            (date) => setState(() => deliveryDate = date)
          ),
          SizedBox(height: 8),
          _buildTimePicker(
            "Delivery Time", 
            deliveryTime, 
            (time) => setState(() => deliveryTime = time)
          ),
          
          SizedBox(height: 24),
          Text("Location", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          TextField(
            controller: _addressController,
            decoration: InputDecoration(
              labelText: "Pickup/Delivery Address",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: Icon(Icons.location_on_outlined),
              filled: true,
              fillColor: Colors.white,
            ),
            maxLines: 2,
          ),
          SizedBox(height: 16),
          TextField(
            controller: _notesController,
            decoration: InputDecoration(
              labelText: "Special Instructions / Notes",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: Icon(Icons.note_alt_outlined),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimePicker(String label, DateTime? value, Function(DateTime) onSelect) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context, 
          initialDate: DateTime.now(), 
          firstDate: DateTime.now(), 
          lastDate: DateTime.now().add(Duration(days: 30))
        );
        if (date != null) onSelect(date);
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.2))
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: Color(0xFF2196F3)),
            SizedBox(width: 12),
            Text(
              value != null ? DateFormat('EEE, MMM d, yyyy').format(value) : "Select $label",
              style: GoogleFonts.inter(fontSize: 14, fontWeight: value != null ? FontWeight.bold : FontWeight.normal),
            ),
            Spacer(),
            Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker(String label, TimeOfDay? value, Function(TimeOfDay) onSelect) {
    return InkWell(
      onTap: () async {
        final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
        if (time != null) onSelect(time);
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.2))
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, color: Color(0xFF2196F3)),
            SizedBox(width: 12),
            Text(
              value != null ? value.format(context) : "Select $label",
              style: GoogleFonts.inter(fontSize: 14, fontWeight: value != null ? FontWeight.bold : FontWeight.normal),
            ),
            Spacer(),
            Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewOrderStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Order Summary", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                Divider(height: 24),
                _summaryRow("Provider", widget.provider['username']),
                _summaryRow("Items", "${cartItems.length} items"),
                if (pickupDate != null)
                   _summaryRow("Pickup", "${DateFormat('MMM d').format(pickupDate!)} at ${pickupTime?.format(context) ?? ''}"),
                if (deliveryDate != null)
                   _summaryRow("Delivery", "${DateFormat('MMM d').format(deliveryDate!)} at ${deliveryTime?.format(context) ?? ''}"),
                _summaryRow("Address", _addressController.text, maxLines: 2),
                Divider(height: 24),
                _buildPriceSummary(compact: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _summaryRow(String label, String value, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: GoogleFonts.inter(color: Colors.grey))),
          Expanded(child: Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w500), maxLines: maxLines, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildPriceSummary({bool compact = false}) {
    double subtotal = cartItems.fold(0, (sum, item) => sum + (item['price'] * item['quantity']));
    double delivery = 100.0; // Fixed for now or calc based on distance
    double total = subtotal + delivery;

    return Column(
      children: [
        _priceRow("Subtotal", subtotal),
        _priceRow("Delivery Fee", delivery),
        Divider(),
        _priceRow("Total", total, isTotal: true),
      ],
    );
  }

  Widget _priceRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, fontSize: isTotal ? 16 : 14)),
          Text("PKR ${amount.toStringAsFixed(0)}", style: GoogleFonts.inter(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, fontSize: isTotal ? 16 : 14, color: isTotal ? Color(0xFF2196F3) : Colors.black)),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))]),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _isLoading ? null : _handleNext,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF2196F3),
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isLoading 
              ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(_currentStep == 2 ? "Confirm Order" : "Next", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  void _handleNext() {
    if (_currentStep == 0) {
      if (cartItems.isEmpty) return;
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      if (pickupDate == null && widget.provider['pickupAvailable'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please select pickup date")));
        return;
      }
      if (deliveryDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please select delivery date")));
        return;
      }
      if (_addressController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please enter address")));
        return;
      }
      setState(() => _currentStep = 2);
    } else {
      _submitOrder();
    }
  }

  Future<void> _submitOrder() async {
    setState(() => _isLoading = true);
    
    double subtotal = cartItems.fold(0, (sum, item) => sum + (item['price'] * item['quantity']));
    double deliveryFee = 100.0;
    
    final orderData = {
      'serviceProviderId': widget.provider['_id'] ?? widget.provider['serviceProviderId'],
      'items': cartItems.map((i) => {
        'serviceId': i['_id'],
        'quantity': i['quantity'],
      }).toList(),
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'totalAmount': subtotal + deliveryFee,
      'deliveryAddress': _addressController.text,
      'deliveryInstructions': _notesController.text,
      'pickupDate': pickupDate?.toIso8601String(),
      'pickupTime': pickupTime?.format(context),
      'deliveryDate': deliveryDate?.toIso8601String(),
      'deliveryTime': deliveryTime?.format(context),
    };
    
    final result = await ApiService.placeOrder(orderData);
    
    setState(() => _isLoading = false);
    
    if (result['success'] == true) {
      // Navigate to tracking or home
      Navigator.popUntil(context, (route) => route.isFirst);
      // Ideally show success dialog then go to orders
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Order placed successfully!")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: ${result['message']}")));
    }
  }
}
