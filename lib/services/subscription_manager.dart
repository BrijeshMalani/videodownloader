import 'dart:async';
import 'dart:io';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionManager {
  static final SubscriptionManager _instance = SubscriptionManager._internal();
  factory SubscriptionManager() => _instance;
  SubscriptionManager._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  // Your subscription product ID from Google Play Console
  static const String _subscriptionId = 'weekly_premium_subscription';

  bool _isSubscribed = false;
  bool get isSubscribed => _isSubscribed;

  // Stream controller to notify listeners about subscription status changes
  final StreamController<bool> _subscriptionStatusController =
      StreamController<bool>.broadcast();
  Stream<bool> get subscriptionStatusStream =>
      _subscriptionStatusController.stream;

  Future<void> initialize() async {
    // Check if in-app purchase is available
    final bool available = await _inAppPurchase.isAvailable();
    if (!available) {
      print('In-app purchase not available');
      return;
    }

    // Enable pending purchases for Android
    if (Platform.isAndroid) {
      final InAppPurchaseAndroidPlatformAddition androidAddition =
          _inAppPurchase
              .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      // Note: enablePendingPurchases is automatically handled in newer versions
    }

    // Listen to purchase updates
    _subscription = _inAppPurchase.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription.cancel(),
      onError: (error) => print('Purchase stream error: $error'),
    );

    // Check existing subscription status
    await _checkSubscriptionStatus();
  }

  Future<void> _checkSubscriptionStatus() async {
    try {
      // Check local storage first
      final prefs = await SharedPreferences.getInstance();
      _isSubscribed = prefs.getBool('is_subscribed') ?? false;

      // Restore purchases to verify current status
      await _inAppPurchase.restorePurchases();

      _subscriptionStatusController.add(_isSubscribed);
    } catch (e) {
      print('Error checking subscription status: $e');
    }
  }

  Future<ProductDetails?> getProductDetails() async {
    try {
      final ProductDetailsResponse response = await _inAppPurchase
          .queryProductDetails({_subscriptionId});

      if (response.notFoundIDs.isNotEmpty) {
        print('Product not found: ${response.notFoundIDs}');
        return null;
      }

      if (response.productDetails.isEmpty) {
        return null;
      }

      return response.productDetails.first;
    } catch (e) {
      print('Error getting product details: $e');
      return null;
    }
  }

  Future<void> purchaseSubscription() async {
    try {
      // Get product details
      final ProductDetails? productDetails = await getProductDetails();

      if (productDetails == null) {
        throw Exception('Subscription product not found');
      }

      // Create purchase param
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: productDetails,
      );

      // Start the purchase
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      print('Error purchasing subscription: $e');
      rethrow;
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      await _handlePurchase(purchaseDetails);
    }
  }

  Future<void> _handlePurchase(PurchaseDetails purchaseDetails) async {
    if (purchaseDetails.status == PurchaseStatus.purchased) {
      // Verify the purchase (you should implement server-side verification in production)
      await _verifyPurchase(purchaseDetails);

      // Update subscription status
      await _updateSubscriptionStatus(true);
    } else if (purchaseDetails.status == PurchaseStatus.error) {
      print('Purchase error: ${purchaseDetails.error}');
    } else if (purchaseDetails.status == PurchaseStatus.restored) {
      // Handle restored purchase
      if (purchaseDetails.productID == _subscriptionId) {
        await _updateSubscriptionStatus(true);
      }
    }

    // Complete the purchase
    if (purchaseDetails.pendingCompletePurchase) {
      await _inAppPurchase.completePurchase(purchaseDetails);
    }
  }

  Future<void> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    // In production, you should verify the purchase with your server
    // For now, we'll just check if it's the correct product
    if (purchaseDetails.productID == _subscriptionId) {
      print('Purchase verified successfully');
      return;
    }
    throw Exception('Purchase verification failed');
  }

  Future<void> _updateSubscriptionStatus(bool isSubscribed) async {
    _isSubscribed = isSubscribed;

    // Save to local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_subscribed', isSubscribed);

    // Notify listeners
    _subscriptionStatusController.add(isSubscribed);

    print('Subscription status updated: $isSubscribed');
  }

  Future<void> restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      print('Error restoring purchases: $e');
      rethrow;
    }
  }

  // Method to manually check and update subscription status
  Future<bool> checkSubscriptionValidity() async {
    try {
      // In a real app, you would check with your server or Google Play Billing
      // For now, we'll check local storage and restore purchases
      await _inAppPurchase.restorePurchases();
      return _isSubscribed;
    } catch (e) {
      print('Error checking subscription validity: $e');
      return false;
    }
  }

  void dispose() {
    _subscription.cancel();
    _subscriptionStatusController.close();
  }
}
