import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hello/core/services/api_service.dart';
import 'package:hello/features/orders/screens/checkout.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  Map<String, dynamic>? _cart;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final result = await ApiService.getCart();
    if (mounted) {
      setState(() {
        if (result['success'] == true) {
          _cart = result['cart'];
        } else {
          _cart = null;
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _updateQuantity(String itemId, int newQuantity) async {
    if (newQuantity < 1) {
      await _removeItem(itemId);
      return;
    }
    
    // Optimistic update
    setState(() {
      final items = _cart?['items'] as List;
      final idx = items.indexWhere((i) => i['_id'] == itemId);
      if (idx != -1) {
        items[idx]['quantity'] = newQuantity;
      }
    });

    final result = await ApiService.updateCartItem(itemId, newQuantity);
    if (result['success'] != true) {
      _loadCart(); // Rollback/Refresh on error
      _showMsg(result['message'] ?? "Failed to update quantity", true);
    } else {
      setState(() {
        _cart = result['cart'];
      });
    }
  }

  Future<void> _removeItem(String itemId) async {
    final result = await ApiService.removeFromCart(itemId);
    if (result['success'] == true) {
      setState(() {
        _cart = result['cart'];
      });
    } else {
      _showMsg(result['message'] ?? "Failed to remove item", true);
    }
  }

  Future<void> _clearCart() async {
    final result = await ApiService.clearCart();
    if (result['success'] == true) {
      setState(() {
        _cart = null;
      });
    }
  }

  void _showMsg(String msg, bool error) {
    if(!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    List items = _cart?['items'] ?? [];

    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text("My Basket", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        actions: [
          if (items.isNotEmpty)
            TextButton(
              onPressed: _clearCart,
              child: Text("Clear", style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isLoading 
                ? Center(child: CircularProgressIndicator(color: Color(0xFF1E293B)))
                : items.isEmpty 
                  ? _buildEmptyCart() 
                  : _buildCartList(items),
            ),
            if (items.isNotEmpty) _buildCheckoutSummary(items),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20)]),
            child: Icon(Icons.shopping_basket_outlined, size: 80, color: Color(0xFF1E293B).withOpacity(0.3)),
          ),
          SizedBox(height: 32),
          Text("Your basket is empty", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text("Add some items to get started.", style: GoogleFonts.inter(color: Colors.grey[500])),
          SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: StadiumBorder(),
              backgroundColor: Color(0xFF1E293B)
            ),
            child: Text("Explore Services", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildCartList(List items) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      physics: BouncingScrollPhysics(),
      itemCount: items.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              children: [
                Icon(Icons.storefront, color: Colors.grey, size: 20),
                SizedBox(width: 8),
                Text("Provider: ", style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600])),
                Text(_cart?['providerName'] ?? 'Unknown', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(6)),
                  child: Text(_cart?['serviceType'] ?? '', style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }
        final item = items[i - 1];
        return _buildCartItem(item, i - 1);
      },
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item, int index) {
    bool hasImage = item['image'] != null && item['image'].toString().isNotEmpty;
    // Derive a generic icon based on the service name if possible, or use a neutral shopping icon.
    IconData fallbackIcon = Icons.shopping_bag_outlined;
    if (item['name'] != null) {
      String name = item['name'].toString().toLowerCase();
      if (name.contains('wash') || name.contains('iron') || name.contains('laundry')) {
        fallbackIcon = Icons.local_laundry_service_outlined;
      } else if (name.contains('burger') || name.contains('pizza') || name.contains('meal') || name.contains('chicken')) fallbackIcon = Icons.restaurant_menu;
      else if (name.contains('ac') || name.contains('plumb') || name.contains('repair') || name.contains('clean')) fallbackIcon = Icons.handyman_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[100], 
              borderRadius: BorderRadius.circular(16),
            ),
            child: hasImage
              ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(item['image'], fit: BoxFit.cover, errorBuilder: (c,e,s) => Icon(fallbackIcon, color: Colors.grey[600], size: 30)))
              : Icon(fallbackIcon, color: Colors.grey[600], size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item['name'] ?? 'Item', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Text("PKR ${item['price']}", style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black)),
                if (item['instructions'] != null && item['instructions'].toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(item['instructions'], style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500], fontStyle: FontStyle.italic), maxLines: 1, overflow: TextOverflow.ellipsis),
                ]
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => _removeItem(item['_id']),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), shape: BoxShape.circle),
                  child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                ),
              ),
              const SizedBox(height: 12),
              _quantitySelector(item),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.05, end: 0);
  }

  Widget _quantitySelector(Map<String, dynamic> item) {
    int qty = (item['quantity'] ?? 1).toInt();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => _updateQuantity(item['_id'], qty - 1),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.grey[50], borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20))),
              child: Icon(Icons.remove, size: 14, color: Colors.black87),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text("$qty", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          GestureDetector(
            onTap: () => _updateQuantity(item['_id'], qty + 1),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.black, borderRadius: const BorderRadius.only(topRight: Radius.circular(20), bottomRight: Radius.circular(20))),
              child: const Icon(Icons.add, size: 14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutSummary(List items) {
    double subtotal = double.tryParse(_cart?['subtotal']?.toString() ?? '0') ?? 0;
    double total = double.tryParse(_cart?['totalAmount']?.toString() ?? '0') ?? 0;
    double fees = (double.tryParse(_cart?['deliveryFee']?.toString() ?? '0') ?? 0) + 
                  (double.tryParse(_cart?['platformFee']?.toString() ?? '0') ?? 0);

    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: Offset(0, -10))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (fees > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Subtotal & Fees", style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600])),
                  Text("PKR ${(subtotal + fees).toStringAsFixed(0)}", style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[800])),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Total Amount", style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600])),
              Text("PKR ${total.toStringAsFixed(0)}", style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
            ],
          ),
          SizedBox(height: 24),
          SizedBox(
            width: double.infinity, height: 60,
            child: ElevatedButton(
              onPressed: items.isEmpty ? null : () {
                // Convert list of maps to List<Map<String, dynamic>> explicitly
                List<Map<String, dynamic>> cartItems = List<Map<String, dynamic>>.from(items);
                
                Navigator.push(context, MaterialPageRoute(builder: (_) => CheckoutScreen(
                   cartItems: cartItems,
                   provider: {
                     '_id': _cart?['providerId'],
                     'username': _cart?['providerName'] ?? 'Provider',
                   },
                )));
              },
              style: ElevatedButton.styleFrom(
                shape: StadiumBorder(), 
                backgroundColor: Colors.black,
                elevation: 0
              ),
              child: Text("Secure Checkout", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
          SizedBox(height: 12),
        ],
      ),
    );
  }
}
