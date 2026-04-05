import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hello/core/services/api_service.dart';
import 'package:intl/intl.dart';

class OrderDetailsModal extends StatefulWidget {
  final Map<String, dynamic> order;
  const OrderDetailsModal({super.key, required this.order});
  @override
  _OrderDetailsModalState createState() => _OrderDetailsModalState();
}

class _OrderDetailsModalState extends State<OrderDetailsModal> {
  List<Map<String, dynamic>> messages = [];
  final messageController = TextEditingController();
  bool sendingMessage = false;

  @override
  void initState() {
    super.initState();
    messages = List<Map<String, dynamic>>.from(widget.order['messages'] ?? []);
  }

  Future<void> _sendMessage() async {
    if (messageController.text.isEmpty) return;
    setState(() => sendingMessage = true);
    try {
      final result = await ApiService.sendOrderMessage(
        widget.order['_id'],
        messageController.text,
      );
      if (mounted) setState(() => sendingMessage = false);

      if (result['success'] == true) {
        if (mounted) {
          setState(() {
            messages.add(result['messageData']);
            messageController.clear();
          });
        }
      } else {
        _showErrorSnackBar("Failed to send: ${result['message']}");
      }
    } catch (e) {
      print("Error sending message: $e");
      if (mounted) {
        setState(() => sendingMessage = false);
        _showErrorSnackBar("Network error. Please try again.");
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Confirmed':
        return Colors.blue;
      case 'Preparing':
        return Colors.purple;
      case 'Delivered':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final items = order['items'] ?? [];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      height: MediaQuery.of(context).size.height * 0.9,
      child: Column(
        children: [
          _buildDragHandle(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(order),
                  SizedBox(height: 32),
                  _buildOrderSection("Customer Info", [
                    _infoRow(
                      Icons.person_outline,
                      order['customerName'] ?? 'Guest',
                    ),
                    _infoRow(
                      Icons.phone_outlined,
                      order['customerPhone'] ?? '',
                    ),
                    _infoRow(
                      Icons.location_on_outlined,
                      order['deliveryAddress'] ?? '',
                    ),
                  ]),
                  // Add Provider/Owner Info Section
                  if (_getProviderInfo(order)['hasProvider'] == true) ...[
                    SizedBox(height: 24),
                    _buildOrderSection(
                      _getProviderInfo(order)['isHousing']
                          ? "Property Owner"
                          : "Service Provider",
                      [
                        if (_getProviderInfo(order)['name'] != null)
                          _infoRow(
                            Icons.person_outline,
                            _getProviderInfo(order)['name']!,
                          ),
                        if (_getProviderInfo(order)['email'] != null)
                          _infoRow(
                            Icons.email_outlined,
                            _getProviderInfo(order)['email']!,
                          ),
                        if (_getProviderInfo(order)['phone'] != null)
                          _infoRow(
                            Icons.phone_outlined,
                            _getProviderInfo(order)['phone']!,
                          ),
                        if (_getProviderInfo(order)['city'] != null)
                          _infoRow(
                            Icons.location_city_outlined,
                            _getProviderInfo(order)['city']!,
                          ),
                      ],
                    ),
                  ],
                  if (order['pickupDate'] != null ||
                      order['deliveryDate'] != null) ...[
                    SizedBox(height: 24),
                    _buildOrderSection("Schedule (Laundry)", [
                      if (order['pickupDate'] != null)
                        _infoRow(
                          Icons.upload_outlined,
                          "Pickup: ${DateFormat('MMM dd').format(DateTime.parse(order['pickupDate'].toString()))} at ${order['pickupTime'] ?? ''}",
                        ),
                      if (order['deliveryDate'] != null)
                        _infoRow(
                          Icons.download_outlined,
                          "Delivery: ${DateFormat('MMM dd').format(DateTime.parse(order['deliveryDate'].toString()))} at ${order['deliveryTime'] ?? ''}",
                        ),
                    ]),
                  ],
                  SizedBox(height: 24),
                  _buildOrderSection("Order Items", [
                    ...items.map((item) => _itemRow(item)).toList(),
                    Divider(height: 32),
                    _totalRow(
                      "Total Amount",
                      "PKR ${order['totalAmount']?.toStringAsFixed(2)}",
                    ),
                  ]),
                  SizedBox(height: 24),
                  _buildOrderSection("Communication", [
                    _buildMessageList(),
                    _buildMessageInput(),
                  ]),
                ],
              ),
            ),
          ),
          _buildActionButtons(order),
        ],
      ),
    );
  }

  Widget _buildDragHandle() => Center(
    child: Container(
      margin: EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );

  Widget _buildHeader(Map<String, dynamic> order) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Order #${order['_id'].toString().substring(0, 8)}",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Received on ${DateTime.parse(order['createdAt']).toLocal().toString().split(' ')[0]}",
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _getStatusColor(order['status']).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            order['status'] ?? 'Pending',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: _getStatusColor(order['status']),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withOpacity(0.05)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String val) => Padding(
    padding: EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        SizedBox(width: 8),
        Text(val, style: GoogleFonts.inter(fontSize: 14)),
      ],
    ),
  );

  Widget _itemRow(Map<String, dynamic> item) => Padding(
    padding: EdgeInsets.only(bottom: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "${item['quantity']}x ${item['name']}",
          style: GoogleFonts.inter(fontWeight: FontWeight.w500),
        ),
        Text(
          "PKR ${item['price']}",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );

  Widget _totalRow(String label, String val) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      Text(
        val,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFFFF512F),
        ),
      ),
    ],
  );

  Widget _buildMessageList() {
    return messages.isEmpty
        ? Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                "No messages yet",
                style: GoogleFonts.inter(color: Colors.grey),
              ),
            ),
          )
        : ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final m = messages[index];
              final isMe =
                  m['sender'] == 'provider' || m['sender'] == 'serviceProvider';
              return Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isMe ? Color(0xFFFF9D42) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    m['message'] ?? '',
                    style: GoogleFonts.inter(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            },
          );
  }

  Widget _buildMessageInput() {
    return Container(
      margin: EdgeInsets.only(top: 12),
      padding: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: messageController,
              decoration: InputDecoration(
                hintText: "Reply to customer...",
                border: InputBorder.none,
                hintStyle: GoogleFonts.inter(fontSize: 13),
              ),
            ),
          ),
          IconButton(
            icon: sendingMessage
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.send_rounded, color: Color(0xFFFF9D42)),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> order) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.05))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  shape: StadiumBorder(),
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text("Close", style: GoogleFonts.poppins()),
              ),
            ),
            if (order['status'] == 'Pending') ...[
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _updateStatus('Confirmed'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFF9D42),
                    shape: StadiumBorder(),
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text("Accept", style: GoogleFonts.poppins()),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(String status) async {
    try {
      final result = await ApiService.updateOrderStatus(
        widget.order['_id'],
        status,
        "Order accepted",
      );
      if (!mounted) return;

      if (result['success'] == true) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Order confirmed!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _showErrorSnackBar("Failed to update status: ${result['message']}");
      }
    } catch (e) {
      print("Error updating status: $e");
      _showErrorSnackBar("Network error. Pleaae try again.");
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(fontSize: 14)),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(20),
      ),
    );
  }

  Map<String, dynamic> _getProviderInfo(Map<String, dynamic> order) {
    bool isHousing = order['bookingType'] == 'housing';

    if (isHousing) {
      // For housing bookings, extract from populated ownerId
      final owner = order['ownerId'];
      if (owner is Map && owner.isNotEmpty) {
        return {
          'hasProvider': true,
          'isHousing': true,
          'name': '${owner['firstName'] ?? ''} ${owner['lastName'] ?? ''}'
              .trim(),
          'email': owner['email'],
          'phone': owner['phone'],
          'city': owner['city'],
        };
      }
      // Fallback to ownerName if available
      if (order['ownerName'] != null &&
          order['ownerName'].toString().isNotEmpty) {
        return {
          'hasProvider': true,
          'isHousing': true,
          'name': order['ownerName'],
          'email': null,
          'phone': null,
          'city': null,
        };
      }
    } else {
      // For service orders, extract from available provider fields
      String? providerName;
      String? email;
      String? phone;

      if (order['providerName'] != null &&
          order['providerName'].toString().isNotEmpty) {
        providerName = order['providerName'];
      } else if (order['serviceProviderSpId'] is Map &&
          order['serviceProviderSpId'].isNotEmpty) {
        final sp = order['serviceProviderSpId'];
        providerName = '${sp['firstName'] ?? ''} ${sp['lastName'] ?? ''}'
            .trim();
        email = sp['email'];
        phone = sp['phone'];
      } else if (order['serviceProviderId'] is Map &&
          order['serviceProviderId'].isNotEmpty) {
        final sp = order['serviceProviderId'];
        providerName = '${sp['firstName'] ?? ''} ${sp['lastName'] ?? ''}'
            .trim();
        email = sp['email'];
        phone = sp['phone'];
      }

      if (providerName != null && providerName.isNotEmpty) {
        return {
          'hasProvider': true,
          'isHousing': false,
          'name': providerName,
          'email': email,
          'phone': phone,
          'city': null,
        };
      }
    }

    return {'hasProvider': false};
  }
}
