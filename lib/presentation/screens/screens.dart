import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/models.dart';
import '../../data/reference/world_data.dart';
import '../../domain/scoring/life_score_service.dart';
import '../../domain/services/achievement_service.dart';
import '../../domain/services/advice_service.dart';
import '../../domain/services/cosmetic_service.dart';
import '../../domain/services/nuke_service.dart';
import '../../domain/services/photo_quality_service.dart';
import '../../domain/services/photo_service.dart';
import '../state/app_state.dart';
import '../widgets/ad_widgets.dart';
import '../widgets/brand_widgets.dart';
import '../widgets/fx_widgets.dart';
import '../widgets/widgets.dart';
import 'battle_screen.dart';
import 'get_coins_screen.dart';
import 'nuke_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.heroGlow),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppLogo(size: 160),
              const SizedBox(height: 22),
              Text('RATE MY LIFE',
                  style: AppTypography.title.copyWith(fontSize: 26)),
              const SizedBox(height: 6),
              Text('GAME · SOCIAL · YOU',
                  style: AppTypography.eyebrow.copyWith(color: AppColors.gold)),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _OnboardingPage(
        icon: Icons.psychology_alt_outlined,
        title: 'RATE MY LIFE',
        body:
            "Think you're doing well?\n\nLet's see what everyone else thinks.",
        button: 'START',
        useLogo: true,
      ),
      const _OnboardingPage(
        icon: Icons.account_circle_outlined,
        imageAsset: 'assets/branding/onboarding_profile.png',
        title: 'YOUR LIFE.\nYOUR PROFILE.\nYOUR SCORE.',
        body:
            'Create an anonymous profile and see how people rate your lifestyle.',
        button: 'NEXT',
      ),
      const _OnboardingPage(
        icon: Icons.photo_library_outlined,
        imageAsset: 'assets/branding/onboarding_show_life.png',
        title: 'SHOW YOUR LIFE',
        body:
            'Add travel, home, car, hobbies, food, fitness, achievements, and anything that represents your lifestyle.',
        button: 'NEXT',
      ),
      const _OnboardingPage(
        icon: Icons.lock_outline,
        imageAsset: 'assets/branding/onboarding_anonymous.png',
        title: 'STAY ANONYMOUS',
        body: 'No real name required.\n\nYou control what you share.',
        button: 'BUILD MY PROFILE',
      ),
    ];
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.heroGlow),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _controller,
                    onPageChanged: (value) => setState(() => _page = value),
                    children: pages,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < pages.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        width: _page == i ? 28 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: _page == i ? AppColors.gold : AppTheme.border,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                GradientButton(
                  label: pages[_page].button,
                  gradient: AppColors.purpleGradient,
                  onPressed: () {
                    if (_page == pages.length - 1) {
                      ref.read(appControllerProvider).completeOnboarding();
                    } else {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.body,
    required this.button,
    this.useLogo = false,
    this.imageAsset,
  });

  final IconData icon;
  final String title;
  final String body;
  final String button;
  final bool useLogo;
  final String? imageAsset;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Spacer(),
        if (useLogo)
          const AppLogo(size: 140)
        else if (imageAsset != null)
          Image.asset(
            imageAsset!,
            width: 160,
            height: 160,
            cacheWidth: (160 * MediaQuery.devicePixelRatioOf(context)).round(),
            cacheHeight: (160 * MediaQuery.devicePixelRatioOf(context)).round(),
            filterQuality: FilterQuality.medium,
          )
        else
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppTheme.surfaceHigh,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: Icon(icon, color: AppTheme.gold, size: 48),
          ),
        const SizedBox(height: 28),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTypography.hero.copyWith(fontSize: 40, height: 0.98),
        ),
        const SizedBox(height: 18),
        Text(
          body,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 19,
            color: AppTheme.textMuted,
            height: 1.35,
          ),
        ),
        const Spacer(),
      ],
    );
  }
}

class ProfileWizardScreen extends ConsumerStatefulWidget {
  const ProfileWizardScreen({super.key, this.editing});

  final UserProfile? editing;

  @override
  ConsumerState<ProfileWizardScreen> createState() =>
      _ProfileWizardScreenState();
}

class _ProfileWizardScreenState extends ConsumerState<ProfileWizardScreen> {
  int _step = 0;
  late String displayName = widget.editing?.displayName ?? '';
  late int age = widget.editing?.age ?? 24;
  late String country = widget.editing?.country ?? 'Morocco';
  late String city = widget.editing?.city ?? 'Casablanca';
  late String gender = widget.editing?.gender ?? '';
  late String employment = widget.editing?.employmentStatus ?? 'Employed';
  late String jobCategory = widget.editing?.jobCategory ?? 'Technology';
  late String jobTitle = widget.editing?.jobTitle ?? '';
  late int experience = widget.editing?.yearsExperience ?? 2;
  late String education = widget.editing?.educationLevel ?? 'Bachelor';
  late double income = widget.editing?.monthlyIncome ?? 9000;
  late String currency = widget.editing?.currency ?? 'MAD';
  late double savings = widget.editing?.savings ?? 25000;
  late double investments = widget.editing?.investments ?? 0;
  late double debt = widget.editing?.debt ?? 0;
  late double expenses = widget.editing?.monthlyExpenses ?? 4500;
  late String relationship = widget.editing?.relationshipStatus ?? 'Single';
  late String living = widget.editing?.livingSituation ?? 'With family';
  late bool ownsCar = widget.editing?.ownsCar ?? false;
  late String carModel = widget.editing?.carModel ?? '';
  late bool ownsHome = widget.editing?.ownsHome ?? false;
  late String travel = widget.editing?.travelFrequency ?? 'Once/year';
  late String exercise = widget.editing?.exerciseFrequency ?? 'Sometimes';
  late List<String> hobbies = [...?widget.editing?.hobbies];
  late int freeTime = widget.editing?.freeTimeHours ?? 12;
  late int friends = widget.editing?.closeFriends ?? 4;
  late int happiness = widget.editing?.happiness ?? 7;
  late int stress = widget.editing?.stress ?? 5;
  late String goal = widget.editing?.currentGoal ?? '';
  late String bio = widget.editing?.bio ?? '';
  late Map<String, String> socialLinks = {...?widget.editing?.socialLinks};
  late ProfilePrivacy privacy =
      widget.editing?.privacy ?? const ProfilePrivacy();

  bool get _canContinue => switch (_step) {
        0 => displayName.trim().isNotEmpty &&
            age >= 16 &&
            country.trim().isNotEmpty,
        1 => employment.isNotEmpty && jobCategory.isNotEmpty,
        2 => true,
        3 => true,
        4 => bio.trim().length <= 160,
        _ => true,
      };

  @override
  Widget build(BuildContext context) {
    final titles = ['Basic', 'Career', 'Money', 'Lifestyle', 'Life', 'Privacy'];
    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.editing == null ? 'Build Your Life' : 'Edit Profile'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                children: [
                  for (var i = 0; i < titles.length; i++)
                    Expanded(
                      child: Container(
                        height: 4,
                        margin: EdgeInsets.only(
                            right: i == titles.length - 1 ? 0 : 5),
                        decoration: BoxDecoration(
                          color: i <= _step ? AppTheme.gold : AppTheme.border,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text('STEP ${_step + 1} OF ${titles.length}',
                      style: AppTypography.eyebrow
                          .copyWith(color: AppColors.gold)),
                  const SizedBox(height: 4),
                  Text(
                    titles[_step],
                    style: AppTypography.heading,
                  ),
                  const SizedBox(height: 10),
                  _stepBody(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (_step > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _step--),
                        child: const Text('BACK'),
                      ),
                    ),
                  if (_step > 0) const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _canContinue ? _next : null,
                      child: Text(_step == titles.length - 1
                          ? widget.editing == null
                              ? 'PUBLISH'
                              : 'SAVE'
                          : 'NEXT'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepBody() {
    return switch (_step) {
      0 => _basicStep(),
      1 => _careerStep(),
      2 => _moneyStep(),
      3 => _lifestyleStep(),
      4 => _lifeStep(),
      _ => _privacyStep(),
    };
  }

  Widget _basicStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Use a nickname. No real name required.',
              style: AppTypography.bodyMuted),
          const SizedBox(height: 18),
          _textField(
              'Display name', displayName, (value) => displayName = value),
          _numberSlider(
              'Age', age.toDouble(), 16, 70, (value) => age = value.round()),
          _comboBoxField('Country', country, kAllCountries, (value) {
            setState(() {
              country = value;
              currency = _currencyFor(value);
            });
          }),
          _comboBoxField('City', city, kMajorCities[country] ?? const [],
              (value) => setState(() => city = value),
              fieldKey: ValueKey('city-$country')),
          _choice('Gender (optional)', _genderChoiceValue(), const [
            'Male',
            'Female',
            'Non-binary',
            'Prefer not to say',
            'Other'
          ], (value) {
            gender = value == 'Other'
                ? (_isPresetGender(gender) ? '' : gender)
                : value;
          }),
          if (_genderChoiceValue() == 'Other')
            _textField(
                'Describe (optional)', gender, (value) => gender = value),
        ],
      );

  static const _presetGenders = [
    'Male',
    'Female',
    'Non-binary',
    'Prefer not to say'
  ];

  bool _isPresetGender(String value) => _presetGenders.contains(value);

  String _genderChoiceValue() {
    if (gender.isEmpty) return '';
    return _isPresetGender(gender) ? gender : 'Other';
  }

  Widget _careerStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _choice(
              'Employment',
              employment,
              ['Employed', 'Freelancer', 'Founder', 'Student', 'Unemployed'],
              (value) => employment = value),
          _choice(
              'Category',
              jobCategory,
              [
                'Technology',
                'Healthcare',
                'Education',
                'Business',
                'Creative',
                'Finance',
                'Operations',
                'Other'
              ],
              (value) => jobCategory = value),
          const SizedBox(height: 14),
          _textField(
              'Job title (optional)', jobTitle, (value) => jobTitle = value),
          _numberSlider('Years of experience', experience.toDouble(), 0, 25,
              (value) => experience = value.round()),
          _choice(
              'Education',
              education,
              [
                'High School',
                'Diploma',
                'Bachelor',
                'Master',
                'Doctorate',
                'Student'
              ],
              (value) => education = value),
          const SizedBox(height: 14),
          _moneyField('Monthly income', income, (value) => income = value),
          _choice(
              'Currency',
              currency,
              ['MAD', 'EUR', 'USD', 'INR', 'CAD', 'AED', 'BRL', 'CHF'],
              (value) => currency = value),
        ],
      );

  Widget _moneyStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppCard(
            child: Text(
                "You don't have to share anything you're uncomfortable sharing."),
          ),
          const SizedBox(height: 16),
          _moneyField('Savings', savings, (value) => savings = value),
          _moneyField(
              'Investments', investments, (value) => investments = value),
          _moneyField('Debt', debt, (value) => debt = value),
          _moneyField(
              'Monthly expenses', expenses, (value) => expenses = value),
        ],
      );

  Widget _lifestyleStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _choice(
              'Relationship',
              relationship,
              [
                'Single',
                'In a relationship',
                'Engaged',
                'Married',
                'Prefer not to say'
              ],
              (value) => relationship = value),
          _choice(
              'Living situation',
              living,
              ['With family', 'Rents apartment', 'Owns home', 'Shared place'],
              (value) => living = value),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: ownsCar,
            onChanged: (value) => setState(() {
              ownsCar = value;
              if (!value) carModel = '';
            }),
            title: const Text('Owns a car'),
          ),
          if (ownsCar)
            _textField(
                'Car model (optional)', carModel, (value) => carModel = value),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: ownsHome,
            onChanged: (value) => setState(() => ownsHome = value),
            title: const Text('Owns a home'),
          ),
          _choice(
              'Travel frequency',
              travel,
              ['Rarely', 'Once/year', '3-4 times/year', 'Monthly'],
              (value) => travel = value),
          _choice(
              'Exercise frequency',
              exercise,
              ['Rarely', 'Sometimes', 'Weekly', 'Daily'],
              (value) => exercise = value),
          const SectionTitle('Hobbies'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final hobby in [
                'Travel',
                'Fitness',
                'Food',
                'Gaming',
                'Reading',
                'Music',
                'Football',
                'Photography',
                'Hiking',
                'Cars'
              ])
                FilterChip(
                  label: Text(hobby),
                  selected: hobbies.contains(hobby),
                  onSelected: (selected) => setState(() {
                    selected ? hobbies.add(hobby) : hobbies.remove(hobby);
                  }),
                ),
            ],
          ),
          _numberSlider('Free time per week', freeTime.toDouble(), 0, 40,
              (value) => freeTime = value.round()),
        ],
      );

  Widget _lifeStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _numberSlider('Close friends', friends.toDouble(), 0, 12,
              (value) => friends = value.round()),
          _numberSlider('Happiness', happiness.toDouble(), 1, 10,
              (value) => happiness = value.round()),
          _numberSlider('Stress', stress.toDouble(), 1, 10,
              (value) => stress = value.round()),
          _textField('Current life goal', goal, (value) => goal = value),
          _textField('Short bio', bio, (value) => bio = value,
              maxLength: 160, maxLines: 3),
          const SectionTitle('Social Links (optional)'),
          for (final platform in socialPlatforms)
            _textField(
              platform,
              socialLinks[platform] ?? '',
              (value) => value.trim().isEmpty
                  ? socialLinks.remove(platform)
                  : socialLinks[platform] = value.trim(),
            ),
        ],
      );

  Widget _privacyStep() => Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: privacy.visibility == ProfileVisibility.public,
            onChanged: (value) => setState(() => privacy = privacy.copyWith(
                  visibility: value
                      ? ProfileVisibility.public
                      : ProfileVisibility.private,
                )),
            title: const Text('Public profile'),
            subtitle: const Text(
                'Private profiles are hidden from Discover and cannot receive new ratings.'),
          ),
          _privacySwitch('Show in Discover', privacy.showInDiscover,
              (value) => privacy = privacy.copyWith(showInDiscover: value)),
          _privacySwitch('Show in Leaderboard', privacy.showInLeaderboard,
              (value) => privacy = privacy.copyWith(showInLeaderboard: value)),
          _privacySwitch('Allow Ratings', privacy.allowRatings,
              (value) => privacy = privacy.copyWith(allowRatings: value)),
          _privacySwitch('Allow Comments', privacy.allowComments,
              (value) => privacy = privacy.copyWith(allowComments: value)),
          _privacySwitch('Show Age', privacy.showAge,
              (value) => privacy = privacy.copyWith(showAge: value)),
          _privacySwitch('Show Country', privacy.showCountry,
              (value) => privacy = privacy.copyWith(showCountry: value)),
          _privacySwitch('Show Income', privacy.showIncome,
              (value) => privacy = privacy.copyWith(showIncome: value)),
          _privacySwitch('Show Savings', privacy.showSavings,
              (value) => privacy = privacy.copyWith(showSavings: value)),
        ],
      );

  Widget _privacySwitch(
      String title, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: value,
      onChanged: (next) => setState(() => onChanged(next)),
      title: Text(title),
    );
  }

  Widget _choice(String title, String value, List<String> options,
      ValueChanged<String> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in options)
              ChoiceChip(
                label: Text(option),
                selected: value == option,
                onSelected: (_) => setState(() => onChanged(option)),
              ),
          ],
        ),
      ],
    );
  }

  /// A searchable dropdown that still accepts free text — used for
  /// country/city so the list can cover every country without forcing a
  /// closed set (cities outside the curated list still work by typing).
  Widget _comboBoxField(String label, String value, List<String> options,
      ValueChanged<String> onChanged,
      {Key? fieldKey}) {
    return Padding(
      key: fieldKey,
      padding: const EdgeInsets.only(bottom: 14),
      child: Autocomplete<String>(
        initialValue: TextEditingValue(text: value),
        optionsBuilder: (textEditingValue) {
          if (textEditingValue.text.isEmpty) return options;
          final query = textEditingValue.text.toLowerCase();
          return options
              .where((option) => option.toLowerCase().contains(query));
        },
        onSelected: onChanged,
        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
          return TextFormField(
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              labelText: label,
              suffixIcon: const Icon(Icons.expand_more_rounded,
                  color: AppTheme.textMuted),
            ),
            onChanged: onChanged,
            onFieldSubmitted: (_) => onFieldSubmitted(),
          );
        },
        optionsViewBuilder: (context, onSelected, resultOptions) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              color: AppTheme.surfaceHigh,
              borderRadius: AppRadius.mdRadius,
              elevation: 6,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: 260,
                  maxWidth: MediaQuery.sizeOf(context).width - 40,
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  shrinkWrap: true,
                  itemCount: resultOptions.length,
                  itemBuilder: (context, index) {
                    final option = resultOptions.elementAt(index);
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.place_outlined,
                          size: 18, color: AppColors.purple),
                      title: Text(option),
                      onTap: () => onSelected(option),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _textField(String label, String value, ValueChanged<String> onChanged,
      {int? maxLength, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        initialValue: value,
        maxLength: maxLength,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
        onChanged: (next) => setState(() => onChanged(next)),
      ),
    );
  }

  Widget _moneyField(
      String label, double value, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        initialValue: value.round().toString(),
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: '$label ($currency)'),
        onChanged: (next) =>
            setState(() => onChanged(double.tryParse(next) ?? 0)),
      ),
    );
  }

  Widget _numberSlider(String label, double value, double min, double max,
      ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle('$label: ${value.round()}'),
        Slider(
          value: value.clamp(min, max).toDouble(),
          min: min,
          max: max,
          divisions: (max - min).round(),
          label: value.round().toString(),
          onChanged: (next) => setState(() => onChanged(next)),
        ),
      ],
    );
  }

  Future<void> _next() async {
    if (_step < 5) {
      setState(() => _step++);
      return;
    }
    final now = DateTime.now();
    final existing = widget.editing;
    final id = existing?.id ?? ref.read(appControllerProvider).newProfileId();
    var profile = UserProfile(
      id: id,
      displayName: displayName.trim(),
      age: age,
      country: country,
      city: city,
      gender: gender.trim().isEmpty ? null : gender.trim(),
      employmentStatus: employment,
      jobCategory: jobCategory,
      jobTitle: jobTitle.trim().isEmpty ? null : jobTitle.trim(),
      yearsExperience: experience,
      educationLevel: education,
      monthlyIncome: income,
      currency: currency,
      savings: savings,
      investments: investments,
      debt: debt,
      monthlyExpenses: expenses,
      relationshipStatus: relationship,
      livingSituation: living,
      ownsCar: ownsCar,
      carModel: ownsCar && carModel.trim().isNotEmpty ? carModel.trim() : null,
      ownsHome: ownsHome,
      travelFrequency: travel,
      exerciseFrequency: exercise,
      hobbies: hobbies,
      freeTimeHours: freeTime,
      closeFriends: friends,
      happiness: happiness,
      stress: stress,
      currentGoal: goal.trim(),
      bio: bio.trim().isEmpty ? 'Trying to build a better life.' : bio.trim(),
      photos: existing?.photos ?? const [],
      score: existing?.score ?? LifeScore.empty(),
      ratingSummary: existing?.ratingSummary ?? const RatingSummary(),
      history: existing?.history ?? const [],
      privacy: privacy,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      isCurrentUser: true,
      xp: existing?.xp ?? 0,
      coins: existing?.coins ?? 0,
      // Carried forward like xp/coins above — this rebuild must not
      // silently reset a running view count or unequip a cosmetic frame
      // just because the owner edited an unrelated field.
      viewCount: existing?.viewCount ?? 0,
      equippedFrameId: existing?.equippedFrameId,
      socialLinks: socialLinks,
    );
    profile =
        profile.copyWith(score: const LifeScoreService().calculate(profile));
    if (existing == null) {
      await ref.read(appControllerProvider).createProfile(profile);
    } else {
      await ref
          .read(appControllerProvider)
          .updateProfile(profile, xpReason: XpReason.profileUpdated);
      if (mounted) Navigator.pop(context);
    }
  }

  String _currencyFor(String country) => switch (country) {
        'Morocco' => 'MAD',
        'France' => 'EUR',
        'USA' => 'USD',
        'India' => 'INR',
        'Canada' => 'CAD',
        'UAE' => 'AED',
        'Brazil' => 'BRL',
        'Switzerland' => 'CHF',
        _ => 'USD',
      };
}

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;
  bool _showingAchievementDialog = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    if (state.toast != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final toast = state.toast;
        if (toast == null || !mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(toast)));
        ref.read(appControllerProvider).clearToast();
      });
    }
    if (state.achievementQueue.isNotEmpty && !_showingAchievementDialog) {
      _showingAchievementDialog = true;
      final achievement = state.achievementQueue.first;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (_) => AchievementUnlockDialog(achievement: achievement),
        );
        if (!mounted) return;
        ref.read(appControllerProvider).dequeueAchievement();
        _showingAchievementDialog = false;
      });
    }
    // Deliberately NOT a local takeover here (`if currentCall) return
    // CallScreen`) — AppShell is often not the topmost route (e.g. a
    // call started from inside ConversationScreen, which is pushed on
    // top of it), so swapping AppShell's own body is invisible until
    // the user pops back to it. See `RateMyLifeApp`'s `builder` in
    // main.dart for the real, route-independent overlay.
    final pages = [
      const HomeScreen(),
      const DiscoverScreen(),
      const RateFeedScreen(),
      const ConversationsScreen(),
      const MeScreen(),
    ];
    return Scaffold(
      body: Stack(
        children: [
          for (var i = 0; i < pages.length; i++)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: i != _index,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  opacity: i == _index ? 1 : 0,
                  child: pages[i],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (value) => setState(() => _index = value),
        items: [
          _navItem(Icons.home_rounded, AppColors.purple, 'Home'),
          _navItem(Icons.explore_rounded, AppColors.blue, 'Discover'),
          _navItem(Icons.star_rounded, AppColors.pink, 'Rate'),
          _navItem(Icons.chat_bubble_rounded, AppColors.green, 'Messages',
              badgeCount: state.unreadMessageCount),
          _navItem(Icons.person_rounded, AppColors.cyan, 'Me'),
        ],
      ),
    );
  }

  BottomNavigationBarItem _navItem(IconData icon, Color accent, String label,
      {int badgeCount = 0}) {
    Widget badgeWrap(Widget child) => badgeCount <= 0
        ? child
        : Badge(
            label: Text(badgeCount > 9 ? '9+' : '$badgeCount'),
            backgroundColor: AppColors.neonRed,
            textColor: AppColors.textPrimary,
            child: child,
          );
    return BottomNavigationBarItem(
      icon: badgeWrap(
          NeonIconBadge(icon: icon, accent: accent, size: 34, dim: true)),
      activeIcon:
          badgeWrap(NeonIconBadge(icon: icon, accent: accent, size: 34)),
      label: label,
    );
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final profile = state.currentProfile!;
    final percentile = state.overallPercentile;
    return Scaffold(
      appBar: AppBar(title: const Text('Good Morning')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _StaggerIn(
            delay: Duration.zero,
            child: Row(
              children: [
                const Expanded(
                  child: Text('YOUR LIFE',
                      style: TextStyle(
                          color: AppTheme.gold, fontWeight: FontWeight.w900)),
                ),
                WatchAdPill(
                  onTap: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => GetCoinsScreen())),
                ),
                const SizedBox(width: 8),
                CoinBalancePill(balance: state.wallet.balance),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _StaggerIn(
            delay: const Duration(milliseconds: 60),
            child: Row(
              children: [
                ScoreTile(
                    value: profile.score.overall.toString(),
                    suffix: '/ 100',
                    label: 'Life Score',
                    color: AppTheme.accent),
                const SizedBox(width: 10),
                ScoreTile(
                    value: profile.ratingSummary.averageLook.toStringAsFixed(1),
                    suffix: '/ 5',
                    label: 'Your Look',
                    color: AppColors.pink),
                const SizedBox(width: 10),
                ScoreTile(
                    value:
                        profile.ratingSummary.averageOverall.toStringAsFixed(1),
                    suffix: '/ 5',
                    label: 'Your Life',
                    color: AppTheme.gold),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _StaggerIn(
            delay: const Duration(milliseconds: 120),
            child: GradientButton(
              label: 'Get Life Advice',
              icon: Icons.tips_and_updates_rounded,
              gradient: AppColors.blueGradient,
              onPressed: () => _showAdvice(context, profile),
            ),
          ),
          const SizedBox(height: 14),
          _StaggerIn(
            delay: const Duration(milliseconds: 180),
            child: NukeStatusBanner(
              profile: profile,
              balance: state.wallet.balance,
              onCure: (attribute) => showCureRevealSheet(context, attribute),
            ),
          ),
          const SizedBox(height: 14),
          _StaggerIn(
            delay: const Duration(milliseconds: 240),
            child: LevelProgressCard(levelInfo: state.levelInfo),
          ),
          const SizedBox(height: 14),
          _StaggerIn(
            delay: const Duration(milliseconds: 300),
            child: StreakCard(
                streakDays: state.currentStreakDays,
                lastSevenDays: state.lastSevenDays),
          ),
          const SectionTitle('Daily Challenges'),
          _StaggerIn(
            delay: const Duration(milliseconds: 360),
            child: DailyChallengesCard(
              challenges: state.todaysChallenges,
              progressFor: state.challengeProgress,
              claimedFor: state.isChallengeClaimedToday,
            ),
          ),
          const SizedBox(height: 6),
          // Rate/Discover/Leaderboard/Messages used to duplicate full-width
          // buttons here — now that they're all bottom-nav tabs, repeating
          // them on Home was pure clutter, not a second way in. Only the
          // features with no nav-bar home of their own stay here, as two
          // labeled groups (play vs. discover more) rather than one flat
          // grab-bag grid — same four features, clearer grouping.
          const SectionTitle('Play'),
          _StaggerIn(
            delay: const Duration(milliseconds: 420),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.95,
              children: [
                _ExploreTile(
                  icon: Icons.sports_martial_arts_rounded,
                  accent: AppColors.purple,
                  label: 'Life Battles',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const BattleScreen())),
                ),
                _ExploreTile(
                  icon: Icons.auto_fix_high_rounded,
                  accent: AppColors.green,
                  label: 'What If? Simulator',
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => WhatIfScreen(original: profile))),
                ),
                _ExploreTile(
                  icon: Icons.help_rounded,
                  accent: AppColors.gold,
                  label: 'Would You Choose?',
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const WhatWouldYouChooseScreen())),
                ),
                _ExploreTile(
                  emoji: '☢️',
                  accent: AppColors.nukeOrange,
                  label: "Nuke Someone's Life",
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const NukeScreen())),
                ),
              ],
            ),
          ),
          const SectionTitle('Discover More'),
          _StaggerIn(
            delay: const Duration(milliseconds: 480),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.95,
              children: [
                _ExploreTile(
                  icon: Icons.compare_arrows_rounded,
                  accent: AppColors.neonRed,
                  label: 'Biggest Gaps',
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const BiggestGapsScreen())),
                ),
                _ExploreTile(
                  icon: Icons.trending_up_rounded,
                  accent: AppColors.blue,
                  label: 'New & Rising',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const TrendingScreen())),
                ),
              ],
            ),
          ),
          const SectionTitle('Your Position'),
          _StaggerIn(
            delay: const Duration(milliseconds: 540),
            child: AppCard(
              // Leaderboard dropped off the bottom nav (six tabs was one too
              // many) — this comparison card is the natural place to lead
              // into it instead, rather than losing it as a persistent tab.
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
              child: Row(
                children: [
                  _PercentileRing(percentile: percentile),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('🏆 YOUR POSITION',
                            style: AppTypography.eyebrow.copyWith(color: AppColors.gold)),
                        const SizedBox(height: 2),
                        // overallPercentile compares against every profile
                        // this device currently knows about (mock seed +
                        // real synced users) — not filtered by age/country
                        // (those live in agePercentile/countryPercentile on
                        // the Score screen), so "everyone" here is accurate
                        // rather than implying a narrower "people like you"
                        // comparison it isn't actually making.
                        Text(
                          "You're ahead of $percentile% of everyone here.",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppTheme.textMuted),
                ],
              ),
            ),
          ),
          const SectionTitle('Recent Activity'),
          _StaggerIn(
            delay: const Duration(milliseconds: 600),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Your rating increased',
                      style: TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Text(
                      '${(profile.ratingSummary.averageOverall - 0.1).clamp(0, 10).toStringAsFixed(1)} -> ${profile.ratingSummary.averageOverall.toStringAsFixed(1)}',
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.gold)),
                  const SizedBox(height: 4),
                  Text(
                      '+${37 + profile.ratingSummary.count % 80} new ratings this week',
                      style: const TextStyle(color: AppTheme.textMuted)),
                ],
              ),
            ),
          ),
          const SectionTitle('People Are Saying'),
          const _StaggerIn(
            delay: Duration(milliseconds: 660),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                MetricPill(icon: Icons.work_outline, label: 'Great career'),
                MetricPill(icon: Icons.flight_takeoff, label: 'Fun lifestyle'),
                MetricPill(
                    icon: Icons.savings_outlined,
                    label: 'Money looks disciplined'),
                MetricPill(icon: Icons.favorite_border, label: 'Balanced life'),
              ],
            ),
          ),
          const SectionTitle('Keep Your Profile Fresh'),
          _StaggerIn(
            delay: const Duration(milliseconds: 720),
            child: AppCard(
              child: Column(
                children: [
                  _ActionRow(
                      icon: Icons.add_photo_alternate_outlined,
                      label: 'Add another photo',
                      onTap: () => _openPhotos(context)),
                  _ActionRow(
                      icon: Icons.attach_money,
                      label: 'Update income or savings',
                      onTap: () => _edit(context, profile)),
                  _ActionRow(
                      icon: Icons.emoji_events_outlined,
                      label: 'Add a new achievement',
                      onTap: () => _edit(context, profile)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Center(child: BannerAdWidget()),
        ],
      ),
    );
  }

  void _edit(BuildContext context, UserProfile profile) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ProfileWizardScreen(editing: profile)));
  }

  void _openPhotos(BuildContext context) {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const PhotoManagerScreen()));
  }

  void _showAdvice(BuildContext context, UserProfile profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _LifeCoachSheet(profile: profile),
    );
  }
}

/// "✨ YOUR LIFE COACH" — the Get Life Advice bottom sheet. Each tap of
/// "Give me different advice" re-rolls `LifeAdviceService.generate`
/// (same weakest-categories-first selection, a fresh random variant per
/// category) and re-plays the staggered card entrance so it reads as a
/// genuine reshuffle, not a static list.
class _LifeCoachSheet extends StatefulWidget {
  const _LifeCoachSheet({required this.profile});

  final UserProfile profile;

  @override
  State<_LifeCoachSheet> createState() => _LifeCoachSheetState();
}

class _LifeCoachSheetState extends State<_LifeCoachSheet> {
  static const _service = LifeAdviceService();
  static const _categoryIcons = {
    'Career': Icons.work_rounded,
    'Money': Icons.savings_rounded,
    'Education': Icons.school_rounded,
    'Independence': Icons.home_rounded,
    'Social': Icons.groups_rounded,
    'Lifestyle': Icons.local_fire_department_rounded,
    'Wellbeing': Icons.self_improvement_rounded,
  };

  late List<AdviceTip> _tips = _service.generate(widget.profile);
  int _shuffleCount = 0;

  void _shuffle() {
    HapticFeedback.selectionClick();
    setState(() {
      _tips = _service.generate(widget.profile);
      _shuffleCount++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const NeonIconBadge(
                    icon: Icons.auto_awesome_rounded, accent: AppColors.blue, circular: true),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('✨ YOUR LIFE COACH',
                          style: AppTypography.eyebrow.copyWith(color: AppColors.blue)),
                      const SizedBox(height: 2),
                      Text("Here's what I'd focus on next...", style: AppTypography.heading),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            for (var i = 0; i < _tips.length; i++)
              _AdviceCard(
                key: ValueKey('${_shuffleCount}_${_tips[i].category}_$i'),
                tip: _tips[i],
                icon: _categoryIcons[_tips[i].category] ?? Icons.tips_and_updates_rounded,
                delay: Duration(milliseconds: 90 * i),
              ),
            const SizedBox(height: 6),
            Center(
              child: TextButton.icon(
                onPressed: _shuffle,
                icon: const Icon(Icons.refresh_rounded, color: AppColors.blue),
                label: const Text('Give me different advice',
                    style: TextStyle(color: AppColors.blue, fontWeight: FontWeight.w800)),
              ),
            ),
            Text(
              'Based on your real profile and background — not a measure of your worth, just ideas.',
              style: AppTypography.caption,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _AdviceCard extends StatelessWidget {
  const _AdviceCard({super.key, required this.tip, required this.icon, required this.delay});

  final AdviceTip tip;
  final IconData icon;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return _StaggerIn(
      delay: delay,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: AppCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NeonIconBadge(icon: icon, accent: AppColors.blue, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(tip.category,
                              style: AppTypography.body.copyWith(fontWeight: FontWeight.w900)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.blue.withValues(alpha: 0.15),
                            borderRadius: AppRadius.pillRadius,
                          ),
                          child: Text('${tip.score}',
                              style: const TextStyle(
                                  color: AppColors.blue, fontWeight: FontWeight.w800, fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(tip.tip, style: AppTypography.bodyMuted),
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

/// A one-shot fade+slide-up entrance, delayed by [delay] — the building
/// block behind every staggered list in this screen (advice cards, Home
/// section reveals). Deliberately a plain delayed `AnimatedOpacity`/
/// `AnimatedSlide` rather than a driven `AnimationController`: finite,
/// self-contained, and safe under `pumpAndSettle()` in tests.
class _StaggerIn extends StatefulWidget {
  const _StaggerIn({required this.delay, required this.child});

  final Duration delay;
  final Widget child;

  @override
  State<_StaggerIn> createState() => _StaggerInState();
}

class _StaggerInState extends State<_StaggerIn> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: _visible ? Offset.zero : const Offset(0, 0.08),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

/// A compact circular progress ring around an animated percentile
/// number — used by Home's "Your Position" card. `percentile` is
/// already clamped 1-99 by `PercentileService`, so the ring never reads
/// as literally empty or literally full.
class _PercentileRing extends StatelessWidget {
  const _PercentileRing({required this.percentile});

  final int percentile;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: percentile / 100),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                value: v,
                strokeWidth: 5,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation(AppColors.gold),
              ),
            ),
          ),
          AnimatedCountUp(
            value: percentile.toDouble(),
            suffix: '%',
            duration: const Duration(milliseconds: 900),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

/// A tappable tile for a secondary feature — used in Home's "Play"/
/// "Discover More" grids. A glowing accent-colored border instead of
/// the plain dark `AppCard` look, matching the brand's neon-arcade
/// identity more directly than a flat square.
class _ExploreTile extends StatelessWidget {
  const _ExploreTile(
      {this.icon,
      this.emoji,
      required this.accent,
      required this.label,
      required this.onTap});

  final IconData? icon;

  /// Overrides [icon] with a literal glyph (e.g. a radiation symbol) —
  /// for a mark Material Icons simply doesn't have.
  final String? emoji;
  final Color accent;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: accent, width: 1.5),
        boxShadow: [
          BoxShadow(
              color: accent.withValues(alpha: 0.4),
              blurRadius: 16,
              spreadRadius: 1),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.lgRadius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                emoji != null
                    ? Text(emoji!, style: const TextStyle(fontSize: 52))
                    : Icon(icon, color: accent, size: 60),
                const SizedBox(height: 12),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.button.copyWith(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.badge});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppTheme.gold),
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: AppTheme.surfaceHigh,
                  borderRadius: AppRadius.pillRadius),
              child: Text(badge!,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.gold)),
            ),
            const SizedBox(width: 6),
          ],
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: onTap,
    );
  }
}

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  String sort = 'Recommended';
  String country = 'All';
  final List<String> _dismissed = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_maybeLoadMore);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_maybeLoadMore);
    _scrollController.dispose();
    super.dispose();
  }

  // Fires while scrolling, not just at the very end — starting the
  // next fetch ~600px early means it's usually already in by the time
  // the user reaches the bottom, instead of a visible pause.
  void _maybeLoadMore() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels < position.maxScrollExtent - 600) return;
    final controller = ref.read(appControllerProvider);
    if (controller.discoverHasMore && !controller.discoverLoadingMore) {
      controller.loadMoreDiscover();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final allProfiles = state.discoverProfiles;
    final countries = allProfiles.map((p) => p.country).toSet().toList()
      ..sort();
    var profiles = country == 'All'
        ? allProfiles
        : allProfiles.where((p) => p.country == country).toList();
    profiles =
        _sort(profiles).where((p) => !_dismissed.contains(p.id)).toList();
    // A narrow filter can empty out everything already fetched even
    // though more exists server-side — top it up automatically rather
    // than showing "ran out" prematurely.
    if (profiles.isEmpty &&
        state.discoverHasMore &&
        !state.discoverLoadingMore) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => ref.read(appControllerProvider).loadMoreDiscover());
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Discover')),
      body: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        children: [
          _filterBar(countries),
          if (profiles.isEmpty && !state.discoverHasMore)
            EmptyState(
              icon: Icons.search_off,
              title: "We've run out of lives to judge.",
              subtitle:
                  'Clear filters, try random sorting, or bring back the ones you passed on.',
              action: FilledButton(
                onPressed: () => setState(() {
                  country = 'All';
                  sort = 'Random';
                  _dismissed.clear();
                }),
                child: const Text('TRY AGAIN'),
              ),
            )
          else ...[
            for (var i = 0; i < profiles.length; i++) ...[
              // A banner every 5 cards, mirroring a typical feed's ad
              // cadence — frequent enough to matter, not so frequent it
              // buries the actual discovery content.
              if (i > 0 && i % 5 == 0)
                const Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: Center(child: BannerAdWidget()),
                ),
              Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    _DiscoverCard(
                        profile: profiles[i],
                        nukesSurvived: state.nukesSurvivedFor(profiles[i]),
                        onTap: () => _openProfile(context, profiles[i])),
                    Positioned(
                      bottom: -26,
                      child: _DiscoverActionBar(
                        canRewind: _dismissed.isNotEmpty,
                        onRewind: () => setState(() => _dismissed.removeLast()),
                        onPass: () =>
                            setState(() => _dismissed.add(profiles[i].id)),
                        onViewProfile: () => _openProfile(context, profiles[i]),
                        rating: profiles[i].ratingSummary,
                        onLike: () => _quickRate(profiles[i]),
                        onMessage: () => _messageProfile(context, profiles[i]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (state.discoverLoadingMore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ],
      ),
    );
  }

  // Optimistic: dismiss the card and confirm instantly rather than
  // waiting on the Firestore round-trip first — the "Pass" button next
  // to this one is already instant (no network call at all), so a
  // network-bound "Like" felt broken/laggy by comparison. The actual
  // save still happens (and surfaces its own error toast via
  // AppController if it ever fails), just not gating the UI on it.
  void _quickRate(UserProfile profile) {
    // Guards against a double-tap firing this twice for the same card
    // before the first tap's setState/rebuild removes it — without
    // this, two concurrent submitRating calls can race on the same
    // Firestore rating document.
    if (_dismissed.contains(profile.id)) return;
    setState(() => _dismissed.add(profile.id));
    ref.read(appControllerProvider).submitRating(profile, 5, 5);
  }

  void _messageProfile(BuildContext context, UserProfile profile) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ConversationScreen(otherUserId: profile.id)));
  }

  static const _sortIcons = {
    'Recommended': Icons.auto_awesome_rounded,
    'Highest Rated': Icons.star_rounded,
    'Newest': Icons.fiber_new_rounded,
    'Most Rated': Icons.how_to_reg_rounded,
    'Random': Icons.shuffle_rounded,
  };

  Widget _filterBar(List<String> countries) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: country,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Country',
            prefixIcon: Icon(Icons.public_rounded, color: AppColors.purple),
          ),
          items: [
            const DropdownMenuItem(value: 'All', child: Text('All countries')),
            for (final item in countries)
              DropdownMenuItem(value: item, child: Text(item)),
          ],
          onChanged: (value) => setState(() => country = value ?? 'All'),
        ),
        const SizedBox(height: 10),
        InkWell(
          borderRadius: AppRadius.pillRadius,
          onTap: _pickSort,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: AppTheme.surfaceHigh,
              borderRadius: AppRadius.pillRadius,
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_sortIcons[sort], size: 17, color: AppColors.purple),
                const SizedBox(width: 8),
                Text(sort, style: AppTypography.body.copyWith(fontSize: 14)),
                const SizedBox(width: 4),
                const Icon(Icons.expand_more_rounded,
                    size: 18, color: AppTheme.textMuted),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  void _pickSort() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 6),
              child: Row(
                children: [
                  Text('SORT BY',
                      style: TextStyle(
                          fontWeight: FontWeight.w900, color: AppTheme.gold)),
                ],
              ),
            ),
            for (final entry in _sortIcons.entries)
              ListTile(
                leading: Icon(entry.value,
                    color: sort == entry.key
                        ? AppColors.purple
                        : AppTheme.textMuted),
                title: Text(entry.key),
                trailing: sort == entry.key
                    ? const Icon(Icons.check_rounded, color: AppColors.purple)
                    : null,
                onTap: () {
                  setState(() => sort = entry.key);
                  Navigator.pop(sheetContext);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  List<UserProfile> _sort(List<UserProfile> profiles) {
    final list = [...profiles];
    switch (sort) {
      case 'Highest Rated':
        list.sort((a, b) => b.ratingSummary.averageOverall
            .compareTo(a.ratingSummary.averageOverall));
        break;
      case 'Newest':
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'Most Rated':
        list.sort(
            (a, b) => b.ratingSummary.count.compareTo(a.ratingSummary.count));
        break;
      case 'Random':
        list.shuffle();
        break;
      default:
        list.sort((a, b) => b.score.overall.compareTo(a.score.overall));
    }
    return list;
  }

  void _openProfile(BuildContext context, UserProfile profile) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => PublicProfileScreen(profileId: profile.id)));
  }
}

/// A full-bleed profile card for the Discover feed: photo, bottom gradient
/// overlay with name/age/facts, styled after modern swipe-card apps.
class _DiscoverCard extends StatelessWidget {
  const _DiscoverCard({
    required this.profile,
    required this.onTap,
    this.nukesSurvived = 0,
  });

  final UserProfile profile;
  final VoidCallback onTap;
  final int nukesSurvived;

  @override
  Widget build(BuildContext context) {
    final location = [
      profile.city,
      if (profile.privacy.showCountry) profile.country
    ].where((s) => s.isNotEmpty).join(', ');
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: AppRadius.lgRadius,
        child: SizedBox(
          height: 520,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              PhotoCarousel(
                // Sits inside a Stack(fit: StackFit.expand) at a fixed
                // 520 height — that tight constraint overrides
                // PhotoCarousel's own aspect ratio, same as the plain
                // ProfileImage this replaces did with its own height.
                photos: profile.privacy.showPhotos
                    ? profile.photos
                    : [if (profile.profilePhoto != null) profile.profilePhoto!],
                label: profile.displayName,
                borderRadius: 0,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.45, 1.0],
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.88)
                    ],
                  ),
                ),
              ),
              if (profile.ratingSummary.hasRatings)
                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: AppRadius.pillRadius),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded,
                            color: AppColors.gold, size: 15),
                        const SizedBox(width: 4),
                        Text(
                          profile.ratingSummary.averageOverall
                              .toStringAsFixed(1),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              if (nukesSurvived > 0)
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: AppRadius.pillRadius,
                        border: Border.all(
                            color: AppColors.nukeOrange, width: 1),
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.nukeOrange
                                  .withValues(alpha: 0.55),
                              blurRadius: 10,
                              spreadRadius: 0.5),
                        ]),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('☢️', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        Text(
                          '$nukesSurvived survived',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),
              Positioned(
                left: 20,
                right: 20,
                bottom: 44,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            profile.privacy.showAge
                                ? '${profile.displayName} ${profile.age}'
                                : profile.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.hero
                                .copyWith(color: Colors.white, fontSize: 26),
                          ),
                        ),
                        if (profile.ratingSummary.hasRatings) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified_rounded,
                              color: AppColors.blue, size: 20),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 16,
                      runSpacing: 6,
                      children: [
                        if (location.isNotEmpty)
                          _CardFact(
                              icon: Icons.place_outlined, label: location),
                        if (profile.privacy.showCareer &&
                            (profile.jobTitle ?? profile.jobCategory)
                                .isNotEmpty)
                          _CardFact(
                              icon: Icons.work_outline,
                              label: (profile.jobTitle ?? profile.jobCategory)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 16,
                      runSpacing: 6,
                      children: [
                        _CardFact(
                            icon: Icons.school_outlined,
                            label: profile.educationLevel),
                        if (profile.ownsCar)
                          _CardFact(
                            icon: Icons.directions_car_filled_outlined,
                            label: (profile.carModel?.isNotEmpty ?? false)
                                ? profile.carModel!
                                : 'Owns a car',
                          ),
                        if (nukesSurvived > 0)
                          _CardFact(
                            emoji: '☢️',
                            label: '$nukesSurvived nuked',
                          ),
                      ],
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

class _CardFact extends StatelessWidget {
  const _CardFact({this.icon, this.emoji, required this.label})
      : assert(icon != null || emoji != null, '_CardFact needs either icon or emoji');

  final IconData? icon;

  /// Overrides [icon] with a literal glyph (e.g. a radiation symbol) —
  /// for a mark Material Icons simply doesn't have.
  final String? emoji;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        emoji != null
            ? Text(emoji!, style: const TextStyle(fontSize: 14))
            : Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: 5),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5),
        ),
      ],
    );
  }
}

/// The floating circular action row beneath a Discover card: rewind,
/// pass, view profile, quick-rate, and share.
class _DiscoverActionBar extends StatelessWidget {
  const _DiscoverActionBar({
    required this.canRewind,
    required this.onRewind,
    required this.onPass,
    required this.onViewProfile,
    required this.rating,
    required this.onLike,
    required this.onMessage,
  });

  final bool canRewind;
  final VoidCallback onRewind;
  final VoidCallback onPass;
  final VoidCallback onViewProfile;

  /// Shown as a number on the middle button instead of a plain star
  /// icon — a glanceable life rating right between Pass and Like,
  /// same tap target/action (opens the full profile).
  final RatingSummary rating;
  final VoidCallback onLike;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionButton(
            icon: Icons.replay_rounded,
            color: AppTheme.textMuted,
            size: 46,
            onTap: canRewind ? onRewind : null,
            tooltip: 'Undo last pass'),
        const SizedBox(width: 10),
        _ActionButton(
            icon: Icons.close_rounded,
            color: AppColors.pink,
            size: 58,
            onTap: onPass,
            tooltip: 'Pass'),
        const SizedBox(width: 10),
        _ActionButton(
            icon: Icons.star_rounded,
            label: rating.hasRatings ? rating.averageOverall.toStringAsFixed(1) : null,
            color: AppColors.gold,
            size: 68,
            onTap: onViewProfile,
            tooltip: 'View full profile'),
        const SizedBox(width: 10),
        _ActionButton(
            icon: Icons.favorite_rounded,
            color: AppColors.purple,
            size: 58,
            onTap: onLike,
            tooltip: 'Rate 5/5'),
        const SizedBox(width: 10),
        _ActionButton(
            icon: Icons.chat_bubble_rounded,
            color: AppColors.green,
            size: 46,
            onTap: onMessage,
            tooltip: 'Message'),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    this.label,
    required this.color,
    required this.size,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;

  /// Overrides [icon] with a short text label (e.g. a rating number)
  /// while keeping the same circular button chrome.
  final String? label;
  final Color color;
  final double size;
  final VoidCallback? onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppTheme.surfaceHigh,
        shape: CircleBorder(
            side: BorderSide(
                color:
                    disabled ? AppTheme.border : color.withValues(alpha: 0.6),
                width: 1.5)),
        elevation: disabled ? 0 : 4,
        shadowColor: color.withValues(alpha: 0.5),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: size,
            height: size,
            child: label != null
                ? Center(
                    child: Text(
                      label!,
                      style: TextStyle(
                          color: disabled ? AppTheme.border : color,
                          fontWeight: FontWeight.w900,
                          fontSize: size * 0.34),
                    ),
                  )
                : Icon(icon,
                    color: disabled ? AppTheme.border : color, size: size * 0.46),
          ),
        ),
      ),
    );
  }
}

class PublicProfileScreen extends ConsumerStatefulWidget {
  const PublicProfileScreen({super.key, required this.profileId});

  final String profileId;

  @override
  ConsumerState<PublicProfileScreen> createState() =>
      _PublicProfileScreenState();
}

class _PublicProfileScreenState extends ConsumerState<PublicProfileScreen> {
  int rating = 4;
  int lookRating = 4;

  @override
  void initState() {
    super.initState();
    // Once per screen open, not on every rebuild — the controller/
    // repository layer separately guards against a self-view and a
    // target with no real backing profile, so this doesn't need to
    // duplicate those checks.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = ref.read(appControllerProvider);
      controller.recordProfileView(widget.profileId);
      // A cheap, list-page copy of this profile may already be
      // cached (from Discover/Leaderboard/etc), but it's missing
      // income/savings even when the owner opted to show them — this
      // always fetches the real thing and replaces the cheap copy.
      controller.loadFullProfile(widget.profileId);
      controller.ensureCommentsLoaded(widget.profileId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final profile = state.profileById(widget.profileId);
    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final mine = state.currentProfile?.id == profile.id;
    final existing = state.myRatingFor(profile.id);
    rating = existing?.overall ?? rating;
    lookRating = existing?.look ?? lookRating;
    return Scaffold(
      appBar: AppBar(
        title: Text(mine ? 'Your Public Profile' : profile.displayName),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenu(context, ref, profile, value),
            itemBuilder: (context) => [
              if (!mine)
                const PopupMenuItem(
                  value: 'report',
                  child: Row(children: [
                    Icon(Icons.flag_outlined,
                        size: 18, color: AppColors.danger),
                    SizedBox(width: 10),
                    Text('Report Profile',
                        style: TextStyle(color: AppColors.danger))
                  ]),
                ),
              if (!mine)
                const PopupMenuItem(
                  value: 'block',
                  child: Row(children: [
                    Icon(Icons.block_rounded,
                        size: 18, color: AppColors.danger),
                    SizedBox(width: 10),
                    Text('Block User',
                        style: TextStyle(color: AppColors.danger))
                  ]),
                ),
              const PopupMenuItem(
                value: 'share',
                child: Row(children: [
                  Icon(Icons.ios_share_rounded,
                      size: 18, color: AppTheme.textMuted),
                  SizedBox(width: 10),
                  Text('Share Card')
                ]),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          PhotoCarousel(
            // The cover photo always shows, same as before — "Show
            // Photos" only gates the *rest* of the gallery (see its
            // Privacy Settings subtitle), so a hidden gallery must not
            // become swipeable through here either.
            photos: profile.privacy.showPhotos
                ? profile.photos
                : [if (profile.profilePhoto != null) profile.profilePhoto!],
            label: profile.displayName,
            frameId: profile.equippedFrameId,
          ),
          const SizedBox(height: 18),
          Text(profile.displayName,
              style:
                  const TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(profile.locationLine,
              style: const TextStyle(color: AppTheme.textMuted)),
          const SizedBox(height: 12),
          Text('"${profile.bio}"',
              style: const TextStyle(fontSize: 17, height: 1.35)),
          if (profile.socialLinks.isNotEmpty) ...[
            const SizedBox(height: 12),
            SocialLinksRow(links: profile.socialLinks),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              ScoreTile(
                  value: profile.ratingSummary.averageLook.toStringAsFixed(1),
                  suffix: '/ 5',
                  label: 'Look Rating',
                  color: AppColors.pink),
              const SizedBox(width: 10),
              ScoreTile(
                  value:
                      profile.ratingSummary.averageOverall.toStringAsFixed(1),
                  suffix: '/ 5',
                  label: 'Life Rating',
                  color: AppTheme.gold),
              const SizedBox(width: 10),
              ScoreTile(
                  value: state.displayScoreFor(profile).overall.toString(),
                  suffix: '/ 100',
                  label: 'Life Score',
                  color: AppTheme.accent),
            ],
          ),
          const SizedBox(height: 8),
          Text('${profile.ratingSummary.count} people rated this life',
              style: const TextStyle(color: AppTheme.textMuted)),
          if (profile.viewCount > 0) ...[
            const SizedBox(height: 2),
            Text('${profile.viewCount} profile views',
                style: const TextStyle(color: AppTheme.textMuted)),
          ],
          if (state.nukesSurvivedFor(profile) > 0) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('☢️', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text('${state.nukesSurvivedFor(profile)} nukes survived',
                    style: const TextStyle(
                        color: AppColors.nukeOrange,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ],
          if (!mine &&
              !state.blockedIds.contains(profile.id) &&
              state.messagesAllowedFor(profile)) ...[
            const SizedBox(height: 14),
            GradientButton(
              label: 'Message',
              icon: Icons.chat_bubble_outline_rounded,
              gradient: AppColors.purpleGradient,
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          ConversationScreen(otherUserId: profile.id))),
            ),
          ],
          const SectionTitle('Photos'),
          PhotoGrid(
            photos: profile.privacy.showPhotos ? profile.photos : const [],
            onTap: (index) => _openViewer(context, profile, index),
            voteCounts: profile.photoVoteCounts,
            myVotedPhotoId: mine ? null : state.myBestPhotoVoteFor(profile.id),
            onVote: mine
                ? null
                : (photoId) => ref
                    .read(appControllerProvider)
                    .voteForBestPhoto(profile.id, photoId),
          ),
          const SectionTitle('Life'),
          _lifeFacts(profile),
          const SectionTitle('Score Breakdown'),
          _breakdown(state, profile),
          _commentsSection(context, ref, state, profile, limit: 5),
          if (!mine && profile.privacy.allowRatings) ...[
            const SectionTitle('Rate This Life'),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.favorite, color: AppColors.pink, size: 18),
                      SizedBox(width: 6),
                      Text('RATE THEIR LOOK',
                          style: TextStyle(fontWeight: FontWeight.w900)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  RatingSelector(
                      value: lookRating,
                      onChanged: (value) => setState(() => lookRating = value)),
                  const SizedBox(height: 22),
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome,
                          color: AppColors.purple, size: 18),
                      SizedBox(width: 6),
                      Text('RATE THEIR LIFE',
                          style: TextStyle(fontWeight: FontWeight.w900)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  RatingSelector(
                      value: rating,
                      onChanged: (value) => setState(() => rating = value)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => ref
                              .read(appControllerProvider)
                              .submitRating(profile, rating, lookRating),
                          icon: const Icon(Icons.star),
                          label: Text(
                              existing == null ? 'SUBMIT' : 'UPDATE RATING'),
                        ),
                      ),
                      if (existing != null) ...[
                        const SizedBox(width: 8),
                        IconButton.outlined(
                          tooltip: 'Remove rating',
                          onPressed: () => ref
                              .read(appControllerProvider)
                              .removeRating(profile.id),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ],
                  ),
                  if (existing != null) ...[
                    const SizedBox(height: 14),
                    Text(
                        'You gave ${existing.overall}/5. Community rating is ${profile.ratingSummary.averageOverall.toStringAsFixed(1)}/5.'),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _lifeFacts(UserProfile profile) {
    final facts = [
      if (profile.privacy.showCareer) profile.jobTitle ?? profile.jobCategory,
      profile.educationLevel,
      if (profile.privacy.showIncome)
        '${profile.monthlyIncome.round()} ${profile.currency} / month',
      if (profile.privacy.showSavings)
        '${profile.savings.round()} ${profile.currency} savings',
      profile.livingSituation,
      profile.ownsCar
          ? ((profile.carModel?.isNotEmpty ?? false)
              ? 'Owns a ${profile.carModel}'
              : 'Owns a car')
          : 'No car',
      profile.relationshipStatus,
      'Travels ${profile.travelFrequency}',
      'Exercises ${profile.exerciseFrequency}',
    ];
    return AppCard(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final fact in facts)
            MetricPill(icon: Icons.check_circle_outline, label: fact),
        ],
      ),
    );
  }

  Widget _breakdown(AppController state, UserProfile profile) {
    final damage = state.nukeDamageFor(profile);
    // `LifeScore.breakdown`'s labels ('Career', 'Money', ...) match
    // `NukeService.attributeLabels`' values exactly — reverse-lookup to
    // flag which breakdown row a nuke actually hit.
    final damagedLabels = damage.entries
        .where((entry) => entry.value < 0)
        .map((entry) => NukeService.attributeLabels[entry.key])
        .whereType<String>()
        .toSet();

    return AppCard(
      child: Column(
        children: [
          for (final entry in state.displayScoreFor(profile).breakdown.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  Expanded(
                      child: Text(entry.key,
                          style: const TextStyle(fontWeight: FontWeight.w800))),
                  SizedBox(
                    width: 120,
                    child: LinearProgressIndicator(
                        value: entry.value / 100,
                        minHeight: 8,
                        color: damagedLabels.contains(entry.key)
                            ? AppColors.danger
                            : null),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 28,
                    child: Text('${entry.value}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                  ),
                  // Always-reserved slot (present or not) so a damaged
                  // row's marker never steals width from the label
                  // column and shifts that row's progress bar left —
                  // every row must lay out identically regardless of
                  // damage state.
                  SizedBox(
                    width: 20,
                    child: damagedLabels.contains(entry.key)
                        ? const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Text('☢️', style: TextStyle(fontSize: 12)),
                          )
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _openViewer(BuildContext context, UserProfile profile, int index) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => PhotoViewerScreen(
                photos: profile.photos,
                initialIndex: index,
                owner: profile.displayName)));
  }

  void _handleMenu(
      BuildContext context, WidgetRef ref, UserProfile profile, String value) {
    if (value == 'block') {
      ref.read(appControllerProvider).blockProfile(profile);
      Navigator.pop(context);
    } else if (value == 'report') {
      _reportDialog(context, ref, profile);
    } else {
      _shareDialog(context, ref, profile);
    }
  }

  void _reportDialog(BuildContext context, WidgetRef ref, UserProfile profile) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Report Profile',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            for (final reason in ReportReason.values)
              ListTile(
                title: Text(enumName(reason)),
                onTap: () {
                  Navigator.pop(context);
                  ref
                      .read(appControllerProvider)
                      .reportProfile(profile, reason);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _commentsSection(BuildContext context, WidgetRef ref,
      AppController state, UserProfile profile,
      {int? limit}) {
    final allComments = state.commentsFor(profile.id);
    final shown =
        limit != null ? allComments.take(limit).toList() : allComments;
    final allowed = state.commentsAllowedFor(profile);
    final mineProfile = state.currentProfile?.id == profile.id;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle('Comments (${allComments.length})'),
        if (!allowed)
          const AppCard(child: Text('Comments are disabled for this profile.'))
        else ...[
          if (!mineProfile) ...[
            AppCard(
                child: CommentComposer(
                    onSubmit: (text) => ref
                        .read(appControllerProvider)
                        .addComment(profile, text))),
            const SizedBox(height: 10),
          ],
          if (shown.isEmpty)
            const AppCard(
                child: Text('No comments yet.',
                    style: TextStyle(color: AppTheme.textMuted)))
          else
            AppCard(
              child: Column(
                children: [
                  for (var i = 0; i < shown.length; i++) ...[
                    if (i > 0)
                      const Divider(color: AppTheme.border, height: 24),
                    _commentCard(context, ref, state, shown[i]),
                  ],
                ],
              ),
            ),
          if (limit != null && allComments.length > limit)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Center(
                child: TextButton(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              CommentsScreen(profileId: profile.id))),
                  child: Text('View all ${allComments.length} comments'),
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _commentCard(BuildContext context, WidgetRef ref, AppController state,
      Comment comment) {
    return CommentCard(
      comment: comment,
      authorName: authorNameFor(state, comment.authorId),
      authorPhoto: authorPhotoFor(state, comment.authorId),
      reactionCounts: state.reactionCountsFor(comment.id),
      myReactions: {
        for (final type in CommentReactionType.values)
          if (state.hasReacted(comment.id, type)) type,
      },
      canEdit: state.canEditComment(comment),
      canDelete: state.canDeleteComment(comment),
      isOwnComment: comment.authorId == state.currentUserId,
      onReact: (type) =>
          ref.read(appControllerProvider).toggleReaction(comment.id, type),
      onEdit: () => _editCommentDialog(context, ref, comment),
      onDelete: () => _confirmDeleteComment(context, ref, comment),
      onReport: () => _reportCommentDialog(context, ref, comment),
      onBlock: () =>
          ref.read(appControllerProvider).blockCommentAuthor(comment.id),
    );
  }

  void _editCommentDialog(
      BuildContext context, WidgetRef ref, Comment comment) {
    final controller = TextEditingController(text: comment.content);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit comment'),
        content: TextField(
            controller: controller,
            maxLength: Comment.maxLength,
            maxLines: 4,
            autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CANCEL')),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ref
                  .read(appControllerProvider)
                  .editComment(comment.id, controller.text);
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteComment(
      BuildContext context, WidgetRef ref, Comment comment) {
    showDeleteCommentDialog(context,
        () => ref.read(appControllerProvider).deleteComment(comment.id));
  }

  void _reportCommentDialog(
      BuildContext context, WidgetRef ref, Comment comment) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Report Comment',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            for (final reason in ReportReason.values)
              ListTile(
                title: Text(enumName(reason)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  ref
                      .read(appControllerProvider)
                      .reportComment(comment.id, reason);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _shareDialog(BuildContext context, WidgetRef ref, UserProfile profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShareProfileCard(profile: profile),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  shareProfileSummary(profile);
                  if (ref.read(appControllerProvider).currentProfile?.id ==
                      profile.id) {
                    ref.read(appControllerProvider).awardProfileSharedXp();
                  }
                },
                icon: const Icon(Icons.ios_share),
                label: const Text('SHARE'),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(
                      text:
                          '${profile.displayName} rated ${profile.ratingSummary.averageOverall.toStringAsFixed(1)}/5 on Rate My Life with a ${profile.score.overall}/100 Life Score.'));
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.copy),
                label: const Text('COPY TEXT INSTEAD'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared by `PublicProfileScreen` and `CommentsScreen` — a branded
/// destructive-confirmation dialog, styled distinctly from a regular
/// action (danger-colored icon badge and Delete button) so removing a
/// comment doesn't look like any other confirmation in the app.
Future<void> showDeleteCommentDialog(
    BuildContext context, VoidCallback onConfirm) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
            color: AppColors.danger, shape: BoxShape.circle),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      title: const Text('Delete comment?'),
      content: const Text("This can't be undone."),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCEL')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
          onPressed: () {
            Navigator.pop(dialogContext);
            onConfirm();
          },
          child: const Text('DELETE'),
        ),
      ],
    ),
  );
}

/// Shared by `PublicProfileScreen` and `CommentsScreen` — a comment's
/// author is either the local user or a mock profile already in
/// `profiles`; falls back gracefully if neither (e.g. stale local data).
String authorNameFor(AppController state, String authorId) {
  if (authorId == state.currentUserId && state.currentProfile != null) {
    return state.currentProfile!.displayName;
  }
  for (final profile in state.profiles) {
    if (profile.id == authorId) {
      return profile.displayName.isEmpty ? 'Anonymous' : profile.displayName;
    }
  }
  return 'Anonymous';
}

ProfilePhoto? authorPhotoFor(AppController state, String authorId) {
  if (authorId == state.currentUserId) {
    return state.currentProfile?.profilePhoto;
  }
  for (final profile in state.profiles) {
    if (profile.id == authorId) return profile.profilePhoto;
  }
  return null;
}

/// The full comment list for a profile — reached from "View all N
/// comments" when there are more than the inline preview shows.
class CommentsScreen extends ConsumerWidget {
  const CommentsScreen({super.key, required this.profileId});

  final String profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final profile = state.profileById(profileId);
    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final comments = state.commentsFor(profileId);
    return Scaffold(
      appBar: AppBar(title: Text('Comments (${comments.length})')),
      body: comments.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: EmptyState(
                  icon: Icons.forum_outlined,
                  title: 'No comments yet.',
                  subtitle: 'Be the first to say something.'),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                for (var i = 0; i < comments.length; i++) ...[
                  if (i > 0) const Divider(color: AppTheme.border, height: 24),
                  CommentCard(
                    comment: comments[i],
                    authorName: authorNameFor(state, comments[i].authorId),
                    authorPhoto: authorPhotoFor(state, comments[i].authorId),
                    reactionCounts: state.reactionCountsFor(comments[i].id),
                    myReactions: {
                      for (final type in CommentReactionType.values)
                        if (state.hasReacted(comments[i].id, type)) type,
                    },
                    canEdit: state.canEditComment(comments[i]),
                    canDelete: state.canDeleteComment(comments[i]),
                    isOwnComment: comments[i].authorId == state.currentUserId,
                    onReact: (type) => ref
                        .read(appControllerProvider)
                        .toggleReaction(comments[i].id, type),
                    onEdit: () => _editComment(context, ref, comments[i]),
                    onDelete: () => _confirmDelete(context, ref, comments[i]),
                    onReport: () => _report(context, ref, comments[i]),
                    onBlock: () => ref
                        .read(appControllerProvider)
                        .blockCommentAuthor(comments[i].id),
                  ),
                ],
              ],
            ),
      bottomNavigationBar: state.commentsAllowedFor(profile) &&
              state.currentProfile?.id != profileId
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: CommentComposer(
                    onSubmit: (text) => ref
                        .read(appControllerProvider)
                        .addComment(profile, text)),
              ),
            )
          : null,
    );
  }

  void _editComment(BuildContext context, WidgetRef ref, Comment comment) {
    final controller = TextEditingController(text: comment.content);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit comment'),
        content: TextField(
            controller: controller,
            maxLength: Comment.maxLength,
            maxLines: 4,
            autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CANCEL')),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ref
                  .read(appControllerProvider)
                  .editComment(comment.id, controller.text);
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Comment comment) {
    showDeleteCommentDialog(context,
        () => ref.read(appControllerProvider).deleteComment(comment.id));
  }

  void _report(BuildContext context, WidgetRef ref, Comment comment) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Report Comment',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            for (final reason in ReportReason.values)
              ListTile(
                title: Text(enumName(reason)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  ref
                      .read(appControllerProvider)
                      .reportComment(comment.id, reason);
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// One-on-one message thread with [otherUserId]. Marks incoming
/// messages read as soon as the thread opens.
class ConversationScreen extends ConsumerStatefulWidget {
  const ConversationScreen({super.key, required this.otherUserId});

  final String otherUserId;

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final ScrollController _scrollController = ScrollController();

  /// Last thread length this screen scrolled for — lets `build` detect
  /// "the thread just changed" (opened, sent, or a live message just
  /// arrived) without re-jumping on every unrelated rebuild.
  int _lastMessageCount = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = ref.read(appControllerProvider);
      controller.markConversationRead(widget.otherUserId);
      controller.ensureProfileLoaded(widget.otherUserId);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // The list previously had no ScrollController at all, so it opened
  // wherever ListView's default layout happened to land instead of the
  // newest message — the user had to scroll down manually every time.
  // Jumps rather than animates: opening a long thread should land on
  // the latest message instantly, not visibly scroll through every
  // message on the way down.
  void _scrollToBottomIfNeeded(int messageCount) {
    if (messageCount == _lastMessageCount) return;
    _lastMessageCount = messageCount;
    // Two frames, not one: the mark-as-read side effect a couple of
    // lines below schedules its own postFrameCallback for this same
    // build, and its resulting notifyListeners() lands a frame later —
    // by then the thread's own read-receipt UI may have nudged layout
    // just enough that a single jump already falls slightly short.
    _jumpToBottom(remainingFrames: 2);
  }

  void _jumpToBottom({required int remainingFrames}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      if (remainingFrames > 1) _jumpToBottom(remainingFrames: remainingFrames - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final otherProfile = state.profileById(widget.otherUserId);
    final otherName = otherProfile?.displayName.isNotEmpty == true
        ? otherProfile!.displayName
        : 'Anonymous';
    final thread = state.conversationWith(widget.otherUserId);
    _scrollToBottomIfNeeded(thread.length);
    // Not just an initState one-shot — a message that arrives live
    // while this screen is already open (the other side is mid-chat,
    // not just opening the thread) needs to get marked read too, or
    // it's still "unread" the moment you navigate away.
    if (thread.any((m) => m.recipientId == state.currentUserId && !m.isRead)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref
              .read(appControllerProvider)
              .markConversationRead(widget.otherUserId);
        }
      });
    }
    final canReply = otherProfile != null &&
        !state.blockedIds.contains(widget.otherUserId) &&
        state.messagesAllowedFor(otherProfile);
    final canCall = otherProfile != null &&
        !state.blockedIds.contains(widget.otherUserId) &&
        state.callsAllowedFor(otherProfile) &&
        state.hasConversationWith(widget.otherUserId);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.green, width: 1.2),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.green.withValues(alpha: 0.4),
                      blurRadius: 8)
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: ProfileImage(
                  photo: authorPhotoFor(state, widget.otherUserId),
                  label: otherName,
                  height: 32,
                  width: 32,
                  borderRadius: 16,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(child: Text(otherName, overflow: TextOverflow.ellipsis)),
          ],
        ),
        actions: [
          if (canCall)
            IconButton(
              icon: const Icon(Icons.call_rounded, color: AppColors.green),
              tooltip: 'Call $otherName',
              onPressed: () =>
                  ref.read(appControllerProvider).startCall(otherProfile),
            ),
          if (otherProfile != null)
            PopupMenuButton<String>(
              onSelected: (value) => switch (value) {
                'block' =>
                  ref.read(appControllerProvider).blockProfile(otherProfile),
                'delete' => _confirmDeleteConversation(
                    context, ref, widget.otherUserId, otherName),
                _ => null,
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete_outline_rounded,
                        size: 18, color: AppColors.danger),
                    SizedBox(width: 10),
                    Text('Delete Conversation',
                        style: TextStyle(color: AppColors.danger))
                  ]),
                ),
                PopupMenuItem(
                  value: 'block',
                  child: Row(children: [
                    const Icon(Icons.block_rounded,
                        size: 18, color: AppColors.danger),
                    const SizedBox(width: 10),
                    Text('Block $otherName',
                        style: const TextStyle(color: AppColors.danger))
                  ]),
                ),
              ],
            ),
        ],
      ),
      body: thread.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: EmptyState(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'No messages yet.',
                  subtitle: 'Say hello.'),
            )
          : ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              children: [
                for (final message in thread)
                  MessageBubble(
                    message: message,
                    isMine: message.senderId == state.currentUserId,
                    onLongPress: () =>
                        _showMessageActions(context, ref, message),
                  ),
              ],
            ),
      bottomNavigationBar: canReply
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: MessageComposer(
                    onSubmit: (text) => ref
                        .read(appControllerProvider)
                        .sendMessage(otherProfile, text)),
              ),
            )
          : const SafeArea(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('You can\'t message this person right now.',
                    style: TextStyle(color: AppTheme.textMuted)),
              ),
            ),
    );
  }

  void _confirmDeleteConversation(BuildContext context, WidgetRef ref,
      String otherUserId, String otherName) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Conversation?'),
        content: Text(
            'This removes your copy of the conversation with $otherName. They\'ll still see their own copy.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context);
              ref.read(appControllerProvider).deleteConversation(otherUserId);
            },
            child:
                const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  void _showMessageActions(
      BuildContext context, WidgetRef ref, Message message) {
    final isMine =
        message.senderId == ref.read(appControllerProvider).currentUserId;
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            if (isMine)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.danger),
                title: const Text('Delete',
                    style: TextStyle(color: AppColors.danger)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  ref.read(appControllerProvider).deleteMessage(message.id);
                },
              )
            else
              ListTile(
                leading:
                    const Icon(Icons.flag_outlined, color: AppColors.danger),
                title: const Text('Report & Block',
                    style: TextStyle(color: AppColors.danger)),
                onTap: () => _reportMessage(sheetContext, ref, message),
              ),
          ],
        ),
      ),
    );
  }

  void _reportMessage(
      BuildContext sheetContext, WidgetRef ref, Message message) {
    showModalBottomSheet(
      context: sheetContext,
      builder: (reasonContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Report Message',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            for (final reason in ReportReason.values)
              ListTile(
                title: Text(enumName(reason)),
                onTap: () {
                  Navigator.pop(reasonContext);
                  Navigator.pop(sheetContext);
                  ref
                      .read(appControllerProvider)
                      .reportMessage(message.id, reason);
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen audio-call UI — ringing (both directions) and active call.
/// Rendered by `AppShell` in place of the normal tabbed shell whenever
/// `AppController.currentCall` is non-null, so it appears the instant a
/// call starts or arrives regardless of which tab/screen was open, and
/// disappears automatically once the call ends on either side.
class CallScreen extends ConsumerStatefulWidget {
  const CallScreen({super.key});

  @override
  ConsumerState<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen> {
  Timer? _ticker;
  Duration _activeElapsed = Duration.zero;
  bool _wasActive = false;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _syncTicker(bool active) {
    if (active && !_wasActive) {
      _activeElapsed = Duration.zero;
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() => _activeElapsed += const Duration(seconds: 1));
        }
      });
    } else if (!active && _wasActive) {
      _ticker?.cancel();
      _ticker = null;
    }
    _wasActive = active;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final call = state.currentCall;
    if (call == null) return const SizedBox.shrink();
    _syncTicker(call.status == CallStatus.active);

    final isCaller = call.callerId == state.currentUserId;
    final otherId = call.otherUserId(state.currentUserId);
    final otherProfile = state.profileById(otherId);
    if (otherProfile == null) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => ref.read(appControllerProvider).ensureProfileLoaded(otherId));
    }
    final otherName = otherProfile?.displayName.isNotEmpty == true
        ? otherProfile!.displayName
        : 'Anonymous';

    final String statusText;
    if (call.status == CallStatus.active) {
      final minutes = _activeElapsed.inMinutes.toString().padLeft(2, '0');
      final seconds =
          (_activeElapsed.inSeconds % 60).toString().padLeft(2, '0');
      statusText = '$minutes:$seconds';
    } else if (isCaller) {
      statusText = 'Calling…';
    } else {
      statusText = 'Incoming call';
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              const Spacer(),
              CircleAvatar(
                radius: 64,
                backgroundColor: AppColors.surfaceHigh,
                child: Text(
                  otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
                  style: AppTypography.hero.copyWith(fontSize: 48),
                ),
              ),
              const SizedBox(height: 24),
              Text(otherName,
                  style: AppTypography.title, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(statusText, style: AppTypography.bodyMuted),
              const Spacer(),
              if (call.status == CallStatus.ringing && !isCaller)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _callButton(
                      icon: Icons.call_end_rounded,
                      color: AppColors.neonRed,
                      label: 'Decline',
                      onTap: () =>
                          ref.read(appControllerProvider).declineCall(),
                    ),
                    _callButton(
                      icon: Icons.call_rounded,
                      color: AppColors.green,
                      label: 'Accept',
                      onTap: () => ref.read(appControllerProvider).acceptCall(),
                    ),
                  ],
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (call.status == CallStatus.active)
                      _callButton(
                        icon: state.isCallMuted
                            ? Icons.mic_off_rounded
                            : Icons.mic_rounded,
                        color: AppColors.surfaceHigh,
                        label: state.isCallMuted ? 'Unmute' : 'Mute',
                        onTap: () =>
                            ref.read(appControllerProvider).toggleCallMute(),
                      ),
                    _callButton(
                      icon: Icons.call_end_rounded,
                      color: AppColors.neonRed,
                      label: isCaller && call.status == CallStatus.ringing
                          ? 'Cancel'
                          : 'End',
                      onTap: () => ref.read(appControllerProvider).endCall(),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _callButton(
      {required IconData icon,
      required Color color,
      required String label,
      required VoidCallback onTap}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: CircleAvatar(
              radius: 32,
              backgroundColor: color,
              child: Icon(icon, color: Colors.white, size: 28)),
        ),
        const SizedBox(height: 8),
        Text(label, style: AppTypography.caption),
      ],
    );
  }
}

/// Inbox: a horizontal strip of the most recently-active conversations
/// (neon-ringed avatars, tap to jump straight in), then the full list,
/// most recent message first.
class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  String _otherIdFor(AppController state, Message message) =>
      message.senderId == state.currentUserId
          ? message.recipientId
          : message.senderId;

  int _unreadCountFor(AppController state, String otherId) => state.messages
      .where((m) =>
          m.senderId == otherId &&
          m.recipientId == state.currentUserId &&
          !m.isRead)
      .length;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final latest = state.conversations;
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: latest.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: EmptyState(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'No conversations yet.',
                  subtitle: 'Message someone from their profile to start one.'),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              children: [
                SizedBox(
                  height: 88,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: latest.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (context, i) {
                      final otherId = _otherIdFor(state, latest[i]);
                      final name = authorNameFor(state, otherId);
                      return GestureDetector(
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    ConversationScreen(otherUserId: otherId))),
                        child: SizedBox(
                          width: 64,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: AppColors.green, width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                        color: AppColors.green
                                            .withValues(alpha: 0.45),
                                        blurRadius: 10)
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: ProfileImage(
                                      photo: authorPhotoFor(state, otherId),
                                      label: name,
                                      height: 48,
                                      width: 48,
                                      borderRadius: 24),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: AppTypography.caption
                                    .copyWith(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                const SectionTitle('Recent'),
                for (final message in latest)
                  Builder(builder: (context) {
                    final otherId = _otherIdFor(state, message);
                    final unreadCount = _unreadCountFor(state, otherId);
                    final unread = unreadCount > 0;
                    final name = authorNameFor(state, otherId);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Dismissible(
                        key: ValueKey('conversation_$otherId'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                              color: AppColors.danger.withValues(alpha: 0.85),
                              borderRadius: AppRadius.lgRadius),
                          child: const Icon(Icons.delete_rounded,
                              color: Colors.white),
                        ),
                        confirmDismiss: (_) => showDialog<bool>(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: const Text('Delete Conversation?'),
                            content: Text(
                                'This removes your copy of the conversation with $name. They\'ll still see their own copy.'),
                            actions: [
                              TextButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, false),
                                  child: const Text('Cancel')),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(dialogContext, true),
                                child: const Text('Delete',
                                    style: TextStyle(color: AppColors.danger)),
                              ),
                            ],
                          ),
                        ).then((confirmed) => confirmed ?? false),
                        onDismissed: (_) => ref
                            .read(appControllerProvider)
                            .deleteConversation(otherId),
                        child: AppCard(
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => ConversationScreen(
                                      otherUserId: otherId))),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: unread
                                    ? BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: AppColors.green, width: 1.5),
                                        boxShadow: [
                                          BoxShadow(
                                              color: AppColors.green
                                                  .withValues(alpha: 0.4),
                                              blurRadius: 8)
                                        ],
                                      )
                                    : null,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: ProfileImage(
                                      photo: authorPhotoFor(state, otherId),
                                      label: authorNameFor(state, otherId),
                                      height: 48,
                                      width: 48,
                                      borderRadius: 24),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(authorNameFor(state, otherId),
                                        style: TextStyle(
                                            fontWeight: unread
                                                ? FontWeight.w900
                                                : FontWeight.w700)),
                                    const SizedBox(height: 2),
                                    Text(
                                      message.content,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          color: AppTheme.textMuted,
                                          fontWeight: unread
                                              ? FontWeight.w700
                                              : FontWeight.normal),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(timeAgo(message.createdAt),
                                      style: const TextStyle(
                                          color: AppTheme.textMuted,
                                          fontSize: 11)),
                                  const SizedBox(height: 6),
                                  if (unread)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        gradient: AppColors.greenGradient,
                                        borderRadius: AppRadius.pillRadius,
                                        boxShadow: [
                                          BoxShadow(
                                              color: AppColors.green
                                                  .withValues(alpha: 0.5),
                                              blurRadius: 8)
                                        ],
                                      ),
                                      child: Text(
                                        '$unreadCount',
                                        style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w900),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
    );
  }
}

class PhotoViewerScreen extends StatefulWidget {
  const PhotoViewerScreen(
      {super.key,
      required this.photos,
      required this.initialIndex,
      required this.owner});

  final List<ProfilePhoto> photos;
  final int initialIndex;
  final String owner;

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  late final PageController _controller =
      PageController(initialPage: widget.initialIndex);
  late int index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photos = [...widget.photos]
      ..sort((a, b) => a.order.compareTo(b.order));
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('${index + 1} / ${photos.length}'),
      ),
      body: PageView.builder(
        controller: _controller,
        onPageChanged: (value) => setState(() => index = value),
        itemCount: photos.length,
        itemBuilder: (context, i) => InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Center(
            child: ProfileImage(
                photo: photos[i],
                label: widget.owner,
                height: MediaQuery.of(context).size.height * 0.72,
                borderRadius: 0),
          ),
        ),
      ),
    );
  }
}

class RateFeedScreen extends ConsumerStatefulWidget {
  const RateFeedScreen({super.key});

  @override
  ConsumerState<RateFeedScreen> createState() => _RateFeedScreenState();
}

class _RateFeedScreenState extends ConsumerState<RateFeedScreen> {
  int pointer = 0;
  int rating = 4;
  int lookRating = 4;

  void _skip() => setState(() {
        pointer++;
        rating = 4;
        lookRating = 4;
      });

  Future<void> _submit(UserProfile profile) async {
    await ref
        .read(appControllerProvider)
        .submitRating(profile, rating, lookRating);
    _skip();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final queue = state.rateQueue();
    if (queue.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rate')),
        body: const Padding(
          padding: EdgeInsets.all(20),
          child: EmptyState(
              icon: Icons.star_border,
              title: "We've run out of lives to judge.",
              subtitle:
                  'Discover will refill as more public profiles are available.'),
        ),
      );
    }
    final profile = queue[pointer % queue.length];
    return Scaffold(
      appBar: AppBar(title: const Text('Rate')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text("WHO'S LIFE WOULD YOU RATHER HAVE?",
              style:
                  TextStyle(color: AppTheme.gold, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text('Swipe right to rate, left to skip.',
              style: AppTypography.bodyMuted.copyWith(fontSize: 12.5)),
          const SizedBox(height: 12),
          _SwipeCard(
            key: ValueKey(profile.id),
            profile: profile,
            onSwipeRight: () => _submit(profile),
            onSwipeLeft: _skip,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        PublicProfileScreen(profileId: profile.id))),
          ),
          const SectionTitle('Your Rating'),
          AppCard(
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.favorite, color: AppColors.pink, size: 18),
                    const SizedBox(width: 6),
                    const Text('LOOK',
                        style: TextStyle(fontWeight: FontWeight.w900)),
                    const Spacer(),
                    Text('$lookRating / 5',
                        style: const TextStyle(color: AppTheme.textMuted)),
                  ],
                ),
                const SizedBox(height: 10),
                RatingSelector(
                    value: lookRating,
                    onChanged: (value) => setState(() => lookRating = value)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Icon(Icons.auto_awesome,
                        color: AppColors.purple, size: 18),
                    const SizedBox(width: 6),
                    const Text('LIFE',
                        style: TextStyle(fontWeight: FontWeight.w900)),
                    const Spacer(),
                    Text('$rating / 5',
                        style: const TextStyle(color: AppTheme.textMuted)),
                  ],
                ),
                const SizedBox(height: 10),
                RatingSelector(
                    value: rating,
                    onChanged: (value) => setState(() => rating = value)),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () => _submit(profile),
                  icon: const Icon(Icons.star),
                  label: const Text('SUBMIT'),
                ),
                TextButton.icon(
                  onPressed: _skip,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('NEXT LIFE'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A Tinder-style draggable card: drag past the threshold to submit the
/// current rating (right) or skip to the next profile (left).
class _SwipeCard extends StatefulWidget {
  const _SwipeCard({
    super.key,
    required this.profile,
    required this.onSwipeLeft,
    required this.onSwipeRight,
    required this.onTap,
  });

  final UserProfile profile;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;
  final VoidCallback onTap;

  @override
  State<_SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<_SwipeCard>
    with SingleTickerProviderStateMixin {
  static const _threshold = 110.0;

  Offset _drag = Offset.zero;
  late final AnimationController _controller;
  Animation<Offset>? _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 260))
      ..addListener(() {
        final animation = _animation;
        if (animation != null) setState(() => _drag = animation.value);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) =>
      setState(() => _drag += details.delta);

  void _onPanEnd(DragEndDetails details) {
    if (_drag.dx > _threshold) {
      _fling(right: true);
    } else if (_drag.dx < -_threshold) {
      _fling(right: false);
    } else {
      _springBack();
    }
  }

  void _fling({required bool right}) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final end =
        Offset(right ? screenWidth * 1.4 : -screenWidth * 1.4, _drag.dy);
    _animation = Tween<Offset>(begin: _drag, end: end).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInCubic));
    _controller.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      right ? widget.onSwipeRight() : widget.onSwipeLeft();
    });
  }

  void _springBack() {
    _animation = Tween<Offset>(begin: _drag, end: Offset.zero).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final angle = (_drag.dx / 300).clamp(-0.4, 0.4).toDouble();
    final likeOpacity = (_drag.dx / _threshold).clamp(0.0, 1.0).toDouble();
    final passOpacity = (-_drag.dx / _threshold).clamp(0.0, 1.0).toDouble();
    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onTap: widget.onTap,
      child: Transform.translate(
        offset: _drag,
        child: Transform.rotate(
          angle: angle,
          alignment: Alignment.bottomCenter,
          child: _RateCardVisual(
              profile: widget.profile,
              likeOpacity: likeOpacity,
              passOpacity: passOpacity),
        ),
      ),
    );
  }
}

class _RateCardVisual extends StatelessWidget {
  const _RateCardVisual(
      {required this.profile,
      required this.likeOpacity,
      required this.passOpacity});

  final UserProfile profile;
  final double likeOpacity;
  final double passOpacity;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.lgRadius,
      child: SizedBox(
        height: 460,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ProfileImage(
                photo: profile.profilePhoto,
                label: profile.displayName,
                height: 460),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.45, 1.0],
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.88)
                  ],
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    profile.privacy.showAge
                        ? '${profile.displayName}, ${profile.age}'
                        : profile.displayName,
                    style: AppTypography.title.copyWith(color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (profile.privacy.showCareer &&
                          (profile.jobTitle ?? profile.jobCategory).isNotEmpty)
                        _EssentialChip(
                            icon: Icons.work_outline,
                            label: (profile.jobTitle ?? profile.jobCategory)),
                      if (profile.privacy.showIncome)
                        _EssentialChip(
                            icon: Icons.payments_outlined,
                            label:
                                '${profile.monthlyIncome.round()} ${profile.currency}/mo'),
                      if (profile.ownsCar)
                        _EssentialChip(
                          icon: Icons.directions_car_filled_outlined,
                          label: (profile.carModel?.isNotEmpty ?? false)
                              ? profile.carModel!
                              : 'Owns a car',
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: 22,
              right: 22,
              child: Opacity(
                  opacity: likeOpacity,
                  child:
                      const _StampBadge(label: 'RATE', color: AppColors.gold)),
            ),
            Positioned(
              top: 22,
              left: 22,
              child: Opacity(
                  opacity: passOpacity,
                  child:
                      const _StampBadge(label: 'SKIP', color: AppColors.pink)),
            ),
          ],
        ),
      ),
    );
  }
}

class _EssentialChip extends StatelessWidget {
  const _EssentialChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: AppRadius.pillRadius,
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5)),
        ],
      ),
    );
  }
}

class _StampBadge extends StatelessWidget {
  const _StampBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.25,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 3),
          borderRadius: AppRadius.smRadius,
          color: Colors.black.withValues(alpha: 0.25),
        ),
        child: Text(
          label,
          style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 22,
              letterSpacing: 1.5),
        ),
      ),
    );
  }
}

enum _LeaderboardScope { global, country, city, age }

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  _LeaderboardScope scope = _LeaderboardScope.global;

  static const _scopeMeta = {
    _LeaderboardScope.global: (icon: Icons.public, label: 'GLOBAL'),
    _LeaderboardScope.country: (icon: Icons.flag_outlined, label: 'COUNTRY'),
    _LeaderboardScope.city: (icon: Icons.location_city, label: 'CITY'),
    _LeaderboardScope.age: (icon: Icons.cake_outlined, label: 'AGE'),
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(appControllerProvider).loadMoreLeaderboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final me = state.currentProfile;
    var profiles = state.leaderboardProfiles;
    if (profiles.isEmpty &&
        state.leaderboardHasMore &&
        !state.leaderboardLoadingMore) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(appControllerProvider).loadMoreLeaderboard();
      });
    }
    final scopeUnavailable = me == null && scope != _LeaderboardScope.global;
    if (me != null) {
      profiles = switch (scope) {
        _LeaderboardScope.global => profiles,
        _LeaderboardScope.country =>
          profiles.where((p) => p.country == me.country).toList(),
        _LeaderboardScope.city =>
          profiles.where((p) => p.city == me.city).toList(),
        _LeaderboardScope.age =>
          profiles.where((p) => (p.age - me.age).abs() <= 5).toList(),
      };
    }
    profiles = profiles.take(50).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Top Rated Lives')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in _scopeMeta.entries)
                ChoiceChip(
                  avatar: Icon(entry.value.icon,
                      size: 16,
                      color: scope == entry.key
                          ? Colors.black
                          : AppTheme.textMuted),
                  label: Text(entry.value.label),
                  selected: scope == entry.key,
                  onSelected: (_) => setState(() => scope = entry.key),
                ),
            ],
          ),
          if (scopeUnavailable) ...[
            const SizedBox(height: 8),
            Text(
                'Create a profile to filter by your own country, city, or age.',
                style: AppTypography.bodyMuted.copyWith(fontSize: 12.5)),
          ],
          const SizedBox(height: 14),
          if (profiles.isEmpty)
            EmptyState(
              icon: Icons.leaderboard,
              title: 'No leaderboard yet.',
              subtitle: 'Public profiles with ratings will appear here.',
              action: FilledButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PrivacySettingsScreen())),
                child: const Text('PRIVACY SETTINGS'),
              ),
            )
          else
            for (var i = 0; i < profiles.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              PublicProfileScreen(profileId: profiles[i].id))),
                  child: Row(
                    children: [
                      _RankBadge(rank: i + 1),
                      const SizedBox(width: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: ProfileImage(
                          photo: profiles[i].privacy.showPhotos
                              ? profiles[i].profilePhoto
                              : null,
                          label: profiles[i].displayName,
                          height: 56,
                          width: 56,
                          borderRadius: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profiles[i].displayName.isEmpty
                                  ? 'Anonymous'
                                  : profiles[i].displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.body
                                  .copyWith(fontWeight: FontWeight.w800),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.place,
                                    size: 13, color: AppTheme.textMuted),
                                const SizedBox(width: 3),
                                Text(profiles[i].country,
                                    style: AppTypography.bodyMuted
                                        .copyWith(fontSize: 12.5)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          gradient: AppColors.goldGradient,
                          borderRadius: AppRadius.pillRadius,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            StarRating(
                                value: profiles[i].ratingSummary.averageOverall,
                                size: 13,
                                color: Colors.black),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

/// Where the AI algorithm and the community disagree the most — the Score
/// screen already frames that disagreement as part of the game; this
/// screen turns it into a discovery hook, using only real, already-known
/// scores and ratings (no new model, no fabricated data).
class BiggestGapsScreen extends ConsumerWidget {
  const BiggestGapsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final profiles = state.biggestGapProfiles.take(50).toList();
    if (profiles.isEmpty && state.gapHasMore && !state.gapLoadingMore) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => ref.read(appControllerProvider).loadMoreGap());
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Biggest Gaps')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ShaderMask(
            shaderCallback: (bounds) => AppColors.neonRedGradient.createShader(bounds),
            child: Text('🔥 BIGGEST GAPS',
                style: AppTypography.hero.copyWith(fontSize: 30, color: Colors.white)),
          ),
          const SizedBox(height: 4),
          Text('When the algorithm and people see life differently...', style: AppTypography.bodyMuted),
          const SizedBox(height: 6),
          Text(
            'These profiles have the biggest gap between their calculated Life Score and community ratings — neither one is objectively "correct".',
            style: AppTypography.caption,
          ),
          const SizedBox(height: 16),
          if (profiles.isEmpty)
            const EmptyState(
              icon: Icons.compare_arrows_rounded,
              title: '👀 Not enough data yet',
              subtitle:
                  'We need more community ratings before the biggest gaps can appear.',
            )
          else
            for (var i = 0; i < profiles.length; i++)
              _StaggerIn(
                delay: Duration(milliseconds: 60 * i.clamp(0, 8)),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _GapCard(
                    profile: profiles[i],
                    algorithmScore: profiles[i].score.overall,
                    communityScore: state.communityScoreOf(profiles[i].ratingSummary),
                    gap: state.gapFor(profiles[i]) ?? 0,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => PublicProfileScreen(profileId: profiles[i].id))),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _GapCard extends StatelessWidget {
  const _GapCard({
    required this.profile,
    required this.algorithmScore,
    required this.communityScore,
    required this.gap,
    required this.onTap,
  });

  final UserProfile profile;
  final int algorithmScore;
  final int communityScore;
  final int gap;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: ProfileFrame(
                  frameId: profile.equippedFrameId,
                  borderRadius: 24,
                  child: ProfileImage(
                    photo: profile.privacy.showPhotos ? profile.profilePhoto : null,
                    label: profile.displayName,
                    height: 48,
                    width: 48,
                    borderRadius: 24,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  profile.displayName.isEmpty ? 'Anonymous' : profile.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    gradient: AppColors.purpleGradient, borderRadius: AppRadius.pillRadius),
                child: Text('+$gap',
                    style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _gapBar('Algorithm', algorithmScore, AppTheme.accent),
          const SizedBox(height: 6),
          _gapBar('Community', communityScore, AppColors.gold),
        ],
      ),
    );
  }

  Widget _gapBar(String label, int value, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(label, style: AppTypography.caption.copyWith(color: AppTheme.textMuted)),
        ),
        Expanded(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value / 100),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: v,
                minHeight: 10,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 28,
          child: Text('$value',
              textAlign: TextAlign.right,
              style: AppTypography.body.copyWith(fontWeight: FontWeight.w900, color: color)),
        ),
      ],
    );
  }
}

/// Recently-created, publicly-discoverable profiles already earning
/// real engagement — an honest "New & Rising" list, not a fabricated
/// live growth-rate feed (see `TrendingService`'s own doc comment).
class TrendingScreen extends ConsumerWidget {
  const TrendingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final profiles = state.trendingProfiles.take(50).toList();
    if (profiles.isEmpty &&
        state.trendingHasMore &&
        !state.trendingLoadingMore) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => ref.read(appControllerProvider).loadMoreTrending());
    }
    return Scaffold(
      appBar: AppBar(title: const Text('New & Rising')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ShaderMask(
            shaderCallback: (bounds) => AppColors.blueGradient.createShader(bounds),
            child: Text('🚀 NEW & RISING',
                style: AppTypography.hero.copyWith(fontSize: 30, color: Colors.white)),
          ),
          const SizedBox(height: 4),
          Text('Fresh profiles getting attention.', style: AppTypography.bodyMuted),
          const SizedBox(height: 6),
          Text(
            'Newer profiles already earning real views and ratings — not a fake live feed, just genuinely recent activity.',
            style: AppTypography.caption,
          ),
          const SizedBox(height: 16),
          if (profiles.isEmpty)
            const EmptyState(
              icon: Icons.trending_up_rounded,
              title: '🚀 Nothing rising yet',
              subtitle:
                  'New public profiles that pick up views or ratings will show up here.',
            )
          else
            for (var i = 0; i < profiles.length; i++)
              _StaggerIn(
                delay: Duration(milliseconds: 60 * i.clamp(0, 8)),
                child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              PublicProfileScreen(profileId: profiles[i].id))),
                  child: Row(
                    children: [
                      _RankBadge(rank: i + 1),
                      const SizedBox(width: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: ProfileFrame(
                          frameId: profiles[i].equippedFrameId,
                          borderRadius: 28,
                          child: ProfileImage(
                            photo: profiles[i].privacy.showPhotos
                                ? profiles[i].profilePhoto
                                : null,
                            label: profiles[i].displayName,
                            height: 56,
                            width: 56,
                            borderRadius: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    profiles[i].displayName.isEmpty
                                        ? 'Anonymous'
                                        : profiles[i].displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.body
                                        .copyWith(fontWeight: FontWeight.w800),
                                  ),
                                ),
                                if (i < 3) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                        color: AppColors.gold.withValues(alpha: 0.18),
                                        borderRadius: AppRadius.pillRadius),
                                    child: const Text('🔥 RISING',
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.gold)),
                                  ),
                                ],
                                if (DateTime.now()
                                        .difference(profiles[i].createdAt)
                                        .inDays <
                                    3) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                        color: AppColors.green
                                            .withValues(alpha: 0.18),
                                        borderRadius: AppRadius.pillRadius),
                                    child: const Text('✨ NEW',
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.green)),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.visibility_outlined,
                                    size: 13, color: AppTheme.textMuted),
                                const SizedBox(width: 3),
                                Text('${profiles[i].viewCount} views',
                                    style: const TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 12.5)),
                                const SizedBox(width: 10),
                                const Icon(Icons.star_rounded,
                                    size: 13, color: AppTheme.textMuted),
                                const SizedBox(width: 3),
                                Text('${profiles[i].ratingSummary.count} ratings',
                                    style: const TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 12.5)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    const medalColors = {
      1: AppColors.gold,
      2: Color(0xFFC7D0DA),
      3: Color(0xFFE0954B),
    };
    final medal = medalColors[rank];
    if (medal != null) {
      return NeonIconBadge(
          icon: Icons.emoji_events_rounded, accent: medal, size: 44);
    }
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppTheme.surfaceHigh,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.border),
      ),
      child: Text('$rank',
          style: AppTypography.body
              .copyWith(fontWeight: FontWeight.w800, fontSize: 14)),
    );
  }
}

class MeScreen extends ConsumerWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final profile = state.currentProfile!;
    return Scaffold(
      appBar: AppBar(title: const Text('Me')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          LifestyleProfileCard(
              profile: profile,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          PublicProfileScreen(profileId: profile.id)))),
          const SizedBox(height: 14),
          Align(
              alignment: Alignment.centerRight,
              child: CoinBalancePill(balance: state.wallet.balance)),
          const SizedBox(height: 10),
          NukeStatusBanner(
            profile: profile,
            balance: state.wallet.balance,
            onCure: (attribute) => showCureRevealSheet(context, attribute),
          ),
          const SizedBox(height: 10),
          LevelProgressCard(levelInfo: state.levelInfo),
          const SizedBox(height: 14),
          StreakCard(
              streakDays: state.currentStreakDays,
              lastSevenDays: state.lastSevenDays),
          // Split from one flat "Account" list into two: editing/visibility
          // of your own profile vs. app features that happen to live under
          // Me because they don't have their own nav-bar tab — two
          // different concerns previously mixed into a single list.
          const SectionTitle('Your Profile'),
          AppCard(
            child: Column(
              children: [
                _ActionRow(
                    icon: Icons.edit,
                    label: 'Edit Profile',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                ProfileWizardScreen(editing: profile)))),
                _ActionRow(
                    icon: Icons.photo_library_outlined,
                    label: 'Edit Photos',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PhotoManagerScreen()))),
                _ActionRow(
                    icon: Icons.speed,
                    label: 'Score Details',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ScoreScreen()))),
                _ActionRow(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Privacy Settings',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PrivacySettingsScreen()))),
              ],
            ),
          ),
          const SectionTitle('App'),
          AppCard(
            child: Column(
              children: [
                _ActionRow(
                  icon: Icons.emoji_events_outlined,
                  label: 'Achievements',
                  badge:
                      '${state.unlockedAchievementIds.length} / ${AchievementService.catalog.length}',
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AchievementsScreen())),
                ),
                _ActionRow(
                  icon: Icons.sports_martial_arts_rounded,
                  label: 'Life Battles',
                  badge: state.battlesVotedCount > 0
                      ? '${state.battlesVotedCount} judged'
                      : null,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const BattleScreen())),
                ),
                _ActionRow(
                  icon: Icons.auto_awesome_rounded,
                  label: 'Customize',
                  badge: state.ownedFrameIds.isNotEmpty
                      ? '${state.ownedFrameIds.length} owned'
                      : null,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CosmeticsScreen())),
                ),
              ],
            ),
          ),
          const SectionTitle('Shareable Card'),
          ShareProfileCard(profile: profile),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () {
              shareProfileSummary(profile);
              ref.read(appControllerProvider).awardProfileSharedXp();
            },
            icon: const Icon(Icons.ios_share),
            label: const Text('SHARE PROFILE'),
          ),
          const SectionTitle('Settings'),
          AppCard(
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: state.settings.notifications,
                  onChanged: (value) => ref
                      .read(appControllerProvider)
                      .updateSettings(
                          state.settings.copyWith(notifications: value)),
                  title: const Text('Notifications'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: state.settings.sound,
                  onChanged: (value) => ref
                      .read(appControllerProvider)
                      .updateSettings(state.settings.copyWith(sound: value)),
                  title: const Text('Sound'),
                ),
                _ActionRow(
                    icon: Icons.file_download_outlined,
                    label: 'Export My Data',
                    onTap: () => Clipboard.setData(
                        ClipboardData(text: encodeJson(profile.toJson())))),
                _ActionRow(
                    icon: Icons.info_outline,
                    label: 'About Rate My Life',
                    onTap: () => _dialog(context, 'About Rate My Life',
                        'Rate My Life benchmarks lifestyle data and community perception. It is not a measure of human worth.')),
                _ActionRow(
                    icon: Icons.policy_outlined,
                    label: 'Privacy',
                    onTap: () => _dialog(context, 'Privacy',
                        'You control profile visibility and sensitive fields. Raters are anonymous in this MVP.')),
                _ActionRow(
                    icon: Icons.description_outlined,
                    label: 'Terms',
                    onTap: () => _dialog(context, 'Terms',
                        'Do not harass, impersonate, or upload content you do not have permission to share.')),
                _ActionRow(
                    icon: Icons.delete_forever,
                    label: 'Delete My Data',
                    onTap: () => _confirmDelete(context, ref)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _dialog(BuildContext context, String title, String body) {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
                title: Text(title),
                content: Text(body),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'))
                ]));
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete profile?'),
        content:
            const Text('This removes your local profile from this device.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL')),
          FilledButton(
              onPressed: () {
                Navigator.pop(context);
                ref.read(appControllerProvider).deleteProfile();
              },
              child: const Text('DELETE')),
        ],
      ),
    );
  }
}

class ScoreScreen extends ConsumerWidget {
  const ScoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final profile = state.currentProfile!;
    return Scaffold(
      appBar: AppBar(title: const Text('Your Score')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: ScoreBadge(
              score: profile.score.overall,
              subtitle: profile.ratingSummary.hasRatings
                  ? 'Look ${profile.ratingSummary.averageLook.toStringAsFixed(1)} · Life ${profile.ratingSummary.averageOverall.toStringAsFixed(1)} / 5'
                  : 'No community ratings yet.',
            ),
          ),
          const SectionTitle('Algorithm vs People'),
          const AppCard(
            child: Text(
                'The algorithm evaluates your submitted life data.\n\nPeople rate the lifestyle they see.\n\nThey can disagree, and that difference is part of the game.'),
          ),
          const SectionTitle('Compared to Others'),
          AppCard(
            child: Column(
              children: [
                _ComparisonRow(
                    label: 'Overall', percentile: state.overallPercentile),
                _ComparisonRow(
                    label: 'Your age group (±5 yrs)',
                    percentile: state.agePercentile),
                _ComparisonRow(
                    label: profile.country,
                    percentile: state.countryPercentile),
              ],
            ),
          ),
          const SectionTitle('Score Breakdown'),
          for (final entry in profile.score.breakdown.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: Text(entry.key.toUpperCase(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900))),
                        Text('${entry.value}',
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.w900)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                        value: entry.value / 100, minHeight: 8),
                    const SizedBox(height: 8),
                    Text(
                        profile.score.explanations[entry.key] ??
                            'This category is part of your lifestyle benchmark.',
                        style: const TextStyle(color: AppTheme.textMuted)),
                    const SizedBox(height: 4),
                    Text('Percentile: ${state.categoryPercentile(entry.key)}%',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ),
          const SectionTitle('Community Feedback'),
          const AppCard(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                MetricPill(icon: Icons.work_outline, label: 'Career'),
                MetricPill(icon: Icons.flight_takeoff, label: 'Travel'),
                MetricPill(icon: Icons.savings_outlined, label: 'Money'),
                MetricPill(icon: Icons.fitness_center, label: 'Fitness'),
              ],
            ),
          ),
          const SectionTitle('Score History'),
          AppCard(child: _ScoreHistoryChart(history: profile.history)),
          const SizedBox(height: 18),
          GradientButton(
            label: 'What If? Simulator',
            gradient: AppColors.greenGradient,
            foregroundColor: Colors.black,
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => WhatIfScreen(original: profile))),
          ),
        ],
      ),
    );
  }
}

/// One row of "Compared to Others" — a real percentile against
/// currently-known other profiles for that comparison scope (see
/// `AppController.overallPercentile`/`agePercentile`/`countryPercentile`).
class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({required this.label, required this.percentile});

  final String label;
  final int percentile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w700))),
          Text('Better than $percentile%',
              style: const TextStyle(
                  fontWeight: FontWeight.w900, color: AppTheme.gold)),
        ],
      ),
    );
  }
}

/// A pure "what if I changed X" preview: adjusts a scratch copy of the
/// current profile and re-runs the real `LifeScoreService` on it, live —
/// never persisted, never touches the repository, so there's no risk of
/// this exploration accidentally overwriting the real profile.
class WhatIfScreen extends StatefulWidget {
  const WhatIfScreen({super.key, required this.original});

  final UserProfile original;

  @override
  State<WhatIfScreen> createState() => _WhatIfScreenState();
}

class _WhatIfScreenState extends State<WhatIfScreen> {
  static const _service = LifeScoreService();

  late String country = widget.original.country;
  late String employment = widget.original.employmentStatus;
  late double income = widget.original.monthlyIncome;
  late double savings = widget.original.savings;
  late String living = widget.original.livingSituation;
  late String exercise = widget.original.exerciseFrequency;
  late int friends = widget.original.closeFriends;
  late int happiness = widget.original.happiness;

  LifeScore get _simulated => _service.calculate(widget.original.copyWith(
        country: country,
        employmentStatus: employment,
        monthlyIncome: income,
        savings: savings,
        livingSituation: living,
        exerciseFrequency: exercise,
        closeFriends: friends,
        happiness: happiness,
      ));

  void _reset() => setState(() {
        country = widget.original.country;
        employment = widget.original.employmentStatus;
        income = widget.original.monthlyIncome;
        savings = widget.original.savings;
        living = widget.original.livingSituation;
        exercise = widget.original.exerciseFrequency;
        friends = widget.original.closeFriends;
        happiness = widget.original.happiness;
      });

  bool get _hasChanges =>
      country != widget.original.country ||
      employment != widget.original.employmentStatus ||
      income != widget.original.monthlyIncome ||
      savings != widget.original.savings ||
      living != widget.original.livingSituation ||
      exercise != widget.original.exerciseFrequency ||
      friends != widget.original.closeFriends ||
      happiness != widget.original.happiness;

  @override
  Widget build(BuildContext context) {
    final before = widget.original.score;
    final after = _simulated;
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop || !_hasChanges) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Your simulation wasn't saved. Your real profile remains unchanged."),
        ));
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('🔮 What If?'),
          actions: [
            TextButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('RESET'),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'What would your life score look like if you changed one thing?',
              style: AppTypography.bodyMuted,
            ),
            const SizedBox(height: 4),
            Text(
              'Nothing here is saved to your real profile — pure exploration.',
              style: AppTypography.caption,
            ),
            const SizedBox(height: 14),
            _WhatIfOverallCard(before: before.overall, after: after.overall),
            const SizedBox(height: 10),
          AppCard(
            child: Column(
              children: [
                for (final entry in before.breakdown.entries)
                  _WhatIfCategoryRow(
                      label: entry.key,
                      before: entry.value,
                      after: after.breakdown[entry.key]!),
              ],
            ),
          ),
          _LeverCard(
            icon: Icons.public_rounded,
            title: 'Country',
            child: _choiceRow(country, LifeScoreService.benchmarks.keys.toList(),
                (v) => setState(() => country = v)),
          ),
          _LeverCard(
            icon: Icons.work_rounded,
            title: 'Employment',
            child: _choiceRow(
                employment,
                const [
                  'Employed',
                  'Freelancer',
                  'Founder',
                  'Student',
                  'Unemployed'
                ],
                (v) => setState(() => employment = v)),
          ),
          _LeverCard(
            icon: Icons.home_rounded,
            title: 'Living situation',
            child: _choiceRow(
                living,
                const [
                  'With family',
                  'Rents apartment',
                  'Owns home',
                  'Shared place'
                ],
                (v) => setState(() => living = v)),
          ),
          _LeverCard(
            icon: Icons.fitness_center_rounded,
            title: 'Exercise frequency',
            child: _choiceRow(exercise, const ['Rarely', 'Sometimes', 'Weekly', 'Daily'],
                (v) => setState(() => exercise = v)),
          ),
          _LeverCard(
            icon: Icons.attach_money_rounded,
            title: 'Monthly income',
            child: _moneyField(income, (v) => setState(() => income = v)),
          ),
          _LeverCard(
            icon: Icons.savings_rounded,
            title: 'Savings',
            child: _moneyField(savings, (v) => setState(() => savings = v)),
          ),
          _LeverCard(
            icon: Icons.groups_rounded,
            title: 'Close friends: ${friends.round()}',
            child: _numberSlider(friends.toDouble(), 0, 12,
                (v) => setState(() => friends = v.round())),
          ),
          _LeverCard(
            icon: Icons.sentiment_satisfied_alt_rounded,
            title: 'Happiness: ${happiness.round()}',
            child: _numberSlider(happiness.toDouble(), 1, 10,
                (v) => setState(() => happiness = v.round())),
          ),
          ],
        ),
      ),
    );
  }

  Widget _choiceRow(
      String value, List<String> options, ValueChanged<String> onChanged) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in options)
          ChoiceChip(
              label: Text(option),
              selected: value == option,
              onSelected: (_) => onChanged(option)),
      ],
    );
  }

  Widget _moneyField(double value, ValueChanged<double> onChanged) {
    return TextFormField(
      key: ValueKey('money-${value.round()}'),
      initialValue: value.round().toString(),
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: widget.original.currency,
        isDense: true,
      ),
      onChanged: (next) => onChanged(double.tryParse(next) ?? 0),
    );
  }

  Widget _numberSlider(
      double value, double min, double max, ValueChanged<double> onChanged) {
    return Slider(
      value: value.clamp(min, max),
      min: min,
      max: max,
      divisions: (max - min).round(),
      label: value.round().toString(),
      onChanged: onChanged,
    );
  }
}

/// A bordered "lever" card wrapping one What-If control — an icon +
/// label header over the actual chip row/slider/field, so the levers
/// read as a set of distinct dials rather than a flat settings list.
/// Purple throughout (this app's "player/exploration energy" accent,
/// per the same color-semantics this pass applied to Life Battles/Nuke)
/// — deliberately not colored per-lever, since these controls don't
/// individually carry a good/bad meaning the way a score delta does.
class _LeverCard extends StatelessWidget {
  const _LeverCard({required this.icon, required this.title, required this.child});

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHigh,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.purple, size: 18),
              const SizedBox(width: 8),
              Text(title, style: AppTypography.body.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _WhatIfOverallCard extends StatelessWidget {
  const _WhatIfOverallCard({required this.before, required this.after});

  final int before;
  final int after;

  @override
  Widget build(BuildContext context) {
    final delta = after - before;
    final color = delta > 0
        ? AppColors.green
        : (delta < 0 ? AppColors.danger : AppTheme.textMuted);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHigh,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: delta == 0 ? AppColors.border : color.withValues(alpha: 0.6)),
        boxShadow: delta == 0
            ? null
            : [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 18, spreadRadius: 1)],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('NOW',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMuted)),
                Text('$before',
                    style: const TextStyle(
                        fontSize: 32, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_rounded, color: AppTheme.textMuted),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('WHAT IF',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMuted)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        if (delta != 0)
                          BurstFx(
                            key: ValueKey('whatIfBurst-$after'),
                            colors: [color],
                            particleCount: 10,
                            radius: 30,
                            duration: const Duration(milliseconds: 500),
                          ),
                        AnimatedCountUp(
                          value: after.toDouble(),
                          textKey: const Key('whatIfAfterOverall'),
                          style: TextStyle(
                              fontSize: 32, fontWeight: FontWeight.w900, color: color),
                        ),
                      ],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      delta == 0 ? '±0' : (delta > 0 ? '+$delta' : '$delta'),
                      key: const Key('whatIfDeltaOverall'),
                      style:
                          TextStyle(fontWeight: FontWeight.w800, color: color),
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

class _WhatIfCategoryRow extends StatelessWidget {
  const _WhatIfCategoryRow(
      {required this.label, required this.before, required this.after});

  final String label;
  final int before;
  final int after;

  @override
  Widget build(BuildContext context) {
    final delta = after - before;
    final color = delta > 0
        ? AppColors.gold
        : (delta < 0 ? AppColors.danger : AppTheme.textMuted);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w700))),
          Text(delta == 0 ? '±0' : (delta > 0 ? '+$delta' : '$delta'),
              style: TextStyle(fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
}

/// A minimal line chart of algorithm score over time, with the current
/// score, month-over-month delta, and month labels below the plot.
class _ScoreHistoryChart extends StatelessWidget {
  const _ScoreHistoryChart({required this.history});

  final List<ScoreHistoryPoint> history;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const EmptyState(
        icon: Icons.show_chart_rounded,
        title: 'No score history yet.',
        subtitle: 'Your score will be tracked here as it changes.',
      );
    }
    final latest = history.last;
    final previous = history.length > 1 ? history[history.length - 2] : null;
    final delta = previous == null
        ? null
        : latest.algorithmScore - previous.algorithmScore;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${latest.algorithmScore}',
                style: AppTypography.hero.copyWith(fontSize: 34)),
            const Padding(
              padding: EdgeInsets.only(left: 6, bottom: 6),
              child: Text('/ 100 now'),
            ),
            const Spacer(),
            if (delta != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: (delta >= 0 ? AppColors.gold : AppColors.pink)
                        .withValues(alpha: 0.15),
                    borderRadius: AppRadius.pillRadius,
                  ),
                  child: Text(
                    delta == 0
                        ? 'No change'
                        : '${delta > 0 ? '+' : ''}$delta this month',
                    style: TextStyle(
                        color: delta >= 0 ? AppColors.gold : AppColors.pink,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          width: double.infinity,
          child: CustomPaint(painter: _ScoreLinePainter(history: history)),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final point in history)
              Expanded(
                child: Text(
                  point.month,
                  textAlign: TextAlign.center,
                  style:
                      AppTypography.caption.copyWith(color: AppTheme.textMuted),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ScoreLinePainter extends CustomPainter {
  _ScoreLinePainter({required this.history});

  final List<ScoreHistoryPoint> history;

  static const _minScore = 0.0;
  static const _maxScore = 100.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (history.length == 1) {
      canvas.drawCircle(Offset(size.width / 2, size.height / 2), 5,
          Paint()..color = AppColors.gold);
      return;
    }

    final stepX = size.width / (history.length - 1);
    Offset pointAt(int i) {
      final t =
          ((history[i].algorithmScore - _minScore) / (_maxScore - _minScore))
              .clamp(0.0, 1.0);
      return Offset(stepX * i, size.height - t * size.height);
    }

    final linePath = Path();
    final fillPath = Path()..moveTo(0, size.height);
    for (var i = 0; i < history.length; i++) {
      final point = pointAt(i);
      if (i == 0) {
        linePath.moveTo(point.dx, point.dy);
      } else {
        linePath.lineTo(point.dx, point.dy);
      }
      fillPath.lineTo(point.dx, point.dy);
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.gold.withValues(alpha: 0.28),
            AppColors.gold.withValues(alpha: 0)
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      linePath,
      Paint()
        ..color = AppColors.gold
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    for (var i = 0; i < history.length; i++) {
      final point = pointAt(i);
      final isLast = i == history.length - 1;
      if (isLast) {
        canvas.drawCircle(
            point, 8, Paint()..color = AppColors.gold.withValues(alpha: 0.25));
      }
      canvas.drawCircle(point, isLast ? 5 : 3.5,
          Paint()..color = isLast ? AppColors.gold : Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _ScoreLinePainter oldDelegate) =>
      oldDelegate.history != history;
}

class PhotoManagerScreen extends ConsumerStatefulWidget {
  const PhotoManagerScreen({super.key});

  @override
  ConsumerState<PhotoManagerScreen> createState() => _PhotoManagerScreenState();
}

class _PhotoManagerScreenState extends ConsumerState<PhotoManagerScreen> {
  String _newPhotoCategory = PhotoService.categories.first;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final profile = state.currentProfile!;
    final photos = [...profile.photos]
      ..sort((a, b) => a.order.compareTo(b.order));
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Photos')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SectionTitle('What kind of photo is this?'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final category in PhotoService.categories)
                ChoiceChip(
                  label: Text(category),
                  selected: _newPhotoCategory == category,
                  onSelected: (_) =>
                      setState(() => _newPhotoCategory = category),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child: FilledButton.icon(
                      onPressed: () => ref.read(appControllerProvider).addPhoto(
                          ImageSource.camera,
                          category: _newPhotoCategory),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('CAMERA'))),
              const SizedBox(width: 8),
              Expanded(
                  child: OutlinedButton.icon(
                      onPressed: () => ref.read(appControllerProvider).addPhoto(
                          ImageSource.gallery,
                          category: _newPhotoCategory),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('GALLERY'))),
            ],
          ),
          const SizedBox(height: 14),
          if (photos.isEmpty)
            const EmptyState(
                icon: Icons.add_photo_alternate_outlined,
                title: 'No photos yet.',
                subtitle: 'Add up to 8 photos that represent your lifestyle.')
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: photos.length,
              onReorderItem: (oldIndex, newIndex) {
                // onReorderItem's newIndex is already adjusted for the
                // removed item; PhotoService.reorder expects the raw,
                // pre-removal index, so undo that adjustment here.
                final rawNewIndex =
                    newIndex > oldIndex ? newIndex + 1 : newIndex;
                ref
                    .read(appControllerProvider)
                    .reorderPhoto(oldIndex, rawNewIndex);
              },
              itemBuilder: (context, index) {
                final photo = photos[index];
                return Padding(
                  key: ValueKey(photo.id),
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    child: Row(
                      children: [
                        Container(
                          decoration: photo.isProfilePhoto
                              ? BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: AppColors.gold, width: 2),
                                )
                              : null,
                          padding: photo.isProfilePhoto
                              ? const EdgeInsets.all(2)
                              : EdgeInsets.zero,
                          child: ProfileImage(
                              photo: photo,
                              label: photo.category,
                              height: 76,
                              width: 76,
                              isPerson: false),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (photo.isProfilePhoto) ...[
                                    const Icon(Icons.star_rounded,
                                        size: 15, color: AppColors.gold),
                                    const SizedBox(width: 3),
                                    const Flexible(
                                      child: Text('Profile photo',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              fontWeight: FontWeight.w900)),
                                    ),
                                  ] else
                                    InkWell(
                                      onTap: () =>
                                          _pickCategory(context, ref, photo),
                                      borderRadius: AppRadius.pillRadius,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 2),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Flexible(
                                              child: Text(photo.category,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w900)),
                                            ),
                                            const SizedBox(width: 3),
                                            const Icon(
                                                Icons.expand_more_rounded,
                                                size: 16,
                                                color: AppTheme.textMuted),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              Text('Drag to reorder',
                                  style: AppTypography.bodyMuted),
                            ],
                          ),
                        ),
                        if (!photo.isProfilePhoto)
                          IconButton(
                              tooltip: 'Set as profile photo',
                              onPressed: () => ref
                                  .read(appControllerProvider)
                                  .setProfilePhoto(photo.id),
                              icon: const Icon(Icons.person_outline)),
                        IconButton(
                          tooltip: 'Check photo quality',
                          onPressed: () =>
                              _showQualityResult(context, ref, photo),
                          icon: const Icon(Icons.insights_rounded),
                        ),
                        IconButton(
                          tooltip: 'Delete photo',
                          onPressed: () =>
                              _confirmDeletePhoto(context, ref, photo.id),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _pickCategory(BuildContext context, WidgetRef ref, ProfilePhoto photo) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.lg))),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 6),
              child: Row(children: [
                Text('WHAT KIND OF PHOTO?',
                    style: TextStyle(
                        fontWeight: FontWeight.w900, color: AppTheme.gold))
              ]),
            ),
            for (final category in PhotoService.categories)
              ListTile(
                title: Text(category),
                trailing: photo.category == category
                    ? const Icon(Icons.check_rounded, color: AppColors.purple)
                    : null,
                onTap: () {
                  ref
                      .read(appControllerProvider)
                      .setPhotoCategory(photo.id, category);
                  Navigator.pop(sheetContext);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmDeletePhoto(
      BuildContext context, WidgetRef ref, String photoId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete photo?'),
        content: const Text('This photo will be removed from your profile.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(appControllerProvider).deletePhoto(photoId);
            },
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  void _showQualityResult(
      BuildContext context, WidgetRef ref, ProfilePhoto photo) {
    final future = ref.read(appControllerProvider).analyzePhotoQuality(photo);
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Photo Quality'),
        content: FutureBuilder<PhotoQualityResult?>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(
                  height: 60,
                  child: Center(child: CircularProgressIndicator()));
            }
            final result = snapshot.data;
            if (result == null) {
              return const Text("This photo can't be analyzed right now.");
            }
            final color = result.score >= 80
                ? AppColors.success
                : (result.score >= 50 ? AppColors.gold : AppColors.danger);
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('${result.score}',
                        style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            color: color)),
                    const Text(' / 100',
                        style: TextStyle(color: AppTheme.textMuted)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(result.tip),
                const SizedBox(height: 14),
                Text(
                  'This checks the photograph itself — lighting, sharpness, resolution — never you.',
                  style: AppTypography.bodyMuted.copyWith(fontSize: 12),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('OK'))
        ],
      ),
    );
  }
}

class PrivacySettingsScreen extends ConsumerWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(appControllerProvider).currentProfile!;
    final privacy = profile.privacy;
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _switch(
              ref,
              privacy.visibility == ProfileVisibility.public,
              'Profile visibility',
              'Public profiles can appear in social surfaces.',
              (value) => privacy.copyWith(
                  visibility: value
                      ? ProfileVisibility.public
                      : ProfileVisibility.private)),
          _switch(
              ref,
              privacy.showInDiscover,
              'Show in Discover',
              'Hide me from discovery.',
              (value) => privacy.copyWith(showInDiscover: value)),
          _switch(
              ref,
              privacy.showInLeaderboard,
              'Show in Leaderboard',
              'Hide me from leaderboard.',
              (value) => privacy.copyWith(showInLeaderboard: value)),
          _switch(
              ref,
              privacy.allowRatings,
              'Allow Ratings',
              'Private or disabled profiles cannot receive new ratings.',
              (value) => privacy.copyWith(allowRatings: value)),
          _switch(
              ref,
              privacy.allowComments,
              'Allow Comments',
              'Turn off to disable new comments on your profile.',
              (value) => privacy.copyWith(allowComments: value)),
          _switch(
              ref,
              privacy.allowMessages,
              'Allow Messages',
              'Turn off to stop new people from messaging you.',
              (value) => privacy.copyWith(allowMessages: value)),
          _switch(
              ref,
              privacy.allowCalls,
              'Allow Calls',
              'Turn off to stop people you message with from calling you.',
              (value) => privacy.copyWith(allowCalls: value)),
          const SectionTitle('Sensitive Fields'),
          _switch(
              ref,
              privacy.showAge,
              'Show Age',
              'Age can be hidden on public profiles.',
              (value) => privacy.copyWith(showAge: value)),
          _switch(
              ref,
              privacy.showCountry,
              'Show Country',
              'Country can be hidden on public profiles.',
              (value) => privacy.copyWith(showCountry: value)),
          _switch(
              ref,
              privacy.showIncome,
              'Show Income',
              'Income is hidden by default.',
              (value) => privacy.copyWith(showIncome: value)),
          _switch(
              ref,
              privacy.showSavings,
              'Show Savings',
              'Savings are hidden by default.',
              (value) => privacy.copyWith(showSavings: value)),
          _switch(
              ref,
              privacy.showCareer,
              'Show Career',
              'Career information can be public without money.',
              (value) => privacy.copyWith(showCareer: value)),
          _switch(
              ref,
              privacy.showPhotos,
              'Show Photos',
              'Hide all gallery photos on public profile.',
              (value) => privacy.copyWith(showPhotos: value)),
          const SectionTitle('Data & Ads'),
          const AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: AppTheme.textMuted),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This app shows ads to stay free. Unlike everything else here, '
                    "ads use a device advertising ID for targeting — it isn't linked "
                    'to your anonymous profile or any of the data above.',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _switch(WidgetRef ref, bool value, String title, String subtitle,
      ProfilePrivacy Function(bool) update) {
    return AppCard(
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: value,
        title: Text(title),
        subtitle: Text(subtitle),
        onChanged: (next) =>
            ref.read(appControllerProvider).updatePrivacy(update(next)),
      ),
    );
  }
}

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final unlockedIds = state.unlockedAchievementIds;
    final total = AchievementService.catalog.length;
    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppCard(
            child: Row(
              children: [
                const Icon(Icons.emoji_events_rounded,
                    color: AppColors.gold, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${unlockedIds.length} / $total unlocked',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          for (final achievement in AchievementService.catalog)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AchievementCard(
                achievement: achievement,
                unlocked: unlockedIds.contains(achievement.id),
                unlockedAt:
                    state.achievementRecordFor(achievement.id)?.unlockedAt,
              ),
            ),
        ],
      ),
    );
  }
}

class CosmeticsScreen extends ConsumerWidget {
  const CosmeticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(appControllerProvider);
    final state = ref.watch(appControllerProvider);
    final ownedIds = state.ownedFrameIds;
    final equippedId = state.currentProfile?.equippedFrameId;
    return Scaffold(
      appBar: AppBar(title: const Text('Customize')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppCard(
            child: Row(
              children: [
                const Icon(Icons.monetization_on_rounded,
                    color: AppColors.gold, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${state.wallet.balance} coins',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          for (final frame in CosmeticService.catalog)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CosmeticFrameCard(
                frame: frame,
                owned: frame.id == 'none' || ownedIds.contains(frame.id),
                equipped: equippedId == frame.id ||
                    (equippedId == null && frame.id == 'none'),
                canAfford: state.wallet.balance >= frame.cost,
                onPurchase: () => controller.purchaseFrame(frame.id),
                onEquip: () => controller.equipFrame(frame.id),
              ),
            ),
        ],
      ),
    );
  }
}

class _CosmeticFrameCard extends StatelessWidget {
  const _CosmeticFrameCard({
    required this.frame,
    required this.owned,
    required this.equipped,
    required this.canAfford,
    required this.onPurchase,
    required this.onEquip,
  });

  final CosmeticFrame frame;
  final bool owned;
  final bool equipped;
  final bool canAfford;
  final VoidCallback onPurchase;
  final VoidCallback onEquip;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          ProfileFrame(
            frameId: frame.id,
            borderRadius: 28,
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                  color: AppTheme.surfaceHigh, shape: BoxShape.circle),
              child:
                  const Icon(Icons.person_rounded, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(frame.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 2),
                Text(
                  frame.cost == 0 ? 'Free' : '${frame.cost} coins',
                  style:
                      const TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
          if (equipped)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.check_circle_rounded, color: AppColors.gold),
            )
          else if (owned)
            OutlinedButton(onPressed: onEquip, child: const Text('Equip'))
          else
            FilledButton(
                onPressed: canAfford ? onPurchase : null,
                child: const Text('Unlock')),
        ],
      ),
    );
  }
}

/// A daily would-you-rather prompt. Unlike Life Battles' estimated split,
/// this shows a real vote tally once you've answered — see
/// `ChoiceService`'s doc comment for why that's possible here but not
/// there.
class WhatWouldYouChooseScreen extends ConsumerStatefulWidget {
  const WhatWouldYouChooseScreen({super.key});

  @override
  ConsumerState<WhatWouldYouChooseScreen> createState() => _WhatWouldYouChooseScreenState();
}

class _WhatWouldYouChooseScreenState extends ConsumerState<WhatWouldYouChooseScreen> {
  ChoiceOption? _locking;

  Future<void> _choose(ChoiceOption option) async {
    if (_locking != null) return;
    HapticFeedback.selectionClick();
    playSfx(AppSfx.choiceSelect);
    setState(() => _locking = option);
    await ref.read(appControllerProvider).submitChoice(option);
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    playSfx(AppSfx.choiceReveal);
    setState(() => _locking = null);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final choice = state.todaysChoice;
    final myVote = state.myChoiceVoteToday;
    final tally = state.todaysChoiceTally;
    final voted = myVote != null;
    final total = (tally?.countA ?? 0) + (tally?.countB ?? 0);
    final pctA = total == 0 ? 50 : ((tally!.countA / total) * 100).round();
    final pctB = 100 - pctA;

    return Scaffold(
      appBar: AppBar(title: const Text('Would You Choose?')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(voted ? 'THE CROWD HAS SPOKEN 👀' : "TODAY'S QUESTION",
              style: AppTypography.eyebrow.copyWith(color: AppColors.gold)),
          const SizedBox(height: 4),
          Text('🤔 Would you rather...', style: AppTypography.title),
          const SizedBox(height: 16),
          _ChoiceOption(
            prompt: choice.promptA,
            gradient: AppColors.purpleGradient,
            voted: voted,
            isMine: myVote?.chosenOption == ChoiceOption.a,
            percentage: pctA,
            locking: _locking == ChoiceOption.a,
            onTap: voted || _locking != null ? null : () => _choose(ChoiceOption.a),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text('OR', textAlign: TextAlign.center, style: AppTypography.eyebrow.copyWith(color: AppColors.textMuted)),
          ),
          _ChoiceOption(
            prompt: choice.promptB,
            gradient: AppColors.pinkGradient,
            voted: voted,
            isMine: myVote?.chosenOption == ChoiceOption.b,
            percentage: pctB,
            locking: _locking == ChoiceOption.b,
            onTap: voted || _locking != null ? null : () => _choose(ChoiceOption.b),
          ),
          const SizedBox(height: 18),
          if (voted)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.12),
                borderRadius: AppRadius.pillRadius,
                border: Border.all(color: AppColors.green.withValues(alpha: 0.4)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.green, size: 16),
                      const SizedBox(width: 6),
                      Text('You answered today\'s question',
                          style: AppTypography.caption.copyWith(color: AppColors.green)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('Come back tomorrow for a new one.', style: AppTypography.caption),
                ],
              ),
            )
          else
            Text(
              'Tap an option to see how everyone else answered.',
              textAlign: TextAlign.center,
              style: AppTypography.caption,
            ),
        ],
      ),
    );
  }
}

class _ChoiceOption extends StatelessWidget {
  const _ChoiceOption({
    required this.prompt,
    required this.gradient,
    required this.voted,
    required this.isMine,
    required this.percentage,
    required this.locking,
    required this.onTap,
  });

  final String prompt;
  final Gradient gradient;
  final bool voted;
  final bool isMine;
  final int percentage;
  final bool locking;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: locking ? 0.97 : 1,
        duration: const Duration(milliseconds: 150),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(minHeight: 110),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: AppRadius.lgRadius,
            border: isMine ? Border.all(color: Colors.white, width: 2) : null,
            boxShadow: isMine ? [BoxShadow(color: Colors.white.withValues(alpha: 0.3), blurRadius: 14)] : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      prompt,
                      style: AppTypography.heading.copyWith(color: Colors.white, fontSize: 18),
                    ),
                  ),
                  if (voted)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isMine) const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                          AnimatedCountUp(
                            value: percentage.toDouble(),
                            suffix: '%',
                            style: AppTypography.title.copyWith(color: Colors.white, fontSize: 20),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              if (voted) ...[
                const SizedBox(height: 10),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: percentage / 100),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: value,
                      minHeight: 8,
                      backgroundColor: Colors.black.withValues(alpha: 0.25),
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
