class WorkoutDay {
  final String day;
  List<PlannedExercise> exercises;

  WorkoutDay({required this.day, List<PlannedExercise>? exercises})
      : exercises = exercises ?? [];
}

class PlannedExercise {
  final String exerciseId;
  final String name;
  final String muscleGroup;
  int sets;
  String reps;
  bool isComplete;

  PlannedExercise({
    required this.exerciseId,
    required this.name,
    required this.muscleGroup,
    this.sets = 3,
    this.reps = '10-12',
    this.isComplete = false,
  });

  Map<String, dynamic> toMap() => {
    'exerciseId': exerciseId,
    'name': name,
    'muscleGroup': muscleGroup,
    'sets': sets,
    'reps': reps,
  };

  factory PlannedExercise.fromMap(Map<String, dynamic> m) => PlannedExercise(
    exerciseId: m['exerciseId'] ?? '',
    name: m['name'] ?? '',
    muscleGroup: m['muscleGroup'] ?? '',
    sets: m['sets'] ?? 3,
    reps: m['reps'] ?? '10-12',
  );
}

class WorkoutPlanTemplate {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final List<String> highlights;
  final List<WorkoutDay> days;

  const WorkoutPlanTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.highlights,
    required this.days,
  });
}

// ── Pre-built plan templates ───────────────────────────────────────────────────
final List<WorkoutPlanTemplate> kPlanTemplates = [
  WorkoutPlanTemplate(
    id: 'bro_split',
    name: 'Bro Split',
    emoji: '💪',
    description: '1 major + 1 minor muscle per day. Classic bodybuilder style.',
    highlights: ['6 days/week', 'High volume', 'Isolation focused'],
    days: [
      WorkoutDay(day: 'Monday'),
      WorkoutDay(day: 'Tuesday'),
      WorkoutDay(day: 'Wednesday'),
      WorkoutDay(day: 'Thursday'),
      WorkoutDay(day: 'Friday'),
      WorkoutDay(day: 'Saturday'),
      WorkoutDay(day: 'Sunday'),
    ],
  ),
  WorkoutPlanTemplate(
    id: 'ppl',
    name: 'Push Pull Legs',
    emoji: '🔄',
    description: 'Push (Chest/Shoulders/Triceps), Pull (Back/Biceps), Legs. Repeat.',
    highlights: ['6 days/week', 'Balanced', 'Efficient'],
    days: [
      WorkoutDay(day: 'Monday'),
      WorkoutDay(day: 'Tuesday'),
      WorkoutDay(day: 'Wednesday'),
      WorkoutDay(day: 'Thursday'),
      WorkoutDay(day: 'Friday'),
      WorkoutDay(day: 'Saturday'),
      WorkoutDay(day: 'Sunday'),
    ],
  ),
  WorkoutPlanTemplate(
    id: 'two_per_day',
    name: 'Two Muscles / Day',
    emoji: '⚡',
    description: 'Two muscle groups per session at 50/50 volume split.',
    highlights: ['4-5 days/week', 'Moderate volume', 'Beginner friendly'],
    days: [
      WorkoutDay(day: 'Monday'),
      WorkoutDay(day: 'Tuesday'),
      WorkoutDay(day: 'Wednesday'),
      WorkoutDay(day: 'Thursday'),
      WorkoutDay(day: 'Friday'),
      WorkoutDay(day: 'Saturday'),
      WorkoutDay(day: 'Sunday'),
    ],
  ),
  WorkoutPlanTemplate(
    id: 'custom',
    name: 'Custom Plan',
    emoji: '🎯',
    description: 'Build your own plan from scratch. Full control.',
    highlights: ['Your schedule', 'Your exercises', 'Your goals'],
    days: [
      WorkoutDay(day: 'Monday'),
      WorkoutDay(day: 'Tuesday'),
      WorkoutDay(day: 'Wednesday'),
      WorkoutDay(day: 'Thursday'),
      WorkoutDay(day: 'Friday'),
      WorkoutDay(day: 'Saturday'),
      WorkoutDay(day: 'Sunday'),
    ],
  ),
];
