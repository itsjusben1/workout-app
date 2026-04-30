import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'backend.dart';
import 'main.dart' show AppDrawer, rankColor;

class WorkoutsPage extends StatefulWidget {
  const WorkoutsPage({super.key});

  @override
  State<WorkoutsPage> createState() => _WorkoutsPageState();
}

class _WorkoutsPageState extends State<WorkoutsPage> {
  final DBHelper _db = DBHelper();
  List<WorkoutItem> _workouts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  Future<void> _loadWorkouts() async {
    final w = await _db.getWorkouts();
    setState(() {
      _workouts = w;
      _loading = false;
    });
  }

  Future<void> _showWorkoutDialog({WorkoutItem? editing}) async {
    final nameCtrl = TextEditingController(text: editing?.name ?? '');
    final weightCtrl = TextEditingController(
      text: editing?.weightValue.toString() ?? '',
    );
    String weightType = editing?.weightType ?? 'weight';
    List<String> selectedMuscles = List.from(editing?.muscleGroups ?? []);
    int expGain = editing?.expGain ?? 5;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1C1C2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            editing == null ? 'Add Workout' : 'Edit Workout',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Workout name
                _dialogTextField(
                  nameCtrl,
                  'Workout Name',
                  Icons.fitness_center,
                ),
                const SizedBox(height: 16),

                // Weight type toggle
                const Text(
                  'Load Type',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'weight',
                      label: Text('Weight (kg/lb)'),
                    ),
                    ButtonSegment(
                      value: 'machine',
                      label: Text('Machine Level'),
                    ),
                  ],
                  selected: {weightType},
                  onSelectionChanged: (s) =>
                      setDialogState(() => weightType = s.first),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.selected)
                          ? const Color(0xFF6C63FF)
                          : const Color(0xFF2A2A3E),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _dialogTextField(
                  weightCtrl,
                  weightType == 'weight' ? 'Weight (kg/lb)' : 'Machine Level',
                  Icons.speed,
                  inputType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                // Muscle groups
                const Text(
                  'Target Muscle Groups',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: muscleGroups.map((mg) {
                    final selected = selectedMuscles.contains(mg);
                    return FilterChip(
                      label: Text(
                        mg,
                        style: TextStyle(
                          fontSize: 12,
                          color: selected ? Colors.white : Colors.white60,
                        ),
                      ),
                      selected: selected,
                      onSelected: (v) => setDialogState(() {
                        v
                            ? selectedMuscles.add(mg)
                            : selectedMuscles.remove(mg);
                      }),
                      backgroundColor: const Color(0xFF2A2A3E),
                      selectedColor: const Color(0xFF6C63FF),
                      checkmarkColor: Colors.white,
                      side: BorderSide.none,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // EXP slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'EXP Gain',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C63FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$expGain EXP',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: expGain.toDouble(),
                  min: 1,
                  max: 20,
                  divisions: 19,
                  activeColor: const Color(0xFF6C63FF),
                  inactiveColor: const Color(0xFF2A2A3E),
                  onChanged: (v) => setDialogState(() => expGain = v.round()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                if (nameCtrl.text.isEmpty || selectedMuscles.isEmpty) return;
                final item = WorkoutItem(
                  id: editing?.id,
                  name: nameCtrl.text.trim(),
                  weightType: weightType,
                  weightValue: double.tryParse(weightCtrl.text) ?? 0,
                  muscleGroups: selectedMuscles,
                  expGain: expGain,
                );
                if (editing == null) {
                  await _db.insertWorkout(item);
                } else {
                  await _db.updateWorkout(item);
                }
                Navigator.pop(ctx);
                _loadWorkouts();
              },
              child: Text(
                editing == null ? 'Add' : 'Save',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteWorkout(WorkoutItem w) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C2E),
        title: const Text(
          'Delete Workout?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Remove "${w.name}" from your list?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _db.deleteWorkout(w.id!);
      _loadWorkouts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F1A),
        elevation: 0,
        title: const Text(
          'WORKOUTS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showWorkoutDialog(),
        backgroundColor: const Color(0xFF6C63FF),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _workouts.isEmpty
          ? _emptyState()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: _workouts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _WorkoutCard(
                workout: _workouts[i],
                onEdit: () => _showWorkoutDialog(editing: _workouts[i]),
                onDelete: () => _deleteWorkout(_workouts[i]),
              ),
            ),
    );
  }

  Widget _emptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.fitness_center,
          size: 64,
          color: Colors.white.withOpacity(0.1),
        ),
        const SizedBox(height: 16),
        Text(
          'No workouts yet',
          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap + to add your first workout',
          style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 13),
        ),
      ],
    ),
  );
}

// ─── Workout Card ─────────────────────────────────────────────────────────────

class _WorkoutCard extends StatelessWidget {
  final WorkoutItem workout;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _WorkoutCard({
    required this.workout,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workout.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      workout.weightType == 'weight'
                          ? Icons.monitor_weight_rounded
                          : Icons.tune_rounded,
                      size: 13,
                      color: Colors.white38,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      workout.weightType == 'weight'
                          ? '${workout.weightValue} kg'
                          : 'Level ${workout.weightValue.toInt()}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.bolt_rounded,
                      size: 13,
                      color: Color(0xFF6C63FF),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${workout.expGain} EXP',
                      style: const TextStyle(
                        color: Color(0xFF6C63FF),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: workout.muscleGroups
                      .map(
                        (mg) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C63FF).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            mg,
                            style: const TextStyle(
                              color: Color(0xFF6C63FF),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),

          // Actions
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.edit_rounded, size: 18),
                color: Colors.white54,
                onPressed: onEdit,
              ),
              IconButton(
                icon: const Icon(Icons.delete_rounded, size: 18),
                color: Colors.redAccent,
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Helper ───────────────────────────────────────────────────────────────────

Widget _dialogTextField(
  TextEditingController ctrl,
  String hint,
  IconData icon, {
  TextInputType inputType = TextInputType.text,
}) {
  return TextField(
    controller: ctrl,
    keyboardType: inputType,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      prefixIcon: Icon(icon, color: Colors.white38, size: 18),
      filled: true,
      fillColor: const Color(0xFF2A2A3E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  );
}
