import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  bool _initialized = false;

  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;

  RewardedAd? _rewardedAd;
  bool _isRewardedLoading = false;

  // Test ad unit IDs from Google AdMob.
  static const String _testBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialId = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testRewardedId = 'ca-app-pub-3940256099942544/5224354917';

  // Production ad unit IDs.
  static const String _prodBannerId = 'ca-app-pub-1137151357132919/2420750983';
  static const String _prodInterstitialId = 'ca-app-pub-1137151357132919/6168424303';
  static const String _prodRewardedId = 'ca-app-pub-1137151357132919/9916097628';

  String get _bannerId => kDebugMode ? _testBannerId : _prodBannerId;
  String get _interstitialId => kDebugMode ? _testInterstitialId : _prodInterstitialId;
  String get _rewardedId => kDebugMode ? _testRewardedId : _prodRewardedId;

  Future<void> init() async {
    if (_initialized) return;
    await MobileAds.instance.initialize();
    _initialized = true;
    _loadInterstitial();
    _loadRewarded();
  }

  // --------------------------------------------------------------------------
  // Banner
  // --------------------------------------------------------------------------
  BannerAd? createBannerAd() {
    if (!_initialized) return null;
    final banner = BannerAd(
      adUnitId: _bannerId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner failed to load: $error');
          ad.dispose();
        },
      ),
    );
    banner.load();
    return banner;
  }

  // --------------------------------------------------------------------------
  // Interstitial
  // --------------------------------------------------------------------------
  void _loadInterstitial() {
    if (_isInterstitialLoading || !_initialized) return;
    _isInterstitialLoading = true;

    InterstitialAd.load(
      adUnitId: _interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              _loadInterstitial();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitialAd = null;
              _loadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial failed to load: $error');
          _interstitialAd = null;
          _isInterstitialLoading = false;
        },
      ),
    );
  }

  Future<void> showInterstitial() async {
    if (_interstitialAd != null) {
      await _interstitialAd!.show();
    } else {
      _loadInterstitial();
    }
  }

  // --------------------------------------------------------------------------
  // Rewarded
  // --------------------------------------------------------------------------
  void _loadRewarded() {
    if (_isRewardedLoading || !_initialized) return;
    _isRewardedLoading = true;

    RewardedAd.load(
      adUnitId: _rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedLoading = false;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewardedAd = null;
              _loadRewarded();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _rewardedAd = null;
              _loadRewarded();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded failed to load: $error');
          _rewardedAd = null;
          _isRewardedLoading = false;
        },
      ),
    );
  }

  Future<void> showRewarded({
    required VoidCallback onRewarded,
    required VoidCallback onDismissed,
  }) async {
    if (_rewardedAd != null) {
      await _rewardedAd!.show(
        onUserEarnedReward: (_, rewardItem) {
          onRewarded();
        },
      );
      onDismissed();
    } else {
      _loadRewarded();
      onDismissed();
    }
  }

  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }
}
