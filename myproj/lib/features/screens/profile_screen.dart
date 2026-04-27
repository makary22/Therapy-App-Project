import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_service.dart';
import '../home/HomeScreen.dart';
import '../theme/app_theme_controller.dart';
import 'login.dart';

const Color _purple = Color(0xFF7B5EA7);
const Color _dark = Color(0xFF1A1A2E);
const Color _bg = Color(0xFFF4F1F8);
const Color _cardBg = Color(0xFFECE9F2);
const Color _textPrimary = Color(0xFF1E1F29);
const Color _textMuted = Color(0xFF888888);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  bool _darkTheme = false;
  bool _smartNotifications = true;
  bool _dailyReminder = true;
  bool _isSigningOut = false;
  int _currentNavIndex = 3;
  String _selectedReminderTime = '08:00 AM';
  String _fullName = 'Safe User';
  String _email = '';
  String? _avatarBase64;
  Uint8List? _avatarBytes;

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  TimeOfDay _parseTime(String value) {
    try {
      final parts = value.trim().split(' ');
      if (parts.length != 2) return const TimeOfDay(hour: 8, minute: 0);
      final hourMinute = parts[0].split(':');
      if (hourMinute.length != 2) return const TimeOfDay(hour: 8, minute: 0);
      int hour = int.parse(hourMinute[0]);
      final minute = int.parse(hourMinute[1]);
      final period = parts[1].toUpperCase();
      if (period == 'PM' && hour != 12) hour += 12;
      if (period == 'AM' && hour == 12) hour = 0;
      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return const TimeOfDay(hour: 8, minute: 0);
    }
  }

  Future<void> _pickReminderTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _parseTime(_selectedReminderTime),
      helpText: 'Choose reminder time',
    );
    if (selected == null || !mounted) return;
    setState(() {
      _selectedReminderTime = _formatTime(selected);
      _dailyReminder = true;
    });
    await _savePreferences();
  }

  @override
  void initState() {
    super.initState();
    _initializeProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _initializeProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();

    final email = (user?.email ?? '').trim();
    final firebaseName = (user?.displayName ?? '').trim();
    final savedName = (prefs.getString('profile_name') ?? '').trim();

    final resolvedName = firebaseName.isNotEmpty
        ? firebaseName
        : (savedName.isNotEmpty
            ? savedName
            : (email.isNotEmpty ? email.split('@').first : 'Safe User'));

    final savedAvatarBase64 = prefs.getString('profile_avatar_base64');

    if (!mounted) return;
    setState(() {
      _fullName = resolvedName;
      _email = email;
      _avatarBase64 = savedAvatarBase64;
      _avatarBytes =
          savedAvatarBase64 == null ? null : base64Decode(savedAvatarBase64);
      _darkTheme = prefs.getBool('profile_dark_theme') ?? false;
      _smartNotifications =
          prefs.getBool('profile_smart_notifications') ?? true;
      _dailyReminder = prefs.getBool('profile_daily_reminder') ?? true;
      _selectedReminderTime =
          prefs.getString('profile_reminder_time') ?? '08:00 AM';
      _nameController.text = _fullName;
    });

    await AppThemeController.setDarkMode(_darkTheme);
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('profile_dark_theme', _darkTheme);
    await prefs.setBool('profile_smart_notifications', _smartNotifications);
    await prefs.setBool('profile_daily_reminder', _dailyReminder);
    await prefs.setString('profile_reminder_time', _selectedReminderTime);
    await prefs.setString('profile_name', _fullName);
    if (_avatarBase64 != null && _avatarBase64!.isNotEmpty) {
      await prefs.setString('profile_avatar_base64', _avatarBase64!);
    }
  }

  Future<void> _showImageSourceDialog() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1F2A) : Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Change Profile Photo',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFF1EEF8) : _textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _ImageSourceOption(
                      isDark: isDark,
                      icon: Icons.photo_library_outlined,
                      label: 'Gallery',
                      onTap: () async {
                        Navigator.of(ctx).pop();
                        await _pickAvatarImage(ImageSource.gallery);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ImageSourceOption(
                      isDark: isDark,
                      icon: Icons.camera_alt_outlined,
                      label: 'Camera',
                      onTap: () async {
                        Navigator.of(ctx).pop();
                        await _pickAvatarImage(ImageSource.camera);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_avatarBytes != null)
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    setState(() {
                      _avatarBytes = null;
                      _avatarBase64 = null;
                    });
                    _savePreferences();
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text(
                    'Remove Photo',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAvatarImage(ImageSource source) async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1080,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final encoded = base64Encode(bytes);
      if (!mounted) return;
      setState(() {
        _avatarBytes = bytes;
        _avatarBase64 = encoded;
      });
      await _savePreferences();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to pick image right now.'),
          backgroundColor: Color(0xFFB13C3C),
        ),
      );
    }
  }

  Future<void> _editProfileInfo() async {
    _nameController.text = _fullName;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;

        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1F2A) : Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit profile',
                  style: TextStyle(
                    color: isDark ? const Color(0xFFF1EEF8) : _textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _nameController,
                  textInputAction: TextInputAction.done,
                  style: TextStyle(
                    color: isDark ? const Color(0xFFF1EEF8) : _textPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Name',
                    labelStyle: TextStyle(
                      color: isDark ? const Color(0xFFB9B6C7) : _textMuted,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF2A2B38)
                        : const Color(0xFFEFE8FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.of(sheetContext).pop();
                    await _showImageSourceDialog();
                  },
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Change photo'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _purple,
                    side: BorderSide(
                      color: isDark
                          ? const Color(0xFF47485A)
                          : const Color(0xFFD6CEE6),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final updatedName = _nameController.text.trim();
                      if (updatedName.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Name cannot be empty.'),
                            backgroundColor: Color(0xFFB13C3C),
                          ),
                        );
                        return;
                      }

                      if (!mounted) return;
                      setState(() => _fullName = updatedName);
                      await _savePreferences();

                      FirebaseAuth.instance.currentUser
                          ?.updateDisplayName(updatedName)
                          .catchError((_) {});

                      if (!mounted) return;
                      Navigator.of(sheetContext).pop();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Profile updated!'),
                          backgroundColor: _purple,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _purple,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Save changes'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleSignOut() async {
    if (_isSigningOut) return;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Sign out'),
          content: const Text('Are you sure you want to sign out now?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text('Sign out'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    setState(() => _isSigningOut = true);
    try {
      await AuthService.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong while signing out.'),
          backgroundColor: Color(0xFFB13C3C),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  void _onNavTap(int index) {
    if (index == _currentNavIndex) return;
    setState(() => _currentNavIndex = index);
    if (index == 0) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This section is coming soon.'),
        backgroundColor: _purple,
      ),
    );
    setState(() => _currentNavIndex = 3);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBg = isDark ? const Color(0xFF12131C) : _bg;
    final sectionTitle =
        isDark ? const Color(0xFFB8B5C6) : const Color(0xFF4A4A55);

    final String displayFirst = _fullName.split(' ').first;

    final String initials = _fullName
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          children: [
            _buildHeader(initials),
            const SizedBox(height: 24),
            _buildProfileCard(displayFirst, _fullName, _email, initials),
            const SizedBox(height: 24),
            Text(
              'PREFERENCE & ACCOUNT',
              style: TextStyle(
                color: sectionTitle,
                fontSize: 12,
                letterSpacing: 1.7,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _buildSettingsCard(),
            const SizedBox(height: 26),
            _buildSignOutButton(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildHeader(String initials) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? const Color(0xFFE5DFF0) : _purple;
    final avatarBorder =
        isDark ? const Color(0xFF383A4A) : const Color(0xFFD4D2DD);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.eco_outlined, size: 22, color: titleColor),
            const SizedBox(width: 6),
            Text(
              'Safe Space',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
            ),
          ],
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: avatarBorder, width: 2),
          ),
          child: ClipOval(
            child: _avatarBytes != null
                ? Image.memory(
                    _avatarBytes!,
                    fit: BoxFit.cover,
                    width: 44,
                    height: 44,
                  )
                : CircleAvatar(
                    backgroundColor: isDark ? const Color(0xFF2D2F3D) : _dark,
                    child: Text(
                      initials.isEmpty ? 'U' : initials[0],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(
    String displayFirst,
    String fullName,
    String email,
    String initials,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1A1C27) : _cardBg;
    final nameColor = isDark ? const Color(0xFFF2EEF9) : _textPrimary;
    final fullNameColor =
        isDark ? const Color(0xFFCCC8DB) : const Color(0xFF4D4E58);
    final emailColor = isDark ? const Color(0xFF9A97A8) : _textMuted;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 106,
                height: 106,
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF7B5EA7), Color(0xFFD45DA1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? const Color(0xFF292B39)
                        : const Color(0xFFF3ECFA),
                  ),
                  child: ClipOval(
                    child: _avatarBytes != null
                        ? Image.memory(
                            _avatarBytes!,
                            fit: BoxFit.cover,
                            width: 98,
                            height: 98,
                          )
                        : Center(
                            child: Text(
                              initials.isEmpty ? 'U' : initials,
                              style: TextStyle(
                                color: nameColor,
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
              Positioned(
                right: -4,
                bottom: -4,
                child: InkWell(
                  onTap: _showImageSourceDialog,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF764AA1), Color(0xFFD96CB3)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  displayFirst,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: nameColor,
                    fontSize: 33,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: _editProfileInfo,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF313346)
                        : const Color(0xFFF0E8FB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.edit_note_rounded,
                    size: 18,
                    color: _purple,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            fullName,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: fullNameColor,
              fontSize: 13,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(email, style: TextStyle(color: emailColor, fontSize: 12)),
          ],
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1C27) : const Color(0xFFEDEAF3),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          _PreferenceTile(
            isDark: isDark,
            icon: Icons.access_time_rounded,
            title: 'Daily Reflection',
            subtitle: 'Gentle reminder to check in',
            trailing: _TimePickerChip(
              isDark: isDark,
              value: _selectedReminderTime,
              enabled: _dailyReminder,
              onTap: _pickReminderTime,
            ),
          ),
          const SizedBox(height: 8),
          _PreferenceTile(
            isDark: isDark,
            icon: Icons.dark_mode_outlined,
            title: 'Dark Theme',
            subtitle: 'Ease eye strain at night',
            trailing: Switch(
              value: _darkTheme,
              onChanged: (value) async {
                setState(() => _darkTheme = value);
                await AppThemeController.setDarkMode(value);
                await _savePreferences();
              },
              activeColor: Colors.white,
              activeTrackColor: _purple,
              inactiveThumbColor:
                  isDark ? const Color(0xFFBEBACD) : Colors.white,
              inactiveTrackColor:
                  isDark ? const Color(0xFF3A3B4D) : const Color(0xFFD6D3DE),
            ),
          ),
          const SizedBox(height: 8),
          _PreferenceTile(
            isDark: isDark,
            icon: Icons.notifications_none_rounded,
            title: 'Smart Notifications',
            subtitle: 'Insights and activity alerts',
            trailing: Switch(
              value: _smartNotifications,
              onChanged: (value) async {
                setState(() => _smartNotifications = value);
                await _savePreferences();
              },
              activeColor: Colors.white,
              activeTrackColor: _purple,
              inactiveThumbColor:
                  isDark ? const Color(0xFFBEBACD) : Colors.white,
              inactiveTrackColor:
                  isDark ? const Color(0xFF3A3B4D) : const Color(0xFFD6D3DE),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignOutButton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isSigningOut ? null : _handleSignOut,
        icon: _isSigningOut
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Color(0xFFBF2D2D),
                ),
              )
            : const Icon(Icons.logout_rounded, size: 20),
        label: Text(
          _isSigningOut ? 'Signing out...' : 'Sign out',
          style: const TextStyle(fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          foregroundColor:
              isDark ? const Color(0xFFFF8484) : const Color(0xFFD22F2F),
          backgroundColor:
              isDark ? const Color(0xFF302734) : const Color(0xFFF2E9ED),
          disabledForegroundColor: const Color(0xFFBF6767),
          disabledBackgroundColor:
              isDark ? const Color(0xFF302734) : const Color(0xFFF2E9ED),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final List<Map<String, dynamic>> items = [
      {'icon': Icons.home_rounded, 'label': 'HOME'},
      {'icon': Icons.menu_book_outlined, 'label': 'JOURNAL'},
      {'icon': Icons.insights_outlined, 'label': 'INSIGHTS'},
      {'icon': Icons.person_outline_rounded, 'label': 'PROFILE'},
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1C27) : const Color(0xFFF0EEF5),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final bool active = index == _currentNavIndex;
          return GestureDetector(
            onTap: () => _onNavTap(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: active
                  ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
                  : const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                gradient: active
                    ? const LinearGradient(
                        colors: [Color(0xFF764AA1), Color(0xFFD96CB3)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item['icon'] as IconData,
                    color: active
                        ? Colors.white
                        : (isDark
                            ? const Color(0xFF9C9AAF)
                            : const Color(0xFF8A9AB3)),
                    size: 20,
                  ),
                  if (active) ...[
                    const SizedBox(width: 6),
                    Text(
                      item['label'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ImageSourceOption extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ImageSourceOption({
    required this.isDark,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2B38) : const Color(0xFFF4F1F8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: _purple, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isDark ? const Color(0xFFF1EEF8) : _textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreferenceTile extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  const _PreferenceTile({
    required this.isDark,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2E3D) : const Color(0xFFF5F3F8),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _purple, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDark ? const Color(0xFFF1EEF8) : _textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFFA8A6B5)
                        : const Color(0xFF5E5F69),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}

class _TimePickerChip extends StatelessWidget {
  final bool isDark;
  final String value;
  final bool enabled;
  final VoidCallback onTap;

  const _TimePickerChip({
    required this.isDark,
    required this.value,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: enabled
            ? (isDark ? const Color(0xFF35374A) : const Color(0xFFE0DBEA))
            : (isDark ? const Color(0xFF2A2B38) : const Color(0xFFE8E6EF)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: isDark ? const Color(0xFFD8C9F0) : _purple,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: isDark
                      ? const Color(0xFFA8A6B5)
                      : const Color(0xFF7A7B85),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
