import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'backend.dart';
import 'main.dart' show AppDrawer;

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final DBHelper _db = DBHelper();
  final ImagePicker _picker = ImagePicker();

  UserProfile? _profile;
  int _totalExp = 0;
  bool _loading = true;

  // Before/After items stored as list of maps: {before, after, beforeDate, afterDate}
  // Persisted inside goals with a special prefix for simplicity
  List<_BeforeAfterItem> _baItems = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final profile = await _db.getProfile();
    final exp = await _db.getTotalExpAllTime();

    // Parse before/after items from goals that start with '__BA__'
    final goals = profile.goals.where((g) => !g.startsWith('__BA__')).toList();
    final baRaw = profile.goals.where((g) => g.startsWith('__BA__')).toList();
    final baItems = baRaw.map((s) {
      final parts = s.replaceFirst('__BA__', '').split('|');
      return _BeforeAfterItem(
        beforePath: parts.length > 0 ? parts[0] : null,
        afterPath: parts.length > 1 ? parts[1] : null,
        beforeDate: parts.length > 2 ? parts[2] : null,
        afterDate: parts.length > 3 ? parts[3] : null,
      );
    }).toList();

    setState(() {
      _profile = UserProfile(
        username: profile.username,
        photoPath: profile.photoPath,
        startDate: profile.startDate,
        goals: goals,
      );
      _totalExp = exp;
      _baItems = baItems;
      _loading = false;
    });
  }

  Future<void> _saveProfile() async {
    if (_profile == null) return;
    final baGoals = _baItems
        .map(
          (b) =>
              '__BA__${b.beforePath ?? ''}|${b.afterPath ?? ''}|${b.beforeDate ?? ''}|${b.afterDate ?? ''}',
        )
        .toList();
    await _db.updateProfile(
      UserProfile(
        username: _profile!.username,
        photoPath: _profile!.photoPath,
        startDate: _profile!.startDate,
        goals: [..._profile!.goals, ...baGoals],
      ),
    );
  }

  /// Returns a file path using file_selector on macOS, image_picker elsewhere.
  Future<String?> _pickImagePath() async {
    if (Platform.isMacOS) {
      const typeGroup = XTypeGroup(
        label: 'images',
        extensions: ['jpg', 'jpeg', 'png', 'heic', 'webp'],
      );
      final file = await openFile(acceptedTypeGroups: [typeGroup]);
      return file?.path;
    } else {
      final file = await _picker.pickImage(source: ImageSource.gallery);
      return file?.path;
    }
  }

  Future<void> _pickProfilePhoto() async {
    final path = await _pickImagePath();
    if (path == null) return;
    setState(
      () => _profile = UserProfile(
        username: _profile!.username,
        photoPath: path,
        startDate: _profile!.startDate,
        goals: _profile!.goals,
      ),
    );
    await _saveProfile();
  }

  Future<void> _editUsername() async {
    final ctrl = TextEditingController(text: _profile?.username ?? '');
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Edit Username',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Username',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF2A2A3E),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
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
              setState(
                () => _profile = UserProfile(
                  username: ctrl.text.trim().isEmpty
                      ? 'Athlete'
                      : ctrl.text.trim(),
                  photoPath: _profile!.photoPath,
                  startDate: _profile!.startDate,
                  goals: _profile!.goals,
                ),
              );
              await _saveProfile();
              Navigator.pop(ctx);
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _profile?.startDate != null
          ? DateTime.parse(_profile!.startDate!)
          : now,
      firstDate: DateTime(2000),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF6C63FF),
            surface: Color(0xFF1C1C2E),
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    final key =
        '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    setState(
      () => _profile = UserProfile(
        username: _profile!.username,
        photoPath: _profile!.photoPath,
        startDate: key,
        goals: _profile!.goals,
      ),
    );
    await _saveProfile();
  }

  Future<void> _addGoal() async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Add Goal',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'e.g. Bench 100kg by June',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF2A2A3E),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
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
              if (ctrl.text.trim().isEmpty) return;
              setState(
                () => _profile = UserProfile(
                  username: _profile!.username,
                  photoPath: _profile!.photoPath,
                  startDate: _profile!.startDate,
                  goals: [..._profile!.goals, ctrl.text.trim()],
                ),
              );
              await _saveProfile();
              Navigator.pop(ctx);
            },
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteGoal(int index) async {
    final updated = List<String>.from(_profile!.goals)..removeAt(index);
    setState(
      () => _profile = UserProfile(
        username: _profile!.username,
        photoPath: _profile!.photoPath,
        startDate: _profile!.startDate,
        goals: updated,
      ),
    );
    await _saveProfile();
  }

  Future<void> _addBeforeAfterItem() async {
    setState(() => _baItems.add(_BeforeAfterItem()));
    await _saveProfile();
  }

  Future<void> _pickBAPhoto(int index, bool isBefore) async {
    final path = await _pickImagePath();
    if (path == null) return;
    final now = DateTime.now();
    final dateKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    setState(() {
      final item = _baItems[index];
      _baItems[index] = _BeforeAfterItem(
        beforePath: isBefore ? path : item.beforePath,
        afterPath: isBefore ? item.afterPath : path,
        beforeDate: isBefore ? dateKey : item.beforeDate,
        afterDate: isBefore ? item.afterDate : dateKey,
      );
    });
    await _saveProfile();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _profile == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0F1A),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F1A),
        elevation: 0,
        title: const Text(
          'PROFILE',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Profile Card ──
            _profileCard(),
            const SizedBox(height: 20),

            // ── Stats Card ──
            _statsCard(),
            const SizedBox(height: 24),

            // ── Before / After Carousel ──
            _sectionLabel('PROGRESS PHOTOS'),
            const SizedBox(height: 10),
            _beforeAfterSection(),
            const SizedBox(height: 24),

            // ── Goals ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionLabel('GOALS'),
                TextButton.icon(
                  onPressed: _addGoal,
                  icon: const Icon(
                    Icons.add,
                    size: 16,
                    color: Color(0xFF6C63FF),
                  ),
                  label: const Text(
                    'Add Goal',
                    style: TextStyle(color: Color(0xFF6C63FF), fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _goalsList(),
          ],
        ),
      ),
    );
  }

  // ── Profile Card ─────────────────────────────────────────────────────────

  Widget _profileCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: _pickProfilePhoto,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xFF2A2A3E),
                  backgroundImage: _profile!.photoPath != null
                      ? FileImage(File(_profile!.photoPath!))
                      : null,
                  child: _profile!.photoPath == null
                      ? const Icon(
                          Icons.person_rounded,
                          size: 40,
                          color: Colors.white38,
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF6C63FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Name + start date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: _editUsername,
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          _profile!.username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.edit_rounded,
                        size: 14,
                        color: Colors.white38,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: _pickStartDate,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.flag_rounded,
                        size: 13,
                        color: Colors.white38,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _profile!.startDate != null
                            ? 'Started ${_profile!.startDate}'
                            : 'Tap to set start date',
                        style: TextStyle(
                          color: _profile!.startDate != null
                              ? Colors.white54
                              : const Color(0xFF6C63FF),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats Card ────────────────────────────────────────────────────────────

  Widget _statsCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6C63FF).withOpacity(0.2),
            const Color(0xFF6C63FF).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          const Icon(Icons.bolt_rounded, color: Color(0xFF6C63FF), size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TOTAL EXP EARNED',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$_totalExp EXP',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Before / After ────────────────────────────────────────────────────────

  Widget _beforeAfterSection() {
    return Column(
      children: [
        if (_baItems.isEmpty)
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
                  Icons.photo_library_rounded,
                  size: 32,
                  color: Colors.white.withOpacity(0.15),
                ),
                const SizedBox(height: 8),
                Text(
                  'No progress photos yet',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _baItems.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _BACard(
                item: _baItems[i],
                onPickBefore: () => _pickBAPhoto(i, true),
                onPickAfter: () => _pickBAPhoto(i, false),
              ),
            ),
          ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _addBeforeAfterItem,
            icon: const Icon(
              Icons.add_photo_alternate_rounded,
              size: 16,
              color: Color(0xFF6C63FF),
            ),
            label: const Text(
              'Add Entry',
              style: TextStyle(color: Color(0xFF6C63FF), fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  // ── Goals ─────────────────────────────────────────────────────────────────

  Widget _goalsList() {
    if (_profile!.goals.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C2E),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          'No goals yet. Tap "Add Goal" to get started!',
          style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _profile!.goals.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              const Icon(
                Icons.flag_rounded,
                size: 16,
                color: Color(0xFF6C63FF),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _profile!.goals[i],
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.redAccent,
                ),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                onPressed: () => _deleteGoal(i),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) => Text(
    text,
    style: TextStyle(
      color: Colors.white.withOpacity(0.4),
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 2,
    ),
  );
}

// ─── Before/After Item Model ─────────────────────────────────────────────────

class _BeforeAfterItem {
  final String? beforePath;
  final String? afterPath;
  final String? beforeDate;
  final String? afterDate;

  _BeforeAfterItem({
    this.beforePath,
    this.afterPath,
    this.beforeDate,
    this.afterDate,
  });
}

// ─── Before/After Card ────────────────────────────────────────────────────────

class _BACard extends StatelessWidget {
  final _BeforeAfterItem item;
  final VoidCallback onPickBefore;
  final VoidCallback onPickAfter;

  const _BACard({
    required this.item,
    required this.onPickBefore,
    required this.onPickAfter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _photoSlot(
            path: item.beforePath,
            label: 'BEFORE',
            date: item.beforeDate,
            onTap: onPickBefore,
          ),
          const SizedBox(width: 8),
          _photoSlot(
            path: item.afterPath,
            label: 'AFTER',
            date: item.afterDate,
            onTap: onPickAfter,
          ),
        ],
      ),
    );
  }

  Widget _photoSlot({
    required String? path,
    required String label,
    required String? date,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: path != null
                    ? Image.file(
                        File(path),
                        fit: BoxFit.cover,
                        width: double.infinity,
                      )
                    : Container(
                        color: const Color(0xFF2A2A3E),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.add_a_photo_rounded,
                              color: Colors.white38,
                              size: 24,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              label,
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            if (date != null)
              Text(
                date,
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
          ],
        ),
      ),
    );
  }
}
