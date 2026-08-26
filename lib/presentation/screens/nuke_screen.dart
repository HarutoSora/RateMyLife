import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/models.dart';
import '../../domain/services/nuke_service.dart';
import '../state/app_state.dart';
import '../widgets/brand_widgets.dart';
import '../widgets/fx_widgets.dart';
import '../widgets/widgets.dart';
import 'get_coins_screen.dart';

/// Opens the healing reveal sheet for curing [attribute] — shared by
/// `_MyDamageCard` (this screen) and `NukeStatusBanner` (Home/Me), so
/// every "cure" affordance in the app gets the same reward moment
/// instead of a silent, instant heal.
void showCureRevealSheet(BuildContext context, String attribute) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _CureRevealSheet(attribute: attribute),
  );
}

/// "Nuke" — spend coins to knock a random Life Score attribute down on
/// someone else's profile, or spend coins on a cure potion to heal your
/// own. A lightweight competitive mini-game layered on top of the
/// existing scoring system (see `NukeService`/`LifeScoreService.
/// applyDelta`) — entertainment, same spirit as Life Battles, not a
/// claim about anyone's real worth.
class NukeScreen extends ConsumerWidget {
  const NukeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final profile = state.currentProfile;
    final targets = state.discoverProfiles
        .where((p) => p.id != state.currentUserId)
        .take(30)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Nuke')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Center(
            child: Column(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppColors.nukeOrangeGradient.createShader(bounds),
                  child: Text(
                    'NUKE',
                    textAlign: TextAlign.center,
                    style: AppTypography.hero
                        .copyWith(fontSize: 42, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Damage a random attribute of their life. For fun.',
                  textAlign: TextAlign.center,
                  style: AppTypography.title.copyWith(color: AppColors.blue),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Center(
            child: NeonIconBadge(
              emoji: '☢️',
              accent: AppColors.nukeOrange,
              size: 110,
              circular: true,
            ),
          ),
          const SizedBox(height: 24),
          if (profile != null) ...[
            const SectionTitle('Your Damage'),
            _MyDamageCard(
              profile: profile,
              balance: state.wallet.balance,
              onCure: (attribute) => showCureRevealSheet(context, attribute),
            ),
          ],
          const SectionTitle(
              'Pick a Target — ${NukeService.attackCost} coins'),
          if (targets.isEmpty)
            const EmptyState(
              icon: Icons.groups_outlined,
              title: 'No targets yet.',
              subtitle:
                  'Browse Discover a little first, then come back to nuke someone.',
            )
          else
            for (final target in targets)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _NukeTargetRow(
                  profile: target,
                  onNuke: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => _NukeConfirmSheet(target: target),
                  ),
                ),
              ),
          const SectionTitle('Sent History'),
          if (state.nukeHistory.isEmpty)
            const EmptyState(
              icon: Icons.history_rounded,
              title: 'No nukes sent yet.',
              subtitle: 'Every attack you launch shows up here.',
            )
          else
            for (final event in state.nukeHistory.reversed.take(30))
              _NukeHistoryRow(event: event),
        ],
      ),
    );
  }

}

enum _NukePhase { confirm, insufficientCoins, countdown, impact }

/// The full "☢️ Nuke someone's life?" flow, opened from a target row:
/// confirm (with a real balance/cost/remaining breakdown, or an
/// insufficient-coins state) → a short countdown → the real impact
/// dealt. Never charges optimistically — `AppController.nukeProfile`'s
/// existing validation (`NukeService.assertCanNuke`) is the sole source
/// of truth; if it rejects the attack after confirmation (e.g. a balance
/// race), this sheet just closes and lets the normal toast/SnackBar
/// mechanism surface the real reason, rather than fabricating one.
class _NukeConfirmSheet extends ConsumerStatefulWidget {
  const _NukeConfirmSheet({required this.target});

  final UserProfile target;

  @override
  ConsumerState<_NukeConfirmSheet> createState() => _NukeConfirmSheetState();
}

class _NukeConfirmSheetState extends ConsumerState<_NukeConfirmSheet>
    with SingleTickerProviderStateMixin {
  late _NukePhase _phase;
  NukeEvent? _result;
  late final AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    final balance = ref.read(appControllerProvider).wallet.balance;
    _phase = balance < NukeService.attackCost ? _NukePhase.insufficientCoins : _NukePhase.confirm;
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _launch() {
    HapticFeedback.heavyImpact();
    playSfx(AppSfx.nukeLaunch);
    setState(() => _phase = _NukePhase.countdown);
  }

  Future<void> _onCountdownComplete() async {
    final controller = ref.read(appControllerProvider);
    final before = controller.nukeHistory.length;
    await controller.nukeProfile(widget.target);
    if (!mounted) return;
    if (controller.nukeHistory.length == before) {
      // Rejected after confirmation (e.g. a balance/eligibility race) —
      // close and let the existing toast/SnackBar mechanism explain why.
      Navigator.pop(context);
      return;
    }
    HapticFeedback.heavyImpact();
    playSfx(AppSfx.nukeImpact);
    setState(() {
      _result = controller.nukeHistory.last;
      _phase = _NukePhase.impact;
    });
    _shakeController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final balance = ref.watch(appControllerProvider).wallet.balance;
    return SafeArea(
      child: AnimatedBuilder(
        animation: _shakeController,
        builder: (context, child) {
          // A decaying sine wiggle — strongest right at impact, settled by
          // the end of `_shakeController`'s ~420ms run. No-op (offset 0)
          // outside the impact phase since the controller never starts.
          final t = _shakeController.value;
          final decay = 1 - t;
          final dx = sin(t * pi * 8) * 10 * decay;
          return Transform.translate(offset: Offset(dx, 0), child: child);
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: switch (_phase) {
            _NukePhase.confirm => _confirmContent(balance),
            _NukePhase.insufficientCoins => _insufficientContent(balance),
            _NukePhase.countdown => _countdownContent(),
            _NukePhase.impact => _impactContent(),
          },
        ),
      ),
    );
  }

  Widget _confirmContent(int balance) {
    final remaining = balance - NukeService.attackCost;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const NeonIconBadge(emoji: '☢️', accent: AppColors.nukeOrange, size: 72, circular: true),
        const SizedBox(height: 14),
        Text('NUKE SOMEONE\'S LIFE?',
            textAlign: TextAlign.center,
            style: AppTypography.title.copyWith(color: AppColors.nukeOrange)),
        const SizedBox(height: 6),
        Text(widget.target.displayName.isEmpty ? 'Anonymous' : widget.target.displayName,
            textAlign: TextAlign.center, style: AppTypography.bodyMuted),
        const SizedBox(height: 16),
        _CoinLedgerCard(
          balance: balance,
          cost: NukeService.attackCost,
          remaining: remaining,
          accent: AppColors.nukeOrange,
        ),
        const SizedBox(height: 14),
        Text(
          'One random score category will lose ${NukeService.damagePerNuke} points.\nChoose carefully. 😈',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMuted,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GradientButton(
                label: '☢️ NUKE',
                gradient: AppColors.nukeOrangeGradient,
                onPressed: _launch,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _insufficientContent(int balance) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const NeonIconBadge(icon: Icons.monetization_on_rounded, accent: AppColors.textMuted, size: 72, circular: true),
        const SizedBox(height: 14),
        Text('🪙 NOT ENOUGH COINS', style: AppTypography.title),
        const SizedBox(height: 6),
        Text(
          'You need ${NukeService.attackCost} coins.\nYou have $balance.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMuted,
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: GradientButton(
            label: 'Get Free Coins',
            gradient: AppColors.goldGradient,
            foregroundColor: Colors.black,
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => GetCoinsScreen()));
            },
          ),
        ),
        const SizedBox(height: 8),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
    );
  }

  Widget _countdownContent() {
    return SizedBox(
      height: 220,
      child: Center(
        child: _NukeCountdown(onComplete: _onCountdownComplete),
      ),
    );
  }

  Widget _impactContent() {
    final result = _result;
    final label = result == null ? '' : (NukeService.attributeLabels[result.attribute] ?? result.attribute);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Stack(
          alignment: Alignment.center,
          children: [
            BurstFx(
              colors: [AppColors.nukeOrange, AppColors.neonRed],
              particleCount: 26,
              radius: 110,
              duration: Duration(milliseconds: 900),
            ),
            NeonIconBadge(emoji: '☢️', accent: AppColors.nukeOrange, size: 90, circular: true),
          ],
        ),
        const SizedBox(height: 14),
        Text('💥 IMPACT!', style: AppTypography.title.copyWith(color: AppColors.nukeOrange)),
        const SizedBox(height: 8),
        Text('Someone just lost ${NukeService.damagePerNuke} points in:',
            textAlign: TextAlign.center, style: AppTypography.bodyMuted),
        const SizedBox(height: 6),
        Text(label, style: AppTypography.hero.copyWith(fontSize: 26)),
        const SizedBox(height: 4),
        Text('-${NukeService.damagePerNuke}',
            style: AppTypography.hero.copyWith(fontSize: 34, color: AppColors.nukeOrange)),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: GradientButton(
            label: 'Done',
            gradient: AppColors.nukeOrangeGradient,
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ],
    );
  }
}

/// A short "3... 2... 1... ☢️ NUKE!" beat before the impact reveals —
/// same finite, self-contained `Timer.periodic` pattern as Life
/// Battles' countdown, kept local here since the copy differs.
class _NukeCountdown extends StatefulWidget {
  const _NukeCountdown({required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<_NukeCountdown> createState() => _NukeCountdownState();
}

class _NukeCountdownState extends State<_NukeCountdown> {
  static const _steps = ['3', '2', '1', '☢️ NUKE!'];
  int _i = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 350), (t) {
      if (_i < _steps.length - 1) {
        setState(() => _i++);
        return;
      }
      t.cancel();
      Future.delayed(const Duration(milliseconds: 300), widget.onComplete);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      transitionBuilder: (child, anim) =>
          ScaleTransition(scale: anim, child: FadeTransition(opacity: anim, child: child)),
      child: Text(
        _steps[_i],
        key: ValueKey(_i),
        style: AppTypography.hero
            .copyWith(fontSize: _i == _steps.length - 1 ? 30 : 48, color: AppColors.nukeOrange),
      ),
    );
  }
}

/// Balance / cost / remaining breakdown shown before any coin spend —
/// reused by Nuke's confirm sheet; kept local rather than in a shared
/// widgets file since it's specific to this screen's flows for now.
class _CoinLedgerCard extends StatelessWidget {
  const _CoinLedgerCard({
    required this.balance,
    required this.cost,
    required this.remaining,
    required this.accent,
  });

  final int balance;
  final int cost;
  final int remaining;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHigh,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          _row('Current balance', '$balance 🪙', AppTheme.textMuted),
          const SizedBox(height: 6),
          _row('Cost', '-$cost 🪙', accent),
          const Divider(height: 18),
          _row('Remaining', '$remaining 🪙', remaining < 0 ? AppColors.danger : AppColors.green),
        ],
      ),
    );
  }

  Widget _row(String label, String value, Color color) {
    return Row(
      children: [
        Expanded(child: Text(label, style: AppTypography.bodyMuted)),
        Text(value, style: AppTypography.body.copyWith(fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }
}

/// Lists every currently-damaged attribute on the local user's own
/// profile with a per-attribute cure button, or a reassuring empty
/// state when nothing is damaged.
class _MyDamageCard extends StatelessWidget {
  const _MyDamageCard({
    required this.profile,
    required this.balance,
    required this.onCure,
  });

  final UserProfile profile;
  final int balance;
  final void Function(String attribute) onCure;

  @override
  Widget build(BuildContext context) {
    final damaged = profile.nukeDamage.entries
        .where((entry) => entry.value < 0)
        .toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    if (damaged.isEmpty) {
      return AppCard(
        child: Row(
          children: [
            const Icon(Icons.health_and_safety_rounded,
                color: AppColors.green),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "You're undamaged — no nuke hits active.",
                style: AppTypography.body,
              ),
            ),
          ],
        ),
      );
    }

    final canAfford = balance >= NukeService.curePotionCost;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < damaged.length; i++) ...[
            if (i > 0) const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        NukeService.attributeLabels[damaged[i].key] ??
                            damaged[i].key,
                        style: AppTypography.body
                            .copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '${damaged[i].value} damage',
                        style: AppTypography.bodyMuted
                            .copyWith(color: AppColors.nukeOrange),
                      ),
                    ],
                  ),
                ),
                _GlowWrap(
                  color: AppColors.green,
                  dim: !canAfford,
                  child: OutlinedButton(
                    onPressed:
                        canAfford ? () => onCure(damaged[i].key) : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.green,
                      side: const BorderSide(color: AppColors.green),
                    ),
                    child: const Text(
                        'CURE +${NukeService.healPerPotion} (${NukeService.curePotionCost})'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _NukeTargetRow extends StatelessWidget {
  const _NukeTargetRow({required this.profile, required this.onNuke});

  final UserProfile profile;
  final VoidCallback onNuke;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: ProfileImage(
              photo: profile.privacy.showPhotos ? profile.profilePhoto : null,
              label: profile.displayName,
              height: 48,
              width: 48,
              borderRadius: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.displayName.isEmpty
                      ? 'Anonymous'
                      : profile.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(fontWeight: FontWeight.w800),
                ),
                if (profile.privacy.showCountry)
                  Text(profile.country, style: AppTypography.caption),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _GlowWrap(
            color: AppColors.nukeOrange,
            child: OutlinedButton.icon(
              onPressed: onNuke,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.nukeOrange,
                side: const BorderSide(color: AppColors.nukeOrange),
              ),
              icon: const Text('☢️', style: TextStyle(fontSize: 14)),
              label: const Text('NUKE'),
            ),
          ),
        ],
      ),
    );
  }
}

class _NukeHistoryRow extends StatelessWidget {
  const _NukeHistoryRow({required this.event});

  final NukeEvent event;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceHigh,
          borderRadius: AppRadius.lgRadius,
        ),
        child: Row(
          children: [
            const Text('☢️', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Nuked ${event.targetName} — '
                '${NukeService.attributeLabels[event.attribute] ?? event.attribute} '
                '${event.damage}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body,
              ),
            ),
            Text(
              DateFormat.MMMd().format(event.createdAt),
              style: AppTypography.caption,
            ),
          ],
        ),
      ),
    );
  }
}

/// Wraps a button-shaped child in a two-layer neon glow — a plain
/// Material `OutlinedButton`/`FilledButton` shadow isn't vivid enough
/// to read as "neon" against this screen's dark background, matching
/// the glow `NeonIconBadge` already gives the hero icon above. [dim]
/// mutes the glow (no blur, low alpha) for a disabled button, same
/// spirit as `NeonIconBadge.dim`.
class _GlowWrap extends StatelessWidget {
  const _GlowWrap({required this.color, required this.child, this.dim = false});

  final Color color;
  final Widget child;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.pillRadius,
        boxShadow: dim
            ? null
            : [
                BoxShadow(
                    color: color.withValues(alpha: 0.55),
                    blurRadius: 18,
                    spreadRadius: 1),
                BoxShadow(
                    color: color.withValues(alpha: 0.28),
                    blurRadius: 32,
                    spreadRadius: 2),
              ],
      ),
      child: child,
    );
  }
}

/// A hard-to-miss, pulsing prompt for Home/Me — "N nukes survived" plus
/// a per-attribute Buy Heal button for anything currently damaged.
/// Deliberately eye-catching (a looping glow, not a static badge) since
/// its whole point is nudging a spend on a cure potion, not just
/// reporting a stat. Renders nothing when there's no damage and nothing
/// to report — a heal button with nothing to heal doesn't belong on
/// every screen regardless of state.
class NukeStatusBanner extends StatefulWidget {
  const NukeStatusBanner({
    super.key,
    required this.profile,
    required this.balance,
    required this.onCure,
  });

  final UserProfile profile;
  final int balance;
  final void Function(String attribute) onCure;

  @override
  State<NukeStatusBanner> createState() => _NukeStatusBannerState();
}

class _NukeStatusBannerState extends State<NukeStatusBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final damaged = widget.profile.nukeDamage.entries
        .where((entry) => entry.value < 0)
        .toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    if (damaged.isEmpty && widget.profile.nukesSurvived == 0) {
      return const SizedBox.shrink();
    }

    final canAfford = widget.balance >= NukeService.curePotionCost;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = _pulse.value;
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh,
            borderRadius: AppRadius.lgRadius,
            border: Border.all(
                color: AppColors.nukeOrange.withValues(alpha: 0.6 + t * 0.4),
                width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: AppColors.nukeOrange.withValues(alpha: 0.25 + t * 0.35),
                  blurRadius: 12 + t * 16,
                  spreadRadius: 1 + t * 2),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: child,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('☢️', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${widget.profile.nukesSurvived} nukes survived',
                  style: AppTypography.heading,
                ),
              ),
            ],
          ),
          if (damaged.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (var i = 0; i < damaged.length; i++)
              Padding(
                padding: EdgeInsets.only(bottom: i == damaged.length - 1 ? 0 : 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${NukeService.attributeLabels[damaged[i].key] ?? damaged[i].key} '
                        '(${damaged[i].value})',
                        style: AppTypography.body.copyWith(color: AppColors.nukeOrange),
                      ),
                    ),
                    _GlowWrap(
                      color: AppColors.green,
                      dim: !canAfford,
                      child: OutlinedButton(
                        onPressed: canAfford ? () => widget.onCure(damaged[i].key) : null,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.green,
                          side: const BorderSide(color: AppColors.green),
                        ),
                        child: const Text('BUY HEAL (${NukeService.curePotionCost})'),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// "Use a cure potion?" confirm (balance/cost/remaining, or an
/// insufficient-coins state) → "🧪 HEALING... +1 +2 +3" → "✨ RESTORED" —
/// opened via `showCureRevealSheet`. Calls the real
/// `AppController.cureDamage` only after confirmation (same
/// balance/eligibility validation as everywhere else, see
/// `NukeService.assertCanCure`); only shows the restored state once the
/// wallet balance actually dropped by the cure's cost, never
/// optimistically. On a rejected cure (e.g. a balance race), closes and
/// lets the existing toast/SnackBar mechanism explain why, matching
/// `_NukeConfirmSheet`'s failure handling.
class _CureRevealSheet extends ConsumerStatefulWidget {
  const _CureRevealSheet({required this.attribute});

  final String attribute;

  @override
  ConsumerState<_CureRevealSheet> createState() => _CureRevealSheetState();
}

enum _CurePhase { confirm, insufficientCoins, healing, restored }

class _CureRevealSheetState extends ConsumerState<_CureRevealSheet> {
  late _CurePhase _phase;
  int _healedSoFar = 0;
  Timer? _tickTimer;

  @override
  void initState() {
    super.initState();
    final balance = ref.read(appControllerProvider).wallet.balance;
    _phase = balance < NukeService.curePotionCost ? _CurePhase.insufficientCoins : _CurePhase.confirm;
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  void _startHealing() {
    HapticFeedback.mediumImpact();
    playSfx(AppSfx.cureStart);
    setState(() => _phase = _CurePhase.healing);
    _tickTimer = Timer.periodic(const Duration(milliseconds: 260), (t) {
      if (_healedSoFar >= NukeService.healPerPotion) {
        t.cancel();
        _finishHealing();
        return;
      }
      setState(() => _healedSoFar++);
    });
  }

  Future<void> _finishHealing() async {
    final controller = ref.read(appControllerProvider);
    final before = controller.wallet.balance;
    await controller.cureDamage(widget.attribute);
    if (!mounted) return;
    if (controller.wallet.balance >= before) {
      // Rejected after confirmation (e.g. a balance race) — close and let
      // the existing toast/SnackBar mechanism explain why, matching
      // `_NukeConfirmSheet`'s failure handling.
      Navigator.pop(context);
      return;
    }
    HapticFeedback.mediumImpact();
    playSfx(AppSfx.cureComplete);
    setState(() => _phase = _CurePhase.restored);
  }

  @override
  Widget build(BuildContext context) {
    final balance = ref.watch(appControllerProvider).wallet.balance;
    final label = NukeService.attributeLabels[widget.attribute] ?? widget.attribute;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: switch (_phase) {
          _CurePhase.confirm => _confirmContent(balance, label),
          _CurePhase.insufficientCoins => _insufficientContent(balance),
          _CurePhase.healing => _healingContent(label),
          _CurePhase.restored => _restoredContent(label),
        },
      ),
    );
  }

  Widget _confirmContent(int balance, String label) {
    final remaining = balance - NukeService.curePotionCost;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const NeonIconBadge(icon: Icons.science_rounded, accent: AppColors.green, size: 72, circular: true),
        const SizedBox(height: 14),
        Text('USE A CURE POTION?', textAlign: TextAlign.center, style: AppTypography.title.copyWith(color: AppColors.green)),
        const SizedBox(height: 6),
        Text('Restore +${NukeService.healPerPotion} to $label', textAlign: TextAlign.center, style: AppTypography.bodyMuted),
        const SizedBox(height: 16),
        _CoinLedgerCard(balance: balance, cost: NukeService.curePotionCost, remaining: remaining, accent: AppColors.green),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL'))),
            const SizedBox(width: 10),
            Expanded(
              child: GradientButton(
                label: 'HEAL',
                gradient: AppColors.greenGradient,
                foregroundColor: Colors.black,
                onPressed: _startHealing,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _insufficientContent(int balance) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const NeonIconBadge(icon: Icons.monetization_on_rounded, accent: AppColors.textMuted, size: 72, circular: true),
        const SizedBox(height: 14),
        Text('🪙 NOT ENOUGH COINS', style: AppTypography.title),
        const SizedBox(height: 6),
        Text('You need ${NukeService.curePotionCost} coins.\nYou have $balance.',
            textAlign: TextAlign.center, style: AppTypography.bodyMuted),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: GradientButton(
            label: 'Get Free Coins',
            gradient: AppColors.goldGradient,
            foregroundColor: Colors.black,
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => GetCoinsScreen()));
            },
          ),
        ),
        const SizedBox(height: 8),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
    );
  }

  Widget _healingContent(String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const NeonIconBadge(icon: Icons.science_rounded, accent: AppColors.green, size: 80, circular: true),
        const SizedBox(height: 16),
        Text('🧪 HEALING...', style: AppTypography.title.copyWith(color: AppColors.green)),
        const SizedBox(height: 6),
        Text(label, style: AppTypography.bodyMuted),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: FadeTransition(opacity: anim, child: child)),
          child: Text(
            '+$_healedSoFar',
            key: ValueKey(_healedSoFar),
            style: AppTypography.hero.copyWith(fontSize: 34, color: AppColors.green),
          ),
        ),
      ],
    );
  }

  Widget _restoredContent(String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Stack(
          alignment: Alignment.center,
          children: [
            BurstFx(
              colors: [AppColors.green, AppColors.blue],
              particleCount: 20,
              radius: 90,
              duration: Duration(milliseconds: 800),
            ),
            NeonIconBadge(icon: Icons.favorite_rounded, accent: AppColors.green, size: 80, circular: true),
          ],
        ),
        const SizedBox(height: 14),
        Text('✨ RESTORED', style: AppTypography.title.copyWith(color: AppColors.green)),
        const SizedBox(height: 6),
        Text('+${NukeService.healPerPotion} to $label', style: AppTypography.bodyMuted),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: GradientButton(
            label: 'Nice!',
            gradient: AppColors.greenGradient,
            foregroundColor: Colors.black,
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ],
    );
  }
}
