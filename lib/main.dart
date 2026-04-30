import 'package:flutter/material.dart';
import 'backend.dart';
import 'workouts.dart';
import 'calendar.dart';
import 'measurements.dart';
import 'max.dart';
import 'profile.dart';

void main() {
  runApp(const WorkoutTrackerApp());
}

class WorkoutTrackerApp extends StatelessWidget {
  const WorkoutTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Workout Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0F0F1A),
        cardTheme: CardThemeData(
          color: const Color(0xFF1C1C2E),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        drawerTheme: const DrawerThemeData(backgroundColor: Color(0xFF14141F)),
      ),
      home: const HomePage(),
    );
  }
}

// ─── Rank Colors ─────────────────────────────────────────────────────────────

Color rankColor(int level) {
  if (level >= 24) return const Color(0xFFFFFFFF); // Peak – white
  final tier = level ~/ 3;
  const colors = [
    Color(0xFF8B4513), // Dirt   – saddle brown
    Color(0xFF8B6914), // Wood   – dark goldenrod
    Color(0xFFCD7F32), // Bronze
    Color(0xFFC0C0C0), // Silver
    Color(0xFFFFD700), // Gold
    Color(0xFF40E0D0), // Platinum – turquoise
    Color(0xFF00BFFF), // Diamond – deep sky blue
    Color(0xFFDA70D6), // Mythical – orchid
  ];
  return colors[tier];
}

Color rankCardBackground(int level) {
  return rankColor(level).withOpacity(0.12);
}

// ─── App Drawer ───────────────────────────────────────────────────────────────

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _navigate(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Text(
                'MENU',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.5,
                ),
              ),
            ),
            const Divider(color: Color(0xFF2A2A3E)),
            _drawerItem(context, Icons.home_rounded, 'Home', const HomePage()),
            _drawerItem(
              context,
              Icons.fitness_center_rounded,
              'Workouts',
              const WorkoutsPage(),
            ),
            _drawerItem(
              context,
              Icons.calendar_month_rounded,
              'Calendar',
              const CalendarPage(),
            ),
            _drawerItem(
              context,
              Icons.straighten_rounded,
              'Measurements',
              const MeasurementsPage(),
            ),
            _drawerItem(
              context,
              Icons.emoji_events_rounded,
              'Personal Records',
              const MaxPage(),
            ),
            _drawerItem(
              context,
              Icons.person_rounded,
              'Profile',
              const ProfilePage(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(
    BuildContext ctx,
    IconData icon,
    String label,
    Widget page,
  ) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF6C63FF)),
      title: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 15),
      ),
      onTap: () => _navigate(ctx, page),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}

// ─── Home Page ────────────────────────────────────────────────────────────────

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DBHelper _db = DBHelper();
  RankInfo? _overallRank;
  Map<String, int> _muscleExp = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final rank = await _db.getOverallRank();
    final exp = await _db.getAllMuscleExp();
    setState(() {
      _overallRank = rank;
      _muscleExp = exp;
      _loading = false;
    });
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
          'WORKOUT TRACKER',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Overall Rank Row ──
                    _OverallRankCard(rankInfo: _overallRank!),
                    const SizedBox(height: 24),

                    // ── Section Label ──
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'MUSCLE GROUPS',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.5,
                        ),
                      ),
                    ),

                    // ── Muscle Group Cards ──
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: muscleGroups.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final mg = muscleGroups[i];
                        final exp = _muscleExp[mg] ?? 0;
                        final rank = getRankInfo(exp);
                        return _MuscleGroupCard(
                          muscleGroup: mg,
                          rankInfo: rank,
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}

// ─── Overall Rank Card ────────────────────────────────────────────────────────

class _OverallRankCard extends StatelessWidget {
  final RankInfo rankInfo;
  const _OverallRankCard({required this.rankInfo});

  @override
  Widget build(BuildContext context) {
    final color = rankColor(rankInfo.level);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.18), color.withOpacity(0.05)],
        ),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Rank emblem
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.15),
              border: Border.all(color: color, width: 2),
            ),
            child: Center(
              child: Text(
                rankInfo.name.split(' ').first.substring(0, 1),
                style: TextStyle(
                  color: color,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Rank info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'OVERALL RANK',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  rankInfo.name,
                  style: TextStyle(
                    color: color,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                if (rankInfo.level < 24) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: rankInfo.progress,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${rankInfo.currentExp} / ${rankInfo.requiredExp} EXP',
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ] else
                  const Text(
                    'MAX RANK ACHIEVED',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Muscle Group Card ────────────────────────────────────────────────────────

class _MuscleGroupCard extends StatelessWidget {
  final String muscleGroup;
  final RankInfo rankInfo;
  const _MuscleGroupCard({required this.muscleGroup, required this.rankInfo});

  @override
  Widget build(BuildContext context) {
    final color = rankColor(rankInfo.level);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: rankCardBackground(rankInfo.level),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.15),
              border: Border.all(color: color.withOpacity(0.5), width: 1.5),
            ),
            child: Center(
              child: Text(
                rankInfo.name.split(' ').first.substring(0, 1),
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      muscleGroup,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      rankInfo.name,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: rankInfo.progress,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  rankInfo.level < 24
                      ? '${rankInfo.currentExp} / ${rankInfo.requiredExp} EXP'
                      : 'PEAK',
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
