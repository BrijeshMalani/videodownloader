import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../Utils/common.dart';

class NativeBannerAdWidget extends StatefulWidget {
  @override
  _NativeBannerAdWidgetState createState() => _NativeBannerAdWidgetState();
}

class _NativeBannerAdWidgetState extends State<NativeBannerAdWidget> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();

    _nativeAd = NativeAd(
      adUnitId: Common.native_ad_id, // Test Native Ad Unit ID
      factoryId: 'banner', // Different factory ID for banner-style native ads
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          print('Banner Native Ad failed to load: $error');
          ad.dispose();
        },
      ),
      request: AdRequest(),
    )..load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isAdLoaded
        ? Container(
            height: 160, // Smaller height for banner-style native ad
            child: AdWidget(ad: _nativeAd!),
          )
        : SizedBox(); // Empty space before ad loads
  }
}
