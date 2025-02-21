import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

enum PaymentProvider {
  chargebee,
  blink,
  btcpay,
  lemonsqueezy,
  inAppPurchase // Required for Play Store
}

abstract class PaymentProcessor {
  Future<String> createPayment(double amount, String currency);
  Future<bool> verifyPayment(String paymentId);
}

class BlinkLightningProcessor implements PaymentProcessor {
  final String apiKey;
  final String apiEndpoint;

  BlinkLightningProcessor({
    required this.apiKey,
    this.apiEndpoint = 'https://api.blink.sv/v1',
  });

  @override
  Future<String> createPayment(double amount, String currency) async {
    final response = await http.post(
      Uri.parse('$apiEndpoint/invoice'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'amount': (amount * 100).round(), // Convert to sats
        'memo': 'Robinpedia Premium',
        'expiry': 3600, // 1 hour expiry
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['payment_request'];
    }
    throw Exception('Failed to create lightning invoice');
  }

  @override
  Future<bool> verifyPayment(String paymentId) async {
    final response = await http.get(
      Uri.parse('$apiEndpoint/invoice/$paymentId'),
      headers: {'Authorization': 'Bearer $apiKey'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['settled'] == true;
    }
    return false;
  }
}

class ChargebeeProcessor implements PaymentProcessor {
  final String siteApiKey;
  final String site;

  ChargebeeProcessor({
    required this.siteApiKey,
    required this.site,
  });

  @override
  Future<String> createPayment(double amount, String currency) async {
    // Implement Chargebee-specific logic
    // Can be extended to support BTCPay Server integration
    throw UnimplementedError();
  }

  @override
  Future<bool> verifyPayment(String paymentId) async {
    throw UnimplementedError();
  }
}

class PaymentManager {
  static final PaymentManager _instance = PaymentManager._internal();
  factory PaymentManager() => _instance;
  PaymentManager._internal();

  final Map<PaymentProvider, PaymentProcessor> _processors = {};
  PaymentProvider? _preferredProvider;

  void initialize({
    String? blinkApiKey,
    String? chargebeeSite,
    String? chargebeeApiKey,
  }) {
    if (blinkApiKey != null) {
      _processors[PaymentProvider.blink] = BlinkLightningProcessor(
        apiKey: blinkApiKey,
      );
    }

    if (chargebeeSite != null && chargebeeApiKey != null) {
      _processors[PaymentProvider.chargebee] = ChargebeeProcessor(
        siteApiKey: chargebeeApiKey,
        site: chargebeeSite,
      );
    }

    // Default to Blink if available
    _preferredProvider = _processors.containsKey(PaymentProvider.blink)
        ? PaymentProvider.blink
        : _processors.keys.first;
  }

  Future<PaymentResult> processPayment({
    required double amount,
    required String currency,
    PaymentProvider? provider,
  }) async {
    final selectedProvider = provider ?? _preferredProvider;
    if (selectedProvider == null) {
      throw Exception('No payment provider configured');
    }

    final processor = _processors[selectedProvider];
    if (processor == null) {
      throw Exception('Selected payment provider not available');
    }

    try {
      final paymentId = await processor.createPayment(amount, currency);
      return PaymentResult(
        provider: selectedProvider,
        paymentId: paymentId,
        status: PaymentStatus.pending,
      );
    } catch (e) {
      return PaymentResult(
        provider: selectedProvider,
        status: PaymentStatus.failed,
        error: e.toString(),
      );
    }
  }

  Stream<PaymentStatus> monitorPayment(PaymentResult payment) async* {
    final processor = _processors[payment.provider];
    if (processor == null) return;

    while (true) {
      try {
        final isComplete = await processor.verifyPayment(payment.paymentId!);
        if (isComplete) {
          yield PaymentStatus.completed;
          break;
        }
        yield PaymentStatus.pending;
      } catch (e) {
        yield PaymentStatus.failed;
        break;
      }
      await Future.delayed(const Duration(seconds: 2));
    }
  }
}

class PaymentResult {
  final PaymentProvider provider;
  final String? paymentId;
  final PaymentStatus status;
  final String? error;

  PaymentResult({
    required this.provider,
    this.paymentId,
    required this.status,
    this.error,
  });
}

enum PaymentStatus {
  pending,
  completed,
  failed,
}
