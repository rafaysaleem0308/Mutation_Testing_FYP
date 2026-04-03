import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hello/core/services/api_service.dart';
import 'package:hello/features/orders/screens/order_details_modal.dart';
import 'package:intl/intl.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  _OrdersScreenState createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<dynamic> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final result = await ApiService.getCustomerOrders();
    if (mounted) {
      setState(() {
        if (result['success'] == true) {
          _orders = result['orders'] ?? [];
          // Sort by date descending
          _orders.sort((a, b) => (b['createdAt'] ?? '').compareTo(a['createdAt'] ?? ''));
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text("Order History", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.black))
          : _orders.isEmpty
              ? _buildEmptyOrders()
              : RefreshIndicator(
                  onRefresh: _loadOrders,
                  color: Colors.black,
                  child: ListView.builder(
                    padding: EdgeInsets.all(20),
                    itemCount: _orders.length,
                    itemBuilder: (context, index) => _buildOrderCard(_orders[index]),
                  ),
                ),
    );
  }

  Widget _buildEmptyOrders() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey[300]),
          SizedBox(height: 16),
          Text("No orders yet", style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey[600])),
          SizedBox(height: 8),
          Text("Start ordering some delicious meals or laundry services!", style: GoogleFonts.inter(color: Colors.grey[500]), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] ?? 'Pending';
    final date = order['createdAt'] != null ? DateTime.parse(order['createdAt']) : DateTime.now();
    final total = double.tryParse(order['totalAmount']?.toString() ?? '0') ?? 0.0;
    final orderId = order['_id']?.toString() ?? 'ID';
    final providerName = order['providerName'] ?? order['serviceProviderName'] ?? 'Provider';

    return GestureDetector(
      onTap: () => _showOrderDetails(order),
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Order #${orderId.substring(orderId.length > 8 ? orderId.length - 8 : 0)}", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[600])),
                    SizedBox(height: 4),
                    Text(providerName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                _statusBadge(status),
              ],
            ),
            Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormat('MMM dd, yyyy • hh:mm a').format(date), style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
                    SizedBox(height: 4),
                    Text("${(order['items'] as List).length} items", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
                Text("PKR ${total.toStringAsFixed(0)}", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFFFF512F))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'completed': color = Colors.green; break;
      case 'cancelled': color = Colors.red; break;
      case 'accepted': color = Colors.blue; break;
      case 'pending': color = Colors.orange; break;
      default: color = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status.toUpperCase(), style: GoogleFonts.inter(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  void _showOrderDetails(Map<String, dynamic> order) {
     showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OrderDetailsModal(order: order),
    );
  }
}
