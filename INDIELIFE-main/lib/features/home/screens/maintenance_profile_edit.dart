import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hello/core/services/api_service.dart';
// import 'package:image_picker/image_picker.dart'; // Assuming image_picker is available or use existing utility

class MaintenanceProfileEditScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const MaintenanceProfileEditScreen({super.key, required this.userData});

  @override
  _MaintenanceProfileEditScreenState createState() => _MaintenanceProfileEditScreenState();
}

class _MaintenanceProfileEditScreenState extends State<MaintenanceProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _bioController;
  late TextEditingController _skillsController;
  late TextEditingController _servicesController;
  late TextEditingController _experienceController;
  late TextEditingController _serviceNameController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _bioController = TextEditingController(text: widget.userData['bio'] ?? widget.userData['description'] ?? '');
    _skillsController = TextEditingController(text: (widget.userData['skills'] as List?)?.join(', ') ?? '');
    _servicesController = TextEditingController(text: (widget.userData['servicesOffered'] as List?)?.join(', ') ?? '');
    _experienceController = TextEditingController(text: widget.userData['experienceYears']?.toString() ?? '0');
    _serviceNameController = TextEditingController(text: widget.userData['serviceName'] ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Service Profile", style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(color: Colors.black),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: Text("Save", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF43cea2))),
          )
        ],
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: Color(0xFF43cea2)))
        : SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle("Professional Info"),
                  SizedBox(height: 16),
                  _buildTextField("Service Name / Title", "e.g. Expert Electrician", _serviceNameController),
                  SizedBox(height: 16),
                  _buildTextField("Experience (Years)", "e.g. 5", _experienceController, isNumber: true),
                  SizedBox(height: 16),
                  _buildTextField("Bio / Description", "Tell customers about your expertise...", _bioController, maxLines: 4),
                  
                  SizedBox(height: 32),
                  _sectionTitle("Skills & Services"),
                  Text("Separate with commas", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                  SizedBox(height: 16),
                  _buildTextField("Skills", "e.g. Wiring, Installation, Repair", _skillsController),
                  SizedBox(height: 16),
                  _buildTextField("Services Offered", "e.g. AC Repair, Fan Installation", _servicesController),
                  
                  // TODO: Add Portfolio Image Upload here
                ],
              ),
            ),
          ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87));
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, {bool isNumber = false, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.black87)),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Color(0xFF43cea2))),
          ),
          validator: (val) => val == null || val.isEmpty ? "Required" : null,
        ),
      ],
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    final skills = _skillsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final services = _servicesController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    
    final Map<String, dynamic> updateData = {
      'serviceName': _serviceNameController.text,
      'bio': _bioController.text,
      'description': _bioController.text, // Sync description
      'experienceYears': int.tryParse(_experienceController.text) ?? 0,
      'skills': skills,
      'servicesOffered': services,
    };
    
    try {
      // We assume an endpoint /api/service-provider/update-profile exists or we use user update
      // Based on previous code, ServiceProvider model is updated. 
      // We often use ApiService.updateUserProfile or similar. 
      // If not specific sp update, user update might handle it if it merges.
      // However, usually we update the SP document. 
      
      final userId = widget.userData['userId'] ?? widget.userData['_id'] ?? widget.userData['id'];
      final role = widget.userData['role'] ?? 'service_provider';

      final result = await ApiService.updateProfile(userId, updateData, role);
      
      if (result['success'] == true) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Profile updated successfully")));
           Navigator.pop(context, true);
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: ${result['message']}")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
