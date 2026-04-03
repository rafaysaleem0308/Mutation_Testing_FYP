import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:hello/core/services/api_service.dart';

/// ─── Stripe Payment Service ─────────────────────────────────────────────────
/// Handles all Stripe payment sheet operations for IndieLife.
/// The SECRET KEY is NEVER in this file. Only the Publishable Key is used here.
class StripePaymentService {
  // Stripe is initialized synchronously in main.dart

  // ─── Create PaymentIntent via Backend ─────────────────────────────────────
  static Future<Map<String, dynamic>> _createPaymentIntent({
    required String bookingId,
    required String serviceType,
  }) async {
    try {
      final token = await ApiService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'You are not logged in'};
      }

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/payments/create-payment-intent'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'bookingId': bookingId,
          'serviceType': serviceType,
        }),
      ).timeout(const Duration(seconds: 30));

      final data = json.decode(response.body);
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ─── Confirm Payment via Backend ───────────────────────────────────────────
  static Future<Map<String, dynamic>> _confirmPaymentWithBackend(
      String paymentIntentId) async {
    try {
      final token = await ApiService.getToken();
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/payments/confirm'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'stripePaymentIntentId': paymentIntentId}),
      ).timeout(const Duration(seconds: 30));

      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Confirmation error: $e'};
    }
  }

  // ─── MAIN: Present Payment Sheet ───────────────────────────────────────────
  /// Full payment flow:
  /// 1. Create PaymentIntent on backend (gets server-calculated amount)
  /// 2. Initialize Stripe Payment Sheet
  /// 3. Present Payment Sheet to user
  /// 4. On success: confirm with backend (verify with Stripe API)
  ///
  /// Returns: {'success': true/false, 'message': '...', 'payment': {...}}
  static Future<Map<String, dynamic>> processPayment({
    required BuildContext context,
    required String bookingId,
    required String serviceType,
    required double displayAmount, // Only for UI display — backend recalculates
    String? customerName,
    String? customerEmail,
  }) async {
    // Note: Stripe is initialized in main.dart


    // Step 1: Create PaymentIntent on backend
    final intentResult = await _createPaymentIntent(
      bookingId: bookingId,
      serviceType: serviceType,
    );

    if (intentResult['success'] != true) {
      return {
        'success': false,
        'message': intentResult['message'] ?? 'Failed to create payment',
      };
    }

    final clientSecret = intentResult['clientSecret'] as String?;
    if (clientSecret == null) {
      return {'success': false, 'message': 'Invalid payment session'};
    }

    // Step 2: Initialize Payment Sheet
    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'IndieLife',
          style: ThemeMode.light, // Forced Light mode to bypass MIUI Dark Mode unclickable bug
        ),
      );
    } catch (e) {
      return {
        'success': false,
        'message': 'Payment setup failed: $e',
      };
    }

    // Step 3: Present Payment Sheet
    try {
      await Stripe.instance.presentPaymentSheet();
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        return {'success': false, 'canceled': true, 'message': 'Payment cancelled'};
      }
      return {
        'success': false,
        'message': e.error.localizedMessage ?? 'Payment failed',
      };
    } catch (e) {
      return {'success': false, 'message': 'Unexpected error: $e'};
    }

    // Step 4: Payment sheet succeeded — confirm with backend
    // Extract paymentIntentId from clientSecret (format: pi_xxx_secret_xxx)
    final paymentIntentId = clientSecret.split('_secret_')[0];
    final confirmResult = await _confirmPaymentWithBackend(paymentIntentId);

    if (confirmResult['success'] == true) {
      return {
        'success': true,
        'message': 'Payment successful!',
        'payment': confirmResult['payment'],
        'amount': intentResult['amount'],
        'commission': intentResult['commission'],
      };
    } else {
      // Payment went through Stripe but backend confirmation had an issue
      // This is handled by webhook as a safety net
      return {
        'success': true, // Still show success — webhook will confirm
        'message': 'Payment received. Confirmation pending.',
        'warning': confirmResult['message'],
      };
    }
  }
}
