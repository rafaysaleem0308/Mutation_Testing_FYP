import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hello/core/services/api_service.dart';
import 'package:hello/shared/widgets/review_list_widget.dart';
import 'package:intl/intl.dart';

class MaintenanceProviderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> provider;
  const MaintenanceProviderDetailScreen({super.key, required this.provider});

  @override
  State<MaintenanceProviderDetailScreen> createState() => _MaintenanceProviderDetailScreenState();
}

class _MaintenanceProviderDetailScreenState extends State<MaintenanceProviderDetailScreen> {
  // Provider detail loaded directly from widget.provider

  String get _fullName {
    final f = widget.provider['firstName'];
    final l = widget.provider['lastName'];
    if (f != null && l != null && f.toString().isNotEmpty) {
      return "$f $l";
    }
    return widget.provider['username'] ?? 'Professional';
  }

  @override
  Widget build(BuildContext context) {
    // Determine provider USER ID vs DOCUMENT ID
    // Generally 'provider' passed here is from `getProvidersByType` which returns a mix.
    // However, for Chat and Hire, we often need the User ID.
    // The keys might be 'userId' (string) or '_id' (docId) depending on source.
    // In `MaintenanceScreen`, the provider list usually has user data flattened or populated.
    
    // Check if we have userId specifically (often `userId` or `_id` in provider object)
    // If provider object comes from `getServiceProvidersByType`, `_id` is usually the ServiceProvider Doc ID.
    // `userId` field might be present if populated.
    
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), shape: BoxShape.circle),
          child: const BackButton(color: Colors.black),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), shape: BoxShape.circle),
            child: IconButton(icon: const Icon(Icons.favorite_border, color: Colors.black), onPressed: () {}), // TODO: Implement Favorites
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            _buildProfileInfo(),
            _buildTabs(),
            SizedBox(height: 100), // Spacing for bottom floating container
          ],
        ),
      ),
      bottomSheet: _buildBottomAction(),
    );
  }

  Widget _buildHeader() {
    final verified = widget.provider['isVerified'] == true;
    final rating = (widget.provider['rating'] ?? 0).toStringAsFixed(1);
    
    return Container(
      height: 280,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF11998E),
        gradient: const LinearGradient(colors: [Color(0xFF11998E), Color(0xFF38ef7d)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        image: widget.provider['profileImage'] != null && widget.provider['profileImage'].isNotEmpty
          ? DecorationImage(
              image: NetworkImage(widget.provider['profileImage']), 
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.35), BlendMode.darken),
            )
          : null,
      ),
      child: Stack(
        children: [
          if (widget.provider['profileImage'] == null || widget.provider['profileImage'].isEmpty)
            Center(child: Icon(Icons.engineering, size: 100, color: Colors.white.withValues(alpha: 0.2))),
          
          if (verified)
            Positioned(
              top: 50, right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified, color: Colors.blue, size: 14),
                    const SizedBox(width: 4),
                    Text('Verified', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue)),
                  ],
                ),
              ),
            ),
          Positioned(
            bottom: 40, left: 20, right: 20,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Text(widget.provider['serviceName'] ?? widget.provider['spSubRole'] ?? 'Maintenance Expert', style: GoogleFonts.inter(color: const Color(0xFF38ef7d), fontSize: 13, fontWeight: FontWeight.bold)),
                       const SizedBox(height: 4),
                       Text(_fullName, style: GoogleFonts.poppins(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(rating, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      )
    );
  }

  Widget _buildProfileInfo() {
    return Transform.translate(
      offset: const Offset(0, -25),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _infoCard(Icons.work_outline, "${widget.provider['totalOrders'] ?? '0'}", "Jobs Done", const Color(0xFF11998E)),
                _containerDivider(),
                _infoCard(Icons.calendar_today, "${widget.provider['experienceYears'] ?? 1}+ Yrs", "Experience", Colors.purple),
                _containerDivider(),
                _infoCard(Icons.thumb_up_alt_outlined, "${widget.provider['rating'] ?? 'New'}", "Rating", Colors.amber),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                   const Icon(Icons.location_on_outlined, color: Colors.grey, size: 18),
                   const SizedBox(width: 8),
                   Expanded(
                     child: Text(widget.provider['city'] ?? "Unknown Location", style: GoogleFonts.inter(color: Colors.grey[700])),
                   ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text("Available", style: GoogleFonts.inter(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                    )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _infoCard(IconData icon, String val, String label, Color c) {
    return Column(children: [
      Icon(icon, color: c, size: 24),
      const SizedBox(height: 6),
      Text(val, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
      Text(label, style: GoogleFonts.inter(color: Colors.grey, fontSize: 12)),
    ]);
  }

  Widget _containerDivider() => Container(height: 40, width: 1, color: Colors.grey[200]);

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("About", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text(
            widget.provider['bio'] ?? widget.provider['description'] ?? "No description available.",
            style: GoogleFonts.inter(color: Colors.grey[700], height: 1.5),
          ),
          SizedBox(height: 24),
          
          if (widget.provider['servicesOffered'] != null && (widget.provider['servicesOffered'] as List).isNotEmpty) ...[
            Text("Services", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (widget.provider['servicesOffered'] as List).map((s) => Chip(
                label: Text(s.toString()),
                backgroundColor: const Color(0xFF11998E).withValues(alpha: 0.05),
                labelStyle: GoogleFonts.inter(color: const Color(0xFF11998E), fontWeight: FontWeight.w600),
                side: BorderSide.none,
              )).toList(),
            ),
            SizedBox(height: 24),
          ],

          if (widget.provider['skills'] != null && (widget.provider['skills'] as List).isNotEmpty) ...[
            Text("Skills", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (widget.provider['skills'] as List).map((s) => Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(s.toString(), style: GoogleFonts.inter(color: Colors.black87)),
              )).toList(),
            ),
            SizedBox(height: 24),
          ],

          if (widget.provider['gallery'] != null && (widget.provider['gallery'] as List).isNotEmpty) ...[
             Text("Portfolio", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
             SizedBox(height: 12),
             SizedBox(height: 120, child: ListView.builder(
               scrollDirection: Axis.horizontal,
               itemCount: (widget.provider['gallery'] as List).length,
               itemBuilder: (ctx, i) {
                 final img = widget.provider['gallery'][i];
                 return Container(
                   width: 120,
                   margin: EdgeInsets.only(right: 12),
                   decoration: BoxDecoration(
                     borderRadius: BorderRadius.circular(12),
                     image: DecorationImage(image: NetworkImage(img), fit: BoxFit.cover),
                   ),
                 );
               },
             )),
             SizedBox(height: 24),
          ],
          
          Text("Reviews", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          ReviewListWidget(spId: widget.provider['_id'], themeColor: Color(0xFF11998E)),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _handleChat,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Color(0xFF11998E)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Icon(Icons.chat_bubble_outline, color: Color(0xFF11998E)),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: ElevatedButton(
              onPressed: () => _showHireForm(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF11998E),
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text("Hire Now", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleChat() async {
    final pId = widget.provider['userId'] ?? widget.provider['_id']; // Prefer User ID
    final spId = widget.provider['_id']; // SP Document ID
    
    final result = await ApiService.startChat(pId, spId);
    if (!mounted) return;
    if (result['success'] == true) {
      Navigator.pushNamed(context, '/chat', arguments: {
        'chatId': result['chat']['_id'],
        'otherUserName': _fullName,
        'otherUserImage': widget.provider['profileImage'] ?? "",
        'serviceName': 'Maintenance',
        'receiverId': pId,
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not start chat")));
    }
  }

  void _showHireForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _HireRequestForm(provider: widget.provider),
    );
  }
}

class _HireRequestForm extends StatefulWidget {
  final Map<String, dynamic> provider;
  const _HireRequestForm({required this.provider});

  @override
  State<_HireRequestForm> createState() => __HireRequestFormState();
}

class __HireRequestFormState extends State<_HireRequestForm> {
  final _descController = TextEditingController();
  final _addressController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserAddress();
  }
  
  Future<void> _loadUserAddress() async {
    final u = await ApiService.getUserData();
    if (u.isNotEmpty && u['address'] != null) {
      if (mounted) setState(() { _addressController.text = u['address']; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 25,
            spreadRadius: 2,
            offset: const Offset(0, -5),
          )
        ],
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Hire ${widget.provider['firstName'] ?? 'Professional'}", 
                style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF11998E))
              ),
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
                  child: Icon(Icons.close_rounded, color: Colors.grey[700], size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          Text("What do you need help with?", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: _descController,
            maxLines: 4,
            style: GoogleFonts.inter(fontSize: 14),
            decoration: InputDecoration(
              hintText: "Describe the issue clearly (e.g. Broken AC cooling...)",
              hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.grey[50],
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey[200]!)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF11998E))),
            ),
          ),
          const SizedBox(height: 16),

          Text("Service Location", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: _addressController,
            style: GoogleFonts.inter(fontSize: 14),
            decoration: InputDecoration(
              hintText: "Enter your full address",
              hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.grey[50],
              prefixIcon: const Icon(Icons.location_on_outlined, size: 20, color: Color(0xFF11998E)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey[200]!)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF11998E))),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Select Date", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context, 
                          initialDate: DateTime.now(), 
                          firstDate: DateTime.now(), 
                          lastDate: DateTime.now().add(const Duration(days: 60)),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(primary: Color(0xFF11998E)),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (d != null) setState(() => _selectedDate = d);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.grey[50], 
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!)
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month_rounded, size: 18, color: Color(0xFF11998E)), 
                            const SizedBox(width: 8), 
                            Text(
                              _selectedDate == null ? "Select Date" : DateFormat('MMM dd, yyyy').format(_selectedDate!),
                              style: GoogleFonts.inter(color: _selectedDate == null ? Colors.grey[500] : Colors.black87, fontSize: 14),
                            )
                          ]
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Select Time", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final t = await showTimePicker(
                          context: context, 
                          initialTime: TimeOfDay.now(),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(primary: Color(0xFF11998E)),
                              ),
                              child: child!,
                            );
                          },  
                        );
                        if (t != null) setState(() => _selectedTime = t);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.grey[50], 
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!)
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_rounded, size: 18, color: Color(0xFF11998E)), 
                            const SizedBox(width: 8), 
                            Text(
                              _selectedTime == null ? "Select Time" : _selectedTime!.format(context),
                              style: GoogleFonts.inter(color: _selectedTime == null ? Colors.grey[500] : Colors.black87, fontSize: 14),
                            )
                          ]
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF11998E), 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isLoading 
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)) 
                : Text("Send Request", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5)),
            ),
          )
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_descController.text.trim().isEmpty || _addressController.text.trim().isEmpty || _selectedDate == null || _selectedTime == null) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.warning_rounded, color: Colors.orange, size: 28),
              const SizedBox(width: 8),
              Text("Missing Data", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Text("Please fill in all the required fields including date and time before sending your request.", style: GoogleFonts.inter(fontSize: 14, height: 1.5)),
          actionsPadding: const EdgeInsets.only(right: 16, bottom: 16),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text("Got It", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    final formattedTime = _selectedTime!.format(context);
    setState(() => _isLoading = true);
    final user = await ApiService.getUserData();
    if (user.isEmpty) {
       if (!mounted) return;
       setState(() => _isLoading = false);
       if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please log in")));
       }
       return;
    }

    final req = {
      'serviceProviderId': widget.provider['userId'] ?? widget.provider['_id'],
      'serviceProviderSpId': widget.provider['_id'],
      'userId': user['_id'] ?? user['id'],
      'description': _descController.text,
      'deliveryAddress': _addressController.text,
      'date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
      'time': formattedTime,
      'phone': user['phone'],
    };

    final res = await ApiService.createHireRequest(req);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      showDialog(
        context: context, 
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: const EdgeInsets.all(32),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 60),
              ),
              const SizedBox(height: 24),
              Text("Request Sent", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 22)),
              const SizedBox(height: 8),
              Text(
                "Your hiring request has been sent! The provider will review it shortly.", 
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.grey[600], height: 1.5, fontSize: 14)
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close Success dialog
                    Navigator.pop(context); // Close Form Bottom sheet
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF11998E),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text("Done", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      );
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: ${res['message']}")));
      }
    }
  }
}
