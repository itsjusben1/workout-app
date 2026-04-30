import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'backend.dart';
import 'main.dart' show AppDrawer;

class MeasurementsPage extends StatefulWidget {
  const MeasurementsPage({super.key});

  @override
  State<MeasurementsPage> createState() => _MeasurementsPageState();
}

class _MeasurementsPageState extends State<MeasurementsPage> {
  final DBHelper _db = DBHelper();
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  List<Measurement> _allMeasurements = [];
  Measurement? _selectedDayMeasurement;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _loadData() async {
    final all = await _db.getMeasurements();
    final sel = await _db.getMeasurementForDate(_dateKey(_selectedDay));
    setState(() {
      _allMeasurements = all;
      _selectedDayMeasurement = sel;
      _loading = false;
    });
  }

  Future<void> _loadSelectedDay() async {
    final sel = await _db.getMeasurementForDate(_dateKey(_selectedDay));
    setState(() => _selectedDayMeasurement = sel);
  }

  Set<String> get _measuredDates => _allMeasurements.map((m) => m.date).toSet();

  Future<void> _showMeasurementDialog({Measurement? editing}) async {
    final fields = <String, TextEditingController>{
      'Height (cm)': TextEditingController(
        text: editing?.height?.toString() ?? '',
      ),
      'Weight (kg)': TextEditingController(
        text: editing?.weight?.toString() ?? '',
      ),
      'Bust (cm)': TextEditingController(text: editing?.bust?.toString() ?? ''),
      'Bicep (cm)': TextEditingController(
        text: editing?.bicep?.toString() ?? '',
      ),
      'Tricep (cm)': TextEditingController(
        text: editing?.tricep?.toString() ?? '',
      ),
      'Forearm (cm)': TextEditingController(
        text: editing?.forearm?.toString() ?? '',
      ),
      'Shoulder Width (cm)': TextEditingController(
        text: editing?.shoulderWidth?.toString() ?? '',
      ),
    };

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          editing == null
              ? 'Add Measurements\n${_dateKey(_selectedDay)}'
              : 'Edit Measurements\n${editing.date}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: fields.entries
                .map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      controller: e.value,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: e.key,
                        hintStyle: const TextStyle(
                          color: Colors.white38,
                          fontSize: 13,
                        ),
                        filled: true,
                        fillColor: const Color(0xFF2A2A3E),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
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
              double? parse(String key) =>
                  double.tryParse(fields[key]!.text.trim());

              final m = Measurement(
                id: editing?.id,
                date: editing?.date ?? _dateKey(_selectedDay),
                height: parse('Height (cm)'),
                weight: parse('Weight (kg)'),
                bust: parse('Bust (cm)'),
                bicep: parse('Bicep (cm)'),
                tricep: parse('Tricep (cm)'),
                forearm: parse('Forearm (cm)'),
                shoulderWidth: parse('Shoulder Width (cm)'),
              );

              if (editing == null) {
                await _db.insertMeasurement(m);
              } else {
                await _db.deleteMeasurement(editing.id!);
                await _db.insertMeasurement(m);
              }

              Navigator.pop(ctx);
              _loadData();
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
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
          'MEASUREMENTS',
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
        onPressed: () =>
            _showMeasurementDialog(editing: _selectedDayMeasurement),
        backgroundColor: const Color(0xFF6C63FF),
        child: Icon(
          _selectedDayMeasurement != null ? Icons.edit_rounded : Icons.add,
          color: Colors.white,
        ),
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
                          color: Color(0xFFFFD700),
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
                        return _measuredDates.contains(_dateKey(day))
                            ? [1]
                            : [];
                      },
                      onDaySelected: (selected, focused) {
                        setState(() {
                          _selectedDay = selected;
                          _focusedDay = focused;
                        });
                        _loadSelectedDay();
                      },
                      onPageChanged: (focused) =>
                          setState(() => _focusedDay = focused),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Selected Day Measurement ──
                  if (_selectedDayMeasurement != null)
                    _MeasurementCard(
                      measurement: _selectedDayMeasurement!,
                      onEdit: () => _showMeasurementDialog(
                        editing: _selectedDayMeasurement,
                      ),
                      onDelete: () async {
                        await _db.deleteMeasurement(
                          _selectedDayMeasurement!.id!,
                        );
                        _loadData();
                      },
                    )
                  else
                    _noDataCard(),

                  const SizedBox(height: 24),

                  // ── All Measurements List ──
                  if (_allMeasurements.isNotEmpty) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'ALL MEASUREMENTS',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _allMeasurements.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final m = _allMeasurements[i];
                        return _MeasurementCard(
                          measurement: m,
                          onEdit: () => _showMeasurementDialog(editing: m),
                          onDelete: () async {
                            await _db.deleteMeasurement(m.id!);
                            _loadData();
                          },
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _noDataCard() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: const Color(0xFF1C1C2E),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      children: [
        Icon(
          Icons.straighten_rounded,
          size: 32,
          color: Colors.white.withOpacity(0.15),
        ),
        const SizedBox(height: 8),
        Text(
          'No measurements for this day',
          style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          'Tap + to log your measurements',
          style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 12),
        ),
      ],
    ),
  );
}

// ─── Measurement Card ─────────────────────────────────────────────────────────

class _MeasurementCard extends StatelessWidget {
  final Measurement measurement;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MeasurementCard({
    required this.measurement,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final fields = <String, double?>{
      'Height': measurement.height,
      'Weight': measurement.weight,
      'Bust': measurement.bust,
      'Bicep': measurement.bicep,
      'Tricep': measurement.tricep,
      'Forearm': measurement.forearm,
      'Shoulders': measurement.shoulderWidth,
    };
    final present = fields.entries.where((e) => e.value != null).toList();

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
          Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                size: 14,
                color: Colors.white38,
              ),
              const SizedBox(width: 6),
              Text(
                measurement.date,
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.edit_rounded, size: 16),
                color: Colors.white54,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                onPressed: onEdit,
              ),
              IconButton(
                icon: const Icon(Icons.delete_rounded, size: 16),
                color: Colors.redAccent,
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: present.map((e) => _statChip(e.key, e.value!)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _statChip(String label, double value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFF2A2A3E),
      borderRadius: BorderRadius.circular(20),
    ),
    child: RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label  ',
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          TextSpan(
            text: value.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}
