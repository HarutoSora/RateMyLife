import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/ads/ad_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_theme.dart';

/// A compact, tappable pill for the "get coins" entry point — matches
/// `CoinBalancePill`'s size/shape so the two sit naturally side by side
/// in a page header. Opens `GetCoinsScreen` rather than watching an ad
/// directly, since there are now two ways to get coins.
class WatchAdPill extends StatelessWidget {
  const WatchAdPill({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.pillRadius,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppTheme.surfaceHigh,
            borderRadius: AppRadius.pillRadius,
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_circle_rounded, color: AppColors.gold, size: 18),
              SizedBox(width: 6),
              Text('Get Coins', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.gold)),
            ],
          ),
        ),
      ),
    );
  }
}

/// A self-contained banner ad — loads on mount, renders nothing (zero
/// height, no placeholder box) until it's actually loaded, and collapses
/// again if it fails, so a slow/blocked ad network never reserves
/// visible empty space or shifts surrounding layout. Owns its own
/// `BannerAd` lifecycle (load on init, dispose on unmount) rather than
/// going through a repository — purely presentational, never touches
/// `AppController` state, so it doesn't need to be fakeable for tests
/// the way `AdRepository`'s rewarded-ad flow does.
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _ad;

  @override
  void initState() {
    super.initState();
    final ad = BannerAd(
      adUnitId: AdConfig.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _ad = ad as BannerAd);
        },
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    );
    ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (ad == null) return const SizedBox.shrink();
    return Container(
      alignment: Alignment.center,
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}
