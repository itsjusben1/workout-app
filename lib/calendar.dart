import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'backend.dart';
import 'main.dart' show AppDrawer;

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final DBHelper _db = DBHelper();
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  List<String> _workedOutDates = [];
  List<CalendarEntry> _selectedDayEntries = [];
  List<WorkoutItem> _allWorkouts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _loadData() async {
    final dates = await _db.getWorkedOutDates();
    final workouts = await _db.getWorkouts();
    final entries = await _db.getEntriesForDate(_dateKey(_selectedDay));
    setState(() {
      _workedOutDates = dates;
      _allWorkouts = workouts;
      _selectedDayEntries = entries;
      _loading = false;
    });
  }

  Future<void> _loadEntriesForSelected() async {
    final entries = await _db.getEntriesForDate(_dateKey(_selectedDay));
    setState(() => _selectedDayEntries = entries);
  }

  Future<void> _showAddWorkoutDialog() async {
    if (_allWorkouts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add workouts in the Workouts page first!'),
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
          title: Text(
            'Log Workout – ${_dateKey(_selectedDay)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _allWorkouts.length,
              itemBuilder: (_, i) {
                final w = _allWorkouts[i];
                final isSelected = selected?.id == w.id;
                return ListTile(
                  title: Text(
                    w.name,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF6C63FF)
                          : Colors.white,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    w.muscleGroups.join(', '),
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  trailing: Text(
                    '+${w.expGain} EXP',
                    style: const TextStyle(
                      color: Color(0xFF6C63FF),
                      fontSize: 12,
                    ),
                  ),
                  tileColor: isSelected
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
                      await _db.insertCalendarEntry(
                        CalendarEntry(
                          date: _dateKey(_selectedDay),
                          workoutId: selected!.id!,
                        ),
                      );
                      Navigator.pop(ctx);
                      _loadData();
                    },
              child: const Text('Log', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
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
          'CALENDAR',
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
        onPressed: _showAddWorkoutDialog,
        backgroundColor: const Color(0xFF6C63FF),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
              child: Column(
                children: [
                  // ── Calendar ──
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C2E),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: TableCalendar(
                      firstDay: DateTime(2020),
                      lastDay: DateTime(2099),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
                      calendarStyle: CalendarStyle(
                        defaultTextStyle: const TextStyle(
                          color: Colors.white70,
                        ),
                        weekendTextStyle: const TextStyle(
                          color: Colors.white54,
                        ),
                        todayDecoration: BoxDecoration(
                          color: const Color(0xFF6C63FF).withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: const BoxDecoration(
                          color: Color(0xFF6C63FF),
                          shape: BoxShape.circle,
                        ),
                        outsideDaysVisible: false,
                        markerDecoration: const BoxDecoration(
                          color: Color(0xFF00E5A0),
                          shape: BoxShape.circle,
                        ),
                      ),
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                        leftChevronIcon: Icon(
                          Icons.chevron_left,
                          color: Colors.white54,
                        ),
                        rightChevronIcon: Icon(
                          Icons.chevron_right,
                          color: Colors.white54,
                        ),
                      ),
                      daysOfWeekStyle: const DaysOfWeekStyle(
                        weekdayStyle: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                        weekendStyle: TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                      eventLoader: (day) {
                        final key = _dateKey(day);
                        return _workedOutDates.contains(key) ? [1] : [];
                      },
                      onDaySelected: (selected, focused) {
                        setState(() {
                          _selectedDay = selected;
                          _focusedDay = focused;
                        });
                        _loadEntriesForSelected();
                      },
                      onPageChanged: (focused) {
                        setState(() => _focusedDay = focused);
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Selected Day Entries ──
                  if (_selectedDayEntries.isNotEmpty) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'WORKOUTS ON ${_dateKey(_selectedDay)}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ..._selectedDayEntries.map(
                      (e) => FutureBuilder<WorkoutItem?>(
                        future: _db.getWorkoutById(e.workoutId),
                        builder: (ctx, snap) {
                          if (!snap.hasData) return const SizedBox.shrink();
                          final w = snap.data!;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1C1C2E),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF00E5A0),
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        w.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        w.muscleGroups.join(', '),
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '+${w.expGain} EXP',
                                  style: const TextStyle(
                                    color: Color(0xFF6C63FF),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () async {
                                    await _db.deleteCalendarEntry(e.id!);
                                    _loadData();
                                  },
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.redAccent,
                                    size: 16,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ] else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C2E),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 32,
                            color: Colors.white.withOpacity(0.15),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No workouts logged',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap + to log a workout for this day',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.2),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
