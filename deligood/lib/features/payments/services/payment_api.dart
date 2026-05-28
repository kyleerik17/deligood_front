import 'dart:convert';

import 'package:deligood/core/network/api.dart';
import 'package:http/http.dart' as http;

class PaymentException implements Exception {
  final String message;
  const PaymentException(this.message);

  @override
  String toString() => message;
}

class PaymentSession {
  final String id;
  final String redirectUrl;
  final String status;

  const PaymentSession({
    required this.id,
    required this.redirectUrl,
    required this.status,
  });

  factory PaymentSession.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'] ?? json;
    final data = rawData is Map<String, dynamic>
        ? rawData
        : Map<String, dynamic>.from(rawData as Map);

    return PaymentSession(
      id: data['id']?.toString() ?? '',
      redirectUrl:
          data['redirect_url']?.toString() ??
          data['payment_url']?.toString() ??
          data['checkout_url']?.toString() ??
          '',
      status: data['status']?.toString() ?? 'pending',
    );
  }
}

class PaymentApi {
  static String normalizePhone(String value, {String countryPrefix = '+225'}) {
    final prefixDigits = countryPrefix.replaceAll(RegExp(r'[^0-9]'), '');
    var local = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (local.startsWith(prefixDigits)) {
      local = local.substring(prefixDigits.length);
    }
    if (local.length > 10) {
      local = local.substring(local.length - 10);
    }
    if (local.length < 8) {
      throw const PaymentException("Numero invalide");
    }

    return "$countryPrefix$local";
  }

  static Future<PaymentSession> createPayment({
    required int orderId,
    required String paymentMethod,
    required double amount,
    required String phoneNumber,
    String? successUrl,
    String? errorUrl,
  }) async {
    final payload = {
      "order_id": orderId,
      "payment_method": paymentMethod,
      "amount": amount.round(),
      "phone_number": phoneNumber,
      if (successUrl != null) "success_url": successUrl,
      if (errorUrl != null) "error_url": errorUrl,
    };

    if (Api.paymentBaseUrl == Api.baseUrl) {
      final data = await Api.post(Api.paymentCreateEndpoint, body: payload);
      if (data is Map<String, dynamic>) {
        return PaymentSession.fromJson(data);
      }
      throw const PaymentException("Reponse paiement invalide");
    }

    final res = await http
        .post(
          Api.paymentUri(Api.paymentCreateEndpoint),
          headers: Api.paymentHeaders(),
          body: jsonEncode(payload),
        )
        .timeout(Api.timeout);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw PaymentException(_paymentErrorMessage(res));
    }

    try {
      return PaymentSession.fromJson(jsonDecode(res.body));
    } on FormatException {
      throw const PaymentException("Reponse paiement invalide");
    } catch (error) {
      throw PaymentException(error.toString());
    }
  }

  static String _paymentErrorMessage(http.Response response) {
    if (response.body.isEmpty || response.body.trimLeft().startsWith('<')) {
      return "Erreur paiement (${response.statusCode})";
    }

    try {
      final data = jsonDecode(response.body);
      if (data is Map) {
        return (data['detail'] ?? data['message'] ?? data['error'] ?? data)
            .toString();
      }
      return data.toString();
    } catch (_) {
      return response.body;
    }
  }
}
