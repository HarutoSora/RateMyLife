import '../../data/models/models.dart';

/// Picks and judges the daily "What Would You Choose" would-you-rather
/// prompt. Unlike Life Battles (which compares two real profiles and can
/// only ever *estimate* an audience split — see `BattleResult`'s doc
/// comment), these prompts are hypothetical and unrelated to any real
/// profile, so a real vote tally is not just possible but the only
/// sensible option — there's no Life Score gap to estimate a split from.
class ChoiceService {
  const ChoiceService();

  /// Deliberately light, everyday lifestyle dilemmas — this is a social
  /// comparison game, not a survey with stakes.
  static const List<Choice> pool = [
    Choice(id: 'salary_weekends', promptA: 'Double your salary, but work every weekend', promptB: 'Keep your salary, but every Friday off'),
    Choice(id: 'house_friends', promptA: 'A huge house far from everyone you love', promptB: 'A tiny apartment surrounded by your best friends'),
    Choice(id: 'famous_private', promptA: 'Be famous, but have zero privacy', promptB: 'Be anonymous, but never be recognized for your work'),
    Choice(id: 'sleep_work', promptA: 'Never need sleep again', promptB: 'Never need to work again'),
    Choice(id: 'travel_money', promptA: 'Travel the world with no money to spend', promptB: 'Stay home with unlimited money to spend'),
    Choice(id: 'job_salary', promptA: 'Your dream job, average salary', promptB: 'An average job, your dream salary'),
    Choice(id: 'look_feel', promptA: 'Look 10 years younger', promptB: 'Feel 10 years younger'),
    Choice(id: 'know_surprise', promptA: 'Know exactly how your life turns out', promptB: 'Never know what\'s coming next'),
    Choice(id: 'smart_happy', promptA: 'Be the smartest person you know', promptB: 'Be the happiest person you know'),
    Choice(id: 'vacation_savings', promptA: 'Unlimited vacation days, no savings', promptB: 'Unlimited savings, no vacation days'),
    Choice(id: 'family_career', promptA: 'Live near your family', promptB: 'Live near your dream career opportunities'),
    Choice(id: 'retire_early_modest', promptA: 'Retire at 30, live modestly', promptB: 'Retire at 60, live lavishly'),
  ];

  static DateTime dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  /// A deterministic pick for [date] — the same day always yields the
  /// same prompt, mirroring `DailyChallengeService.challengesFor`.
  Choice choiceFor(DateTime date) {
    final day = dateOnly(date);
    final dayIndex = day.difference(DateTime(2026)).inDays;
    return pool[dayIndex % pool.length];
  }

  bool hasVoted(List<ChoiceVote> votes, String questionId) => votes.any((v) => v.questionId == questionId);
}
