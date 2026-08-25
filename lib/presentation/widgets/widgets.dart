import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/models.dart';
import 'brand_widgets.dart';

/// Short relative timestamp ("now", "5m", "3h", "2d", or a date past a
/// week) — shared by comments and messages rather than each keeping
/// its own copy.
String timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'now';
  if (diff.inHours < 1) return '${diff.inMinutes}m';
  if (diff.inDays < 1) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  return '${dt.day}/${dt.month}/${dt.year}';
}

/// Maps an `AchievementDefinition.iconKey` to its icon. Kept in the
/// presentation layer since models stay Flutter-free.
IconData achievementIcon(String key) => switch (key) {
      'flag' => Icons.flag_rounded,
      'star' => Icons.star_rounded,
      'bolt' => Icons.bolt_rounded,
      'camera' => Icons.camera_alt_rounded,
      'trending_up' => Icons.trending_up_rounded,
      'share' => Icons.ios_share_rounded,
      'shield' => Icons.shield_rounded,
      'crown' => Icons.emoji_events_rounded,
      'flame' => Icons.local_fire_department_rounded,
      'edit' => Icons.edit_rounded,
      'swords' => Icons.sports_martial_arts_rounded,
      'help' => Icons.help_rounded,
      _ => Icons.emoji_events_rounded,
    };

/// A single achievement row — used both in the achievements gallery and
/// (in a larger form) the unlock dialog. Locked achievements are visibly
/// desaturated with a lock icon; unlocked ones get the gold treatment
/// and their unlock date.
class AchievementCard extends StatelessWidget {
  const AchievementCard({
    super.key,
    required this.achievement,
    required this.unlocked,
    this.unlockedAt,
  });

  final AchievementDefinition achievement;
  final bool unlocked;
  final DateTime? unlockedAt;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: unlocked ? AppColors.goldGradient : null,
              color: unlocked ? null : AppTheme.surfaceHigh,
              border: Border.all(color: unlocked ? AppColors.gold : AppTheme.border),
            ),
            child: Icon(
              achievementIcon(achievement.iconKey),
              color: unlocked ? Colors.black : AppTheme.textMuted,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.name,
                  style: TextStyle(fontWeight: FontWeight.w900, color: unlocked ? Colors.white : AppTheme.textMuted),
                ),
                const SizedBox(height: 2),
                Text(achievement.description, style: AppTypography.bodyMuted.copyWith(fontSize: 12.5)),
                if (unlocked && unlockedAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Unlocked ${unlockedAt!.day}/${unlockedAt!.month}/${unlockedAt!.year}',
                    style: const TextStyle(fontSize: 11, color: AppColors.gold, fontWeight: FontWeight.w700),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (!unlocked)
            const Icon(Icons.lock_outline, color: AppTheme.textMuted, size: 18)
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.15),
                borderRadius: AppRadius.pillRadius,
              ),
              child: Text(
                '+${achievement.xpReward} XP',
                style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w800, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }
}

/// Opens the OS share sheet with a text summary of [profile]. Used
/// everywhere a profile can be shared (Me, public profile, Discover).
Future<void> shareProfileSummary(UserProfile profile) {
  return SharePlus.instance.share(
    ShareParams(
      text: '${profile.displayName}: ${profile.ratingSummary.averageOverall.toStringAsFixed(1)}/5 community rating, '
          '${profile.score.overall}/100 Life Score on Rate My Life.',
      subject: 'Rate My Life — ${profile.displayName}',
    ),
  );
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = AnimatedScale(
      scale: 1,
      duration: const Duration(milliseconds: 120),
      child: Card(
        child: Padding(padding: padding, child: child),
      ),
    );
    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: card,
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

class ScoreTile extends StatelessWidget {
  const ScoreTile({
    super.key,
    required this.value,
    required this.suffix,
    required this.label,
    this.color,
  });

  final String value;
  final String suffix;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: double.tryParse(value) ?? 0),
                    duration: const Duration(milliseconds: 650),
                    curve: Curves.easeOutCubic,
                    builder: (context, number, _) => Text(
                      value.contains('.')
                          ? number.toStringAsFixed(1)
                          : number.round().toString(),
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: color ?? Colors.white,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      suffix,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }
}

/// Wraps [child] (typically a `ProfileImage`) in a gradient border
/// matching a purchased `CosmeticFrame.gradientKey` — no border at all
/// for `'none'`, null, or an unrecognized id. Only ever one of the
/// app's existing brand gradients, never a hand-rolled color.
class ProfileFrame extends StatelessWidget {
  const ProfileFrame({super.key, required this.frameId, required this.child, this.borderRadius = 12});

  final String? frameId;
  final Widget child;
  final double borderRadius;

  static const _gradients = {
    'gold': AppColors.goldGradient,
    'purple': AppColors.purpleGradient,
    'pink': AppColors.pinkGradient,
    'blue': AppColors.blueGradient,
  };

  @override
  Widget build(BuildContext context) {
    final gradient = frameId == null ? null : _gradients[frameId];
    if (gradient == null) return child;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(borderRadius + 4)),
      child: ClipRRect(borderRadius: BorderRadius.circular(borderRadius), child: child),
    );
  }
}

/// A Tinder-style photo carousel: swipe, or tap the left/right half of the
/// photo, to move between a profile's photos. Falls back to a single
/// static photo (no tap zones/indicator) when there's zero or one photo,
/// since there's nothing to navigate between.
class PhotoCarousel extends StatefulWidget {
  const PhotoCarousel({
    super.key,
    required this.photos,
    required this.label,
    this.frameId,
    this.aspectRatio = 3 / 4,
    this.borderRadius = 16,
  });

  final List<ProfilePhoto> photos;
  final String label;
  final String? frameId;

  /// width / height — 3/4 (the default) is a tall, Tinder-style portrait
  /// rectangle. Sizing by ratio (not a fixed height) keeps the photo
  /// correctly proportioned across phone widths instead of looking too
  /// short/wide on a narrow screen or too tall/cropped on a wide one.
  final double aspectRatio;
  final double borderRadius;

  @override
  State<PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<PhotoCarousel> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(int delta, int count) {
    final next = (_index + delta).clamp(0, count - 1);
    if (next == _index) return;
    _controller.animateToPage(next, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    // The designated profile photo always opens the carousel, regardless
    // of where it falls in display order — the rest follow in the order
    // the owner arranged them in Photo Manager.
    final photos = [...widget.photos]
      ..sort((a, b) {
        if (a.isProfilePhoto != b.isProfilePhoto) return a.isProfilePhoto ? -1 : 1;
        return a.order.compareTo(b.order);
      });
    final single = ProfileFrame(
      frameId: widget.frameId,
      borderRadius: widget.borderRadius,
      child: AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: ProfileImage(
          photo: photos.isEmpty ? null : photos.first,
          label: widget.label,
          height: double.infinity,
          width: double.infinity,
          borderRadius: widget.borderRadius,
        ),
      ),
    );
    if (photos.length <= 1) return single;

    return ProfileFrame(
      frameId: widget.frameId,
      borderRadius: widget.borderRadius,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: AspectRatio(
          aspectRatio: widget.aspectRatio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                controller: _controller,
                itemCount: photos.length,
                onPageChanged: (value) => setState(() => _index = value),
                itemBuilder: (context, i) =>
                    ProfileImage(photo: photos[i], label: widget.label, height: double.infinity, width: double.infinity, borderRadius: 0),
              ),
              Positioned(
                top: 10,
                left: 10,
                right: 10,
                child: Row(
                  children: [
                    for (var i = 0; i < photos.length; i++)
                      Expanded(
                        child: Container(
                          height: 3,
                          margin: EdgeInsets.only(right: i == photos.length - 1 ? 0 : 4),
                          decoration: BoxDecoration(
                            color: i <= _index ? Colors.white : Colors.white.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Positioned.fill(
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () => _go(-1, photos.length),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () => _go(1, photos.length),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileImage extends StatelessWidget {
  const ProfileImage({
    super.key,
    required this.photo,
    required this.label,
    this.height = 220,
    this.width,
    this.borderRadius = 8,
    this.isPerson = true,
  });

  final ProfilePhoto? photo;
  final String label;
  final double height;
  final double? width;
  final double borderRadius;

  /// True for every "this is a person" call site (a profile/message/
  /// comment avatar — the overwhelming majority) — a missing photo
  /// there renders as a proper initials avatar, not a camera icon,
  /// which reads as "tap to add a photo" and is only correct for an
  /// actual upload slot. Set false only for an individual gallery
  /// photo tile's own load-failure fallback, where the existing
  /// category icon (travel/home/food/etc, matched from [label]) is
  /// the right fallback instead.
  final bool isPerson;

  @override
  Widget build(BuildContext context) {
    final path = photo?.path;
    Widget child;
    if (path != null && path.startsWith('assets/')) {
      child = Image.asset(path, fit: BoxFit.cover);
    } else if (path != null && path.startsWith('mock://')) {
      // mock:// is always a themed seed/demo photo, never "this person has
      // no photo" — always render the category placeholder, regardless of
      // isPerson.
      child = _MockPhoto(label: path.replaceFirst('mock://', ''), isPerson: false);
    } else if (path != null && (path.startsWith('http://') || path.startsWith('https://'))) {
      child = Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _MockPhoto(label: label, isPerson: isPerson),
        loadingBuilder: (context, image, progress) =>
            progress == null ? image : const ColoredBox(color: AppColors.surfaceHigh),
      );
    } else if (path != null && File(path).existsSync()) {
      child = Image.file(File(path), fit: BoxFit.cover);
    } else {
      child = _MockPhoto(label: label, isPerson: isPerson);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(height: height, width: width, child: child),
    );
  }
}

class _MockPhoto extends StatelessWidget {
  const _MockPhoto({required this.label, this.isPerson = true});

  final String label;
  final bool isPerson;

  @override
  Widget build(BuildContext context) {
    final colors = _colorsFor(label);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: isPerson ? _initialsAvatar() : _categoryPlaceholder(),
    );
  }

  /// A classic initials avatar (Gmail/Slack/WhatsApp-style) — reads
  /// clearly at any size, unlike an icon-plus-name-label layout, so a
  /// tiny 24px conversation-list avatar and a 460px profile hero both
  /// just show a big, legible letter or two.
  Widget _initialsAvatar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.biggest.shortestSide.isFinite ? constraints.biggest.shortestSide : 96.0;
        return Center(
          child: Text(
            _initialsFor(label),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: side * 0.38,
            ),
          ),
        );
      },
    );
  }

  Widget _categoryPlaceholder() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              label.toUpperCase(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
        Center(
          child: Icon(
            _iconFor(label),
            size: 52,
            color: Colors.white.withValues(alpha: 0.78),
          ),
        ),
      ],
    );
  }

  String _initialsFor(String label) {
    final words = label.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
    return (words.first.substring(0, 1) + words.last.substring(0, 1)).toUpperCase();
  }

  List<Color> _colorsFor(String label) {
    final code = label.codeUnits.fold(0, (a, b) => a + b);
    final palettes = [
      [const Color(0xFF22333B), const Color(0xFF39D98A)],
      [const Color(0xFF2D1E2F), const Color(0xFFFFC84B)],
      [const Color(0xFF111827), const Color(0xFF4F7CAC)],
      [const Color(0xFF2F2504), const Color(0xFFE85D04)],
      [const Color(0xFF1B263B), const Color(0xFFB8DBD9)],
      [const Color(0xFF2B2D42), const Color(0xFFFF5A66)],
    ];
    return palettes[code % palettes.length];
  }

  IconData _iconFor(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('travel')) return Icons.flight_takeoff;
    if (lower.contains('home')) return Icons.home_outlined;
    if (lower.contains('food')) return Icons.restaurant;
    if (lower.contains('car')) return Icons.directions_car;
    if (lower.contains('fitness')) return Icons.fitness_center;
    if (lower.contains('achievement')) return Icons.emoji_events;
    if (lower.contains('hobby')) return Icons.palette;
    return Icons.photo_camera_outlined;
  }
}

class LifestyleProfileCard extends StatelessWidget {
  const LifestyleProfileCard({
    super.key,
    required this.profile,
    required this.onTap,
    this.compact = false,
  });

  final UserProfile profile;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              PhotoCarousel(
                photos: profile.photos,
                label: profile.displayName,
                frameId: profile.equippedFrameId,
                aspectRatio: compact ? 4 / 3 : 3 / 4,
              ),
              if (profile.ratingSummary.hasRatings)
                Positioned(
                  top: compact ? 8 : 10,
                  right: compact ? 8 : 10,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 9, vertical: compact ? 4 : 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: AppRadius.pillRadius,
                    ),
                    child: StarRating(value: profile.ratingSummary.averageOverall, size: compact ? 11 : 14),
                  ),
                ),
            ],
          ),
          Padding(
            padding: EdgeInsets.all(compact ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 15 : 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: compact ? 2 : 4),
                Text(
                  profile.locationLine,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppTheme.textMuted, fontSize: compact ? 12 : 14),
                ),
                SizedBox(height: compact ? 8 : 12),
                if (!compact)
                  Text(
                    '"${profile.bio}"',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, height: 1.35),
                  ),
                if (!compact) const SizedBox(height: 14),
                if (compact)
                  MetricPill(
                    icon: Icons.speed,
                    label: '${profile.score.overall} / 100',
                    color: AppTheme.accent,
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      MetricPill(
                        icon: Icons.speed,
                        label: '${profile.score.overall} / 100',
                        color: AppTheme.accent,
                      ),
                      MetricPill(
                        icon: Icons.how_to_reg,
                        label: '${profile.ratingSummary.count} ratings',
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MetricPill extends StatelessWidget {
  const MetricPill({
    super.key,
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color ?? AppTheme.textMuted),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class RatingSelector extends StatelessWidget {
  const RatingSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (var i = 1; i <= 5; i++)
          Semantics(
            button: true,
            label: 'Rate $i out of 5',
            child: InkWell(
              onTap: () => onChanged(i),
              customBorder: const CircleBorder(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutCubic,
                width: 48,
                height: 52,
                alignment: Alignment.center,
                child: Icon(
                  i <= value ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: i <= value ? 44 : 38,
                  color: i <= value ? AppTheme.gold : AppTheme.border,
                  shadows: i <= value
                      ? [Shadow(color: AppTheme.gold.withValues(alpha: 0.7), blurRadius: 12)]
                      : null,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Platforms a profile owner can optionally link to. "Website" is the
/// deliberate catch-all for anything not explicitly listed — a link
/// system that only worked for a fixed brand set would just push
/// unlisted platforms into the bio field instead.
const socialPlatforms = ['Instagram', 'TikTok', 'Twitter/X', 'Facebook', 'YouTube', 'Snapchat', 'Website'];

IconData socialPlatformIcon(String platform) => switch (platform) {
      'Instagram' => Icons.camera_alt_rounded,
      'TikTok' => Icons.music_note_rounded,
      'Twitter/X' => Icons.alternate_email_rounded,
      'Facebook' => Icons.facebook_rounded,
      'YouTube' => Icons.smart_display_rounded,
      'Snapchat' => Icons.camera_rounded,
      _ => Icons.language_rounded,
    };

/// A row of tappable chips for whichever social links the owner filled
/// in — empty entries are skipped, and the row collapses to nothing if
/// there are none. Opens the real URL in the device's browser/app, never
/// in-app, so this stays a link-out, not an embedded webview.
class SocialLinksRow extends StatelessWidget {
  const SocialLinksRow({super.key, required this.links});

  final Map<String, String> links;

  @override
  Widget build(BuildContext context) {
    final entries = links.entries.where((entry) => entry.value.trim().isNotEmpty).toList();
    if (entries.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final entry in entries)
          ActionChip(
            avatar: Icon(socialPlatformIcon(entry.key), size: 16),
            label: Text(entry.key),
            onPressed: () => _open(entry.value),
          ),
      ],
    );
  }

  Future<void> _open(String rawUrl) async {
    final trimmed = rawUrl.trim();
    final normalized = trimmed.startsWith('http://') || trimmed.startsWith('https://') ? trimmed : 'https://$trimmed';
    final uri = Uri.tryParse(normalized);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

IconData _categoryIcon(String category) => switch (category) {
      'Travel' => Icons.flight_takeoff_rounded,
      'Home' => Icons.home_rounded,
      'Car' => Icons.directions_car_rounded,
      'Food' => Icons.restaurant_rounded,
      'Fitness' => Icons.fitness_center_rounded,
      'Hobby' => Icons.palette_rounded,
      'Achievement' => Icons.emoji_events_rounded,
      _ => Icons.photo_camera_outlined,
    };

class PhotoGrid extends StatelessWidget {
  const PhotoGrid({
    super.key,
    required this.photos,
    required this.onTap,
    this.voteCounts = const {},
    this.myVotedPhotoId,
    this.onVote,
  });

  final List<ProfilePhoto> photos;
  final ValueChanged<int> onTap;

  /// "Best photo" vote tally, photoId → count (see `PhotoVote`).
  final Map<String, int> voteCounts;

  /// The viewer's own current pick, if any — shown as a filled heart.
  final String? myVotedPhotoId;

  /// Null hides the vote affordance entirely (e.g. viewing your own
  /// profile — you can't vote on your own photos).
  final ValueChanged<String>? onVote;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return const AppCard(
        child: EmptyState(
          icon: Icons.add_photo_alternate_outlined,
          title: 'Your life deserves better photos.',
          subtitle: 'Add travel, home, hobbies, food, fitness, or achievements.',
        ),
      );
    }
    final sorted = [...photos]..sort((a, b) => a.order.compareTo(b.order));
    final maxVotes = voteCounts.values.isEmpty ? 0 : voteCounts.values.reduce((a, b) => a > b ? a : b);
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: sorted.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final photo = sorted[index];
        final isFanFavorite = maxVotes > 0 && (voteCounts[photo.id] ?? 0) == maxVotes;
        final iVotedThis = myVotedPhotoId == photo.id;
        return InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            Positioned.fill(
              child: ProfileImage(
                photo: photo,
                label: photo.category,
                height: double.infinity,
              ),
            ),
            if (photo.isProfilePhoto)
              const Positioned(
                top: 8,
                left: 8,
                child: MetricPill(
                  icon: Icons.person,
                  label: 'Profile',
                  color: AppTheme.gold,
                ),
              )
            else
              Positioned(
                bottom: 8,
                left: 8,
                child: MetricPill(
                  icon: _categoryIcon(photo.category),
                  label: photo.category,
                ),
              ),
            if (isFanFavorite)
              const Positioned(
                top: 8,
                right: 8,
                child: MetricPill(
                  icon: Icons.local_fire_department_rounded,
                  label: 'Fan Favorite',
                  color: AppColors.pink,
                ),
              ),
            if (onVote != null)
              Positioned(
                bottom: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => onVote!(photo.id),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55), shape: BoxShape.circle),
                    child: Icon(
                      iVotedThis ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      size: 16,
                      color: iVotedThis ? AppColors.pink : Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
        );
      },
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.gold, size: 32),
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(subtitle, style: const TextStyle(color: AppTheme.textMuted)),
        if (action != null) ...[
          const SizedBox(height: 14),
          action!,
        ],
      ],
    );
  }
}

class ShareProfileCard extends StatelessWidget {
  const ShareProfileCard({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RATE MY LIFE',
            style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.gold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ProfileImage(
                  photo: profile.privacy.showPhotos ? profile.profilePhoto : null,
                  label: profile.displayName,
                  height: 86,
                  width: 86,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      profile.locationLine,
                      style: const TextStyle(color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              ScoreTile(
                value: profile.ratingSummary.averageOverall.toStringAsFixed(1),
                suffix: '/ 5',
                label: "People's Rating",
                color: AppTheme.gold,
              ),
              const SizedBox(width: 10),
              ScoreTile(
                value: profile.score.overall.toString(),
                suffix: '/ 100',
                label: 'Life Score',
                color: AppTheme.accent,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Better than ${(profile.score.overall * 0.94).round().clamp(1, 99)}% of people like me.',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

/// The celebratory modal shown when an achievement unlocks — deliberately
/// a separate dialog rather than a `toast` entry, both for visual weight
/// and because it avoids the toast/postFrameCallback race described on
/// `AppController._grantXp`.
class AchievementUnlockDialog extends StatelessWidget {
  const AchievementUnlockDialog({super.key, required this.achievement});

  final AchievementDefinition achievement;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: AppRadius.lgRadius,
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.6), width: 1.5),
          boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: 0.25), blurRadius: 32, spreadRadius: 4)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('ACHIEVEMENT UNLOCKED', style: AppTypography.eyebrow.copyWith(color: AppColors.gold)),
            const SizedBox(height: 18),
            Container(
              width: 84,
              height: 84,
              alignment: Alignment.center,
              decoration: const BoxDecoration(gradient: AppColors.goldGradient, shape: BoxShape.circle),
              child: Icon(achievementIcon(achievement.iconKey), color: Colors.black, size: 42),
            ),
            const SizedBox(height: 16),
            Text(
              achievement.name,
              textAlign: TextAlign.center,
              style: AppTypography.title.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              achievement.description,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMuted,
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: 0.15), borderRadius: AppRadius.pillRadius),
              child: Text(
                '+${achievement.xpReward} XP',
                style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w900, fontSize: 14),
              ),
            ),
            const SizedBox(height: 22),
            GradientButton(
              label: 'NICE!',
              gradient: AppColors.goldGradient,
              foregroundColor: Colors.black,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small coin-balance chip — the soft currency's only UI surface so
/// far (nothing spends coins yet; see `Wallet`'s doc comment).
class CoinBalancePill extends StatelessWidget {
  const CoinBalancePill({super.key, required this.balance});

  final int balance;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHigh,
        borderRadius: AppRadius.pillRadius,
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on_rounded, color: AppColors.gold, size: 18),
          const SizedBox(width: 6),
          Text('$balance', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.gold)),
        ],
      ),
    );
  }
}

/// The 🔥 N-day-streak card with a Mon..Sun activity row. [lastSevenDays]
/// should be oldest-first, as returned by `StreakService.lastSevenDays`.
class StreakCard extends StatelessWidget {
  const StreakCard({super.key, required this.streakDays, required this.lastSevenDays});

  final int streakDays;
  final List<MapEntry<DateTime, bool>> lastSevenDays;

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department_rounded, color: AppColors.gold, size: 22),
              const SizedBox(width: 8),
              Text(
                streakDays == 1 ? '1 DAY STREAK' : '$streakDays DAY STREAK',
                style: AppTypography.eyebrow.copyWith(color: AppColors.gold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final entry in lastSevenDays)
                Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: entry.value ? AppColors.goldGradient : null,
                        color: entry.value ? null : AppTheme.surfaceHigh,
                        border: Border.all(color: entry.value ? AppColors.gold : AppTheme.border),
                      ),
                      child: entry.value ? const Icon(Icons.check_rounded, size: 16, color: Colors.black) : null,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _dayLabels[entry.key.weekday - 1],
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Today's 3-challenge checklist. [progressFor] and [claimedFor] are
/// injected rather than computed here so this stays a pure display
/// widget — `AppController` already knows how to compute both from real
/// activity.
class DailyChallengesCard extends StatelessWidget {
  const DailyChallengesCard({
    super.key,
    required this.challenges,
    required this.progressFor,
    required this.claimedFor,
  });

  final List<DailyChallenge> challenges;
  final int Function(DailyChallenge) progressFor;
  final bool Function(String challengeId) claimedFor;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < challenges.length; i++) ...[
            if (i > 0) const Divider(height: 26, color: AppTheme.border),
            _ChallengeRow(
              challenge: challenges[i],
              progress: progressFor(challenges[i]),
              claimed: claimedFor(challenges[i].id),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChallengeRow extends StatelessWidget {
  const _ChallengeRow({required this.challenge, required this.progress, required this.claimed});

  final DailyChallenge challenge;
  final int progress;
  final bool claimed;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0, challenge.targetCount);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: claimed ? AppColors.goldGradient : null,
            color: claimed ? null : AppTheme.surfaceHigh,
          ),
          child: Icon(achievementIcon(challenge.iconKey), size: 20, color: claimed ? Colors.black : AppColors.purple),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                challenge.title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  decoration: claimed ? TextDecoration.lineThrough : null,
                  color: claimed ? AppTheme.textMuted : null,
                ),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: clamped / challenge.targetCount,
                  minHeight: 5,
                  backgroundColor: AppTheme.surfaceHigh,
                  valueColor: const AlwaysStoppedAnimation(AppColors.gold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        if (claimed)
          const Icon(Icons.check_circle_rounded, color: AppColors.gold, size: 22)
        else
          Text('$clamped/${challenge.targetCount}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
      ],
    );
  }
}

/// A single-line text field + send button for posting a comment.
/// Disabled entirely (with an explanatory line, per spec's exact
/// wording) when comments aren't allowed — see `commentsAllowedFor`.
class CommentComposer extends StatefulWidget {
  const CommentComposer({super.key, required this.onSubmit});

  final ValueChanged<String> onSubmit;

  @override
  State<CommentComposer> createState() => _CommentComposerState();
}

class _CommentComposerState extends State<CommentComposer> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSubmit(text);
    _controller.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            maxLength: Comment.maxLength,
            maxLines: 3,
            minLines: 1,
            decoration: const InputDecoration(hintText: 'Add a comment...', counterText: ''),
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(onPressed: _submit, icon: const Icon(Icons.send_rounded)),
      ],
    );
  }
}

class MessageComposer extends StatefulWidget {
  const MessageComposer({super.key, required this.onSubmit});

  final ValueChanged<String> onSubmit;

  @override
  State<MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<MessageComposer> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSubmit(text);
    _controller.clear();
  }

  // A multi-line TextField (maxLines > 1) treats a bare Enter as
  // "insert a newline", not "fire onSubmitted" — that's why the
  // keyboard's Enter/return key did nothing here despite
  // textInputAction: send already being set (that only wires up an
  // on-screen action *glyph* some keyboards render, not the literal
  // Enter key). Enter sends, Shift+Enter still inserts a newline —
  // same convention as Slack/Discord.
  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    final isEnter = event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.numpadEnter;
    if (event is KeyDownEvent && isEnter && !HardwareKeyboard.instance.isShiftPressed) {
      _submit();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: AppRadius.pillRadius,
              border: Border.all(color: AppColors.green.withValues(alpha: 0.5)),
              boxShadow: [BoxShadow(color: AppColors.green.withValues(alpha: 0.18), blurRadius: 12, spreadRadius: -2)],
            ),
            child: Focus(
              onKeyEvent: _handleKey,
              child: TextField(
                controller: _controller,
                maxLength: Message.maxLength,
                maxLines: 4,
                minLines: 1,
                decoration: const InputDecoration(
                  hintText: 'Message...',
                  counterText: '',
                  // The app-wide input theme sets its own enabledBorder/
                  // focusedBorder (a smaller-radius purple outline) —
                  // those are more specific than the generic `border`
                  // below and win over it, so they need to be silenced
                  // individually or that theme border shows through
                  // misaligned against this pill's own neon border.
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _submit(),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.greenGradient,
            boxShadow: [BoxShadow(color: AppColors.green.withValues(alpha: 0.45), blurRadius: 14, offset: const Offset(0, 4))],
          ),
          child: IconButton(
            onPressed: _submit,
            icon: const Icon(Icons.send_rounded, color: Colors.black),
          ),
        ),
      ],
    );
  }
}

/// One message bubble — right-aligned/accent for the local user's own
/// sent messages, left-aligned/muted for the other side. Long-press for
/// actions (delete your own, report/block theirs).
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.onLongPress,
  });

  final Message message;
  final bool isMine;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: isMine ? AppColors.purpleGradient : null,
            color: isMine ? null : AppTheme.surfaceHigh,
            border: isMine ? null : Border.all(color: AppColors.green.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMine ? 16 : 4),
              bottomRight: Radius.circular(isMine ? 4 : 16),
            ),
            boxShadow: isMine
                ? null
                : [BoxShadow(color: AppColors.green.withValues(alpha: 0.12), blurRadius: 10, spreadRadius: -2)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message.content, style: TextStyle(color: isMine ? Colors.white : AppColors.textPrimary)),
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('h:mm a').format(message.createdAt),
                    style: TextStyle(
                      fontSize: 10.5,
                      color: isMine ? Colors.white.withValues(alpha: 0.7) : AppTheme.textMuted,
                    ),
                  ),
                  // Read receipt — only meaningful on your own sent
                  // messages; the other side's bubbles never show one,
                  // the same way no chat app shows you a receipt for a
                  // message that was sent *to* you.
                  if (isMine) ...[
                    const SizedBox(width: 4),
                    Icon(
                      message.isRead ? Icons.done_all_rounded : Icons.done_rounded,
                      size: 14,
                      color: message.isRead ? AppColors.cyan : Colors.white.withValues(alpha: 0.7),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One comment row: avatar, name + relative time, text, reaction chips,
/// and a permission-gated ••• menu (only actions the current viewer is
/// actually allowed to take are shown).
class CommentCard extends StatelessWidget {
  const CommentCard({
    super.key,
    required this.comment,
    required this.authorName,
    required this.authorPhoto,
    required this.reactionCounts,
    required this.myReactions,
    required this.canEdit,
    required this.canDelete,
    required this.isOwnComment,
    required this.onReact,
    required this.onEdit,
    required this.onDelete,
    required this.onReport,
    required this.onBlock,
  });

  final Comment comment;
  final String authorName;
  final ProfilePhoto? authorPhoto;
  final Map<CommentReactionType, int> reactionCounts;
  final Set<CommentReactionType> myReactions;
  final bool canEdit;
  final bool canDelete;
  final bool isOwnComment;
  final ValueChanged<CommentReactionType> onReact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onReport;
  final VoidCallback onBlock;

  static const _emojiFor = {
    CommentReactionType.heart: '❤️',
    CommentReactionType.laugh: '😂',
    CommentReactionType.fire: '🔥',
    CommentReactionType.thumbsUp: '👍',
  };

  @override
  Widget build(BuildContext context) {
    final showMenu = canEdit || canDelete || !isOwnComment;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: ProfileImage(photo: authorPhoto, label: authorName, height: 36, width: 36, borderRadius: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: authorName, style: const TextStyle(fontWeight: FontWeight.w800)),
                            TextSpan(text: '  ${timeAgo(comment.createdAt)}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (showMenu)
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.more_horiz_rounded, size: 18, color: AppTheme.textMuted),
                        onSelected: (value) => switch (value) {
                          'edit' => onEdit(),
                          'delete' => onDelete(),
                          'report' => onReport(),
                          'block' => onBlock(),
                          _ => null,
                        },
                        itemBuilder: (context) => [
                          if (canEdit)
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(children: [Icon(Icons.edit_outlined, size: 18, color: AppTheme.textMuted), SizedBox(width: 10), Text('Edit')]),
                            ),
                          if (canDelete)
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(children: [Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger), SizedBox(width: 10), Text('Delete', style: TextStyle(color: AppColors.danger))]),
                            ),
                          if (!isOwnComment)
                            const PopupMenuItem(
                              value: 'report',
                              child: Row(children: [Icon(Icons.flag_outlined, size: 18, color: AppColors.danger), SizedBox(width: 10), Text('Report', style: TextStyle(color: AppColors.danger))]),
                            ),
                          if (!isOwnComment)
                            const PopupMenuItem(
                              value: 'block',
                              child: Row(children: [Icon(Icons.block_rounded, size: 18, color: AppColors.danger), SizedBox(width: 10), Text('Block', style: TextStyle(color: AppColors.danger))]),
                            ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment.content, style: const TextStyle(height: 1.3)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final type in CommentReactionType.values)
                      _ReactionChip(
                        emoji: _emojiFor[type]!,
                        count: reactionCounts[type] ?? 0,
                        active: myReactions.contains(type),
                        onTap: () => onReact(type),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

class _ReactionChip extends StatelessWidget {
  const _ReactionChip({required this.emoji, required this.count, required this.active, required this.onTap});

  final String emoji;
  final int count;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppRadius.pillRadius,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: active ? AppColors.purple.withValues(alpha: 0.2) : AppTheme.surfaceHigh,
          borderRadius: AppRadius.pillRadius,
          border: Border.all(color: active ? AppColors.purple : AppTheme.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 13)),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(
                '$count',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: active ? AppColors.purple : AppTheme.textMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
