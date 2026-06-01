/// Daily fitness quiz question model
class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;   // 4 options for MCQ, ['True','False'] for T/F
  final int correctIndex;       // index into options
  final String explanation;     // shown after answering

  const QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  bool get isTrueFalse => options.length == 2 &&
      options[0] == 'True' && options[1] == 'False';
  String get correctAnswer => options[correctIndex];
}

/// 30 questions — covers steps, nutrition, recovery, hydration, gym basics
const List<QuizQuestion> kQuizBank = [
  QuizQuestion(
    id: 'q01',
    question: 'What is the daily step goal recommended for general health?',
    options: ['5,000 steps', '7,500 steps', '10,000 steps', '15,000 steps'],
    correctIndex: 2,
    explanation: '10,000 steps per day is widely recommended for cardiovascular health and calorie burn.',
  ),
  QuizQuestion(
    id: 'q02',
    question: 'How much water should an average adult drink per day?',
    options: ['1 litre', '2 litres', '3 litres', '4 litres'],
    correctIndex: 2,
    explanation: 'About 3 litres (men) and 2.7 litres (women) per day is recommended, including food sources.',
  ),
  QuizQuestion(
    id: 'q03',
    question: 'Protein intake after a workout helps muscle recovery.',
    options: ['True', 'False'],
    correctIndex: 0,
    explanation: 'Consuming 20–40g of protein within 2 hours post-workout maximises muscle protein synthesis.',
  ),
  QuizQuestion(
    id: 'q04',
    question: 'Which macronutrient is the body\'s primary energy source during intense exercise?',
    options: ['Fat', 'Protein', 'Carbohydrate', 'Fibre'],
    correctIndex: 2,
    explanation: 'Carbohydrates (glycogen) are the preferred fuel for high-intensity exercise.',
  ),
  QuizQuestion(
    id: 'q05',
    question: 'How many hours of sleep are recommended for muscle recovery?',
    options: ['5–6 hours', '7–9 hours', '10–12 hours', '4–5 hours'],
    correctIndex: 1,
    explanation: 'Most adults need 7–9 hours. Growth hormone peaks during deep sleep, aiding muscle repair.',
  ),
  QuizQuestion(
    id: 'q06',
    question: 'Stretching before a workout prevents all injuries.',
    options: ['True', 'False'],
    correctIndex: 1,
    explanation: 'Stretching helps but does not prevent all injuries. A proper warm-up (light cardio) is more effective.',
  ),
  QuizQuestion(
    id: 'q07',
    question: 'Which exercise is best for building overall back strength?',
    options: ['Bicep curl', 'Deadlift', 'Lateral raise', 'Calf raise'],
    correctIndex: 1,
    explanation: 'The deadlift engages the entire posterior chain: glutes, hamstrings, spinal erectors, and traps.',
  ),
  QuizQuestion(
    id: 'q08',
    question: 'What does BMI stand for?',
    options: ['Body Mass Index', 'Basal Metabolic Intensity', 'Body Muscle Index', 'Basic Muscle Indicator'],
    correctIndex: 0,
    explanation: 'BMI (Body Mass Index) = weight (kg) ÷ height² (m²). It estimates healthy weight ranges.',
  ),
  QuizQuestion(
    id: 'q09',
    question: 'Rest days are unnecessary if you want to build muscle fast.',
    options: ['True', 'False'],
    correctIndex: 1,
    explanation: 'Muscles grow during rest, not during training. Skipping rest days leads to overtraining and injury.',
  ),
  QuizQuestion(
    id: 'q10',
    question: 'How many calories does 1 gram of protein contain?',
    options: ['4 kcal', '7 kcal', '9 kcal', '11 kcal'],
    correctIndex: 0,
    explanation: 'Protein and carbohydrates each contain 4 kcal/g. Fat contains 9 kcal/g.',
  ),
  QuizQuestion(
    id: 'q11',
    question: 'Which muscle does the bench press primarily target?',
    options: ['Back', 'Biceps', 'Chest (pectorals)', 'Quadriceps'],
    correctIndex: 2,
    explanation: 'The bench press is a compound push movement primarily targeting the pectoralis major (chest).',
  ),
  QuizQuestion(
    id: 'q12',
    question: 'Drinking water before a meal can help with weight management.',
    options: ['True', 'False'],
    correctIndex: 0,
    explanation: 'Studies show drinking 500ml of water 30 minutes before meals reduces caloric intake by up to 13%.',
  ),
  QuizQuestion(
    id: 'q13',
    question: 'What is a "rep" in gym terminology?',
    options: ['A rest period', 'One complete movement of an exercise', 'A set of exercises', 'A warm-up routine'],
    correctIndex: 1,
    explanation: 'A "rep" (repetition) is one complete execution of an exercise, e.g. one full push-up.',
  ),
  QuizQuestion(
    id: 'q14',
    question: 'Cardio should always be done before weight training.',
    options: ['True', 'False'],
    correctIndex: 1,
    explanation: 'If strength is your goal, lift weights first while energy is highest. Save cardio for after.',
  ),
  QuizQuestion(
    id: 'q15',
    question: 'Which vitamin is synthesised by the body when exposed to sunlight?',
    options: ['Vitamin A', 'Vitamin B12', 'Vitamin C', 'Vitamin D'],
    correctIndex: 3,
    explanation: 'Vitamin D is produced in the skin through UVB sunlight exposure. It\'s vital for bone and muscle health.',
  ),
  QuizQuestion(
    id: 'q16',
    question: 'What is the ideal protein intake per kg of body weight for muscle building?',
    options: ['0.5 g/kg', '1.0 g/kg', '1.6–2.2 g/kg', '3.5 g/kg'],
    correctIndex: 2,
    explanation: 'Research supports 1.6–2.2g of protein per kg of body weight daily for optimal muscle growth.',
  ),
  QuizQuestion(
    id: 'q17',
    question: 'Spot reduction (losing fat in one specific area by exercising it) is effective.',
    options: ['True', 'False'],
    correctIndex: 1,
    explanation: 'Fat loss is systemic — you cannot choose where your body loses fat first.',
  ),
  QuizQuestion(
    id: 'q18',
    question: 'Which exercise targets the triceps?',
    options: ['Barbell curl', 'Skull crusher', 'Leg press', 'Pull-up'],
    correctIndex: 1,
    explanation: 'The skull crusher (lying triceps extension) directly isolates the triceps brachii.',
  ),
  QuizQuestion(
    id: 'q19',
    question: 'How long does it typically take to form a new habit?',
    options: ['7 days', '21 days', '66 days', '6 months'],
    correctIndex: 2,
    explanation: 'Research by University College London found that habits form in approximately 66 days on average.',
  ),
  QuizQuestion(
    id: 'q20',
    question: 'Sweating more during a workout means you\'re burning more fat.',
    options: ['True', 'False'],
    correctIndex: 1,
    explanation: 'Sweating is your body\'s cooling mechanism. Fat burn depends on heart rate and caloric deficit, not sweat.',
  ),
  QuizQuestion(
    id: 'q21',
    question: 'What does HIIT stand for?',
    options: ['High Intensity Interval Training', 'Heavy Iron Intense Training', 'High Impact Incremental Training', 'Hybrid Intensity Interval Technique'],
    correctIndex: 0,
    explanation: 'HIIT alternates between intense bursts of activity and fixed periods of rest, burning more calories in less time.',
  ),
  QuizQuestion(
    id: 'q22',
    question: 'Creatine is safe and effective for improving strength and power.',
    options: ['True', 'False'],
    correctIndex: 0,
    explanation: 'Creatine monohydrate is one of the most researched supplements. It\'s proven safe and improves high-intensity performance.',
  ),
  QuizQuestion(
    id: 'q23',
    question: 'Which is NOT a compound exercise?',
    options: ['Squat', 'Deadlift', 'Bicep curl', 'Pull-up'],
    correctIndex: 2,
    explanation: 'The bicep curl is an isolation exercise. Compound exercises like squats and deadlifts engage multiple joints.',
  ),
  QuizQuestion(
    id: 'q24',
    question: 'The human body is approximately what percentage of water?',
    options: ['30%', '45%', '60%', '80%'],
    correctIndex: 2,
    explanation: 'The adult human body is about 60% water. Muscles are ~75% water, making hydration critical for performance.',
  ),
  QuizQuestion(
    id: 'q25',
    question: 'Eating fat will make you fat.',
    options: ['True', 'False'],
    correctIndex: 1,
    explanation: 'Excess calories from ANY macronutrient cause fat gain. Healthy fats (avocado, nuts) are essential for hormones.',
  ),
  QuizQuestion(
    id: 'q26',
    question: 'What does "progressive overload" mean in strength training?',
    options: ['Training every day', 'Gradually increasing weight/reps over time', 'Lifting the heaviest weight on day one', 'Reducing rest time between sets'],
    correctIndex: 1,
    explanation: 'Progressive overload — consistently increasing the demand on muscles — is the key principle behind strength gains.',
  ),
  QuizQuestion(
    id: 'q27',
    question: 'Muscle weighs more than fat.',
    options: ['True', 'False'],
    correctIndex: 0,
    explanation: 'Per unit volume, muscle is denser and heavier than fat. This is why fit people can weigh more but look leaner.',
  ),
  QuizQuestion(
    id: 'q28',
    question: 'Which food is the richest source of natural protein?',
    options: ['White rice', 'Chicken breast', 'Banana', 'Olive oil'],
    correctIndex: 1,
    explanation: 'Chicken breast provides about 31g of protein per 100g, making it one of the densest whole-food protein sources.',
  ),
  QuizQuestion(
    id: 'q29',
    question: 'You should hold your breath when lifting heavy weights.',
    options: ['True', 'False'],
    correctIndex: 1,
    explanation: 'Exhale on exertion, inhale on the return. Breath-holding causes dangerous spikes in blood pressure.',
  ),
  QuizQuestion(
    id: 'q30',
    question: 'How many muscles does the human body have?',
    options: ['206', '360', '650+', '900+'],
    correctIndex: 2,
    explanation: 'The human body has over 650 skeletal muscles. All of them can be trained and strengthened through exercise!',
  ),
];

/// Returns today's question index (0–29) based on date — same Q for entire day
int todayQuestionIndex() {
  final now = DateTime.now();
  final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
  return dayOfYear % kQuizBank.length;
}

QuizQuestion get todayQuestion => kQuizBank[todayQuestionIndex()];