
class DailyStats {
  final String date;       // YYYY-MM-DD
  final int steps;
  final int waterMl;
  final int calories;
  final bool checkedIn;
  final int pointsEarned;  // points earned this day (stored)
  final int currentStreak; // streak at time of this day's stats

  const DailyStats({
    required this.date,
    this.steps       = 0,
    this.waterMl     = 0,
    this.calories    = 0,
    this.checkedIn   = false,
    this.pointsEarned = 0,
    this.currentStreak = 0,
  });

  // Progress fractions (0.0 – 1.0)
  double get stepsProgress    => (steps   / 10000).clamp(0.0, 1.0);
  double get waterProgress    => (waterMl / 3000).clamp(0.0, 1.0);
  double get caloriesProgress => (calories / 500).clamp(0.0, 1.0);

  // ── Score formula ──────────────────────────────────────────────────────────
  // Check-in only → variable (see streakCheckinPoints)
  // Steps and Water are tracked but do NOT award points
  int get score {
    return checkedIn ? streakCheckinPoints(currentStreak) : 0;
  }

  // ── Streak check-in bonus ──────────────────────────────────────────────────
  // Day 1 (streak=1): 30 pts
  // Day 2 (streak=2): 40 pts
  // Day 3+ (streak≥3): 45 pts
  // Streak resets every Monday OR if a day is skipped.
  static int streakCheckinPoints(int streak) {
    if (streak <= 1) return 30;
    if (streak == 2) return 40;
    return 45;
  }

  static int caloriesFromSteps(int steps) => (steps * 0.04).round();

  Map<String, dynamic> toMap() => {
    'date':          date,
    'steps':         steps,
    'waterMl':       waterMl,
    'calories':      calories,
    'checkedIn':     checkedIn,
    'pointsEarned':  pointsEarned,
    'currentStreak': currentStreak,
  };

  factory DailyStats.fromMap(Map<String, dynamic> m) => DailyStats(
    date:          m['date']          as String?  ?? '',
    steps:         m['steps']         as int?     ?? 0,
    waterMl:       m['waterMl']       as int?     ?? 0,
    calories:      m['calories']      as int?     ?? 0,
    checkedIn:     m['checkedIn']     as bool?    ?? false,
    pointsEarned:  m['pointsEarned']  as int?     ?? 0,
    currentStreak: m['currentStreak'] as int?     ?? 0,
  );

  DailyStats copyWith({
    int?  steps,
    int?  waterMl,
    int?  calories,
    bool? checkedIn,
    int?  pointsEarned,
    int?  currentStreak,
  }) => DailyStats(
    date:          date,
    steps:         steps         ?? this.steps,
    waterMl:       waterMl       ?? this.waterMl,
    calories:      calories      ?? this.calories,
    checkedIn:     checkedIn     ?? this.checkedIn,
    pointsEarned:  pointsEarned  ?? this.pointsEarned,
    currentStreak: currentStreak ?? this.currentStreak,
  );
}