import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:videodownloader/ui/home_screen.dart';
import '../services/ad_manager.dart';
import '../services/subscription_manager.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _isLoading = false;
  bool _isPriceLoading = true;
  String _priceText = "Loading...";
  String _currencyCode = "INR";

  @override
  void initState() {
    super.initState();
    // Initialize subscription manager
    SubscriptionManager().initialize();
    // Fetch product price
    _fetchProductPrice();
  }

  Future<void> _fetchProductPrice() async {
    try {
      final productDetails = await SubscriptionManager().getProductDetails();
      if (productDetails != null && mounted) {
        setState(() {
          _priceText = "${productDetails.price}/week after FREE 3-Days trial";
          _currencyCode = productDetails.currencyCode;
          _isPriceLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _priceText = "₹600.00/week after FREE 3-Days trial"; // Fallback
          _isPriceLoading = false;
        });
      }
    }
  }

  Future<void> _handlePurchase() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await SubscriptionManager().purchaseSubscription();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription activated successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to home
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Close button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              onPressed: () {
                                AdManager().showInterstitialAd();
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => HomeScreen(),
                                  ),
                                );
                              },
                              icon: Icon(Icons.close),
                              iconSize: 30,
                              color: Colors.black,
                            ),
                          ],
                        ),

                        // Best Offer Badge
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.red, Colors.orange],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star,
                                  color: Colors.yellow,
                                  size: 20,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  "Best Offer",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 5),

                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Start Today With 3-Days Free",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),

                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Unlock VIP Features & Enjoy Unlimited Access",
                            style: TextStyle(fontSize: 16, color: Colors.black),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        SizedBox(height: 20),

                        // Feature Comparison Table
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 5,
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Header
                              Container(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Row(
                                  children: [
                                    Expanded(flex: 3, child: Container()),
                                    Expanded(
                                      child: Text(
                                        "FREE",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          "PREMIUM",
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                  ],
                                ),
                              ),

                              // Feature rows
                              _buildFeatureRow(
                                Icons.video_library,
                                "Browse Videos",
                                true,
                                true,
                              ),
                              _buildFeatureRow(
                                Icons.speed,
                                "4X Faster Speed",
                                false,
                                true,
                              ),
                              _buildFeatureRow(
                                Icons.download,
                                "Unlimited Downloading",
                                false,
                                true,
                              ),
                              _buildFeatureRow(
                                Icons.cast,
                                "Cast Videos To TV",
                                false,
                                true,
                              ),
                              _buildFeatureRow(
                                Icons.block,
                                "Ad-Free Experience",
                                false,
                                true,
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 20),

                        // No Payment Required Text
                        Text(
                          "No Payment Required Now",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        SizedBox(height: 10),

                        // Start Free Trial Button
                        Container(
                          width: double.infinity,
                          height: 50,
                          margin: EdgeInsets.symmetric(horizontal: 16),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 2,
                            ),
                            onPressed: (_isLoading || _isPriceLoading)
                                ? null
                                : _handlePurchase,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'START FREE TRIAL',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),

                        SizedBox(height: 12),

                        // Pricing Text
                        _isPriceLoading
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Loading price...",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                _priceText,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),

                        SizedBox(height: 8),
                      ],
                    ),
                  ),
                  // Terms and Conditions
                  Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                        children: [
                          TextSpan(text: "By continuing, you agree to our "),
                          TextSpan(
                            text: "Terms",
                            style: TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          TextSpan(text: " and "),
                          TextSpan(
                            text: "Privacy",
                            style: TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          TextSpan(
                            text:
                                " policies.\nSubscription is billed after the trial ends and auto-renews. You can cancel it anytime before the trial ends to avoid charges.",
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(
    IconData icon,
    String title,
    bool freeEnabled,
    bool premiumEnabled,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.red, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          Container(
            width: 65,
            child: Icon(
              freeEnabled ? Icons.check : Icons.remove,
              color: freeEnabled ? Colors.green : Colors.grey,
              size: 20,
            ),
          ),
          Container(
            width: 65,
            child: Icon(
              premiumEnabled ? Icons.check : Icons.remove,
              color: premiumEnabled ? Colors.red : Colors.grey,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
