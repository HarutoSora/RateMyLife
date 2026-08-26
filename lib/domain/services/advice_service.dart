import 'dart:math';

import '../../data/models/models.dart';

/// One generated tip, tagged with the `LifeScore.breakdown` category
/// (and that category's raw 0-100 score) it was generated for — lets the
/// UI show a category icon/score alongside the tip without re-deriving
/// which category produced it.
class AdviceTip {
  const AdviceTip({required this.category, required this.score, required this.tip});

  final String category;
  final int score;
  final String tip;
}

/// Generates short, actionable life-advice tips from a profile's score
/// breakdown plus its raw background fields (country, employment,
/// education, exercise, etc.). Each score category has a large bank of
/// pre-written variants (hundreds across all categories) split into
/// background-specific branches (e.g. student vs. experienced
/// professional, debt-heavy vs. healthy finances) — [generate] picks the
/// weakest categories for this profile, then randomly samples one
/// variant per category, so the same weak category reads differently
/// for different people and differently across repeat taps for the same
/// person. No network call, no LLM — a pure, offline content bank.
class LifeAdviceService {
  const LifeAdviceService();

  /// Returns up to [count] tips, one per category, weakest score
  /// category first. Pass [random] to make selection deterministic
  /// (tests); production callers should omit it so each call reshuffles.
  List<AdviceTip> generate(UserProfile profile, {int count = 4, Random? random}) {
    final rng = random ?? Random();
    final weakest = profile.score.breakdown.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final tips = <AdviceTip>[];
    for (final entry in weakest) {
      if (tips.length >= count) break;
      final pool = _poolFor(entry.key, profile);
      tips.add(AdviceTip(category: entry.key, score: entry.value, tip: pool[rng.nextInt(pool.length)]));
    }
    return tips;
  }

  List<String> _poolFor(String category, UserProfile profile) {
    return switch (category) {
      'Career' => _careerPool(profile),
      'Money' => _moneyPool(profile),
      'Education' => _educationPool(profile),
      'Independence' => _independencePool(profile),
      'Social' => _socialPool(profile),
      'Lifestyle' => _lifestylePool(profile),
      'Wellbeing' => _wellbeingPool(profile),
      _ => const ['Keep building your profile — every category feeds your overall Life Score.'],
    };
  }

  List<String> _careerPool(UserProfile profile) {
    final status = profile.employmentStatus.toLowerCase();
    final job = profile.jobCategory;
    final years = profile.yearsExperience;

    if (status.contains('student')) {
      return [
        "You're still studying — a part-time role or internship in $job builds real experience faster than grades alone.",
        'Try picking up freelance work in $job while you study — even one small project builds a portfolio that outlasts your degree.',
        "A student-friendly certification in $job adds credibility before you've even graduated.",
        'Consider reaching out to alumni working in $job — a single conversation can open doors grades can\'t.',
        'Volunteering in $job-adjacent projects on campus counts as real experience recruiters notice.',
        'One idea: join a student club or competition related to $job — a low-risk way to build a track record.',
        'Building a small personal project in $job now gives you something concrete to show before your first job.',
        'A short online course in $job this semester compounds by the time you\'re job hunting.',
        'Networking early with people already working in $job tends to pay off more than waiting until graduation.',
        'Even a summer internship in $job — paid or not — moves this score more than another semester of study alone.',
      ];
    }
    if (status.contains('unemployed')) {
      return [
        'A short contract or freelance gig in $job rebuilds momentum faster than waiting for the perfect role.',
        'Consider applying to adjacent roles in $job — a foot in the door often matters more than an exact title match right now.',
        'Volunteering in $job keeps your resume active and your skills sharp while you search.',
        'A quick certification in $job can make your applications stand out in a crowded pipeline.',
        'Reaching out to your old contacts in $job tends to surface roles before they\'re even posted.',
        'Try picking up freelance or gig work in $job — income and momentum both matter here.',
        'One idea: a temporary or part-time role in $job keeps this score moving while you look for the right fit.',
        'Updating your portfolio with a fresh project in $job makes the next interview easier to land.',
        "Consider widening your search beyond $job titles you've already tried — adjacent roles often convert faster.",
        'Even unpaid project work in $job beats a resume gap when this score is concerned.',
      ];
    }
    if (years < 3) {
      return [
        "You're early in $job — deepening one skill now compounds more than switching paths again.",
        'A focused specialization inside $job tends to pay off faster than staying a generalist this early.',
        'Finding a mentor already senior in $job can shortcut years of trial and error.',
        'Consider owning one hard project at work — visible wins in $job move careers faster than tenure alone.',
        'A well-timed certification in $job signals momentum to your next employer.',
        "Try asking directly for more responsibility in $job — most managers won't offer it unprompted.",
        'Documenting your wins in $job now makes your next resume or review far easier to write.',
        'One idea: switching teams internally within $job can accelerate growth without the risk of leaving.',
        'Building a visible side project in $job gives you leverage in your next negotiation.',
        'Staying a bit longer in $job before switching again tends to compound more than another jump right now.',
      ];
    }
    return [
      'With $years years in $job, you\'re in a strong position to negotiate your next raise or role.',
      'Consider mentoring someone newer in $job — it strengthens your own standing as much as theirs.',
      'At $years years in, a lateral move within $job can unlock a pay bump a promotion alone won\'t.',
      "Your experience in $job is a real asset in interviews — don't undersell it in your next negotiation.",
      'Consider whether a leadership track in $job fits you better than staying purely hands-on.',
      'One idea: use your $years years in $job to negotiate flexibility, not just salary.',
      'A senior role in $job is well within reach with your track record — worth actively pursuing.',
      'Consider consulting or advisory work in $job on the side — your experience already supports it.',
      'With this much time in $job, updating your resume now captures wins you might otherwise forget.',
      'Your $years years in $job give you real leverage — use it at your next review.',
    ];
  }

  List<String> _moneyPool(UserProfile profile) {
    final country = profile.country;
    final debtHeavy = profile.debt > 0 && profile.debt > profile.savings;
    final expenseHeavy = profile.monthlyExpenses > 0 &&
        profile.monthlyIncome / profile.monthlyExpenses < 1.2;

    if (debtHeavy) {
      return [
        'Your debt currently outweighs your savings — paying it down, even gradually, moves your money score more than earning extra.',
        'Consider tackling your highest-interest debt first — it moves this score faster than spreading payments thin.',
        'A simple debt snowball, smallest balance first, can build momentum even before the total shrinks much.',
        'One idea: redirect any windfall (bonus, gift, refund) straight at debt instead of everyday spending.',
        'Consolidating high-interest debt into a lower rate can free up real monthly breathing room.',
        'Even a small extra payment toward debt each month compounds faster than most people expect.',
        'Consider pausing new spending commitments until your debt-to-savings balance flips the other way.',
        'Tracking your debt total weekly, not just when it feels bad, tends to speed up paying it down.',
        'A short-term side income stream aimed entirely at debt can shrink it faster than budgeting alone.',
        'Your debt is the single biggest lever on this score right now — reducing it beats increasing income.',
      ];
    }
    if (expenseHeavy) {
      return [
        'Your expenses are close to your income for $country — trimming one fixed cost frees up real room to save.',
        'Consider auditing your monthly expenses line by line — one recurring subscription is often the easiest cut.',
        'A single renegotiated bill (rent, phone, insurance) can meaningfully close the gap between income and expenses in $country.',
        'One idea: track every expense for a month — most people underestimate where the money in $country actually goes.',
        "Even a 10% cut to discretionary expenses adds up quickly against $country's cost of living.",
        'Consider whether your biggest fixed expense still matches your actual needs today.',
        'Reducing one habitual expense, even a small one, compounds faster than a one-time cutback.',
        'Your income-to-expense ratio in $country has room to improve without a pay raise — expenses are the faster lever.',
        "A short no-spend week can reveal which expenses you don't actually miss.",
        'Consider automating savings before expenses hit your account — what\'s left tends to get spent regardless.',
      ];
    }
    return [
      "Even a small automatic transfer into savings each month adds up quickly against $country's cost of living.",
      'Consider putting any raise straight into savings before your spending adjusts to match it.',
      'Your finances already look stable — automating investments now compounds while you\'re not thinking about it.',
      "One idea: set a specific savings goal tied to something real — it's easier to stick to than a vague target.",
      'Diversifying beyond a single savings account can put your money to better use in $country.',
      'Consider reviewing your investments once a year — steady is good, but idle cash loses value over time.',
      "A small emergency fund, if you don't have one yet, protects the progress you've already made.",
      'Your money situation is solid — the next lever is usually growth, not just saving more.',
      'Consider automating a fixed percentage of income into investments each month in $country.',
      'Even with healthy finances, reviewing recurring expenses once in a while keeps this score from drifting down quietly.',
    ];
  }

  List<String> _educationPool(UserProfile profile) {
    final level = profile.educationLevel.toLowerCase();
    final job = profile.jobCategory;

    if (level.contains('high') || level.contains('student')) {
      return [
        'A focused certification in $job can lift this score without committing to a full degree.',
        'Consider a short, practical course in $job — targeted beats broad at this stage.',
        'Online certifications in $job are taken seriously by more employers than they used to be.',
        'One idea: pick one in-demand skill in $job and get certified in it this quarter.',
        'A community college or bootcamp track in $job can move this score faster than self-study alone.',
        'Consider whether a part-time degree track fits your schedule — even slow progress compounds here.',
        'Free or low-cost courses in $job exist for almost every skill worth learning right now.',
        'A single completed certification tends to matter more to this score than several half-finished courses.',
        'Consider pairing a certification in $job with a small project that proves you can apply it.',
        'Even one structured course this year keeps your education score from staying flat.',
      ];
    }
    return [
      'A short, targeted course keeps your education score current with where $job is heading.',
      'Consider a refresher certification in $job — fields shift faster than most people update for.',
      'One idea: pick a skill gap you already know about in $job and close it deliberately.',
      'Advanced or specialized courses in $job tend to move this score more than repeating basics.',
      "Consider mentoring or teaching in $job — it's a strong way to solidify what you already know.",
      'A single conference or workshop in $job can be worth more than months of passive reading.',
      'Staying current in $job through even light ongoing learning keeps this score from slipping.',
      "Consider a credential that's specifically valued in $job rather than a generic one.",
      'One idea: set a yearly learning goal tied directly to where $job is trending.',
      'Even revisiting fundamentals in $job occasionally keeps this score healthy long-term.',
    ];
  }

  List<String> _independencePool(UserProfile profile) {
    final living = profile.livingSituation.toLowerCase();
    final age = profile.age;
    final city = profile.city;
    final debtHeavy = profile.debt > 0 && profile.debt > profile.savings;

    if (living.contains('family') && age > 25) {
      return [
        "Living with family past $age isn't a flaw, but a plan toward your own place would lift this score fastest.",
        'Consider setting a concrete timeline for moving out — a vague someday rarely turns into a plan.',
        'Even a shared rental with a roommate can meaningfully lift this score over staying with family long-term.',
        'One idea: start a dedicated moving-out fund, separate from general savings, to make the goal feel real.',
        "Consider what's actually holding the move back — cost, convenience, or habit — each has a different fix.",
        "A small, low-cost place of your own often moves this score more than a larger one you're not ready for.",
        'Consider a trial period living independently, even short-term, to build toward it gradually.',
        'At $age, even a modest studio can shift this score meaningfully compared to staying at home.',
        'One idea: research typical rents in your area now, so the goal has a real number attached.',
        "Independence here isn't about age — it's about having your own space when you're ready for it.",
      ];
    }
    if (debtHeavy) {
      return [
        'Reducing debt relative to savings is the quickest lever here — independence tracks financial breathing room, not just housing.',
        'Consider that debt above savings weighs on independence more than housing status does.',
        'Paying down debt, even slowly, frees up the flexibility this score is actually measuring.',
        'One idea: treat debt reduction as your independence project, not just a money one.',
        'Consider how much of your income debt payments currently take — freeing that up matters here too.',
        'Even modest extra debt payments create the breathing room independence is built on.',
        'Your debt load is the biggest thing standing between you and more independence right now.',
        'Consider consolidating debt to lower payments, which frees up room for everything else this score covers.',
        'One idea: pick one debt to eliminate completely before spreading payments across several.',
        'Independence often comes down to debt versus savings more than people expect — this is where to focus.',
      ];
    }
    if (!profile.ownsHome && !profile.ownsCar) {
      return [
        'Neither owning nor renting long-term is required — even a stable lease in $city strengthens this score over time.',
        "Consider a longer lease term in $city if you're currently month-to-month — stability itself counts here.",
        'One idea: a modest car or reliable transport option in $city can lift this score alongside housing.',
        'Building toward a first lease or purchase in $city, even slowly, moves this score in the right direction.',
        "Consider what independence looks like practically in $city — it doesn't require owning to count.",
        'A stable, predictable living situation in $city matters more here than the size or type of place.',
        'One idea: set a savings target specifically for a deposit or down payment in $city.',
        'Consider whether transport independence (a car, a reliable commute) would move this score faster than housing right now.',
        'Even without ownership, consistency in your living situation in $city builds this score over time.',
        'Independence here rewards stability — a longer commitment in $city, even rented, counts.',
      ];
    }
    return [
      'Your living setup in $city is already a solid base — consistency here compounds.',
      "Consider whether now's the time to build on your stable base in $city — savings, upgrades, or ownership.",
      'One idea: use your current stability in $city as a springboard for a bigger financial goal.',
      'Your independence foundation looks solid — the next lever is usually growth, not just maintaining it.',
      'Consider reviewing your housing costs in $city occasionally — even a stable setup can be optimized.',
      'A stable base in $city is exactly what makes future moves (career, family, savings) easier.',
      'One idea: if ownership is a future goal, your current stability in $city is a good starting point.',
      'Consider what the next step up from your current setup in $city would look like.',
      'Your independence score reflects real stability — protecting it matters as much as building further.',
      'Even with a strong base in $city, revisiting your setup occasionally keeps this score current.',
    ];
  }

  List<String> _socialPool(UserProfile profile) {
    final friends = profile.closeFriends;
    final hobby = profile.hobbies.isNotEmpty ? profile.hobbies.first : 'a hobby you enjoy';

    if (friends < 3) {
      return [
        'You report $friends close friends — joining one recurring activity around $hobby is the fastest way to grow that circle.',
        'Consider reaching out to one old friend this week — reconnecting counts as much as meeting someone new.',
        'One idea: a regular weekly activity, even something small, tends to build close friendships faster than one-off events.',
        'With $friends close friends currently, consistency with the people you do have matters as much as adding more.',
        'Consider joining a group tied to $hobby — shared activity tends to build friendships faster than socializing alone.',
        'A recurring standing plan (weekly call, regular meetup) turns acquaintances into close friends over time.',
        'One idea: host something small and low-pressure — people often wait to be invited before reaching out themselves.',
        'Consider that quality time with $friends close friends can move this score as much as adding new ones.',
        'A community or class around $hobby is a low-pressure way to meet people with something in common.',
        'Even one new recurring connection this month would meaningfully grow your close circle.',
      ];
    }
    if (profile.hobbies.isEmpty) {
      return [
        'Adding even one regular hobby gives you a natural way to meet people and lifts this score alongside Lifestyle.',
        "Consider picking up one activity you've been curious about — hobbies double as a social entry point.",
        'One idea: a group class (sport, art, language) builds both a skill and a social circle at once.',
        'Without a current hobby, a low-commitment one (a walk group, a book club) is an easy place to start.',
        'Consider that a hobby doesn\'t need to be serious — consistency matters more than intensity here.',
        'A shared hobby tends to build friendships faster than trying to make friends directly.',
        'One idea: revisit something you enjoyed years ago — it\'s often an easier restart than something totally new.',
        'Consider joining a local group or class this month — a concrete first step toward this score moving.',
        'Even a casual, low-stakes hobby gives you regular reasons to be around other people.',
        'A hobby you actually enjoy tends to stick, and this score follows from consistency, not intensity.',
      ];
    }
    return [
      'Your social circle looks solid — staying consistent with it matters more than growing it further.',
      'Consider deepening a few key friendships rather than spreading time thin across many.',
      'One idea: a regular tradition with your close circle (monthly dinner, annual trip) keeps bonds strong long-term.',
      'Your social base is healthy — the next lever is usually depth, not more connections.',
      "Consider checking in on a friendship that's drifted — maintenance matters as much as building new ones.",
      'A strong social circle is worth protecting — consistency beats novelty here.',
      'One idea: introduce friends from different parts of your life to each other — it strengthens the whole network.',
      'Your current friendships are a real asset — investing in them compounds like anything else.',
      'Consider being the one who initiates plans occasionally — it keeps a solid circle from going quiet.',
      'Even a strong social base benefits from the occasional new connection through people you already know.',
    ];
  }

  List<String> _lifestylePool(UserProfile profile) {
    final exercise = profile.exerciseFrequency.toLowerCase();
    final travel = profile.travelFrequency.toLowerCase();
    final city = profile.city;

    if (exercise == 'rarely' || exercise == 'never') {
      return [
        'Exercise is currently your lowest lifestyle lever — even two short sessions a week would move this score.',
        "Consider a 15-minute walk most days — exercise doesn't need to be intense to count here.",
        "One idea: pick an activity you don't dread (a sport, dancing, swimming) — consistency beats intensity.",
        'Even light, regular exercise tends to move this score faster than an occasional intense workout.',
        'Consider pairing exercise with something social — a class or a walk with a friend makes it stick.',
        'A single small habit, like stretching each morning, is a realistic starting point for exercise.',
        "One idea: schedule exercise like an appointment — it's far more likely to happen if it's on your calendar.",
        "Consider starting with just two sessions a week rather than an ambitious daily plan that's hard to keep.",
        'Exercise is one of the fastest-moving levers on this whole score — small, consistent steps count.',
        'Even a short daily walk, without any equipment, meaningfully shifts this score over a few weeks.',
      ];
    }
    if (travel == 'rarely') {
      return [
        'You travel rarely — a single trip a year, even locally from $city, adds real variety to this score.',
        'Consider a short weekend trip near $city rather than waiting for a bigger, more expensive one.',
        'One idea: a day trip somewhere new counts more toward this score than people expect.',
        'Even local travel — a nearby town, a new neighborhood in $city — adds variety here.',
        'Consider setting aside a small monthly amount specifically for one trip a year.',
        'A change of scenery, even close to home, tends to move this score more than staying put.',
        'One idea: travel with friends to split the cost — it often makes an otherwise skipped trip realistic.',
        'Consider planning just one trip for the year rather than an open-ended "someday."',
        'Even a single overnight trip from $city counts as real variety for this score.',
        'Your travel frequency is the easiest lever to move here — even one trip changes the picture.',
      ];
    }
    if (profile.freeTimeHours < 5) {
      return [
        'You report very little free time — protecting even a few hours a week for yourself feeds this score directly.',
        "Consider blocking out a fixed weekly slot for something that's just for you — it's easy to lose otherwise.",
        'One idea: treat free time like an obligation on your calendar, not something left over.',
        'Even a couple of protected hours a week tends to move this score more than people expect.',
        "Consider what's currently filling your time — some of it may be worth trimming to make room.",
        'A single recurring block of free time, even short, is more sustainable than sporadic long breaks.',
        'One idea: pair free time with something restorative rather than another task disguised as rest.',
        "Consider saying no to one recurring commitment that isn't adding much, to free up real time.",
        'Even 30 minutes a day set aside deliberately adds up meaningfully over a few weeks.',
        "Protecting your free time isn't indulgent here — it's a direct lever on this score.",
      ];
    }
    return [
      'Your lifestyle mix already looks active — keep the variety going.',
      'Consider trying one new activity this season to keep things from going stale.',
      'One idea: your current routine is solid — the next lever is usually variety, not more volume.',
      'Your active lifestyle is a real asset — protecting the time it takes matters as much as building it.',
      'Consider mixing in a new hobby or trip occasionally to keep this score from plateauing.',
      'A strong lifestyle base is worth maintaining consistently rather than pushing harder.',
      'One idea: share your active lifestyle with a friend — it often makes it easier to sustain.',
      'Your current balance of travel, exercise, and free time looks healthy — keep it up.',
      'Consider setting a small new goal (a race, a trip, a class) to keep this score moving.',
      'Even a well-balanced lifestyle benefits from the occasional change of pace.',
    ];
  }

  List<String> _wellbeingPool(UserProfile profile) {
    if (profile.stress >= 7) {
      return [
        'Your reported stress is high — even one recovery habit (sleep, a walk, journaling) tends to move this score more than any single life change.',
        'Consider identifying your single biggest source of stress — addressing one thing beats trying to fix everything at once.',
        'One idea: a short daily wind-down routine can meaningfully lower stress over a couple of weeks.',
        'Even 10 minutes of deliberate rest a day tends to bring stress down faster than people expect.',
        'Consider whether your stress is coming from one fixable source (workload, money, a relationship) versus general overwhelm.',
        'A consistent sleep schedule is one of the fastest ways to bring stress down.',
        'One idea: talking to someone you trust about your stress often helps more than trying to manage it alone.',
        'Consider building in one recovery activity you actually enjoy — stress relief that feels like a chore rarely sticks.',
        'Even short breaks during the day can meaningfully reduce accumulated stress by evening.',
        'Your stress level is the biggest lever on this score right now — small, consistent relief tends to work better than a single big fix.',
      ];
    }
    if (profile.happiness <= 4) {
      return [
        'Happiness is the biggest wellbeing lever here — small, repeatable things (people, sleep, movement) tend to move it more than big ones.',
        'Consider scheduling one small, genuinely enjoyable thing each week — happiness responds to repetition more than intensity.',
        'One idea: spending deliberate time with people who energize you tends to move happiness more than solo downtime.',
        'Even small wins, noticed and acknowledged, compound into real happiness over time.',
        "Consider what's been missing lately — sleep, connection, movement, or purpose each move happiness differently.",
        'A short gratitude habit, even just noting one good thing daily, measurably shifts happiness over weeks.',
        'One idea: reducing one source of daily friction can lift happiness more than adding a big new thing.',
        'Consider whether your current routine leaves room for anything purely enjoyable, not just productive.',
        'Even brief social contact on a hard day tends to lift happiness more than isolation.',
        'Your happiness score has real room to move — small, consistent changes tend to outperform big ones here.',
      ];
    }
    return [
      'Your wellbeing balance already looks healthy — protecting it matters as much as improving it.',
      "Consider what's currently working for your wellbeing and doing more of exactly that.",
      'One idea: a periodic check-in with yourself keeps a healthy balance from slipping unnoticed.',
      'Your stress and happiness levels look well-managed — consistency is the main lever from here.',
      'Consider protecting the habits that got you here, especially during busier periods.',
      'A healthy wellbeing balance is worth maintaining deliberately, not just assuming it\'ll continue.',
      'One idea: notice what tends to disrupt your balance and plan around it in advance.',
      'Your wellbeing looks solid — the next lever is usually resilience, not more improvement.',
      "Consider sharing whatever's working for your wellbeing with someone who might need it too.",
      'Even a well-balanced wellbeing score benefits from the occasional deliberate reset.',
    ];
  }
}
