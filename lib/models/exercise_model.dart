class ExerciseModel {
  final String id;
  final String name;
  final String muscleGroup;
  final String secondaryMuscle;
  final String equipment;
  final String gifUrl;   // local asset path: 'assets/gifs/xxx.gif'
  final List<String> instructions;
  final int defaultSets;
  final String defaultReps;

  const ExerciseModel({
    required this.id,
    required this.name,
    required this.muscleGroup,
    this.secondaryMuscle = '',
    this.equipment = 'Barbell',
    required this.gifUrl,
    this.instructions = const [],
    this.defaultSets = 3,
    this.defaultReps = '8-12',
  });
}

// ── Categories ────────────────────────────────────────────────────────────────
const List<String> kMuscleCategories = [
  'All', 'Chest', 'Back', 'Legs', 'Shoulders', 'Biceps', 'Triceps', 'Core', 'Cardio',
];

// ── GIF asset paths ───────────────────────────────────────────────────────────
// Two bundled GIFs assigned intelligently by exercise type.
// chest_fly.gif  = dumbbell / isolation upper-body movements
// pushup.gif     = compound / bodyweight / pressing movements
const String _kFly      = 'assets/gifs/chest_fly.gif';
const String _kCompound = 'assets/gifs/pushup.gif';

// ── Exercise data ─────────────────────────────────────────────────────────────
const List<ExerciseModel> kExercises = [
  // ── CHEST ──────────────────────────────────────────────────────────────────
  ExerciseModel(
    id: '0017', name: 'Barbell Bench Press', muscleGroup: 'Chest',
    secondaryMuscle: 'Triceps, Shoulders', equipment: 'Barbell',
    gifUrl: 'assets/gifs/Barbell-Bench-Press.gif',
    instructions: [
      'Lie flat on bench, grip bar slightly wider than shoulders',
      'Lower bar to chest with control — don\'t bounce',
      'Press up explosively to full extension',
      'Keep feet flat and back slightly arched',
    ],
    defaultSets: 4, defaultReps: '6-10',
  ),
  ExerciseModel(
    id: '0022', name: 'Push-Up', muscleGroup: 'Chest',
    secondaryMuscle: 'Triceps, Core', equipment: 'Bodyweight',
    gifUrl: 'assets/gifs/pushup.gif',
    instructions: [
      'Start in high plank — hands shoulder-width, body straight',
      'Lower chest to floor, elbows at 45°',
      'Push through palms back to start',
      'Keep core tight throughout',
    ],
    defaultSets: 3, defaultReps: '15-20',
  ),
  ExerciseModel(
    id: '0030', name: 'Incline Dumbbell Press', muscleGroup: 'Chest',
    secondaryMuscle: 'Shoulders', equipment: 'Dumbbell',
    gifUrl: 'assets/gifs/Incline-Dumbbell-Press.gif',
    instructions: [
      'Set bench to 30–45 degrees',
      'Hold dumbbells at shoulder level, palms forward',
      'Press up until arms are fully extended',
      'Lower slowly back to start',
    ],
    defaultSets: 3, defaultReps: '10-12',
  ),
  ExerciseModel(
    id: '0031', name: 'Dumbbell Chest Fly', muscleGroup: 'Chest',
    equipment: 'Dumbbell',
    gifUrl: _kFly,
    instructions: [
      'Lie flat, dumbbells above chest with slight elbow bend',
      'Lower arms out in wide arc until chest stretches',
      'Squeeze chest to bring arms back together',
      'Keep elbows slightly bent throughout',
    ],
    defaultSets: 3, defaultReps: '12-15',
  ),
  ExerciseModel(
    id: '0036', name: 'Cable Chest Fly', muscleGroup: 'Chest',
    equipment: 'Cable',
    gifUrl: _kFly,
    instructions: [
      'Set cables at shoulder height on both sides',
      'Stand in the center, grip handles',
      'Bring handles together in front of chest',
      'Return slowly with control',
    ],
    defaultSets: 3, defaultReps: '12-15',
  ),

  // ── BACK ───────────────────────────────────────────────────────────────────
  ExerciseModel(
    id: '0032', name: 'Deadlift', muscleGroup: 'Back',
    secondaryMuscle: 'Hamstrings, Glutes', equipment: 'Barbell',
    gifUrl: 'assets/gifs/Barbell-Deadlift.gif',
    instructions: [
      'Stand hip-width, bar over mid-foot',
      'Hinge at hips, grip bar just outside legs',
      'Drive through heels, hips and shoulders rise together',
      'Lock out at top, squeeze glutes',
    ],
    defaultSets: 4, defaultReps: '5-6',
  ),
  ExerciseModel(
    id: '0033', name: 'Pull-Up', muscleGroup: 'Back',
    secondaryMuscle: 'Biceps', equipment: 'Bodyweight',
    gifUrl: 'assets/gifs/pullup.gif',
    instructions: [
      'Hang from bar with overhand grip, arms fully extended',
      'Pull chest to bar, squeezing shoulder blades',
      'Pause at top, then lower with control',
      'Avoid swinging or kipping',
    ],
    defaultSets: 3, defaultReps: '8-12',
  ),
  ExerciseModel(
    id: '0034', name: 'Barbell Row', muscleGroup: 'Back',
    secondaryMuscle: 'Biceps', equipment: 'Barbell',
    gifUrl: 'assets/gifs/Barbell-Bent-Over-Row.gif',
    instructions: [
      'Hinge forward to about 45 degrees',
      'Pull bar to lower chest / upper abdomen',
      'Squeeze shoulder blades at top',
      'Lower the bar slowly',
    ],
    defaultSets: 4, defaultReps: '8-10',
  ),
  ExerciseModel(
    id: '0035', name: 'Lat Pulldown', muscleGroup: 'Back',
    equipment: 'Cable',
    gifUrl: 'assets/gifs/Lat-Pulldown.gif',
    instructions: [
      'Grip bar slightly wider than shoulders, overhand',
      'Lean back slightly, pull bar to upper chest',
      'Keep chest up and elbows pointing down',
      'Control the bar back up slowly',
    ],
    defaultSets: 3, defaultReps: '10-12',
  ),

  // ── LEGS ───────────────────────────────────────────────────────────────────
  ExerciseModel(
    id: '0040', name: 'Barbell Squat', muscleGroup: 'Legs',
    secondaryMuscle: 'Glutes, Core', equipment: 'Barbell',
    gifUrl: _kCompound,
    instructions: [
      'Bar on upper traps, feet shoulder-width apart',
      'Brace core, squat down until thighs are parallel',
      'Drive through heels to stand',
      'Keep chest up throughout',
    ],
    defaultSets: 4, defaultReps: '6-8',
  ),
  ExerciseModel(
    id: '0041', name: 'Romanian Deadlift', muscleGroup: 'Legs',
    secondaryMuscle: 'Glutes', equipment: 'Barbell',
    gifUrl: _kCompound,
    instructions: [
      'Stand hip-width, bar at hips',
      'Hinge at hips, push them back while lowering bar',
      'Feel hamstring stretch, go as low as flexibility allows',
      'Drive hips forward to return',
    ],
    defaultSets: 3, defaultReps: '10-12',
  ),
  ExerciseModel(
    id: '0042', name: 'Leg Press', muscleGroup: 'Legs',
    equipment: 'Machine',
    gifUrl: _kFly,
    instructions: [
      'Sit in machine, feet shoulder-width on plate',
      'Lower until knees are at 90 degrees',
      'Press up through heels, don\'t lock out completely',
      'Keep lower back pressed to pad',
    ],
    defaultSets: 4, defaultReps: '10-15',
  ),
  ExerciseModel(
    id: '0043', name: 'Walking Lunge', muscleGroup: 'Legs',
    secondaryMuscle: 'Glutes', equipment: 'Bodyweight',
    gifUrl: _kCompound,
    instructions: [
      'Stand tall, step forward with one foot',
      'Lower back knee toward floor',
      'Push off front foot, bring feet together',
      'Alternate legs and keep torso upright',
    ],
    defaultSets: 3, defaultReps: '12 each leg',
  ),

  // ── SHOULDERS ──────────────────────────────────────────────────────────────
  ExerciseModel(
    id: '0050', name: 'Overhead Press', muscleGroup: 'Shoulders',
    secondaryMuscle: 'Triceps', equipment: 'Barbell',
    gifUrl: 'assets/gifs/overhead-press.gif',
    instructions: [
      'Grip bar at shoulders, elbows forward',
      'Press bar straight overhead, lock out arms',
      'Squeeze glutes and brace core',
      'Lower bar back to shoulders with control',
    ],
    defaultSets: 4, defaultReps: '6-8',
  ),
  ExerciseModel(
    id: '0051', name: 'Lateral Raise', muscleGroup: 'Shoulders',
    equipment: 'Dumbbell',
    gifUrl: _kFly,
    instructions: [
      'Stand tall, dumbbells at sides',
      'Raise arms out to shoulder height, lead with elbows',
      'Pause at top, feel lateral delt squeeze',
      'Lower slowly — 3 seconds down',
    ],
    defaultSets: 3, defaultReps: '15-20',
  ),
  ExerciseModel(
    id: '0052', name: 'Face Pull', muscleGroup: 'Shoulders',
    secondaryMuscle: 'Rear Delts', equipment: 'Cable',
    gifUrl: 'assets/gifs/Face-Pull.gif',
    instructions: [
      'Set cable at head height, use rope attachment',
      'Pull rope to your face, flare elbows out',
      'Squeeze rear delts at the end',
      'Return with control',
    ],
    defaultSets: 3, defaultReps: '15-20',
  ),

  // ── BICEPS ─────────────────────────────────────────────────────────────────
  ExerciseModel(
    id: '0060', name: 'Barbell Curl', muscleGroup: 'Biceps',
    secondaryMuscle: 'Forearms', equipment: 'Barbell',
    gifUrl: 'assets/gifs/Barbell-Curl.gif',
    instructions: [
      'Hold bar at hips, underhand grip shoulder-width',
      'Curl bar to shoulders keeping elbows pinned',
      'Squeeze bicep hard at top',
      'Lower slowly in 3 seconds',
    ],
    defaultSets: 3, defaultReps: '10-12',
  ),
  ExerciseModel(
    id: '0062', name: 'Hammer Curl', muscleGroup: 'Biceps',
    secondaryMuscle: 'Brachialis', equipment: 'Dumbbell',
    gifUrl: 'assets/gifs/Hammer-Curl.gif',
    instructions: [
      'Hold dumbbells with neutral grip (palms facing each other)',
      'Curl toward shoulders, keep elbows pinned to sides',
      'Squeeze at top, lower slowly',
      'Alternate arms or do together',
    ],
    defaultSets: 3, defaultReps: '10-12',
  ),
  ExerciseModel(
    id: '0064', name: 'Concentration Curl', muscleGroup: 'Biceps',
    equipment: 'Dumbbel',
    gifUrl: 'assets/gifs/Concentration-Curl.gif',
    instructions: [
      'Sit on bench, rest elbow on inner thigh',
      'Curl dumbbell up to shoulder',
      'Squeeze at top, lower with control',
      'Keep upper arm still throughout',
    ],
    defaultSets: 3, defaultReps: '12-15',
  ),

  // ── TRICEPS ────────────────────────────────────────────────────────────────
  ExerciseModel(
    id: '0061', name: 'Tricep Pushdown', muscleGroup: 'Triceps',
    equipment: 'Cable',
    gifUrl: _kFly,
    instructions: [
      'Set cable at head height, use bar or rope',
      'Push down until arms are fully locked out',
      'Flare wrists slightly at bottom if using rope',
      'Control the return — don\'t let elbows flare',
    ],
    defaultSets: 3, defaultReps: '12-15',
  ),
  ExerciseModel(
    id: '0063', name: 'Skull Crusher', muscleGroup: 'Triceps',
    secondaryMuscle: 'Chest', equipment: 'EZ Bar',
    gifUrl: _kFly,
    instructions: [
      'Lie on bench, hold EZ bar above chest',
      'Lower bar toward forehead by bending elbows',
      'Extend arms back up — only elbows move',
      'Keep upper arms perpendicular to floor',
    ],
    defaultSets: 3, defaultReps: '10-12',
  ),
  ExerciseModel(
    id: '0065', name: 'Overhead Tricep Extension', muscleGroup: 'Triceps',
    equipment: 'Dumbbell',
    gifUrl: _kFly,
    instructions: [
      'Hold one dumbbell with both hands overhead',
      'Lower behind head by bending elbows',
      'Extend arms back to straight overhead',
      'Keep elbows close to head',
    ],
    defaultSets: 3, defaultReps: '12-15',
  ),

  // ── CORE ───────────────────────────────────────────────────────────────────
  ExerciseModel(
    id: '0070', name: 'Plank', muscleGroup: 'Core',
    equipment: 'Bodyweight',
    gifUrl: _kCompound,
    instructions: [
      'Forearms on floor, body in a straight line',
      'Brace core as if taking a punch',
      'Keep hips level — don\'t sag or raise',
      'Hold for time, breathe steadily',
    ],
    defaultSets: 3, defaultReps: '45-60 sec',
  ),
  ExerciseModel(
    id: '0071', name: 'Cable Crunch', muscleGroup: 'Core',
    equipment: 'Cable',
    gifUrl: _kFly,
    instructions: [
      'Kneel below high cable, rope at neck level',
      'Crunch elbows toward knees, rounding spine',
      'Squeeze abs hard at bottom',
      'Return slowly under control',
    ],
    defaultSets: 3, defaultReps: '15-20',
  ),
  ExerciseModel(
    id: '0072', name: 'Hanging Leg Raise', muscleGroup: 'Core',
    equipment: 'Bodyweight',
    gifUrl: _kCompound,
    instructions: [
      'Hang from pull-up bar, arms fully extended',
      'Raise straight legs to 90 degrees (or higher)',
      'Control the descent — don\'t swing',
      'Keep shoulders packed throughout',
    ],
    defaultSets: 3, defaultReps: '12-15',
  ),

  // ── CARDIO ─────────────────────────────────────────────────────────────────
  ExerciseModel(
    id: '0080', name: 'Treadmill Run', muscleGroup: 'Cardio',
    equipment: 'Machine',
    gifUrl: _kCompound,
    instructions: [
      'Start at comfortable walking pace, warm up 2 min',
      'Increase to running speed, maintain posture',
      'Breathe rhythmically, arms relaxed',
      'Cool down gradually in last 2 minutes',
    ],
    defaultSets: 1, defaultReps: '20-30 min',
  ),
  ExerciseModel(
    id: '0081', name: 'Jump Rope', muscleGroup: 'Cardio',
    equipment: 'Jump Rope',
    gifUrl: _kCompound,
    instructions: [
      'Hold handles at hip level, rope behind heels',
      'Jump with both feet together, stay on balls of feet',
      'Keep elbows close to body, wrists do the turning',
      'Land softly to protect knees',
    ],
    defaultSets: 3, defaultReps: '2 min rounds',
  ),
  ExerciseModel(
    id: '0082', name: 'Burpee', muscleGroup: 'Cardio',
    secondaryMuscle: 'Full Body', equipment: 'Bodyweight',
    gifUrl: _kCompound,
    instructions: [
      'Start standing, drop hands to floor',
      'Jump feet back to push-up position',
      'Do one push-up (optional)',
      'Jump feet forward, explode up with arms overhead',
    ],
    defaultSets: 3, defaultReps: '10-15',
  ),
];