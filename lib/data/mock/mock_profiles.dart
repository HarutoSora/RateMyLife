import '../../domain/scoring/life_score_service.dart';
import '../models/models.dart';

/// Placeholder headshots used only to make mock/demo profiles look
/// populated during local development — not real user photos.
final _peopleAssets = [
  for (var i = 1; i <= 17; i++) 'assets/mock/people/p${i.toString().padLeft(2, '0')}.png',
];

const _carModels = [
  'Dacia Duster', 'VW Golf', 'Toyota Corolla', 'BMW 3 Series', 'Tesla Model 3',
  'Renault Clio', 'Honda Civic', 'Mercedes C-Class', 'Hyundai Tucson', 'Audi A4',
];

List<UserProfile> buildMockProfiles() {
  final now = DateTime.now();
  const scoreService = LifeScoreService();
  final seeds = <_Seed>[
    const _Seed('Nour', 19, 'Morocco', 'Rabat', 'Student', 'Education', 'Architecture student', 0, 'Student', 1400, 'MAD', 12000, 0, 0, 1800, 'Single', 'With family', false, false, 'Rarely', 'Weekly', ['Sketching', 'Cafe hopping', 'Tennis'], 18, 5, 7, 4, 'Get into a top studio', 'Studying architecture and trying to see more of Morocco.'),
    const _Seed('Maya', 22, 'France', 'Lyon', 'Freelancer', 'Creative', 'Photographer', 2, 'Bachelor', 2100, 'EUR', 9000, 1500, 1200, 1600, 'Single', 'Rents apartment', false, false, '3-4 times/year', 'Sometimes', ['Photography', 'Food', 'Festivals'], 22, 6, 8, 5, 'Build a serious client list', 'Freelance photos, cheap flights, late dinners.'),
    const _Seed('Alex', 24, 'Morocco', 'Casablanca', 'Employed', 'Technology', 'Software Developer', 3, 'Master', 12000, 'MAD', 80000, 20000, 0, 5200, 'Single', 'With family', true, false, '3-4 times/year', 'Weekly', ['Travel', 'Gaming', 'Fitness'], 16, 4, 7, 6, 'Move into my own place', 'Building my life one trip at a time.'),
    const _Seed('Imane', 27, 'Morocco', 'Tangier', 'Employed', 'Healthcare', 'Nurse', 5, 'Diploma', 7600, 'MAD', 45000, 8000, 5000, 4200, 'Engaged', 'Rents apartment', false, false, 'Once/year', 'Weekly', ['Cooking', 'Running', 'Family'], 14, 8, 8, 5, 'Buy a small apartment', 'Night shifts, beach walks, and saving aggressively.'),
    const _Seed('Omar', 31, 'UAE', 'Dubai', 'Founder', 'Business', 'Cafe owner', 7, 'Bachelor', 26000, 'AED', 180000, 90000, 60000, 17000, 'Married', 'Rents apartment', true, false, 'Monthly', 'Sometimes', ['Cars', 'Food', 'Padel'], 12, 7, 7, 7, 'Open a second location', 'Hospitality business, fast city, slow mornings.'),
    const _Seed('Sarah', 26, 'France', 'Paris', 'Employed', 'Design', 'Product Designer', 4, 'Master', 3600, 'EUR', 28000, 6000, 0, 2500, 'Single', 'Rents apartment', false, false, 'Monthly', 'Daily', ['Museums', 'Travel', 'Pilates'], 20, 7, 8, 4, 'See the world without burning out', 'Trying to see the world and still sleep enough.'),
    const _Seed('Ryan', 35, 'USA', 'Austin', 'Employed', 'Technology', 'Engineering Manager', 11, 'Bachelor', 9800, 'USD', 115000, 210000, 180000, 6200, 'Married', 'Owns home', true, true, '3-4 times/year', 'Weekly', ['Cycling', 'BBQ', 'Investing'], 10, 6, 8, 6, 'Spend more time with my kids', 'Comfortable, busy, and trying to stay present.'),
    const _Seed('Priya', 29, 'India', 'Bengaluru', 'Employed', 'Technology', 'Data Scientist', 6, 'Master', 240000, 'INR', 1800000, 750000, 0, 95000, 'In a relationship', 'Rents apartment', false, false, '3-4 times/year', 'Weekly', ['Dance', 'Startups', 'Travel'], 18, 7, 8, 5, 'Move to product leadership', 'Data, dance classes, and weekend flights.'),
    const _Seed('Lucas', 42, 'Switzerland', 'Zurich', 'Executive', 'Finance', 'Portfolio Director', 17, 'Master', 16000, 'CHF', 380000, 900000, 250000, 9800, 'Married', 'Owns home', true, true, 'Monthly', 'Weekly', ['Skiing', 'Wine', 'Reading'], 12, 5, 7, 6, 'Work less without losing momentum', 'High standards, mountain weekends, family first.'),
    const _Seed('Camila', 33, 'Brazil', 'Sao Paulo', 'Business Owner', 'Retail', 'Boutique owner', 9, 'Bachelor', 13000, 'BRL', 90000, 70000, 25000, 8200, 'Single', 'Rents apartment', true, false, 'Once/year', 'Sometimes', ['Fashion', 'Beach', 'Music'], 18, 9, 8, 6, 'Launch online sales', 'Small business energy and big weekend plans.'),
  ];

  final countries = ['Morocco', 'France', 'USA', 'India', 'Canada', 'UAE', 'Brazil', 'Switzerland'];
  final jobs = [
    ['Employed', 'Education', 'Teacher'],
    ['Student', 'Education', 'Medical student'],
    ['Freelancer', 'Creative', 'Video editor'],
    ['Employed', 'Healthcare', 'Physiotherapist'],
    ['Employed', 'Hospitality', 'Hotel manager'],
    ['Founder', 'Business', 'Marketplace founder'],
    ['Employed', 'Operations', 'Logistics coordinator'],
    ['Employed', 'Technology', 'Mobile developer'],
  ];
  final bios = [
    'Trying to build a better life and stop wasting money.',
    'Career is moving, sleep schedule is not.',
    'Good friends, modest money, big plans.',
    'I work hard so my weekends feel expensive.',
    'Building quietly and comparing honestly.',
    'Not rich, not lost, still upgrading.',
    'Making adulthood look easier than it feels.',
    'I want more travel and less stress.',
  ];
  final names = [
    'NightOwl', 'Lea', 'Youssef', 'Ana', 'Momo', 'Kenji', 'Lina', 'Sam',
    'Rania', 'Victor', 'Hana', 'Noah', 'Meryem', 'Adam', 'Chloe', 'Aisha',
    'Leo', 'Sofia', 'Yara', 'Daniel', 'Amir', 'Nina', 'Eli', 'Ines',
    'Bilal', 'Mina', 'Tom', 'Zara', 'Mehdi', 'Ella', 'Jade', 'Karim',
    'Mila', 'Jonas', 'Aya', 'Theo', 'Sara24', 'Neil', 'Rim', 'Ilyas',
  ];

  final generated = <_Seed>[];
  for (var i = 0; i < 40; i++) {
    final country = countries[i % countries.length];
    final job = jobs[i % jobs.length];
    final age = 19 + (i * 3) % 37;
    final incomeBase = switch (country) {
      'Morocco' => 3500 + i * 410,
      'France' => 1300 + i * 95,
      'USA' => 2200 + i * 180,
      'India' => 45000 + i * 6300,
      'Canada' => 2600 + i * 150,
      'UAE' => 7000 + i * 580,
      'Brazil' => 2600 + i * 360,
      'Switzerland' => 4200 + i * 260,
      _ => 2000 + i * 100,
    };
    generated.add(_Seed(
      names[i],
      age,
      country,
      _cityFor(country, i),
      job[0],
      job[1],
      job[2],
      (age - 20).clamp(0, 18).toInt(),
      i % 5 == 0 ? 'Master' : i % 3 == 0 ? 'Bachelor' : 'Diploma',
      incomeBase.toDouble(),
      _currencyFor(country),
      incomeBase * (4 + (i % 10)),
      incomeBase * (i % 6),
      i % 4 == 0 ? incomeBase * 3 : 0,
      incomeBase * (0.48 + (i % 4) * 0.08),
      i % 4 == 0 ? 'Married' : i % 3 == 0 ? 'In a relationship' : 'Single',
      i % 5 == 0 ? 'Owns home' : i % 2 == 0 ? 'Rents apartment' : 'With family',
      i % 2 == 0,
      i % 5 == 0,
      ['Rarely', 'Once/year', '3-4 times/year', 'Monthly'][i % 4],
      ['Rarely', 'Sometimes', 'Weekly', 'Daily'][i % 4],
      [
        ['Food', 'Football', 'Movies'],
        ['Travel', 'Fitness', 'Photography'],
        ['Gaming', 'Music', 'Reading'],
        ['Cooking', 'Hiking', 'Friends'],
      ][i % 4],
      8 + (i % 18),
      2 + (i % 8),
      5 + (i % 5),
      3 + (i % 7),
      'Level up the next chapter',
      bios[i % bios.length],
    ));
  }

  final all = [...seeds, ...generated];
  return [
    for (var i = 0; i < all.length; i++)
      _profileFromSeed(all[i], i, now, scoreService),
  ];
}

UserProfile _profileFromSeed(
  _Seed seed,
  int index,
  DateTime now,
  LifeScoreService scoreService,
) {
  final id = 'mock_${index + 1}';
  final photos = [
    for (var i = 0; i < 4 + (index % 4); i++)
      ProfilePhoto(
        id: '${id}_photo_$i',
        ownerId: id,
        path: i == 0 ? _peopleAssets[index % _peopleAssets.length] : 'mock://${seed.photoLabels[i % seed.photoLabels.length]}',
        isProfilePhoto: i == 0,
        order: i,
        category: seed.photoLabels[i % seed.photoLabels.length],
        createdAt: now.subtract(Duration(days: 30 + i)),
      ),
  ];
  var profile = UserProfile(
    id: id,
    displayName: seed.name,
    age: seed.age,
    country: seed.country,
    city: seed.city,
    gender: index % 3 == 0 ? 'Optional' : null,
    employmentStatus: seed.employmentStatus,
    jobCategory: seed.jobCategory,
    jobTitle: seed.jobTitle,
    yearsExperience: seed.experience,
    educationLevel: seed.education,
    monthlyIncome: seed.income,
    currency: seed.currency,
    savings: seed.savings,
    investments: seed.investments,
    debt: seed.debt,
    monthlyExpenses: seed.expenses,
    relationshipStatus: seed.relationship,
    livingSituation: seed.living,
    ownsCar: seed.ownsCar,
    carModel: seed.ownsCar ? _carModels[index % _carModels.length] : null,
    ownsHome: seed.ownsHome,
    travelFrequency: seed.travel,
    exerciseFrequency: seed.exercise,
    hobbies: seed.hobbies,
    freeTimeHours: seed.freeTime,
    closeFriends: seed.friends,
    happiness: seed.happiness,
    stress: seed.stress,
    currentGoal: seed.goal,
    bio: seed.bio,
    photos: photos,
    score: LifeScore.empty(),
    ratingSummary: RatingSummary(
      averageOverall: (5.8 + (index % 37) / 10) / 2,
      averageLook: (5.6 + (index % 39) / 10) / 2,
      count: 28 + index * 19,
      averageCareer: (5.5 + (index % 32) / 10) / 2,
      averageLifestyle: (5.7 + (index % 35) / 10) / 2,
      averageSocial: (5.2 + (index % 30) / 10) / 2,
      averageIndependence: (5.0 + (index % 34) / 10) / 2,
      averageExperiences: (5.4 + (index % 33) / 10) / 2,
    ),
    history: [
      ScoreHistoryPoint(
        month: 'May',
        algorithmScore: 54 + index % 18,
        communityRating: (5.9 + index % 20 / 10) / 2,
        createdAt: now.subtract(const Duration(days: 90)),
      ),
      ScoreHistoryPoint(
        month: 'Jun',
        algorithmScore: 58 + index % 18,
        communityRating: (6.2 + index % 20 / 10) / 2,
        createdAt: now.subtract(const Duration(days: 60)),
      ),
      ScoreHistoryPoint(
        month: 'Jul',
        algorithmScore: 61 + index % 18,
        communityRating: (6.5 + index % 20 / 10) / 2,
        createdAt: now.subtract(const Duration(days: 30)),
      ),
    ],
    privacy: const ProfilePrivacy(showIncome: true, showSavings: false),
    createdAt: now.subtract(Duration(days: 140 - index)),
    updatedAt: now.subtract(Duration(days: index % 18)),
  );
  profile = profile.copyWith(score: scoreService.calculate(profile));
  return profile.copyWith(
    history: [
      ...profile.history,
      ScoreHistoryPoint(
        month: 'Aug',
        algorithmScore: profile.score.overall,
        communityRating: profile.ratingSummary.averageOverall,
        createdAt: now,
      ),
    ],
  );
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

String _cityFor(String country, int i) => switch (country) {
      'Morocco' => ['Casablanca', 'Rabat', 'Marrakesh', 'Tangier'][i % 4],
      'France' => ['Paris', 'Lyon', 'Marseille', 'Lille'][i % 4],
      'USA' => ['Austin', 'Seattle', 'Miami', 'Denver'][i % 4],
      'India' => ['Bengaluru', 'Mumbai', 'Delhi', 'Pune'][i % 4],
      'Canada' => ['Toronto', 'Vancouver', 'Montreal', 'Calgary'][i % 4],
      'UAE' => ['Dubai', 'Abu Dhabi', 'Sharjah', 'Ajman'][i % 4],
      'Brazil' => ['Sao Paulo', 'Rio', 'Curitiba', 'Salvador'][i % 4],
      'Switzerland' => ['Zurich', 'Geneva', 'Basel', 'Lausanne'][i % 4],
      _ => 'Global City',
    };

class _Seed {
  const _Seed(
    this.name,
    this.age,
    this.country,
    this.city,
    this.employmentStatus,
    this.jobCategory,
    this.jobTitle,
    this.experience,
    this.education,
    this.income,
    this.currency,
    this.savings,
    this.investments,
    this.debt,
    this.expenses,
    this.relationship,
    this.living,
    this.ownsCar,
    this.ownsHome,
    this.travel,
    this.exercise,
    this.hobbies,
    this.freeTime,
    this.friends,
    this.happiness,
    this.stress,
    this.goal,
    this.bio,
  );

  final String name;
  final int age;
  final String country;
  final String city;
  final String employmentStatus;
  final String jobCategory;
  final String jobTitle;
  final int experience;
  final String education;
  final double income;
  final String currency;
  final double savings;
  final double investments;
  final double debt;
  final double expenses;
  final String relationship;
  final String living;
  final bool ownsCar;
  final bool ownsHome;
  final String travel;
  final String exercise;
  final List<String> hobbies;
  final int freeTime;
  final int friends;
  final int happiness;
  final int stress;
  final String goal;
  final String bio;

  List<String> get photoLabels => const [
        'Profile',
        'Travel',
        'Home',
        'Food',
        'Hobby',
        'Fitness',
        'Achievement',
        'Weekend',
      ];
}
