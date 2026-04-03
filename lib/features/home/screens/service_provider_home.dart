import 'package:flutter/material.dart';
import 'package:hello/core/services/api_service.dart';
import 'package:hello/core/services/chat_service.dart';
import 'package:hello/features/home/screens/meal_provider_home.dart';
import 'package:hello/features/home/screens/laundry_provider_home.dart';
import 'package:hello/features/home/screens/hostel_provider_home.dart';
import 'package:hello/features/home/screens/maintenance_provider_home.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ServiceProviderHome extends StatefulWidget {
  const ServiceProviderHome({super.key});

  @override
  _ServiceProviderHomeState createState() => _ServiceProviderHomeState();
}

class _ServiceProviderHomeState extends State<ServiceProviderHome> {
  bool _isLoading = true;
  String _subRole = '';

  @override
  void initState() {
    super.initState();
    ChatService.init(); // Initialize socket connection early
    _determineDashboard();
  }

  Future<void> _determineDashboard() async {
    try {
      // 1. Get cached or fresh user data
      Map<String, dynamic>? userData = await ApiService.getUserData();
      
      // 2. If subRole is missing, try to fetch fresh
      if (userData['spSubRole'] == null || userData['spSubRole'] == '') {
        print("🔄 spSubRole missing in cache, fetching fresh...");
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('user_data');
        userData = await ApiService.getUserData();
      }

      if (mounted) {
        setState(() {
          _subRole = userData?['spSubRole']?.toString() ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error determining dashboard: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Colors.orange)),
      );
    }

    // Dispatch to correct dashboard
    if (_subRole.toLowerCase().contains("meal")) {
      return MealProviderHome();
    } else if (_subRole.toLowerCase().contains("laundry")) {
      return LaundryProviderHome();
    } else if (_subRole.toLowerCase().contains("hostel") || 
               _subRole.toLowerCase().contains("accommodation") ||
               _subRole.toLowerCase().contains("housing") || 
               _subRole.toLowerCase().contains("flat")) {
      return HostelProviderHome();
    } else if (_subRole.toLowerCase().contains("maintenance")) {
      return MaintenanceProviderHome();
    }

    // Fallback if role is unknown or generic (Default to Meal for safety or show error)
    // For now, let's default to Meal but print log
    print("⚠️ Unknown subRole: $_subRole - Defaulting to MealProviderHome");
    return MealProviderHome();
  }
}
