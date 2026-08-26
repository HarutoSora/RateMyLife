import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/services/level_service.dart';

/// A row of 5 gold stars (filled/half/empty) rendering a 0-5 rating value.
/// Use this instead of a bare number wherever a community rating is shown.
class StarRating extends StatelessWidget {
  const StarRating({
    super.key,
    required this.value,
    this.size = 16,
    this.showValue = false,
    this.color = AppColors.gold,
  });

  /// Rating on a 0-5 scale.
  final double value;
  final double size;

  /// Appends the numeric value (e.g. "3.8") after the stars, for detail
  /// screens where precision matters more than a clean face.
  final bool showValue;

  /// Star color — override when the row sits on a gold/light background
  /// where the default gold would disappear.
  final Color color;

  @override
  Widget build(BuildContext context) {
    final filled = value.clamp(0.0, 5.0);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 5; i++)
          Icon(
            _iconFor(filled - i),
            size: size,
            color: color,
          ),
        if (showValue) ...[
          SizedBox(width: size * 0.3),
          Text(value.toStringAsFixed(1), style: AppTypography.body.copyWith(fontSize: size * 0.85)),
        ],
      ],
    );
  }

  IconData _iconFor(double fillAmount) {
    if (fillAmount >= 0.75) return Icons.star_rounded;
    if (fillAmount >= 0.25) return Icons.star_half_rounded;
    return Icons.star_outline_rounded;
  }
}

/// The Rate My Life brand mark (assets/branding/logo.png).
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 120});

  final double size;

  @override
  Widget build(BuildContext context) {
    final pixelSize = (size * MediaQuery.devicePixelRatioOf(context)).round();
    return Image.asset(
      'assets/branding/logo.png',
      width: size,
      height: size,
      cacheWidth: pixelSize,
      cacheHeight: pixelSize,
      filterQuality: FilterQuality.medium,
    );
  }
}

/// A full-width gradient pill CTA — the app's primary-action look
/// (onboarding, score sharing, home quick actions).
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.gradient,
    this.onPressed,
    this.icon,
    this.foregroundColor = Colors.white,
    this.height = 56,
  });

  final String label;
  final Gradient gradient;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color foregroundColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: AppRadius.pillRadius,
          boxShadow: disabled
              ? null
              : [
                  BoxShadow(
                    color: (gradient.colors.last).withValues(alpha: 0.45),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: AppRadius.pillRadius,
            onTap: onPressed,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: foregroundColor, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label.toUpperCase(),
                    style: AppTypography.button.copyWith(color: foregroundColor),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A self-contained "neon arcade" icon badge — a glowing rounded-square
/// (or circular) chip with a glowing glyph inside. Built entirely from
/// code (gradients, borders, shadows) rather than raster art, so it scales
/// cleanly to any size and stays on-theme automatically.
class NeonIconBadge extends StatelessWidget {
  const NeonIconBadge({
    super.key,
    this.icon,
    this.emoji,
    required this.accent,
    this.size = 56,
    this.circular = false,
    this.badgeCount,
    this.dim = false,
  }) : assert(icon != null || emoji != null, 'NeonIconBadge needs either icon or emoji');

  final IconData? icon;

  /// Overrides [icon] with a literal glyph (e.g. a radiation symbol) —
  /// for a mark Material Icons simply doesn't have.
  final String? emoji;
  final Color accent;
  final double size;
  final bool circular;
  final int? badgeCount;

  /// Renders a quieter, unlit version — for inactive states (e.g. an
  /// unselected bottom nav tab) where the full glow would be too busy.
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final glyphColor = dim ? AppColors.textMuted : accent;
    final chip = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: circular ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circular ? null : BorderRadius.circular(size * 0.28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceHigh,
            Color.lerp(AppColors.surfaceSolid, accent, dim ? 0.05 : 0.22)!,
          ],
        ),
        border: Border.all(
          color: dim ? AppColors.border : accent.withValues(alpha: 0.85),
          width: size * 0.035,
        ),
        boxShadow: dim
            ? null
            : [
                BoxShadow(
                  color: accent.withValues(alpha: 0.5),
                  blurRadius: size * 0.32,
                  spreadRadius: size * 0.01,
                ),
              ],
      ),
      alignment: Alignment.center,
      child: emoji != null
          ? Text(emoji!, style: TextStyle(fontSize: size * 0.5))
          : Icon(
              icon,
              size: size * 0.5,
              color: glyphColor,
              shadows: dim
                  ? null
                  : [
                      Shadow(color: accent.withValues(alpha: 0.85), blurRadius: size * 0.22),
                      Shadow(color: Colors.white.withValues(alpha: 0.4), blurRadius: size * 0.06),
                    ],
            ),
    );
    if (badgeCount == null || badgeCount! <= 0) return chip;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        chip,
        Positioned(
          top: -size * 0.1,
          right: -size * 0.1,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: size * 0.11, vertical: size * 0.04),
            constraints: BoxConstraints(minWidth: size * 0.34),
            decoration: BoxDecoration(
              gradient: AppColors.pinkGradient,
              borderRadius: AppRadius.pillRadius,
              border: Border.all(color: AppColors.background, width: size * 0.045),
            ),
            alignment: Alignment.center,
            child: Text(
              '$badgeCount',
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(
                color: Colors.white,
                fontSize: size * 0.17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

String lifeScoreTier(int score) {
  if (score >= 90) return 'LEGENDARY LIFE';
  if (score >= 75) return 'ELITE LIFE';
  if (score >= 60) return 'RISING LIFE';
  if (score >= 40) return 'BUILDING LIFE';
  return 'STARTER LIFE';
}

/// The hexagonal crown-and-score badge used for the Life Score hero
/// moment (home screen, score screen).
class ScoreBadge extends StatelessWidget {
  const ScoreBadge({
    super.key,
    required this.score,
    this.subtitle,
    this.size = 168,
  });

  final int score;
  final String? subtitle;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tier = lifeScoreTier(score);
    return Column(
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.gold.withValues(alpha: 0.38),
                      AppColors.gold.withValues(alpha: 0),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
              ClipPath(
                clipper: _HexagonClipper(),
                child: Container(
                  width: size * 0.86,
                  height: size * 0.86,
                  decoration: const BoxDecoration(gradient: AppColors.goldGradient),
                  padding: const EdgeInsets.all(3),
                  child: ClipPath(
                    clipper: _HexagonClipper(),
                    child: Container(
                      decoration: const BoxDecoration(gradient: AppColors.purpleGradient),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -6,
                child: Icon(Icons.emoji_events, color: AppColors.gold, size: size * 0.22),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: score.toDouble()),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => Text(
                  value.round().toString(),
                  style: AppTypography.hero.copyWith(fontSize: size * 0.34),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            gradient: AppColors.purpleGradient,
            borderRadius: AppRadius.pillRadius,
          ),
          child: Text(tier, style: AppTypography.caption.copyWith(color: Colors.white, fontSize: 12.5)),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMuted,
          ),
        ],
      ],
    );
  }
}

class _HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.5, 0)
      ..lineTo(w, h * 0.25)
      ..lineTo(w, h * 0.75)
      ..lineTo(w * 0.5, h)
      ..lineTo(0, h * 0.75)
      ..lineTo(0, h * 0.25)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Reusable LEVEL / rank / XP progress display — the primary progression
/// surface, used on Home and the Me screen. Purely presentational; all
/// numbers come from `LevelInfo` (derived from `UserProfile.xp` via
/// `LevelService`, never stored directly).
class LevelProgressCard extends StatelessWidget {
  const LevelProgressCard({super.key, required this.levelInfo});

  final LevelInfo levelInfo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.purpleGradient,
        borderRadius: AppRadius.mdRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: AppRadius.pillRadius,
                ),
                child: Text(
                  'LEVEL ${levelInfo.level}',
                  style: AppTypography.button.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                levelInfo.rank.toUpperCase(),
                style: AppTypography.eyebrow.copyWith(color: Colors.white70),
              ),
              const Spacer(),
              if (levelInfo.isMaxLevel) const Icon(Icons.workspace_premium_rounded, color: AppColors.gold),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: levelInfo.progress),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 10,
                backgroundColor: Colors.black.withValues(alpha: 0.25),
                valueColor: const AlwaysStoppedAnimation(AppColors.gold),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            levelInfo.isMaxLevel
                ? '${levelInfo.totalXp} XP · MAX LEVEL'
                : '${levelInfo.xpIntoLevel} / ${levelInfo.xpForNextLevel} XP',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
          ),
          if (!levelInfo.isMaxLevel) ...[
            const SizedBox(height: 2),
            Text(
              'NEXT LEVEL · +${levelInfo.xpRemaining} XP',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ],
      ),
    );
  }
}
