import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:stripe_sdk/stripe_sdk.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'card_details.dart'; // Ajoutez cette importation

class PaymentService {
  static const String stripePublishableKey = 'pk_test_51S5lZdJfUaKmRgioE5ZFHq6Yr14AFzr8Z4jzSKsSgsGlG1s1RDTrDeKSy6mDLIp8ziLwRGReLY5q0IOerEyxs4ow00jezH8hIr';
  static const String stripeSecretKey = 'sk_test_51S5lZdJfUaKmRgiofaRiuJLntzdXvApSCH3PQoH5cywgVVZuxVd9WIkpXg0YYYogndNvcF8A9pxqTR6jbw7A8IrC00Xu2KhN3U';
  static const String stripeApiVersion = '2020-08-27';
  static final Stripe stripe = Stripe.instance;

  static void init() {
    stripe.initialize(publishableKey: stripePublishableKey); // Corrigez "initialise" en "initialize"
  }

  // Créer une intention de paiement pour une enchère
  static Future<Map<String, dynamic>> createPaymentIntent(double amount, String currency, String auctionId, String userId) async {
    try {
      final url = Uri.parse('https://api.stripe.com/v1/payment_intents');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $stripeSecretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'amount': (amount * 100).toStringAsFixed(0), // Convertir en cents
          'currency': currency,
          'metadata': {
            'auction_id': auctionId,
            'user_id': userId,
          },
          'capture_method': 'manual', // Ne pas capturer immédiatement
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erreur lors de la création de l\'intention de paiement: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion à Stripe: $e');
    }
  }

  // Capturer le paiement après la fin de l'enchère
  static Future<void> capturePayment(String paymentIntentId) async {
    try {
      final url = Uri.parse('https://api.stripe.com/v1/payment_intents/$paymentIntentId/capture');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $stripeSecretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Erreur lors de la capture du paiement: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur de capture: $e');
    }
  }

  // Rembourser un paiement
  static Future<void> refundPayment(String paymentIntentId) async {
    try {
      final url = Uri.parse('https://api.stripe.com/v1/refunds');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $stripeSecretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'payment_intent': paymentIntentId,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Erreur lors du remboursement: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur de remboursement: $e');
    }
  }

  // Méthode pour traiter le paiement côté client
  static Future<Map<String, dynamic>> confirmPayment(String clientSecret, CardDetails cardDetails) async {
    try {
      // Pour l'instant, retournez simplement un succès simulé
      // Vous devrez implémenter l'intégration Stripe complète plus tard
      await Future.delayed(const Duration(seconds: 2)); // Simulation de délai

      return {
        'success': true,
        'paymentIntentId': 'pi_${DateTime.now().millisecondsSinceEpoch}'
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}

extension on Stripe {
  void initialize({required String publishableKey}) {}
}