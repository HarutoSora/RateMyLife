import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/models.dart';
import '../../domain/services/progression_service.dart';
import '../../domain/services/reward_service.dart';
import '../state/app_state.dart';
import '../widgets/brand_widgets.dart';
import '../widgets/fx_widgets.dart';
import '../widgets/widgets.dart';

enum _Phase { choosing, locking, revealing, revealed }

class BattleScreen extends ConsumerStatefulWidget {
  const BattleScreen({super.key});

  @override
  ConsumerState<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends ConsumerState<BattleScreen>
    with TickerProviderStateMixin {
  static const _taglines = [
    "WHO'S WINNING AT LIFE? 👀",
    "LET'S SETTLE THIS.",
    'READY?',
    'MAKE YOUR CALL.',
    'NO PRESSURE... 😈',
    'TWO LIVES. ONE WINNER.',
    'JUDGE WISELY.',
  ];
  static const _closeCallLines = [
    'THAT WAS CLOSE.',
    'TOO CLOSE TO CALL.',
    'A REAL TOSS-UP.',
  ];
  static const _underdogLines = [
    'YOU REALLY PICKED THAT ONE? 💀',
    'INTERESTING CHOICE.',
    'BOLD PICK.',
  ];
  static const _clearLines = [
    'THE NUMBERS HAVE SPOKEN.',
    'CALLED IT.',
    'NO SURPRISE THERE.',
  ];

  final _random = Random();
  late final AnimationController _introController;
  late final AnimationController _ambientController;

  Battle? _battle;
  bool _loading = true;
  bool _switching = false;
  _Phase _phase = _Phase.choosing;
  String? _selectedId;
  bool _showIntro = false;
  bool _introFadeOut = false;
  int _introsShown = 0;
  String _tagline = _taglines.first;
  String _reaction = '';

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _ambientController =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPending());
  }

  @override
  void dispose() {
    _introController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  T _pick<T>(List<T> items) => items[_random.nextInt(items.length)];

  Future<void> _loadPending() async {
    final battle = await ref.read(appControllerProvider).ensureBattle();
    if (!mounted) return;
    setState(() => _loading = false);
    _startBattle(battle);
  }

  void _startBattle(Battle? battle) {
    if (!mounted) return;
    setState(() {
      _battle = battle;
      _phase = _Phase.choosing;
      _selectedId = null;
      _reaction = '';
      _tagline = _pick(_taglines);
    });
    if (battle != null && _introsShown < 3) {
      _introsShown++;
      setState(() {
        _showIntro = true;
        _introFadeOut = false;
      });
      _introController
        ..reset()
        ..forward();
      playSfx(AppSfx.battleIntro);
      // Entrance finishes forming around 1000ms; hold the fully-formed
      // "VS" on screen for a while longer before fading it out, rather
      // than yanking it away the instant the entrance animation ends.
      Future.delayed(const Duration(milliseconds: 2400), () {
        if (!mounted || !_showIntro) return;
        setState(() => _introFadeOut = true);
        Future.delayed(const Duration(milliseconds: 320), () {
          if (!mounted) return;
          setState(() {
            _showIntro = false;
            _introFadeOut = false;
          });
        });
      });
    } else {
      _showIntro = false;
    }
  }

  void _skipIntro() {
    if (!_showIntro) return;
    setState(() {
      _showIntro = false;
      _introFadeOut = false;
    });
  }

  Future<void> _next({BattleType type = BattleType.random}) async {
    if (_switching) return;
    _switching = true;
    final battle =
        await ref.read(appControllerProvider).generateBattle(type: type);
    _switching = false;
    if (!mounted) return;
    _startBattle(battle);
  }

  Future<void> _choose(UserProfile profile, BattleResult result) async {
    final battle = _battle;
    if (battle == null || _phase != _Phase.choosing) return;
    HapticFeedback.selectionClick();
    playSfx(AppSfx.battleSelect);
    setState(() {
      _selectedId = profile.id;
      _phase = _Phase.locking;
    });
    await Future.delayed(const Duration(milliseconds: 320));
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    playSfx(AppSfx.battleLockIn);
    await ref.read(appControllerProvider).voteBattle(battle, profile.id);
    if (!mounted) return;

    final diff = (result.percentageForA - result.percentageForB).abs();
    final pickedA = profile.id == battle.profileAId;
    final pickedWinnerSide = pickedA
        ? result.percentageForA >= result.percentageForB
        : result.percentageForB >= result.percentageForA;
    setState(() {
      _phase = _Phase.revealing;
      _reaction = diff <= 10
          ? _pick(_closeCallLines)
          : (pickedWinnerSide ? _pick(_clearLines) : _pick(_underdogLines));
    });
    playSfx(AppSfx.battleReveal);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      playSfx(AppSfx.battleReward);
      setState(() => _phase = _Phase.revealed);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final battle = _battle;

    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (battle == null) {
      body = const Padding(
        padding: EdgeInsets.all(20),
        child: EmptyState(
          icon: Icons.sports_martial_arts_rounded,
          title: 'No battles available yet',
          subtitle:
              'Life Battles need at least two public, discoverable profiles to judge. Check back once more people join Discover.',
        ),
      );
    } else {
      body = _buildBattle(context, state, battle);
    }

    final a = battle == null ? null : state.profileById(battle.profileAId);
    final b = battle == null ? null : state.profileById(battle.profileBId);

    return Scaffold(
      appBar: AppBar(title: const Text('Life Battles')),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.heroGlow),
        child: Stack(
          children: [
            Positioned.fill(child: body),
            if (_showIntro && battle != null)
              Positioned.fill(
                child: AnimatedOpacity(
                  opacity: _introFadeOut ? 0 : 1,
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOut,
                  child: _VsIntroOverlay(
                    controller: _introController,
                    a: a,
                    b: b,
                    onSkip: _skipIntro,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBattle(BuildContext context, AppController state, Battle battle) {
    final a = state.profileById(battle.profileAId);
    final b = state.profileById(battle.profileBId);
    if (a == null || b == null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'This matchup is no longer available',
          subtitle: 'One of these profiles is no longer eligible to battle.',
          action: GradientButton(
              label: 'Next Battle',
              gradient: AppColors.purpleGradient,
              onPressed: () => _next()),
        ),
      );
    }
    final result = state.battleResultFor(battle);
    final categories = state.battleCategoryComparison(battle);
    final revealPhase = _phase == _Phase.revealing || _phase == _Phase.revealed;
    final aWinner = result.percentageForA >= result.percentageForB;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      children: [
        _ModeSelector(current: battle.type, onSelect: (type) => _next(type: type)),
        const SizedBox(height: 14),
        Center(
          child: Text(_tagline,
              textAlign: TextAlign.center,
              style: AppTypography.eyebrow.copyWith(color: AppColors.gold, fontSize: 13)),
        ),
        const SizedBox(height: 12),
        _vsHeader(),
        if (_phase == _Phase.revealing)
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Center(child: _Countdown()),
          ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _BattleCard(
                profile: a,
                accent: AppColors.blue,
                categories: categories,
                sideIndex: 0,
                selected: _selectedId == a.id,
                dimmed: _selectedId != null && _selectedId != a.id,
                locking: _phase == _Phase.locking && _selectedId == a.id,
                revealed: revealPhase,
                percentage: result.percentageForA,
                isWinner: revealPhase && aWinner,
                onTap: _phase == _Phase.choosing ? () => _choose(a, result) : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _BattleCard(
                profile: b,
                accent: AppColors.pink,
                categories: categories,
                sideIndex: 1,
                selected: _selectedId == b.id,
                dimmed: _selectedId != null && _selectedId != b.id,
                locking: _phase == _Phase.locking && _selectedId == b.id,
                revealed: revealPhase,
                percentage: result.percentageForB,
                isWinner: revealPhase && !aWinner,
                onTap: _phase == _Phase.choosing ? () => _choose(b, result) : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (!revealPhase)
          Center(
            child: Text('Tap a profile to cast your vote.',
                textAlign: TextAlign.center, style: AppTypography.bodyMuted),
          )
        else
          _AudienceSplitPanel(result: result, a: a, b: b),
        const SectionTitle('Category Breakdown'),
        AppCard(
          child: Column(
            children: [
              for (final row in categories) _CategoryBar(label: row.$1, a: row.$2, b: row.$3),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (_phase == _Phase.revealed) ...[
          _RewardPanel(state: state, reaction: _reaction),
          const SizedBox(height: 20),
        ],
        if (_phase == _Phase.revealed)
          _PulseNextButton(controller: _ambientController, onPressed: () => _next())
        else if (_phase == _Phase.choosing)
          Center(
            child: TextButton(onPressed: () => _next(), child: const Text('Skip this matchup')),
          ),
      ],
    );
  }

  Widget _vsHeader() {
    return Center(
      child: PulseGlow(
        controller: _ambientController,
        color: AppColors.neonRed,
        child: Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
              shape: BoxShape.circle, gradient: AppColors.neonRedGradient),
          child: Text('VS',
              style: AppTypography.button.copyWith(color: Colors.white, fontSize: 13)),
        ),
      ),
    );
  }
}

/// A short (~900ms), skippable "VS" intro shown for the first few
/// battles of a session — title flash, avatars sliding in, glowing VS,
/// one particle burst. Purely presentational; battle generation already
/// happened before this is shown.
class _VsIntroOverlay extends StatelessWidget {
  const _VsIntroOverlay({
    required this.controller,
    required this.a,
    required this.b,
    required this.onSkip,
  });

  final Animation<double> controller;
  final UserProfile? a;
  final UserProfile? b;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onSkip,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final t = controller.value;
          final titleOpacity = (t / 0.3).clamp(0.0, 1.0);
          final slideT = ((t - 0.25) / 0.55).clamp(0.0, 1.0);
          final burstT = ((t - 0.35) / 0.4).clamp(0.0, 1.0);
          return Container(
            color: AppColors.background.withValues(alpha: 0.92 * titleOpacity),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (burstT > 0 && burstT < 1)
                  const BurstFx(
                    colors: [AppColors.gold, AppColors.pink, AppColors.blue],
                    particleCount: 22,
                    radius: 140,
                    duration: Duration(milliseconds: 500),
                  ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Opacity(
                      opacity: titleOpacity,
                      child: Text('⚡ LIFE BATTLE ⚡',
                          style:
                              AppTypography.eyebrow.copyWith(color: AppColors.gold, fontSize: 15)),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.translate(
                          offset: Offset(-50 * (1 - slideT), 0),
                          child: Opacity(opacity: slideT, child: _avatar(a, AppColors.blue)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Transform.scale(
                            scale: 0.5 + Curves.elasticOut.transform(slideT) * 0.5,
                            child: Text(
                              'VS',
                              style: AppTypography.hero.copyWith(
                                fontSize: 38,
                                color: AppColors.neonRed,
                                shadows: [
                                  Shadow(
                                      color: AppColors.neonRed.withValues(alpha: 0.8),
                                      blurRadius: 22),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Transform.translate(
                          offset: Offset(50 * (1 - slideT), 0),
                          child: Opacity(opacity: slideT, child: _avatar(b, AppColors.pink)),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _avatar(UserProfile? p, Color ring) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ring, width: 2),
        boxShadow: [BoxShadow(color: ring.withValues(alpha: 0.6), blurRadius: 16)],
      ),
      child: ClipOval(
        child: p == null
            ? const SizedBox(width: 64, height: 64, child: ColoredBox(color: AppColors.surfaceHigh))
            : ProfileImage(photo: p.profilePhoto, label: p.displayName, height: 64, width: 64),
      ),
    );
  }
}

/// A compact 3-2-1-WINNER beat shown for the ~900ms `revealing` phase,
/// between the vote landing and the reward panel appearing.
class _Countdown extends StatefulWidget {
  const _Countdown();

  @override
  State<_Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<_Countdown> {
  static const _steps = ['3', '2', '1', '🏆 WINNER 🏆'];
  int _i = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 210), (t) {
      if (_i >= _steps.length - 1) {
        t.cancel();
        return;
      }
      if (mounted) setState(() => _i++);
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
            .copyWith(fontSize: _i == _steps.length - 1 ? 22 : 34, color: AppColors.gold),
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.current, required this.onSelect});

  final BattleType current;
  final ValueChanged<BattleType> onSelect;

  static const _modes = [
    (BattleType.random, Icons.casino_rounded, 'RANDOM', 'Anything can happen.', AppColors.blue),
    (BattleType.trending, Icons.local_fire_department_rounded, 'TRENDING',
        'Judge the lives everyone is watching.', AppColors.gold),
    (BattleType.country, Icons.public_rounded, 'MY COUNTRY', 'How does your country stack up?',
        AppColors.green),
  ];

  @override
  Widget build(BuildContext context) {
    final selected = _modes.firstWhere((m) => m.$1 == current, orElse: () => _modes.first);
    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < _modes.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(child: _chip(_modes[i], _modes[i].$1 == current)),
            ],
          ],
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            selected.$4,
            key: ValueKey(selected.$3),
            style: AppTypography.caption,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _chip((BattleType, IconData, String, String, Color) mode, bool active) {
    return GestureDetector(
      onTap: () => onSelect(mode.$1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: AppRadius.pillRadius,
          border: Border.all(color: active ? mode.$5 : AppColors.border, width: active ? 1.6 : 1),
          color: active ? mode.$5.withValues(alpha: 0.16) : AppColors.surfaceSolid,
          boxShadow:
              active ? [BoxShadow(color: mode.$5.withValues(alpha: 0.45), blurRadius: 14)] : null,
        ),
        child: Column(
          children: [
            Icon(mode.$2, color: active ? mode.$5 : AppColors.textMuted, size: 20),
            const SizedBox(height: 4),
            Text(mode.$3,
                style: AppTypography.caption
                    .copyWith(color: active ? mode.$5 : AppColors.textMuted, fontSize: 10.5)),
          ],
        ),
      ),
    );
  }
}

class _BattleCard extends StatelessWidget {
  const _BattleCard({
    required this.profile,
    required this.accent,
    required this.categories,
    required this.sideIndex,
    required this.selected,
    required this.dimmed,
    required this.locking,
    required this.revealed,
    required this.percentage,
    required this.isWinner,
    required this.onTap,
  });

  final UserProfile profile;
  final Color accent;
  final List<(String, int, int)> categories;
  final int sideIndex;
  final bool selected;
  final bool dimmed;
  final bool locking;
  final bool revealed;
  final int percentage;
  final bool isWinner;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final glowColor = revealed && isWinner ? AppColors.gold : accent;
    final emphasized = selected || (revealed && isWinner);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: selected ? 1.04 : (dimmed ? 0.96 : 1),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutBack,
        child: AnimatedOpacity(
          opacity: dimmed ? 0.55 : 1,
          duration: const Duration(milliseconds: 280),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                decoration: BoxDecoration(
                  borderRadius: AppRadius.lgRadius,
                  border: Border.all(color: glowColor, width: emphasized ? 2 : 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: glowColor.withValues(alpha: emphasized ? 0.55 : 0.25),
                      blurRadius: emphasized ? 22 : 10,
                      spreadRadius: 1,
                    ),
                  ],
                  color: AppColors.surfaceSolid,
                ),
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: AppRadius.mdRadius,
                      child: Stack(
                        children: [
                          ProfileImage(photo: profile.profilePhoto, label: profile.displayName, height: 150),
                          if (revealed)
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: DecoratedBox(
                                decoration:
                                    BoxDecoration(color: Colors.black.withValues(alpha: 0.62)),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Center(
                                    child: AnimatedCountUp(
                                      value: percentage.toDouble(),
                                      suffix: '%',
                                      style: TextStyle(
                                        color: isWinner ? AppColors.gold : Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(profile.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    AnimatedCountUp(
                        value: profile.score.overall.toDouble(),
                        style: AppTypography.hero.copyWith(fontSize: 30, color: glowColor)),
                    Text('LIFE SCORE', style: AppTypography.caption),
                    const SizedBox(height: 8),
                    for (final row in categories)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Expanded(
                                child: Text(row.$1,
                                    style: AppTypography.caption, overflow: TextOverflow.ellipsis)),
                            AnimatedCountUp(
                              value: (sideIndex == 0 ? row.$2 : row.$3).toDouble(),
                              style: AppTypography.caption
                                  .copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    if (selected) ...[
                      const SizedBox(height: 6),
                      Text('🔥 YOUR PICK 🔥',
                          style: AppTypography.caption.copyWith(color: AppColors.gold)),
                    ],
                  ],
                ),
              ),
              if (locking)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Center(
                      child: BurstFx(
                        colors: [accent, AppColors.gold],
                        particleCount: 14,
                        radius: 70,
                        duration: const Duration(milliseconds: 380),
                      ),
                    ),
                  ),
                ),
              if (revealed && isWinner)
                const Positioned.fill(
                  child: IgnorePointer(
                    child: Center(
                      child: BurstFx(
                        colors: [AppColors.gold, Colors.white],
                        particleCount: 26,
                        radius: 110,
                        duration: Duration(milliseconds: 900),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AudienceSplitPanel extends StatelessWidget {
  const _AudienceSplitPanel({required this.result, required this.a, required this.b});

  final BattleResult result;
  final UserProfile a;
  final UserProfile b;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.groups_rounded, color: AppColors.cyan, size: 18),
              const SizedBox(width: 6),
              Text('ESTIMATED CROWD PICK',
                  style: AppTypography.eyebrow.copyWith(color: AppColors.cyan)),
            ],
          ),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: result.percentageForA.toDouble()),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) {
              final aShare = v.round().clamp(2, 98);
              return Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: 14,
                      child: Row(
                        children: [
                          Expanded(flex: aShare, child: const ColoredBox(color: AppColors.blue)),
                          Expanded(
                              flex: 100 - aShare, child: const ColoredBox(color: AppColors.pink)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text('$aShare% ${a.displayName}',
                            style: AppTypography.caption.copyWith(color: AppColors.blue)),
                      ),
                      Expanded(
                        child: Text('${100 - aShare}% ${b.displayName}',
                            textAlign: TextAlign.right,
                            style: AppTypography.caption.copyWith(color: AppColors.pink)),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 6),
          Text('Estimated from the Life Score difference — not a live voter count.',
              style: AppTypography.caption.copyWith(fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }
}

class _RewardPanel extends StatelessWidget {
  const _RewardPanel({required this.state, required this.reaction});

  final AppController state;
  final String reaction;

  /// Mirrors `AchievementService.isUnlocked`'s `battle_judge` threshold —
  /// that service stores the rule as a plain comparison, not a named
  /// constant, so this is display-only sugar and intentionally duplicates
  /// the literal 10 rather than reaching into achievement internals.
  static const _battleJudgeTarget = 10;

  @override
  Widget build(BuildContext context) {
    final xp = ProgressionService.xpRewards[XpReason.battleVoted] ?? 0;
    final coins = RewardService.coinRewards[XpReason.battleVoted] ?? 0;
    final judged = state.battlesVotedCount.clamp(0, _battleJudgeTarget);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (reaction.isNotEmpty)
            Center(
              child: Text(reaction,
                  style: AppTypography.heading.copyWith(color: AppColors.gold),
                  textAlign: TextAlign.center),
            ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _rewardChip(icon: Icons.bolt_rounded, color: AppColors.blue, value: xp, label: 'XP'),
              const SizedBox(width: 24),
              _rewardChip(
                  icon: Icons.monetization_on_rounded, color: AppColors.gold, value: coins, label: 'COINS'),
            ],
          ),
          if (judged < _battleJudgeTarget) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.military_tech_rounded, color: AppColors.green, size: 16),
                const SizedBox(width: 6),
                Text('BATTLE JUDGE', style: AppTypography.caption.copyWith(color: AppColors.green)),
                const Spacer(),
                Text('$judged / $_battleJudgeTarget', style: AppTypography.caption),
              ],
            ),
            const SizedBox(height: 6),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: judged / _battleJudgeTarget),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: v,
                  minHeight: 8,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation(AppColors.green),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _rewardChip(
      {required IconData icon, required Color color, required int value, required String label}) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            BurstFx(colors: [color], particleCount: 10, radius: 34, duration: const Duration(milliseconds: 700)),
            Icon(icon, color: color, size: 26),
          ],
        ),
        const SizedBox(height: 4),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value.toDouble()),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) =>
              Text('+${v.round()}', style: AppTypography.title.copyWith(color: color, fontSize: 22)),
        ),
        Text(label, style: AppTypography.caption),
      ],
    );
  }
}

class _PulseNextButton extends StatelessWidget {
  const _PulseNextButton({required this.controller, required this.onPressed});

  final Animation<double> controller;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final t = (sin(controller.value * 2 * pi) + 1) / 2;
        return Container(
          decoration: BoxDecoration(
            borderRadius: AppRadius.pillRadius,
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.35 + t * 0.35),
                blurRadius: 14 + t * 16,
                spreadRadius: 1 + t * 2,
              ),
            ],
          ),
          child: child,
        );
      },
      child: GradientButton(
        label: 'Next Battle',
        icon: Icons.local_fire_department_rounded,
        gradient: AppColors.goldGradient,
        foregroundColor: Colors.black,
        onPressed: onPressed,
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({required this.label, required this.a, required this.b});

  final String label;
  final int a;
  final int b;

  @override
  Widget build(BuildContext context) {
    final total = (a + b).clamp(1, 200);
    final aShare = ((a / total) * 100).round().clamp(2, 98);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('$a', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.blue)),
              Expanded(
                child: Center(
                  child: Text(label, style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                ),
              ),
              Text('$b', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.pink)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  Expanded(flex: aShare, child: const ColoredBox(color: AppColors.blue)),
                  Expanded(flex: 100 - aShare, child: const ColoredBox(color: AppColors.pink)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
