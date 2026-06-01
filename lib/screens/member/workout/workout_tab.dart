import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../theme/app_theme.dart';
import '../../../services/member_service.dart';
import '../../../models/exercise_model.dart';

// ─── Constants ────────────────────────────────────────────────────────────

const List<String> kDays = [
  'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday',
];

// All selectable muscle groups — Arms split into Biceps + Triceps
const List<String> kPlanMuscles = [
  'Chest','Back','Legs','Shoulders','Biceps','Triceps','Core','cardio',
];

// PPL groups
const Map<String, List<String>> kPplMuscles = {
  'Push': ['Chest','Shoulders','Triceps'],
  'Pull': ['Back','Biceps'],
  'Legs': ['Legs','Core'],
};

const Map<String, String> kMuscleImage = {
  'Chest':    'https://www.gymreapers.com/cdn/shop/articles/header-image-01_Cable-chest-workout---maximizing-your-muscle-growth.jpg?v=1721671171&width=1400',
  'Back':     'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRGY9CcTCHIVpRr6TQtNA4p2s6uxHuBtYYS1A&s',
  'Legs':     'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTObeEoezseBl1UmxRkFZqZtZtPSh6ukE-afg&s',
  'Shoulders':'https://hips.hearstapps.com/menshealth-uk/main/thumbs/35716/shoulder-circuit-wole.jpg?crop=0.8486140724946695xw:1xh;center,top&resize=1200:*',
  'Biceps':   'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTNA_9dzFEAtugO3-CjozXFs65KPZnHAHcvHA&s',
  'Triceps':  'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSKcBB6X9cwtzgntzhRXUkyl_AOufdx_EMOSw&s',
  'Core':     'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400&q=80',
  'Push':     'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=400&q=80',
  'Pull':     'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400&q=80',
};

// Plan type definitions
class WorkoutTabPlanTemplate {
  final String id;
  final String name;
  final String subtitle;
  final String description;
  const WorkoutTabPlanTemplate(this.id, this.name, this.subtitle, this.description);
}

const List<WorkoutTabPlanTemplate> kWorkoutTabPlanTemplates = [
  WorkoutTabPlanTemplate('bro',    'Bro Split',       'Major + Minor muscle per day',       'Focus 80% on one major muscle and 20% on a secondary. Classic bodybuilder-style split.'),
  WorkoutTabPlanTemplate('fifty',  '50 : 50',         'Equal split of two muscle groups',   'Each session targets two muscle groups with equal volume. Balanced and efficient.'),
  WorkoutTabPlanTemplate('ppl',    'Push / Pull / Legs','Push, Pull, or Leg day per session','Group muscles by movement pattern. Great for intermediate lifters.'),
  WorkoutTabPlanTemplate('custom', 'Custom',          'Full control over every day',        'Pick any combination of muscles for each day. Total freedom.'),
];

// ─── Data model ───────────────────────────────────────────────────────────

class _SelectedExercise {
  final ExerciseModel exercise;
  int order;
  _SelectedExercise(this.exercise, this.order);
}

class _DayWorkout {
  final String day;
  bool rest;
  String? majorMuscle;
  String? minorMuscle;
  List<_SelectedExercise> majorExercises;
  List<_SelectedExercise> minorExercises;

  _DayWorkout(this.day) : rest = false, majorExercises = [], minorExercises = [];

  List<String> get muscleLabels {
    if (rest) return ['Rest'];
    final r = <String>[];
    if (majorMuscle != null) r.add(majorMuscle!);
    if (minorMuscle != null) r.add(minorMuscle!);
    return r;
  }

  List<_SelectedExercise> get allExercises => [...majorExercises, ...minorExercises];
  bool get hasContent => rest || majorMuscle != null || majorExercises.isNotEmpty;

  Map<String, dynamic> toMap() => {
    'day': day, 'rest': rest, 'majorMuscle': majorMuscle, 'minorMuscle': minorMuscle,
    'majorExercises': majorExercises.map((e) => {'id': e.exercise.id, 'order': e.order}).toList(),
    'minorExercises': minorExercises.map((e) => {'id': e.exercise.id, 'order': e.order}).toList(),
  };

  static _DayWorkout fromMap(Map<String, dynamic> m) {
    final d = _DayWorkout(m['day'] ?? '');
    d.rest = (m['rest'] as bool?) ?? false;
    d.majorMuscle = m['majorMuscle'] as String?;
    d.minorMuscle = m['minorMuscle'] as String?;
    d.majorExercises = _parseEx(m['majorExercises']);
    d.minorExercises = _parseEx(m['minorExercises']);
    return d;
  }

  static List<_SelectedExercise> _parseEx(dynamic raw) {
    if (raw == null) return [];
    return (raw as List).map((item) {
      final map = item as Map<String, dynamic>;
      final id = map['id'] as String?;
      final order = (map['order'] as int?) ?? 1;
      final ex = kExercises.firstWhere((e) => e.id == id, orElse: () => kExercises.first);
      return _SelectedExercise(ex, order);
    }).toList();
  }
}

// ─── WorkoutTab ───────────────────────────────────────────────────────────

class WorkoutTab extends StatefulWidget {
  final MemberSession session;
  const WorkoutTab({super.key, required this.session});
  @override
  State<WorkoutTab> createState() => _WorkoutTabState();
}

class _WorkoutTabState extends State<WorkoutTab> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  @override
  void initState() { super.initState(); _tabs = TabController(length: 2, vsync: this); }
  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.surface, elevation: 0,
        title: Text('Workout', style: GoogleFonts.inter(color: c.text1, fontWeight: FontWeight.w800, fontSize: 20)),
        bottom: TabBar(
            controller: _tabs, indicatorColor: AppTheme.kAccent, indicatorWeight: 3,
            labelColor: AppTheme.kAccent, unselectedLabelColor: c.text3,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            tabs: const [Tab(text: 'My Plan'), Tab(text: 'Exercises')]),
      ),
      body: TabBarView(controller: _tabs, children: [_PlanTab(session: widget.session), const _ExerciseLibrary()]),
    );
  }
}

// ─── Plan Tab ─────────────────────────────────────────────────────────────

class _PlanTab extends StatefulWidget {
  final MemberSession session;
  const _PlanTab({required this.session});
  @override
  State<_PlanTab> createState() => _PlanTabState();
}

class _PlanTabState extends State<_PlanTab> {
  final _service = MemberService();
  List<_DayWorkout>? _savedPlan;
  String? _savedPlanType;
  bool _loading = true;
  // null = no plan, 'selecting' = choosing template, 'building' = week builder
  String _stage = 'none';
  WorkoutTabPlanTemplate? _selectedTemplate;
  List<_DayWorkout> _buildingDays = [];

  @override
  void initState() { super.initState(); _loadSaved(); }

  Future<void> _loadSaved() async {
    final data = await _service.getWorkoutPlan(widget.session.gymId, widget.session.memberId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (data != null) {
        _savedPlanType = data['planType'] as String?;
        final days = data['days'] as List?;
        if (days != null) {
          _savedPlan = days.map((d) => _DayWorkout.fromMap(d as Map<String, dynamic>)).toList();
        }
      }
    });
  }

  Future<void> _savePlan() async {
    setState(() => _loading = true);
    await _service.saveWorkoutPlan(widget.session.gymId, widget.session.memberId, {
      'planType': _selectedTemplate!.id,
      'planName': _selectedTemplate!.name,
      'days': _buildingDays.map((d) => d.toMap()).toList(),
    });
    if (!mounted) return;
    setState(() {
      _savedPlan = List.from(_buildingDays);
      _savedPlanType = _selectedTemplate!.id;
      _stage = 'none'; _loading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Workout plan saved'), backgroundColor: AppTheme.kGreen));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppTheme.kAccent));

    // Saved plan → show it
    if (_savedPlan != null && _stage == 'none') {
      return _SavedPlanView(
          plan: _savedPlan!, planType: _savedPlanType ?? 'custom',
          onChangePlan: () => setState(() => _stage = 'selecting'));
    }

    // Stage: select template
    if (_stage == 'selecting') {
      return WorkoutTabPlanTemplateSelector(
        onSelect: (t) => setState(() {
          _selectedTemplate = t;
          _buildingDays = kDays.map((d) => _DayWorkout(d)).toList();
          _stage = 'building';
        }),
        onBack: () => setState(() => _stage = 'none'),
      );
    }

    // Stage: building
    if (_stage == 'building') {
      return _WeekBuilderView(
          days: _buildingDays, planType: _selectedTemplate!.id,
          onSave: _savePlan, onChanged: () => setState(() {}),
          onBack: () => setState(() => _stage = 'selecting'));
    }

    // No plan yet
    return _NoPlanView(onStart: () => setState(() => _stage = 'selecting'));
  }
}

// ─── No Plan View ─────────────────────────────────────────────────────────

class _NoPlanView extends StatelessWidget {
  final VoidCallback onStart;
  const _NoPlanView({required this.onStart});
  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(
        mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 100, height: 100,
          decoration: BoxDecoration(color: AppTheme.kAccentDim, borderRadius: BorderRadius.circular(28)),
          child: const Icon(Icons.fitness_center, color: AppTheme.kAccent, size: 48)),
      const SizedBox(height: 24),
      Text('No Plan Yet', style: GoogleFonts.inter(color: c.text1, fontSize: 22, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      Text('Build your personalised weekly\nworkout plan in minutes.',
          textAlign: TextAlign.center, style: TextStyle(color: c.text2, fontSize: 14, height: 1.6)),
      const SizedBox(height: 32),
      GestureDetector(onTap: onStart, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
          decoration: BoxDecoration(color: AppTheme.kAccent, borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: AppTheme.kAccentGlow, blurRadius: 20, offset: Offset(0, 4))]),
          child: Text('Build My Plan', style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 16)))),
    ])));
  }
}

// ─── Plan Template Selector ───────────────────────────────────────────────

class WorkoutTabPlanTemplateSelector extends StatelessWidget {
  final void Function(WorkoutTabPlanTemplate) onSelect;
  final VoidCallback onBack;
  const WorkoutTabPlanTemplateSelector({
    super.key,
    required this.onSelect,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    return Column(children: [
      Container(color: c.surface, padding: const EdgeInsets.fromLTRB(16,12,16,12), child: Row(children: [
        GestureDetector(onTap: onBack, child: Icon(Icons.arrow_back_ios_new, color: c.text1, size: 18)),
        const SizedBox(width: 12),
        Text('Choose a Plan', style: GoogleFonts.inter(color: c.text1, fontWeight: FontWeight.w800, fontSize: 17)),
      ])),
      Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(16,20,16,40), children: [
        Text('Select a training split that fits your goals and schedule.',
            style: TextStyle(color: c.text2, fontSize: 13, height: 1.5)),
        const SizedBox(height: 20),
        ...kWorkoutTabPlanTemplates.map((t) => _PlanCard(template: t, onTap: () => onSelect(t))),
      ])),
    ]);
  }
}

class _PlanCard extends StatelessWidget {
  final WorkoutTabPlanTemplate template;
  final VoidCallback onTap;
  const _PlanCard({required this.template, required this.onTap});

  static const Map<String, Color> _accent = {
    'bro':    AppTheme.kAccent,
    'fifty':  AppTheme.kAccent,
    'ppl':    AppTheme.kAccent,
    'custom': AppTheme.kAccent,
  };

  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    final color = _accent[template.id] ?? AppTheme.kAccent;
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); onTap(); },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: c.card, borderRadius: BorderRadius.circular(18),
            border: Border.all(color: c.border, width: 0.5)),
        child: Row(children: [
          Container(width: 52, height: 52,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
              child: Icon(_planIcon(template.id), color: color, size: 26)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(template.name, style: GoogleFonts.inter(color: c.text1, fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 3),
            Text(template.subtitle, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 5),
            Text(template.description, style: TextStyle(color: c.text2, fontSize: 12, height: 1.4)),
          ])),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward_ios_rounded, color: c.text3, size: 14),
        ]),
      ),
    );
  }

  IconData _planIcon(String id) {
    switch (id) {
      case 'bro':   return Icons.fitness_center;
      case 'fifty': return Icons.balance;
      case 'ppl':   return Icons.swap_horiz;
      default:      return Icons.tune;
    }
  }
}

// ─── Saved Plan View ──────────────────────────────────────────────────────

class _SavedPlanView extends StatelessWidget {
  final List<_DayWorkout> plan;
  final String planType;
  final VoidCallback onChangePlan;
  const _SavedPlanView({required this.plan, required this.planType, required this.onChangePlan});

  String _todayName() {
    const names = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    return names[DateTime.now().weekday - 1];
  }

  String _planLabel() {
    return kWorkoutTabPlanTemplates.firstWhere((t) => t.id == planType, orElse: () => kWorkoutTabPlanTemplates.last).name;
  }

  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    final today = _todayName();
    return ListView(padding: const EdgeInsets.fromLTRB(16,16,16,100), children: [
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('My Weekly Plan', style: GoogleFonts.inter(color: c.text1, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(_planLabel(), style: TextStyle(color: c.text2, fontSize: 12)),
        ])),
        GestureDetector(onTap: onChangePlan, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(10),
                border: Border.all(color: c.border, width: 0.5)),
            child: Text('Edit Plan', style: TextStyle(color: c.text2, fontWeight: FontWeight.w600, fontSize: 12)))),
      ]),
      const SizedBox(height: 20),
      ...plan.map((day) => day.day == today ? _TodayCard(day: day) : _CompactDayCard(day: day)),
    ]);
  }
}

class _TodayCard extends StatelessWidget {
  final _DayWorkout day;
  const _TodayCard({required this.day});
  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.kAccent.withValues(alpha: 0.5), width: 1.5),
      ),  // no glow for cleaner look
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.fromLTRB(16,14,16,0), child: Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppTheme.kAccent, borderRadius: BorderRadius.circular(8)),
              child: Text('TODAY', style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.5))),
          const SizedBox(width: 10),
          Text(day.day, style: GoogleFonts.inter(color: c.text1, fontWeight: FontWeight.w800, fontSize: 18)),
        ])),
        if (day.rest)
          const Padding(padding: EdgeInsets.fromLTRB(16,16,16,16),
              child: Text('Rest Day', style: TextStyle(color: AppTheme.kGreen, fontSize: 16, fontWeight: FontWeight.w700)))
        else ...[
          if (day.muscleLabels.isNotEmpty)
            Padding(padding: const EdgeInsets.fromLTRB(16,10,16,0), child: Wrap(spacing: 8,
                children: day.muscleLabels.map((m) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(color: AppTheme.kAccentDim, borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.kAccent.withValues(alpha: 0.3))),
                  child: Text(m, style: const TextStyle(color: AppTheme.kAccent, fontSize: 12, fontWeight: FontWeight.w700)),
                )).toList())),
          const SizedBox(height: 14),
          if (day.allExercises.isEmpty)
            Padding(padding: const EdgeInsets.fromLTRB(16,0,16,16),
                child: Text('No exercises added yet', style: TextStyle(color: c.text3, fontSize: 13)))
          else ...[
            ...day.allExercises.map((se) => _ExerciseRow(se: se)),
            const SizedBox(height: 8),
          ],
        ],
      ]),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  final _SelectedExercise se;
  const _ExerciseRow({required this.se});
  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _ExDetail(exercise: se.exercise))),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12,0,12,8), padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.border, width: 0.5)),
        child: Row(children: [
          ClipRRect(borderRadius: BorderRadius.circular(8),
              child: Image.asset(se.exercise.gifUrl, width: 52, height: 52, fit: BoxFit.cover)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(se.exercise.name, style: TextStyle(color: c.text1, fontWeight: FontWeight.w700, fontSize: 13),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Text('${se.exercise.defaultSets} sets  ×  ${se.exercise.defaultReps}',
                style: TextStyle(color: c.text3, fontSize: 11)),
          ])),
          Container(width: 28, height: 28,
              decoration: const BoxDecoration(color: AppTheme.kAccentDim, shape: BoxShape.circle),
              child: Center(child: Text('${se.order}',
                  style: const TextStyle(color: AppTheme.kAccent, fontWeight: FontWeight.w800, fontSize: 12)))),
        ]),
      ),
    );
  }
}

class _CompactDayCard extends StatelessWidget {
  final _DayWorkout day;
  const _CompactDayCard({required this.day});
  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    final muscles = day.muscleLabels;
    final hasMuscles = muscles.isNotEmpty && muscles.first != 'Rest';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.border, width: 0.5)),
      child: Row(children: [
        Container(width: 42, height: 42,
            decoration: BoxDecoration(color: hasMuscles ? AppTheme.kAccentDim : c.surface, borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text(day.day.substring(0,3).toUpperCase(),
                style: TextStyle(color: hasMuscles ? AppTheme.kAccent : c.text3, fontWeight: FontWeight.w800, fontSize: 10)))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(day.day, style: TextStyle(color: c.text1, fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 3),
          Text(
              muscles.isEmpty ? 'Not configured' : day.rest ? 'Rest Day' : muscles.join('  +  '),
              style: TextStyle(color: day.rest ? AppTheme.kGreen : c.text2, fontSize: 12),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
        if (!day.rest && day.allExercises.isNotEmpty)
          Text('${day.allExercises.length} ex', style: TextStyle(color: c.text3, fontSize: 11)),
      ]),
    );
  }
}

// ─── Week Builder View ────────────────────────────────────────────────────

class _WeekBuilderView extends StatelessWidget {
  final List<_DayWorkout> days;
  final String planType;
  final Future<void> Function() onSave;
  final VoidCallback onChanged;
  final VoidCallback onBack;
  const _WeekBuilderView({required this.days, required this.planType, required this.onSave, required this.onChanged, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    return Column(children: [
      Container(color: c.surface, padding: const EdgeInsets.fromLTRB(16,12,16,12), child: Row(children: [
        GestureDetector(onTap: onBack, child: Icon(Icons.arrow_back_ios_new, color: c.text1, size: 18)),
        const SizedBox(width: 12),
        Text('Build Your Plan', style: GoogleFonts.inter(color: c.text1, fontWeight: FontWeight.w800, fontSize: 17)),
        const Spacer(),
        GestureDetector(onTap: () async { HapticFeedback.mediumImpact(); await onSave(); }, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            decoration: BoxDecoration(color: AppTheme.kAccent, borderRadius: BorderRadius.circular(10),
                boxShadow: const [BoxShadow(color: AppTheme.kAccentGlow, blurRadius: 12)]),
            child: Text('Save', style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 13)))),
      ])),
      Expanded(child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16,16,16,100),
          itemCount: days.length,
          itemBuilder: (ctx, i) {
            final day = days[i];
            return _DayBuilderCard(day: day, onTap: () async {
              await Navigator.push(ctx, MaterialPageRoute(
                  builder: (_) => _DayWorkoutBuilder(day: day, planType: planType)));
              onChanged();
            });
          })),
    ]);
  }
}

class _DayBuilderCard extends StatelessWidget {
  final _DayWorkout day;
  final VoidCallback onTap;
  const _DayBuilderCard({required this.day, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    final hasContent = day.hasContent;
    return GestureDetector(onTap: onTap, child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: hasContent ? AppTheme.kAccent.withValues(alpha: 0.4) : c.border,
              width: hasContent ? 1 : 0.5)),
      child: Row(children: [
        Container(width: 48, height: 48,
            decoration: BoxDecoration(color: hasContent ? AppTheme.kAccentDim : c.surface, borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(day.day.substring(0,3).toUpperCase(),
                style: TextStyle(color: hasContent ? AppTheme.kAccent : c.text3, fontWeight: FontWeight.w800, fontSize: 11)))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(day.day, style: TextStyle(color: c.text1, fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 3),
          Text(
              day.rest ? 'Rest Day' : day.muscleLabels.isEmpty ? 'Tap to configure' : day.muscleLabels.join(' + '),
              style: TextStyle(color: day.rest ? AppTheme.kGreen : day.muscleLabels.isEmpty ? c.text3 : c.text2, fontSize: 12)),
        ])),
        if (!day.rest && day.allExercises.isNotEmpty) ...[
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: AppTheme.kAccentDim, borderRadius: BorderRadius.circular(8)),
              child: Text('${day.allExercises.length} ex', style: const TextStyle(color: AppTheme.kAccent, fontSize: 10, fontWeight: FontWeight.w700))),
          const SizedBox(width: 8),
        ],
        Icon(Icons.arrow_forward_ios_rounded, color: hasContent ? AppTheme.kAccent : c.text3, size: 14),
      ]),
    ));
  }
}

// ─── Day Workout Builder ──────────────────────────────────────────────────

class _DayWorkoutBuilder extends StatefulWidget {
  final _DayWorkout day;
  final String planType;
  const _DayWorkoutBuilder({required this.day, required this.planType});
  @override
  State<_DayWorkoutBuilder> createState() => _DayWorkoutBuilderState();
}

class _DayWorkoutBuilderState extends State<_DayWorkoutBuilder> {
  int _step = 0;

  // PPL: user picks Push/Pull/Legs label — maps to muscles automatically
  String? _pplChoice;

  // Total steps depend on plan type:
  // bro/fifty: 0=setup, 1=major, 2=majorEx, 3=minor, 4=minorEx
  // ppl:       0=setup, 1=pplChoice, 2=exercises
  // custom:    0=setup, 1=muscles, 2=exercises
  int get _totalSteps {
    if (widget.planType == 'ppl') return 3;
    if (widget.planType == 'custom') return 3;
    return 5;
  }

  void _reset() => setState(() {
    widget.day.rest = false; widget.day.majorMuscle = null; widget.day.minorMuscle = null;
    widget.day.majorExercises.clear(); widget.day.minorExercises.clear();
    _pplChoice = null; _step = 0;
  });

  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(child: Column(children: [_buildHeader(), Expanded(child: _buildStep())])),
    );
  }

  Widget _buildHeader() {
    final c = GFColors(context);
    return Container(color: c.surface, padding: const EdgeInsets.fromLTRB(16,12,16,12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            GestureDetector(
                onTap: () { if (_step > 0) {
                  setState(() => _step--);
                } else {
                  Navigator.pop(context);
                } },
                child: Icon(Icons.arrow_back_ios_new, color: c.text1, size: 18)),
            const SizedBox(width: 12),
            Text(widget.day.day, style: GoogleFonts.inter(color: c.text1, fontWeight: FontWeight.w800, fontSize: 17)),
            const Spacer(),
            if (_step > 0) GestureDetector(onTap: _reset, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppTheme.kRedDim, borderRadius: BorderRadius.circular(8)),
                child: const Text('Reset', style: TextStyle(color: AppTheme.kRed, fontSize: 11, fontWeight: FontWeight.w700)))),
          ]),
          const SizedBox(height: 10),
          Row(children: List.generate(_totalSteps, (i) => Expanded(child: Container(
              height: 3, margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(color: i <= _step ? AppTheme.kAccent : c.border, borderRadius: BorderRadius.circular(2)))))),
        ]));
  }

  Widget _buildStep() {
    // PPL flow
    if (widget.planType == 'ppl') {
      switch (_step) {
        case 0: return _StepSetupDay(day: widget.day,
            onRest: () { setState(() => widget.day.rest = true); Navigator.pop(context); },
            onStart: () => setState(() { widget.day.rest = false; _step = 1; }));
        case 1: return _StepSelectPpl(selected: _pplChoice,
            onSelect: (choice) {
              setState(() {
                _pplChoice = choice;
                // Assign muscles from PPL map
                final muscles = kPplMuscles[choice] ?? [];
                widget.day.majorMuscle = muscles.isNotEmpty ? muscles.first : null;
                widget.day.minorMuscle = muscles.length > 1 ? muscles[1] : null;
                _step = 2;
              });
            });
        case 2: return _StepSelectExercisesMulti(
            muscles: kPplMuscles[_pplChoice ?? ''] ?? [],
            allSelected: [...widget.day.majorExercises, ...widget.day.minorExercises],
            onChanged: (list) => setState(() {
              widget.day.majorExercises = list;
              widget.day.minorExercises = [];
            }),
            onNext: () { HapticFeedback.mediumImpact(); Navigator.pop(context); },
            nextLabel: 'Done');
        default: return const SizedBox.shrink();
      }
    }

    // Custom flow
    if (widget.planType == 'custom') {
      switch (_step) {
        case 0: return _StepSetupDay(day: widget.day,
            onRest: () { setState(() => widget.day.rest = true); Navigator.pop(context); },
            onStart: () => setState(() { widget.day.rest = false; _step = 1; }));
        case 1: return _StepSelectMusclesMulti(
            selected: [...(widget.day.majorMuscle != null ? [widget.day.majorMuscle!] : []),
              ...(widget.day.minorMuscle != null ? [widget.day.minorMuscle!] : [])],
            onNext: (muscles) => setState(() {
              widget.day.majorMuscle = muscles.isNotEmpty ? muscles[0] : null;
              widget.day.minorMuscle = muscles.length > 1 ? muscles[1] : null;
              widget.day.majorExercises.clear(); widget.day.minorExercises.clear();
              _step = 2;
            }));
        case 2: return _StepSelectExercisesMulti(
            muscles: widget.day.muscleLabels,
            allSelected: [...widget.day.majorExercises, ...widget.day.minorExercises],
            onChanged: (list) => setState(() { widget.day.majorExercises = list; widget.day.minorExercises = []; }),
            onNext: () { HapticFeedback.mediumImpact(); Navigator.pop(context); },
            nextLabel: 'Done');
        default: return const SizedBox.shrink();
      }
    }

    // Bro Split / 50:50 flow (5 steps)
    final isMinorOptional = widget.planType == 'bro';
    switch (_step) {
      case 0: return _StepSetupDay(day: widget.day,
          onRest: () { setState(() => widget.day.rest = true); Navigator.pop(context); },
          onStart: () => setState(() { widget.day.rest = false; _step = 1; }));
      case 1: return _StepSelectMuscle(
          title: widget.planType == 'bro' ? 'Major Muscle (80%)' : 'First Muscle (50%)',
          subtitle: widget.planType == 'bro' ? 'Primary focus for this session' : 'First half of your workout',
          selected: widget.day.majorMuscle,
          onSelect: (m) => setState(() { widget.day.majorMuscle = m; _step = 2; }));
      case 2: return _StepSelectExercises(
          muscle: widget.day.majorMuscle ?? '',
          label: widget.planType == 'bro' ? 'Major' : 'First',
          selected: widget.day.majorExercises,
          onNext: () => setState(() => _step = 3));
      case 3: return _StepSelectMuscle(
          title: widget.planType == 'bro' ? 'Minor Muscle (20%)' : 'Second Muscle (50%)',
          subtitle: widget.planType == 'bro' ? 'Secondary focus (or skip)' : 'Second half of your workout',
          selected: widget.day.minorMuscle, exclude: widget.day.majorMuscle,
          onSkip: isMinorOptional ? () { HapticFeedback.lightImpact(); Navigator.pop(context); } : null,
          onSelect: (m) => setState(() { widget.day.minorMuscle = m; _step = 4; }));
      case 4: return _StepSelectExercises(
          muscle: widget.day.minorMuscle ?? '',
          label: widget.planType == 'bro' ? 'Minor' : 'Second',
          selected: widget.day.minorExercises,
          onNext: () { HapticFeedback.mediumImpact(); Navigator.pop(context); },
          nextLabel: 'Done');
      default: return const SizedBox.shrink();
    }
  }
}

// ─── Step 0: Setup Day ────────────────────────────────────────────────────

class _StepSetupDay extends StatelessWidget {
  final _DayWorkout day;
  final VoidCallback onRest, onStart;
  const _StepSetupDay({required this.day, required this.onRest, required this.onStart});
  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    return Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("What's the plan for ${day.day}?",
          style: GoogleFonts.inter(color: c.text1, fontSize: 24, fontWeight: FontWeight.w800, height: 1.3)),
      const SizedBox(height: 32),
      GestureDetector(onTap: onStart, child: Container(
          width: double.infinity, padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: AppTheme.kAccentDim, borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.kAccent.withValues(alpha: 0.5), width: 1.5)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: AppTheme.kAccent, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.fitness_center, color: Colors.black, size: 22)),
            const SizedBox(height: 14),
            Text('Workout Day', style: GoogleFonts.inter(color: AppTheme.kAccent, fontWeight: FontWeight.w800, fontSize: 20)),
            const SizedBox(height: 4),
            Text('Build a custom workout with exercises for this day.',
                style: TextStyle(color: c.text2, fontSize: 13, height: 1.4)),
          ]))),
      const SizedBox(height: 16),
      GestureDetector(onTap: onRest, child: Container(
          width: double.infinity, padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(20),
              border: Border.all(color: c.border, width: 0.5)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: AppTheme.kAccentDim, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.bedtime_outlined, color: AppTheme.kGreen, size: 22)),
            const SizedBox(height: 14),
            Text('Rest Day', style: GoogleFonts.inter(color: AppTheme.kGreen, fontWeight: FontWeight.w800, fontSize: 20)),
            const SizedBox(height: 4),
            Text('Recovery is part of the plan too.',
                style: TextStyle(color: c.text2, fontSize: 13, height: 1.4)),
          ]))),
    ]));
  }
}

// ─── Step PPL: Select Push/Pull/Legs ─────────────────────────────────────

class _StepSelectPpl extends StatelessWidget {
  final String? selected;
  final void Function(String) onSelect;
  const _StepSelectPpl({required this.selected, required this.onSelect});

  static const Map<String, String> _desc = {
    'Push': 'Chest, Shoulders, Triceps',
    'Pull': 'Back, Biceps',
    'Legs': 'Legs, Core',
  };
  static const Map<String, Color> _color = {
    'Push': AppTheme.kAccent,
    'Pull': AppTheme.kAccent,
    'Legs': AppTheme.kAccent,
  };

  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(20,20,20,4),
          child: Text('Select Session Type', style: TextStyle(color: c.text1, fontSize: 22, fontWeight: FontWeight.w800))),
      Padding(padding: const EdgeInsets.fromLTRB(20,0,20,20),
          child: Text('Which movement pattern are you training today?', style: TextStyle(color: c.text2, fontSize: 13))),
      Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(16,0,16,40),
          children: ['Push','Pull','Legs'].map((type) {
            final isSel = type == selected;
            final color = _color[type] ?? AppTheme.kAccent;
            return GestureDetector(
                onTap: () { HapticFeedback.selectionClick(); onSelect(type); },
                child: AnimatedContainer(duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(bottom: 14), padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: isSel ? color.withValues(alpha: 0.1) : c.card,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: isSel ? color : c.border, width: isSel ? 1.5 : 0.5)),
                    child: Row(children: [
                      Container(width: 52, height: 52,
                          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                          child: Center(child: Text(type[0], style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 22)))),
                      const SizedBox(width: 16),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(type, style: GoogleFonts.inter(color: isSel ? color : c.text1, fontWeight: FontWeight.w800, fontSize: 18)),
                        const SizedBox(height: 4),
                        Text(_desc[type] ?? '', style: TextStyle(color: c.text2, fontSize: 13)),
                      ])),
                      if (isSel) Icon(Icons.check_circle, color: color, size: 22),
                    ])));
          }).toList())),
    ]);
  }
}

// ─── Step Multi-Muscle Select (Custom) ───────────────────────────────────

class _StepSelectMusclesMulti extends StatefulWidget {
  final List<String> selected;
  final void Function(List<String>) onNext;
  const _StepSelectMusclesMulti({required this.selected, required this.onNext});
  @override
  State<_StepSelectMusclesMulti> createState() => _StepSelectMusclesMultiState();
}

class _StepSelectMusclesMultiState extends State<_StepSelectMusclesMulti> {
  late List<String> _picked;
  @override
  void initState() { super.initState(); _picked = List.from(widget.selected); }

  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(20,20,20,4),
          child: Text('Choose Muscles', style: TextStyle(color: c.text1, fontSize: 22, fontWeight: FontWeight.w800))),
      Padding(padding: const EdgeInsets.fromLTRB(20,0,20,16),
          child: Text('Select one or more muscle groups for this day', style: TextStyle(color: c.text2, fontSize: 13))),
      Expanded(child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(16,0,16,16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.3),
          itemCount: kPlanMuscles.length,
          itemBuilder: (_, i) {
            final m = kPlanMuscles[i];
            final isSel = _picked.contains(m);
            return GestureDetector(
                onTap: () { HapticFeedback.selectionClick(); setState(() { if (isSel) {
                  _picked.remove(m);
                } else {
                  _picked.add(m);
                } }); },
                child: AnimatedContainer(duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isSel ? AppTheme.kAccent : c.border, width: isSel ? 2 : 0.5),
                        boxShadow: isSel ? [const BoxShadow(color: AppTheme.kAccentGlow, blurRadius: 8)] : null),
                    child: ClipRRect(borderRadius: BorderRadius.circular(15), child: Stack(children: [
                      Positioned.fill(child: CachedNetworkImage(imageUrl: kMuscleImage[m] ?? '', fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: c.card),
                          errorWidget: (_, __, ___) => Container(color: c.card))),
                      Positioned.fill(child: Container(decoration: BoxDecoration(gradient: LinearGradient(
                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.78)])))),
                      if (isSel) Positioned.fill(child: Container(color: AppTheme.kAccent.withValues(alpha: 0.18))),
                      Positioned(bottom: 10, left: 12, right: 12,
                          child: Text(m, style: GoogleFonts.inter(color: isSel ? AppTheme.kAccent : Colors.white, fontWeight: FontWeight.w800, fontSize: 13))),
                      if (isSel) const Positioned(top: 8, right: 8, child: Icon(Icons.check_circle, color: AppTheme.kAccent, size: 20)),
                    ]))));
          })),
      Padding(padding: const EdgeInsets.fromLTRB(16,8,16,20), child: GestureDetector(
          onTap: _picked.isEmpty ? null : () => widget.onNext(_picked),
          child: AnimatedContainer(duration: const Duration(milliseconds: 150),
              width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                  color: _picked.isEmpty ? c.border : AppTheme.kAccent,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: _picked.isEmpty ? null : [const BoxShadow(color: AppTheme.kAccentGlow, blurRadius: 16, offset: Offset(0,4))]),
              child: Center(child: Text('Next  (${_picked.length} selected)',
                  style: GoogleFonts.inter(color: _picked.isEmpty ? c.text3 : Colors.black, fontWeight: FontWeight.w800, fontSize: 15)))))),
    ]);
  }
}

// ─── Step Select Single Muscle ────────────────────────────────────────────

class _StepSelectMuscle extends StatelessWidget {
  final String title, subtitle;
  final String? selected, exclude;
  final void Function(String) onSelect;
  final VoidCallback? onSkip;
  const _StepSelectMuscle({required this.title, required this.subtitle, required this.selected,
    required this.onSelect, this.exclude, this.onSkip});

  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    final muscles = kPlanMuscles.where((m) => m != exclude).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(20,20,20,4),
          child: Text(title, style: GoogleFonts.inter(color: c.text1, fontSize: 22, fontWeight: FontWeight.w800))),
      Padding(padding: const EdgeInsets.fromLTRB(20,0,20,16),
          child: Text(subtitle, style: TextStyle(color: c.text2, fontSize: 13))),
      Expanded(child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(16,0,16,100),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.3),
          itemCount: muscles.length,
          itemBuilder: (_, i) {
            final m = muscles[i];
            final isSel = m == selected;
            return GestureDetector(
                onTap: () { HapticFeedback.selectionClick(); onSelect(m); },
                child: AnimatedContainer(duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isSel ? AppTheme.kAccent : c.border, width: isSel ? 2 : 0.5),
                        boxShadow: isSel ? [const BoxShadow(color: AppTheme.kAccentGlow, blurRadius: 10)] : null),
                    child: ClipRRect(borderRadius: BorderRadius.circular(15), child: Stack(children: [
                      Positioned.fill(child: CachedNetworkImage(imageUrl: kMuscleImage[m] ?? '', fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: c.card),
                          errorWidget: (_, __, ___) => Container(color: c.card))),
                      Positioned.fill(child: Container(decoration: BoxDecoration(gradient: LinearGradient(
                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.75)])))),
                      if (isSel) Positioned.fill(child: Container(color: AppTheme.kAccent.withValues(alpha: 0.2))),
                      Positioned(bottom: 10, left: 12, right: 12,
                          child: Text(m, style: GoogleFonts.inter(color: isSel ? AppTheme.kAccent : Colors.white, fontWeight: FontWeight.w800, fontSize: 14))),
                      if (isSel) const Positioned(top: 8, right: 8, child: Icon(Icons.check_circle, color: AppTheme.kAccent, size: 22)),
                    ]))));
          })),
      if (onSkip != null)
        Padding(padding: const EdgeInsets.fromLTRB(20,0,20,20), child: GestureDetector(onTap: onSkip,
            child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.border)),
                child: Center(child: Text('Skip', style: TextStyle(color: c.text3, fontWeight: FontWeight.w600, fontSize: 13)))))),
    ]);
  }
}

// ─── Step Select Exercises (single muscle) ────────────────────────────────

class _StepSelectExercises extends StatefulWidget {
  final String muscle, label;
  final List<_SelectedExercise> selected;
  final VoidCallback onNext;
  final String nextLabel;
  const _StepSelectExercises({required this.muscle, required this.label, required this.selected,
    required this.onNext, this.nextLabel = 'Next'});
  @override
  State<_StepSelectExercises> createState() => _StepSelectExercisesState();
}

class _StepSelectExercisesState extends State<_StepSelectExercises> {
  bool _isSelected(ExerciseModel ex) => widget.selected.any((s) => s.exercise.id == ex.id);

  void _toggle(ExerciseModel ex) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_isSelected(ex)) {
        widget.selected.removeWhere((s) => s.exercise.id == ex.id);
        for (int i = 0; i < widget.selected.length; i++) {
          widget.selected[i].order = i + 1;
        }
      } else {
        widget.selected.add(_SelectedExercise(ex, widget.selected.length + 1));
      }
    });
  }
  @override
  Widget build(BuildContext context) => _buildList(context, widget.muscle, widget.selected, _toggle, widget.onNext, widget.nextLabel);
}

// ─── Step Select Exercises (multi-muscle, PPL/Custom) ─────────────────────

class _StepSelectExercisesMulti extends StatefulWidget {
  final List<String> muscles;
  final List<_SelectedExercise> allSelected;
  final void Function(List<_SelectedExercise>) onChanged;
  final VoidCallback onNext;
  final String nextLabel;
  const _StepSelectExercisesMulti({required this.muscles, required this.allSelected,
    required this.onChanged, required this.onNext, this.nextLabel = 'Done'});
  @override
  State<_StepSelectExercisesMulti> createState() => _StepSelectExercisesMultiState();
}

class _StepSelectExercisesMultiState extends State<_StepSelectExercisesMulti> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  late List<List<_SelectedExercise>> _perMuscle;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: widget.muscles.length, vsync: this);
    _perMuscle = widget.muscles.map((m) =>
        widget.allSelected.where((s) => s.exercise.muscleGroup == m).toList()).toList();
  }
  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  List<_SelectedExercise> get _allFlat => _perMuscle.expand((list) => list).toList();

  void _toggle(int muscleIdx, ExerciseModel ex) {
    HapticFeedback.selectionClick();
    setState(() {
      final list = _perMuscle[muscleIdx];
      final existIdx = list.indexWhere((s) => s.exercise.id == ex.id);
      if (existIdx >= 0) {
        list.removeAt(existIdx);
        for (int i = 0; i < list.length; i++) {
          list[i].order = i + 1;
        }
      } else {
        list.add(_SelectedExercise(ex, list.length + 1));
      }
    });
    widget.onChanged(_allFlat);
  }

  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    return Column(children: [
      if (widget.muscles.length > 1) ...[
        const SizedBox(height: 8),
        TabBar(controller: _tabs, isScrollable: true,
            indicatorColor: AppTheme.kAccent, labelColor: AppTheme.kAccent,
            unselectedLabelColor: c.text3,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            tabs: widget.muscles.map((m) => Tab(text: m)).toList()),
      ],
      Expanded(child: TabBarView(controller: _tabs, children: List.generate(widget.muscles.length, (mi) {
        final muscle = widget.muscles[mi];
        final exercises = kExercises.where((e) => e.muscleGroup == muscle).toList();
        final sel = _perMuscle[mi];
        bool isSelected(ExerciseModel ex) => sel.any((s) => s.exercise.id == ex.id);
        int? orderOf(ExerciseModel ex) { final m = sel.where((s) => s.exercise.id == ex.id).toList(); return m.isEmpty ? null : m.first.order; }
        return _buildList(context, muscle, sel, (ex) => _toggle(mi, ex), widget.onNext, widget.nextLabel,
            exList: exercises, isSelectedFn: isSelected, orderFn: orderOf, showButton: mi == widget.muscles.length - 1);
      }))),
    ]);
  }
}

// ─── Shared exercise list builder ─────────────────────────────────────────

Widget _buildList(
    BuildContext context,
    String muscle,
    List<_SelectedExercise> selected,
    void Function(ExerciseModel) onToggle,
    VoidCallback onNext,
    String nextLabel, {
      List<ExerciseModel>? exList,
      bool Function(ExerciseModel)? isSelectedFn,
      int? Function(ExerciseModel)? orderFn,
      bool showButton = true,
    }) {
  final c = GFColors(context);
  final exercises = exList ?? kExercises.where((e) => e.muscleGroup == muscle).toList();
  bool isSel(ExerciseModel ex) => isSelectedFn != null ? isSelectedFn(ex) : selected.any((s) => s.exercise.id == ex.id);
  int? orderOf(ExerciseModel ex) => orderFn != null ? orderFn(ex) : (selected.where((s) => s.exercise.id == ex.id).isEmpty ? null : selected.firstWhere((s) => s.exercise.id == ex.id).order);

  return Column(children: [
    Padding(padding: const EdgeInsets.fromLTRB(20,12,20,8), child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(muscle, style: GoogleFonts.inter(color: c.text1, fontSize: 18, fontWeight: FontWeight.w800)),
        Text('Tap exercises to select them in order', style: TextStyle(color: c.text2, fontSize: 12)),
      ])),
      if (selected.isNotEmpty)
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: AppTheme.kAccentDim, borderRadius: BorderRadius.circular(20)),
            child: Text('${selected.length} selected', style: const TextStyle(color: AppTheme.kAccent, fontWeight: FontWeight.w700, fontSize: 11))),
    ])),
    Expanded(child: exercises.isEmpty
        ? Center(child: Text('No exercises available', style: TextStyle(color: c.text3)))
        : ListView.builder(padding: const EdgeInsets.fromLTRB(16,4,16,16), itemCount: exercises.length,
        itemBuilder: (_, i) {
          final ex = exercises[i];
          final sel = isSel(ex);
          final order = orderOf(ex);
          return GestureDetector(onTap: () => onToggle(ex), child: AnimatedContainer(
              duration: const Duration(milliseconds: 180), margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                  color: sel ? AppTheme.kAccentDim : c.card, borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: sel ? AppTheme.kAccent : c.border, width: sel ? 1.5 : 0.5)),
              child: Row(children: [
                ClipRRect(borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), bottomLeft: Radius.circular(14)),
                    child: Image.asset(ex.gifUrl, width: 90, height: 90, fit: BoxFit.cover)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(ex.name, style: TextStyle(color: sel ? AppTheme.kAccent : c.text1,
                      fontWeight: FontWeight.w700, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('${ex.defaultSets} sets  ×  ${ex.defaultReps}',
                      style: TextStyle(color: c.text3, fontSize: 11)),
                  const SizedBox(height: 4),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(4)),
                      child: Text(ex.equipment, style: TextStyle(color: c.text2, fontSize: 10))),
                ])),
                Padding(padding: const EdgeInsets.only(right: 14), child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180), width: 32, height: 32,
                    decoration: BoxDecoration(color: sel ? AppTheme.kAccent : c.elevated, shape: BoxShape.circle,
                        border: Border.all(color: sel ? AppTheme.kAccent : c.border)),
                    child: Center(child: sel
                        ? Text('$order', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13))
                        : Icon(Icons.add, color: c.text3, size: 16)))),
              ])));
        })),
    if (showButton)
      Padding(padding: const EdgeInsets.fromLTRB(16,0,16,20), child: GestureDetector(onTap: onNext,
          child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(color: AppTheme.kAccent, borderRadius: BorderRadius.circular(14),
                  boxShadow: const [BoxShadow(color: AppTheme.kAccentGlow, blurRadius: 16, offset: Offset(0,4))]),
              child: Center(child: Text(nextLabel, style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 15)))))),
  ]);
}

// ─── Exercise Library ─────────────────────────────────────────────────────

class _ExerciseLibrary extends StatefulWidget {
  const _ExerciseLibrary();
  @override
  State<_ExerciseLibrary> createState() => _ExerciseLibraryState();
}

class _ExerciseLibraryState extends State<_ExerciseLibrary> {
  String _query = '';
  String? _selectedCategory;
  final _ctrl = TextEditingController();
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  List<ExerciseModel> get _filtered {
    if (_selectedCategory == null) return [];
    return kExercises.where((e) {
      final mc = e.muscleGroup == _selectedCategory;
      final mq = _query.isEmpty || e.name.toLowerCase().contains(_query.toLowerCase());
      return mc && mq;
    }).toList();
  }

  @override
  Widget build(BuildContext context) => _selectedCategory == null ? _buildCategoryGrid() : _buildExerciseList();

  Widget _buildCategoryGrid() {
    final c = GFColors(context);
    final cats = kMuscleCategories.where((cat) => cat != 'All').toList();
    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(20,20,20,4),
          child: Text('Exercise Library', style: GoogleFonts.inter(color: c.text1, fontSize: 22, fontWeight: FontWeight.w800))),
      Padding(padding: const EdgeInsets.fromLTRB(20,0,20,16),
          child: Text('Choose a muscle group to browse exercises', style: TextStyle(color: c.text2, fontSize: 13))),
      Expanded(child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(16,0,16,40),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.4),
          itemCount: cats.length,
          itemBuilder: (_, i) {
            final cat = cats[i];
            final count = kExercises.where((e) => e.muscleGroup == cat).length;
            final img = kMuscleImage[cat] ?? kMuscleImage['Chest']!;
            return GestureDetector(
                onTap: () { HapticFeedback.selectionClick(); setState(() => _selectedCategory = cat); },
                child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: c.border, width: 0.5)),
                    child: ClipRRect(borderRadius: BorderRadius.circular(15), child: Stack(children: [
                      Positioned.fill(child: CachedNetworkImage(imageUrl: img, fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: c.card),
                          errorWidget: (_, __, ___) => Container(color: c.card))),
                      Positioned.fill(child: Container(decoration: BoxDecoration(gradient: LinearGradient(
                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)])))),
                      Positioned(bottom: 10, left: 12, right: 12, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(cat, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                        Text('$count exercises', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                      ])),
                    ]))));
          })),
    ]);
  }

  Widget _buildExerciseList() {
    final c = GFColors(context);
    return Column(children: [
      Container(color: c.surface, padding: const EdgeInsets.fromLTRB(16,12,16,12), child: Row(children: [
        GestureDetector(onTap: () => setState(() { _selectedCategory = null; _query = ''; _ctrl.clear(); }),
            child: Icon(Icons.arrow_back_ios_new, color: c.text1, size: 18)),
        const SizedBox(width: 12),
        Text(_selectedCategory ?? '', style: GoogleFonts.inter(color: c.text1, fontWeight: FontWeight.w800, fontSize: 17)),
        const Spacer(),
        Text('${_filtered.length} exercises', style: TextStyle(color: c.text3, fontSize: 12)),
      ])),
      Padding(padding: const EdgeInsets.fromLTRB(16,12,16,8), child: TextField(
          controller: _ctrl,
          style: TextStyle(color: c.text1, fontSize: 14),
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(hintText: 'Search exercises…',
              prefixIcon: Icon(Icons.search, color: c.text3, size: 20),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(icon: Icon(Icons.clear, color: c.text3, size: 18),
                  onPressed: () { _ctrl.clear(); setState(() => _query = ''); }) : null))),
      Expanded(child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16,4,16,40), itemCount: _filtered.length,
          itemBuilder: (_, i) => _ExCard(exercise: _filtered[i]))),
    ]);
  }
}

class _ExCard extends StatelessWidget {
  final ExerciseModel exercise;
  const _ExCard({required this.exercise});
  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    return GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _ExDetail(exercise: exercise))),
        child: Container(margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.border, width: 0.5)),
            child: Row(children: [
              ClipRRect(borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
                  child: Image.asset(exercise.gifUrl, width: 100, height: 100, fit: BoxFit.cover)),
              const SizedBox(width: 14),
              Expanded(child: Padding(padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(exercise.name, style: TextStyle(color: c.text1, fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 4),
                    Wrap(spacing: 6, children: [_Tag(exercise.muscleGroup, AppTheme.kAccent), _Tag(exercise.equipment, c.text3)]),
                    const SizedBox(height: 6),
                    Text('${exercise.defaultSets} sets  ×  ${exercise.defaultReps}',
                        style: const TextStyle(color: AppTheme.kAccent, fontSize: 11, fontWeight: FontWeight.w600)),
                  ]))),
              Padding(padding: const EdgeInsets.only(right: 12),
                  child: Icon(Icons.chevron_right, color: c.text3, size: 20)),
            ])));
  }
}

class _Tag extends StatelessWidget {
  final String label; final Color color;
  const _Tag(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)));
}

// ─── Exercise Detail ──────────────────────────────────────────────────────

class _ExDetail extends StatelessWidget {
  final ExerciseModel exercise;
  const _ExDetail({required this.exercise});
  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    return Scaffold(
        backgroundColor: c.bg,
        body: CustomScrollView(slivers: [
          SliverAppBar(backgroundColor: c.surface, expandedHeight: 300, pinned: true,
              leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18), onPressed: () => Navigator.pop(context)),
              flexibleSpace: FlexibleSpaceBar(background: Image.asset(exercise.gifUrl, fit: BoxFit.cover))),
          SliverPadding(padding: const EdgeInsets.all(20), sliver: SliverList(delegate: SliverChildListDelegate([
            Text(exercise.name, style: GoogleFonts.inter(color: c.text1, fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [
              _Tag(exercise.muscleGroup, AppTheme.kAccent), _Tag(exercise.equipment, AppTheme.kGold),
              if (exercise.secondaryMuscle.isNotEmpty) _Tag(exercise.secondaryMuscle, AppTheme.kCyan),
            ]),
            const SizedBox(height: 20),
            Container(padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: c.border, width: 0.5)),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  _Stat('Sets', '${exercise.defaultSets}', AppTheme.kAccent),
                  Container(width: 1, height: 40, color: c.border),
                  _Stat('Reps', exercise.defaultReps, AppTheme.kGold),
                  Container(width: 1, height: 40, color: c.border),
                  const _Stat('Rest', '60-90s', AppTheme.kGreen),
                ])),
            const SizedBox(height: 24),
            Text('How to do it', style: GoogleFonts.inter(color: c.text1, fontWeight: FontWeight.w700, fontSize: 17)),
            const SizedBox(height: 14),
            ...exercise.instructions.asMap().entries.map((e) => Padding(padding: const EdgeInsets.only(bottom: 14),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(width: 28, height: 28,
                      decoration: const BoxDecoration(color: AppTheme.kAccentDim, shape: BoxShape.circle),
                      child: Center(child: Text('${e.key+1}', style: const TextStyle(color: AppTheme.kAccent, fontWeight: FontWeight.w800, fontSize: 12)))),
                  const SizedBox(width: 12),
                  Expanded(child: Padding(padding: const EdgeInsets.only(top: 4),
                      child: Text(e.value, style: TextStyle(color: c.text2, fontSize: 14, height: 1.6)))),
                ]))),
            const SizedBox(height: 40),
          ]))),
        ]));
  }
}

class _Stat extends StatelessWidget {
  final String label, value; final Color color;
  const _Stat(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) {
    final c = GFColors(context);
    return Column(children: [
      Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800)),
      Text(label, style: TextStyle(color: c.text3, fontSize: 11)),
    ]);
  }
}