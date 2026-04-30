import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// ─── Rank System ────────────────────────────────────────────────────────────

const List<String> rankTiers = [
  'Dirt',
  'Wood',
  'Bronze',
  'Silver',
  'Gold',
  'Platinum',
  'Diamond',
  'Mythical',
];

/// Returns the EXP required to advance FROM a given rank level (0-indexed).
/// Rank levels: Dirt1=0, Dirt2=1, Dirt3=2, Wood1=3, ... Mythical3=23, Peak=24
/// From level i to i+1 costs 100 + 50*i EXP.
/// Mythical3 → Peak costs (100 + 50*23) + 300 = 1650 EXP.
int expToNextRank(int currentLevel) {
  if (currentLevel >= 24) return 0; // Already at Peak
  int base = 100 + 50 * currentLevel;
  if (currentLevel == 23) base += 300; // Mythical3 → Peak bonus
  return base;
}

/// Total EXP required to reach a given rank level from 0.
int totalExpForLevel(int level) {
  int total = 0;
  for (int i = 0; i < level; i++) {
    total += expToNextRank(i);
  }
  return total;
}

class RankInfo {
  final String name; // e.g. "Gold 2"
  final int level; // 0–24
  final int currentExp; // EXP within this rank
  final int requiredExp; // EXP needed to advance
  final double progress; // 0.0–1.0

  const RankInfo({
    required this.name,
    required this.level,
    required this.currentExp,
    required this.requiredExp,
    required this.progress,
  });
}

RankInfo getRankInfo(int totalExp) {
  int level = 0;
  while (level < 24) {
    int needed = expToNextRank(level);
    if (totalExp < needed) break;
    totalExp -= needed;
    level++;
  }
  int req = level < 24 ? expToNextRank(level) : 1;
  String name;
  if (level == 24) {
    name = 'Peak';
  } else {
    int tierIndex = level ~/ 3;
    int sub = (level % 3) + 1;
    name = '${rankTiers[tierIndex]} $sub';
  }
  return RankInfo(
    name: name,
    level: level,
    currentExp: totalExp,
    requiredExp: req,
    progress: level < 24 ? totalExp / req : 1.0,
  );
}

// ─── Muscle Groups ───────────────────────────────────────────────────────────

const List<String> muscleGroups = [
  'Chest',
  'Upper Back',
  'Lower Back',
  'Shoulders',
  'Biceps',
  'Triceps',
  'Forearms',
  'Core',
];

// ─── Models ──────────────────────────────────────────────────────────────────

class WorkoutItem {
  final int? id;
  final String name;
  final String weightType; // 'weight' or 'machine'
  final double weightValue;
  final List<String> muscleGroups;
  final int expGain;

  WorkoutItem({
    this.id,
    required this.name,
    required this.weightType,
    required this.weightValue,
    required this.muscleGroups,
    required this.expGain,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'weight_type': weightType,
    'weight_value': weightValue,
    'muscle_groups': muscleGroups.join(','),
    'exp_gain': expGain,
  };

  factory WorkoutItem.fromMap(Map<String, dynamic> m) => WorkoutItem(
    id: m['id'],
    name: m['name'],
    weightType: m['weight_type'],
    weightValue: (m['weight_value'] as num).toDouble(),
    muscleGroups: (m['muscle_groups'] as String).split(','),
    expGain: m['exp_gain'],
  );
}

class CalendarEntry {
  final int? id;
  final String date; // ISO 8601 YYYY-MM-DD
  final int workoutId;

  CalendarEntry({this.id, required this.date, required this.workoutId});

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'date': date,
    'workout_id': workoutId,
  };

  factory CalendarEntry.fromMap(Map<String, dynamic> m) =>
      CalendarEntry(id: m['id'], date: m['date'], workoutId: m['workout_id']);
}

class Measurement {
  final int? id;
  final String date;
  final double? height;
  final double? weight;
  final double? bust;
  final double? bicep;
  final double? tricep;
  final double? forearm;
  final double? shoulderWidth;

  Measurement({
    this.id,
    required this.date,
    this.height,
    this.weight,
    this.bust,
    this.bicep,
    this.tricep,
    this.forearm,
    this.shoulderWidth,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'date': date,
    'height': height,
    'weight': weight,
    'bust': bust,
    'bicep': bicep,
    'tricep': tricep,
    'forearm': forearm,
    'shoulder_width': shoulderWidth,
  };

  factory Measurement.fromMap(Map<String, dynamic> m) => Measurement(
    id: m['id'],
    date: m['date'],
    height: (m['height'] as num?)?.toDouble(),
    weight: (m['weight'] as num?)?.toDouble(),
    bust: (m['bust'] as num?)?.toDouble(),
    bicep: (m['bicep'] as num?)?.toDouble(),
    tricep: (m['tricep'] as num?)?.toDouble(),
    forearm: (m['forearm'] as num?)?.toDouble(),
    shoulderWidth: (m['shoulder_width'] as num?)?.toDouble(),
  );
}

class PersonalRecord {
  final int? id;
  final int workoutId;
  final double weightValue;
  final String weightType;
  final int reps;

  PersonalRecord({
    this.id,
    required this.workoutId,
    required this.weightValue,
    required this.weightType,
    required this.reps,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'workout_id': workoutId,
    'weight_value': weightValue,
    'weight_type': weightType,
    'reps': reps,
  };

  factory PersonalRecord.fromMap(Map<String, dynamic> m) => PersonalRecord(
    id: m['id'],
    workoutId: m['workout_id'],
    weightValue: (m['weight_value'] as num).toDouble(),
    weightType: m['weight_type'],
    reps: m['reps'],
  );
}

class UserProfile {
  final String username;
  final String? photoPath;
  final String? startDate;
  final List<String> goals;

  UserProfile({
    required this.username,
    this.photoPath,
    this.startDate,
    this.goals = const [],
  });
}

// ─── Database Helper ─────────────────────────────────────────────────────────

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  Database? _db;

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'workout_tracker.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE workouts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            weight_type TEXT NOT NULL,
            weight_value REAL NOT NULL,
            muscle_groups TEXT NOT NULL,
            exp_gain INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE calendar_entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            workout_id INTEGER NOT NULL,
            FOREIGN KEY (workout_id) REFERENCES workouts(id)
          )
        ''');
        await db.execute('''
          CREATE TABLE measurements (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            height REAL,
            weight REAL,
            bust REAL,
            bicep REAL,
            tricep REAL,
            forearm REAL,
            shoulder_width REAL
          )
        ''');
        await db.execute('''
          CREATE TABLE personal_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            workout_id INTEGER NOT NULL,
            weight_value REAL NOT NULL,
            weight_type TEXT NOT NULL,
            reps INTEGER NOT NULL,
            FOREIGN KEY (workout_id) REFERENCES workouts(id)
          )
        ''');
        await db.execute('''
          CREATE TABLE muscle_group_exp (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            muscle_group TEXT NOT NULL UNIQUE,
            total_exp INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE user_profile (
            id INTEGER PRIMARY KEY,
            username TEXT,
            photo_path TEXT,
            start_date TEXT,
            goals TEXT
          )
        ''');

        // Seed muscle groups
        for (final mg in muscleGroups) {
          await db.insert('muscle_group_exp', {
            'muscle_group': mg,
            'total_exp': 0,
          });
        }
        await db.insert('user_profile', {
          'id': 1,
          'username': 'Athlete',
          'photo_path': null,
          'start_date': null,
          'goals': '',
        });
      },
    );
  }

  // ── Workouts ──────────────────────────────────────────────────────────────

  Future<int> insertWorkout(WorkoutItem w) async {
    final d = await db;
    return d.insert('workouts', w.toMap());
  }

  Future<List<WorkoutItem>> getWorkouts() async {
    final d = await db;
    final rows = await d.query('workouts', orderBy: 'name ASC');
    return rows.map(WorkoutItem.fromMap).toList();
  }

  Future<void> updateWorkout(WorkoutItem w) async {
    final d = await db;
    await d.update('workouts', w.toMap(), where: 'id = ?', whereArgs: [w.id]);
  }

  Future<void> deleteWorkout(int id) async {
    final d = await db;
    await d.delete('workouts', where: 'id = ?', whereArgs: [id]);
    await d.delete(
      'calendar_entries',
      where: 'workout_id = ?',
      whereArgs: [id],
    );
    await d.delete(
      'personal_records',
      where: 'workout_id = ?',
      whereArgs: [id],
    );
  }

  // ── Calendar ──────────────────────────────────────────────────────────────

  Future<int> insertCalendarEntry(CalendarEntry e) async {
    final d = await db;
    final id = await d.insert('calendar_entries', e.toMap());
    // Award exp to muscle groups
    final workout = await getWorkoutById(e.workoutId);
    if (workout != null) {
      for (final mg in workout.muscleGroups) {
        await addExpToMuscleGroup(mg, workout.expGain);
      }
    }
    return id;
  }

  Future<List<CalendarEntry>> getEntriesForDate(String date) async {
    final d = await db;
    final rows = await d.query(
      'calendar_entries',
      where: 'date = ?',
      whereArgs: [date],
    );
    return rows.map(CalendarEntry.fromMap).toList();
  }

  Future<List<String>> getWorkedOutDates() async {
    final d = await db;
    final rows = await d.rawQuery(
      'SELECT DISTINCT date FROM calendar_entries ORDER BY date',
    );
    return rows.map((r) => r['date'] as String).toList();
  }

  Future<void> deleteCalendarEntry(int id) async {
    final d = await db;
    // Look up the entry first so we can reverse its EXP contribution
    final rows = await d.query(
      'calendar_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isNotEmpty) {
      final entry = CalendarEntry.fromMap(rows.first);
      final workout = await getWorkoutById(entry.workoutId);
      if (workout != null) {
        for (final mg in workout.muscleGroups) {
          await d.rawUpdate(
            '''
            UPDATE muscle_group_exp
            SET total_exp = MAX(0, total_exp - ?)
            WHERE muscle_group = ?
          ''',
            [workout.expGain, mg],
          );
        }
      }
    }
    await d.delete('calendar_entries', where: 'id = ?', whereArgs: [id]);
  }

  // ── Measurements ─────────────────────────────────────────────────────────

  Future<int> insertMeasurement(Measurement m) async {
    final d = await db;
    return d.insert('measurements', m.toMap());
  }

  Future<List<Measurement>> getMeasurements() async {
    final d = await db;
    final rows = await d.query('measurements', orderBy: 'date DESC');
    return rows.map(Measurement.fromMap).toList();
  }

  Future<Measurement?> getMeasurementForDate(String date) async {
    final d = await db;
    final rows = await d.query(
      'measurements',
      where: 'date = ?',
      whereArgs: [date],
    );
    return rows.isEmpty ? null : Measurement.fromMap(rows.first);
  }

  Future<void> deleteMeasurement(int id) async {
    final d = await db;
    await d.delete('measurements', where: 'id = ?', whereArgs: [id]);
  }

  // ── Personal Records ──────────────────────────────────────────────────────

  Future<int> insertPersonalRecord(PersonalRecord pr) async {
    final d = await db;
    return d.insert('personal_records', pr.toMap());
  }

  Future<List<PersonalRecord>> getPersonalRecords() async {
    final d = await db;
    return (await d.query(
      'personal_records',
    )).map(PersonalRecord.fromMap).toList();
  }

  Future<void> updatePersonalRecord(PersonalRecord pr) async {
    final d = await db;
    await d.update(
      'personal_records',
      pr.toMap(),
      where: 'id = ?',
      whereArgs: [pr.id],
    );
  }

  Future<void> deletePersonalRecord(int id) async {
    final d = await db;
    await d.delete('personal_records', where: 'id = ?', whereArgs: [id]);
  }

  // ── Muscle Group EXP ──────────────────────────────────────────────────────

  Future<Map<String, int>> getAllMuscleExp() async {
    final d = await db;
    final rows = await d.query('muscle_group_exp');
    return {
      for (final r in rows) r['muscle_group'] as String: r['total_exp'] as int,
    };
  }

  Future<void> addExpToMuscleGroup(String muscleGroup, int exp) async {
    final d = await db;
    await d.rawUpdate(
      '''
      UPDATE muscle_group_exp SET total_exp = total_exp + ?
      WHERE muscle_group = ?
    ''',
      [exp, muscleGroup],
    );
  }

  // ── Overall Rank ──────────────────────────────────────────────────────────

  Future<RankInfo> getOverallRank() async {
    final expMap = await getAllMuscleExp();
    if (expMap.isEmpty) return getRankInfo(0);
    final total = expMap.values.fold(0, (a, b) => a + b);
    final avg = total ~/ expMap.length;
    return getRankInfo(avg);
  }

  Future<int> getTotalExpAllTime() async {
    final d = await db;
    final result = await d.rawQuery(
      'SELECT SUM(exp_gain) as total FROM calendar_entries ce '
      'JOIN workouts w ON ce.workout_id = w.id',
    );
    return (result.first['total'] as num?)?.toInt() ?? 0;
  }

  // ── Profile ───────────────────────────────────────────────────────────────

  Future<UserProfile> getProfile() async {
    final d = await db;
    final rows = await d.query('user_profile', where: 'id = 1');
    if (rows.isEmpty) return UserProfile(username: 'Athlete');
    final r = rows.first;
    final goalsStr = r['goals'] as String? ?? '';
    return UserProfile(
      username: r['username'] as String? ?? 'Athlete',
      photoPath: r['photo_path'] as String?,
      startDate: r['start_date'] as String?,
      goals: goalsStr.isEmpty ? [] : goalsStr.split('||'),
    );
  }

  Future<void> updateProfile(UserProfile p) async {
    final d = await db;
    await d.update('user_profile', {
      'username': p.username,
      'photo_path': p.photoPath,
      'start_date': p.startDate,
      'goals': p.goals.join('||'),
    }, where: 'id = 1');
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<WorkoutItem?> getWorkoutById(int id) async {
    final d = await db;
    final rows = await d.query('workouts', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : WorkoutItem.fromMap(rows.first);
  }
}
