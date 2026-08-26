import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/purchases/purchase_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/models.dart';
import '../../domain/services/reward_service.dart';
import '../state/app_state.dart';
import '../widgets/brand_widgets.dart';
import '../widgets/fx_widgets.dart';
import '../widgets/widgets.dart';

class _CoinPackage {
  const _CoinPackage({required this.productId, required this.coins, required this.previewPrice, this.badge});

  final String productId;
  final int coins;

  /// Shown until the real product exists in Play Console and
  /// `AppController.purchaseProducts` has a matching, store-priced
  /// entry — see `PurchaseConfig`'s doc comment.
  final String previewPrice;
  final String? badge;
}

const _coinPackages = [
  _CoinPackage(productId: PurchaseConfig.coins500, coins: 500, previewPrice: r'$0.99'),
  _CoinPackage(productId: PurchaseConfig.coins1200, coins: 1200, previewPrice: r'$1.99'),
  _CoinPackage(
      productId: PurchaseConfig.coins2500, coins: 2500, previewPrice: r'$3.99', badge: 'BEST VALUE'),
  _CoinPackage(
      productId: PurchaseConfig.coins6000, coins: 6000, previewPrice: r'$7.99', badge: 'MEGA PACK'),
  _CoinPackage(
      productId: PurchaseConfig.coins15000, coins: 15000, previewPrice: r'$14.99', badge: 'ULTIMATE PACK'),
];

/// "Buy Coins — Boost your game!" — a dedicated screen (not a squeezed
/// dialog) for the two ways to get more coins, styled after a
/// user-supplied reference mockup (neon title, glowing hero badge,
/// bordered package rows with rarity tags) using this app's existing
/// brand tokens rather than new hand-rolled colors.
class GetCoinsScreen extends ConsumerWidget {
  // Deliberately not `const` — this key must be created once per real
  // screen instance (not shared via const-instance canonicalization), so
  // `_AdRewardSheet`'s flying-coin animation always lands on this
  // specific screen's own balance pill, not a stale one from an
  // unrelated route.
  GetCoinsScreen({super.key});

  final _coinBalanceKey = GlobalKey();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final controller = ref.read(appControllerProvider);
    final storePrices = {for (final p in state.purchaseProducts) p.id: p.price};
    return Scaffold(
      appBar: AppBar(
        title: const Text('Get Coins'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: CoinBalancePill(key: _coinBalanceKey, balance: state.wallet.balance),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Center(
            child: Column(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => AppColors.goldGradient.createShader(bounds),
                  child: Text(
                    'BUY COINS',
                    textAlign: TextAlign.center,
                    style: AppTypography.hero.copyWith(fontSize: 42, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Boost your game!',
                  style: AppTypography.title.copyWith(color: AppColors.blue),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Center(
            child: NeonIconBadge(
              icon: Icons.savings_rounded,
              accent: AppColors.gold,
              size: 120,
              circular: true,
            ),
          ),
          const SizedBox(height: 28),
          _WatchAdRow(
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => _AdRewardSheet(coinBalanceKey: _coinBalanceKey),
            ),
          ),
          const SizedBox(height: 20),
          for (final package in _coinPackages)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CoinPackageRow(
                package: package,
                storePrice: storePrices[package.productId],
                onTap: () => controller.purchaseCoins(package.productId),
              ),
            ),
        ],
      ),
    );
  }
}

/// The free option, visually distinct from (and above) the paid
/// packages below it — a "FREE" tag instead of a price, gold border to
/// match the coin theme rather than the packages' blue/purple ones.
class _WatchAdRow extends StatelessWidget {
  const _WatchAdRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.lgRadius,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceHigh,
            borderRadius: AppRadius.lgRadius,
            border: Border.all(color: AppColors.gold, width: 1.5),
            boxShadow: [
              BoxShadow(color: AppColors.gold.withValues(alpha: 0.35), blurRadius: 16, spreadRadius: 1),
            ],
          ),
          child: Row(
            children: [
              const NeonIconBadge(icon: Icons.play_circle_fill_rounded, accent: AppColors.gold, size: 44),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Watch Ad', style: AppTypography.heading),
                    const SizedBox(height: 2),
                    Text('+${RewardService.coinRewards[XpReason.adWatched]} Coins',
                        style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: AppRadius.pillRadius,
                  border: Border.all(color: AppColors.green),
                ),
                child: const Text('FREE', style: TextStyle(color: AppColors.green, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _AdRewardPhase { idle, loading, success, failed }

/// The "🎁 GET FREE COINS" bottom sheet — a dedicated reward moment
/// rather than launching the ad the instant the pill is tapped. Only
/// ever shows the reward as claimed once `AppController.watchRewardedAd`
/// actually reports the rewarded-ad SDK's completion callback fired
/// (see that method's doc comment) — never a fake/optimistic grant.
class _AdRewardSheet extends ConsumerStatefulWidget {
  const _AdRewardSheet({required this.coinBalanceKey});

  /// The Get Coins app bar's real balance pill — the flying-coin
  /// animation's landing target once the reward is claimed.
  final GlobalKey coinBalanceKey;

  @override
  ConsumerState<_AdRewardSheet> createState() => _AdRewardSheetState();
}

class _AdRewardSheetState extends ConsumerState<_AdRewardSheet> {
  _AdRewardPhase _phase = _AdRewardPhase.idle;
  final _rewardIconKey = GlobalKey();

  int get _reward => RewardService.coinRewards[XpReason.adWatched] ?? 0;

  Future<void> _watch() async {
    setState(() => _phase = _AdRewardPhase.loading);
    final earned = await ref.read(appControllerProvider).watchRewardedAd();
    if (!mounted) return;
    if (earned) {
      HapticFeedback.mediumImpact();
      playSfx(AppSfx.adRewardClaimed);
    }
    setState(() => _phase = earned ? _AdRewardPhase.success : _AdRewardPhase.failed);
    if (earned) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        flyCoinsToBalance(context, fromKey: _rewardIconKey, toKey: widget.coinBalanceKey);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            switch (_phase) {
              _AdRewardPhase.success => _successContent(),
              _AdRewardPhase.failed => _failedContent(),
              _AdRewardPhase.idle || _AdRewardPhase.loading => _offerContent(),
            },
          ],
        ),
      ),
    );
  }

  Widget _offerContent() {
    final loading = _phase == _AdRewardPhase.loading;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('🎁 GET FREE COINS',
            style: AppTypography.eyebrow.copyWith(color: AppColors.gold, fontSize: 14)),
        const SizedBox(height: 16),
        Stack(
          alignment: Alignment.center,
          children: [
            const NeonIconBadge(icon: Icons.monetization_on_rounded, accent: AppColors.gold, size: 96, circular: true),
            if (loading)
              const SizedBox(
                width: 96,
                height: 96,
                child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.gold),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Text('Watch a short video and receive:', style: AppTypography.bodyMuted, textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text('+$_reward',
            style: AppTypography.hero.copyWith(fontSize: 40, color: AppColors.gold)),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: GradientButton(
            label: loading ? 'Loading...' : 'Watch Ad',
            icon: loading ? null : Icons.play_arrow_rounded,
            gradient: AppColors.goldGradient,
            foregroundColor: Colors.black,
            onPressed: loading ? null : _watch,
          ),
        ),
      ],
    );
  }

  Widget _successContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            const BurstFx(colors: [AppColors.gold, Colors.white], particleCount: 24, radius: 100, duration: Duration(milliseconds: 900)),
            NeonIconBadge(
                key: _rewardIconKey,
                icon: Icons.celebration_rounded,
                accent: AppColors.gold,
                size: 96,
                circular: true),
          ],
        ),
        const SizedBox(height: 14),
        Text('🎉 REWARD CLAIMED!',
            style: AppTypography.title.copyWith(color: AppColors.gold)),
        const SizedBox(height: 6),
        AnimatedCountUp(
          value: _reward.toDouble(),
          prefix: '+',
          style: AppTypography.hero.copyWith(fontSize: 40, color: AppColors.gold),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: GradientButton(
            label: 'Nice!',
            gradient: AppColors.purpleGradient,
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ],
    );
  }

  Widget _failedContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const NeonIconBadge(icon: Icons.videocam_off_rounded, accent: AppColors.textMuted, size: 80, circular: true),
        const SizedBox(height: 14),
        Text('No reward this time', style: AppTypography.heading),
        const SizedBox(height: 6),
        Text(
          'The ad wasn\'t available or wasn\'t watched to the end. No coins were charged either way — try again in a bit.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMuted,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GradientButton(
                label: 'Try Again',
                gradient: AppColors.goldGradient,
                foregroundColor: Colors.black,
                onPressed: _watch,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// One purchasable coin package — coin count on the left, an optional
/// rarity/value tag (pink-bordered, matching the reference mockup), and
/// a green-bordered price pill on the right, all inside a card bordered
/// in the app's purple/blue brand tones.
class _CoinPackageRow extends StatelessWidget {
  const _CoinPackageRow({required this.package, required this.storePrice, required this.onTap});

  final _CoinPackage package;

  /// The real, localized store price once this product exists in Play
  /// Console and `AppController` was able to query it — falls back to
  /// `package.previewPrice` until then.
  final String? storePrice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.lgRadius,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceHigh,
            borderRadius: AppRadius.lgRadius,
            border: Border.all(color: AppColors.purple.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              const NeonIconBadge(icon: Icons.monetization_on_rounded, accent: AppColors.gold, size: 40, circular: true),
              const SizedBox(width: 14),
              Expanded(
                child: Row(
                  children: [
                    Text('${_formatCoins(package.coins)} COINS', style: AppTypography.heading),
                    if (package.badge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: AppRadius.pillRadius,
                          border: Border.all(color: AppColors.pink),
                        ),
                        child: Text(
                          package.badge!,
                          style: const TextStyle(color: AppColors.pink, fontWeight: FontWeight.w800, fontSize: 10),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: AppRadius.pillRadius,
                  border: Border.all(color: AppColors.green),
                ),
                child: Text(storePrice ?? package.previewPrice,
                    style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatCoins(int coins) {
    final digits = coins.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}
