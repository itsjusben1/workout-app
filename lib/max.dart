import 'package:flutter/material.dart';
import 'backend.dart';
import 'main.dart' show AppDrawer;

class MaxPage extends StatefulWidget {
  const MaxPage({super.key});

  @override
  State<MaxPage> createState() => _MaxPageState();
}

class _MaxPageState extends State<MaxPage> {
  final DBHelper _db = DBHelper();
  List<PersonalRecord> _records = [];
  List<WorkoutItem> _allWorkouts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final records = await _db.getPersonalRecords();
    final workouts = await _db.getWorkouts();
    setState(() {
      _records = records;
      _allWorkouts = workouts;
      _loading = false;
    });
  }

  // IDs already tracked
  Set<int> get _trackedWorkoutIds => _records.map((r) => r.workoutId).toSet();

  Future<void> _showAddRecordDialog() async {
    final available = _allWorkouts
        .where((w) => !_trackedWorkoutIds.contains(w.id))
        .toList();

    if (_allWorkouts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add workouts in the Workouts page first!'),
        ),
      );
      return;
    }
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All workouts are already in your PR list!'),
        ),
      );
      return;
    }

    WorkoutItem? selected;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1C1C2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Add to PR List',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: available.length,
              itemBuilder: (_, i) {
                final w = available[i];
                final isSel = selected?.id == w.id;
                return ListTile(
                  title: Text(
                    w.name,
                    style: TextStyle(
                      color: isSel ? const Color(0xFF6C63FF) : Colors.white,
                      fontWeight: isSel ? FontWeight.w700 : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    w.muscleGroups.join(', '),
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  tileColor: isSel
                      ? const Color(0xFF6C63FF).withOpacity(0.1)
                      : Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  onTap: () => setDialogState(() => selected = w),
                );
              },
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
              onPressed: selected == null
                  ? null
                  : () async {
                      await _db.insertPersonalRecord(
                        PersonalRecord(
                          workoutId: selected!.id!,
                          weightValue: 0,
                          weightType: selected!.weightType,
                          reps: 0,
                        ),
                      );
                      Navigator.pop(ctx);
                      _loadData();
                    },
              child: const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteRecord(PersonalRecord pr) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C2E),
        title: const Text('Remove PR?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Remove this exercise from your PR list?',
          style: TextStyle(color: Colors.white70),
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
              'Remove',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _db.deletePersonalRecord(pr.id!);
      _loadData();
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
          'PERSONAL RECORDS',
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
        onPressed: _showAddRecordDialog,
        backgroundColor: const Color(0xFF6C63FF),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
          ? _emptyState()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: _records.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final pr = _records[i];
                final workout = _allWorkouts.firstWhere(
                  (w) => w.id == pr.workoutId,
                  orElse: () => WorkoutItem(
                    id: pr.workoutId,
                    name: 'Unknown',
                    weightType: 'weight',
                    weightValue: 0,
                    muscleGroups: [],
                    expGain: 0,
                  ),
                );
                return _PRCard(
                  record: pr,
                  workout: workout,
                  onDelete: () => _deleteRecord(pr),
                  onUpdate: (updated) async {
                    await _db.updatePersonalRecord(updated);
                    _loadData();
                  },
                );
              },
            ),
    );
  }

  Widget _emptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.emoji_events_rounded,
          size: 64,
          color: Colors.white.withOpacity(0.1),
        ),
        const SizedBox(height: 16),
        Text(
          'No personal records yet',
          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap + to track your PRs',
          style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 13),
        ),
      ],
    ),
  );
}

// ─── PR Card ──────────────────────────────────────────────────────────────────

class _PRCard extends StatefulWidget {
  final PersonalRecord record;
  final WorkoutItem workout;
  final VoidCallback onDelete;
  final ValueChanged<PersonalRecord> onUpdate;

  const _PRCard({
    required this.record,
    required this.workout,
    required this.onDelete,
    required this.onUpdate,
  });

  @override
  State<_PRCard> createState() => _PRCardState();
}

class _PRCardState extends State<_PRCard> {
  late TextEditingController _weightCtrl;
  late TextEditingController _repsCtrl;

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController(
      text: widget.record.weightValue > 0
          ? widget.record.weightValue.toStringAsFixed(1)
          : '',
    );
    _repsCtrl = TextEditingController(
      text: widget.record.reps > 0 ? widget.record.reps.toString() : '',
    );
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final weight = double.tryParse(_weightCtrl.text) ?? 0;
    final reps = int.tryParse(_repsCtrl.text) ?? 0;
    widget.onUpdate(
      PersonalRecord(
        id: widget.record.id,
        workoutId: widget.record.workoutId,
        weightValue: weight,
        weightType: widget.record.weightType,
        reps: reps,
      ),
    );
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final isWeight = widget.workout.weightType == 'weight';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                size: 16,
                color: Color(0xFFFFD700),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.workout.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_rounded,
                  size: 18,
                  color: Colors.redAccent,
                ),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                onPressed: widget.onDelete,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            children: widget.workout.muscleGroups
                .map(
                  (mg) => Chip(
                    label: Text(
                      mg,
                      style: const TextStyle(
                        color: Color(0xFF6C63FF),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    backgroundColor: const Color(0xFF6C63FF).withOpacity(0.12),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    side: BorderSide.none,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),

          // Input row
          Row(
            children: [
              // Weight / Level
              Expanded(
                child: _inputField(
                  controller: _weightCtrl,
                  hint: isWeight ? 'Weight (kg)' : 'Machine Level',
                  icon: isWeight
                      ? Icons.monitor_weight_rounded
                      : Icons.tune_rounded,
                ),
              ),
              const SizedBox(width: 8),
              // Reps
              Expanded(
                child: _inputField(
                  controller: _repsCtrl,
                  hint: 'Reps',
                  icon: Icons.repeat_rounded,
                ),
              ),
              const SizedBox(width: 8),
              // Save button
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),

          // Current PR display
          if (widget.record.weightValue > 0 || widget.record.reps > 0)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: Color(0xFFFFD700),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Current PR: '
                    '${isWeight ? '${widget.record.weightValue.toStringAsFixed(1)} kg' : 'Level ${widget.record.weightValue.toInt()}'}'
                    ' × ${widget.record.reps} reps',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
        prefixIcon: Icon(icon, color: Colors.white38, size: 16),
        filled: true,
        fillColor: const Color(0xFF2A2A3E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
    );
  }
}
