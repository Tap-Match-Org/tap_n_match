import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:tap_n_match/core/theme_background.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int userId = 1;
  String username = "Player";
  String email = "";
  String selectedTheme = "#A9A9A9";
  String unlockedThemesRaw = "";
  String? lastUsernameChangeDate;
  String? createdAt;
  String? lastChallengeDate;
  Uint8List? profilePictureBytes;
  bool isPublicProfile = false;
  int highestScore = 0;
  int highestLevel = 0;
  int levelsCleared = 0;
  int achievementCount = 0;
  int boxesTapped = 0;
  int leaderboardRank = 0;
  int leaderboardTotalPlayers = 0;
  int availableThemesCount = 1;
  bool isLoading = true;
  bool _didInitialize = false;

  final Map<String, String> _themeNames = {
    "#A9A9A9": "Default",
    "#98EE99": "Mint",
    "#2E1A47": "Amethyst",
    "#1A3A5F": "Ocean",
    "#FFA500": "Orange",
    "#FFC0CB": "Pink",
    "#00FF00": "Lime",
    "#00FFFF": "Cyan",
    "#FFD700": "Gold",
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitialize) return;
    _didInitialize = true;

    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args.containsKey('user_id')) {
      userId = args['user_id'];
    }
    final initialSelectedTheme = (args?['initial_selected_theme'] as String?)?.trim();
    if (initialSelectedTheme != null && initialSelectedTheme.isNotEmpty) {
      selectedTheme = initialSelectedTheme;
    }
    isPublicProfile = args != null && args['public_profile'] == true;
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final userEndpoint = isPublicProfile
          ? 'http://localhost:8000/public-users/$userId'
          : 'http://localhost:8000/users/$userId';
      final userResponse = await http.get(Uri.parse(userEndpoint));
      Map<String, dynamic>? userData;
      if (userResponse.statusCode == 200) {
        userData = jsonDecode(userResponse.body) as Map<String, dynamic>;
      }

      List<Map<String, dynamic>> players = [];
      try {
        final leaderboardResponse = await http.get(Uri.parse('http://localhost:8000/leaderboards'));
        if (leaderboardResponse.statusCode == 200) {
          final data = jsonDecode(leaderboardResponse.body) as Map<String, dynamic>;
          final rawPlayers = (data['players'] as List<dynamic>? ?? []);
          players = rawPlayers
              .map((player) => Map<String, dynamic>.from(player as Map))
              .toList();
        }
      } catch (e) {
        debugPrint('Error loading leaderboard data: $e');
      }

      if (!mounted) return;

      setState(() {
        if (userData != null) {
          username = (userData['username'] as String?) ?? 'Player';
          email = isPublicProfile ? '' : (userData['email'] as String?) ?? '';
          selectedTheme = (userData['selected_theme'] as String?) ?? "#A9A9A9";
          
          final themes = userData['unlocked_themes'];
          if (themes is List) {
            unlockedThemesRaw = themes.join(',');
          } else {
            unlockedThemesRaw = (themes as String?) ?? '';
          }

          lastUsernameChangeDate = isPublicProfile
              ? null
              : userData['last_username_change_date'] as String?;
          profilePictureBytes = _decodeProfilePicture(userData['profile_picture'] as String?);
          createdAt = userData['created_at'] as String?;
          lastChallengeDate = userData['last_challenge_date'] as String?;
          highestScore = (userData['highest_score'] as int?) ?? 0;
          highestLevel = (userData['highest_level'] as int?) ?? 0;
          levelsCleared = (userData['levels_cleared'] as int?) ?? 0;
          achievementCount = (userData['achievement_count'] as int?) ?? 0;
          boxesTapped = (userData['boxes_tapped'] as int?) ?? 0;
          availableThemesCount = _countAvailableThemes(unlockedThemesRaw);
        }

        leaderboardTotalPlayers = players.length;
        leaderboardRank = 0;
        for (final player in players) {
          if (player['user_id'] == userId) {
            leaderboardRank = (player['rank'] as int?) ?? 0;
            break;
          }
        }

        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading profile data: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  int _countAvailableThemes(String? themes) {
    final uniqueThemes = <String>{"#A9A9A9"};
    if (themes != null && themes.isNotEmpty) {
      uniqueThemes.addAll(
        themes
            .split(',')
            .map((theme) => theme.trim())
            .where((theme) => theme.isNotEmpty),
      );
    }
    return uniqueThemes.length;
  }

  String _formatDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) {
      return "N/A";
    }

    try {
      final parsed = DateTime.parse(rawDate);
      return DateFormat('MMM d, y').format(parsed);
    } catch (_) {
      return rawDate;
    }
  }

  String _themeLabel(String hex) {
    return _themeNames[hex] ?? "Custom";
  }

  Uint8List? _decodeProfilePicture(String? encodedPicture) {
    if (encodedPicture == null || encodedPicture.trim().isEmpty) {
      return null;
    }

    final cleaned = encodedPicture.contains(',')
        ? encodedPicture.split(',').last.trim()
        : encodedPicture.trim();

    try {
      return base64Decode(cleaned);
    } catch (_) {
      return null;
    }
  }

  bool _canChangeUsername() {
    if (lastUsernameChangeDate == null || lastUsernameChangeDate!.isEmpty) {
      return true;
    }

    try {
      final lastChange = DateTime.parse(lastUsernameChangeDate!);
      return DateTime.now().difference(lastChange).inDays >= 30;
    } catch (_) {
      return true;
    }
  }

  String _usernameChangeStatusText() {
    if (_canChangeUsername()) {
      return 'Available now';
    }

    try {
      final lastChange = DateTime.parse(lastUsernameChangeDate!);
      final nextDate = lastChange.add(const Duration(days: 30));
      return 'Available on ${DateFormat('MMM d, y').format(nextDate)}';
    } catch (_) {
      return 'Available in 30 days';
    }
  }

  void _showSnack(String message, {Color color = const Color(0xFFB2B9D1)}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.pixelifySans(fontWeight: FontWeight.bold),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _extractErrorMessage(Object error) {
    final raw = error.toString();
    if (raw.startsWith('Exception: ')) {
      return raw.substring('Exception: '.length);
    }
    return raw;
  }

  Future<void> _showEditMenu() async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFD9D9D9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.black, width: 3),
        ),
        title: Text(
          'Edit Profile',
          textAlign: TextAlign.center,
          style: GoogleFonts.pixelifySans(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isPublicProfile) ...[
                _buildActionButton(
                  label: 'Change Profile Picture',
                  icon: Icons.photo_library_outlined,
                  onTap: () {
                    Navigator.pop(ctx);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) _changeProfilePicture();
                    });
                  },
                ),
                const SizedBox(height: 8),
                _buildActionButton(
                  label: _canChangeUsername()
                      ? 'Change Username'
                      : 'Change Username (${_usernameChangeStatusText()})',
                  icon: Icons.badge,
                  enabled: _canChangeUsername(),
                  onTap: () {
                    Navigator.pop(ctx);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) _showUsernameDialog();
                    });
                  },
                ),
                const SizedBox(height: 8),
                _buildActionButton(
                  label: 'Change Password',
                  icon: Icons.lock,
                  onTap: () {
                    Navigator.pop(ctx);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) _showPasswordDialog();
                    });
                  },
                ),
                const SizedBox(height: 8),
                _buildActionButton(
                  label: 'Change Gmail',
                  icon: Icons.email,
                  onTap: () {
                    Navigator.pop(ctx);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) _showEmailDialog();
                    });
                  },
                ),
                const SizedBox(height: 8),
                _buildActionButton(
                  label: 'Reset Account',
                  icon: Icons.restart_alt,
                  onTap: () {
                    Navigator.pop(ctx);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) _confirmResetAccount();
                    });
                  },
                ),
                const SizedBox(height: 8),
                _buildActionButton(
                  label: 'Logout',
                  icon: Icons.logout,
                  onTap: () {
                    Navigator.pop(ctx);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) _confirmLogout();
                    });
                  },
                ),
              ] else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'This profile is public. Private actions are hidden.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.pixelifySans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black, width: 2),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.black, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.pixelifySans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showUsernameDialog() async {
    await _showProfileEditDialog(
      title: 'Change Username',
      label: 'New Username',
      helperText: 'You can only change your username once every 30 days.',
      initialValue: username,
      keyboardType: TextInputType.text,
      submit: _submitUsernameChange,
    );
  }

  Future<void> _showPasswordDialog() async {
    await _showProfileEditDialog(
      title: 'Change Password',
      label: 'New Password',
      helperText: 'Enter a new password for this account.',
      initialValue: '',
      keyboardType: TextInputType.visiblePassword,
      obscureText: true,
      submit: _submitPasswordChange,
    );
  }

  Future<void> _showEmailDialog() async {
    await _showProfileEditDialog(
      title: 'Change Gmail',
      label: 'New Gmail',
      helperText: 'This will update the email used for your account.',
      initialValue: email,
      keyboardType: TextInputType.emailAddress,
      submit: _submitEmailChange,
    );
  }

  Future<void> _changeProfilePicture() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      _showSnack('Could not read that image.', color: Colors.redAccent);
      return;
    }

    const maxBytes = 2 * 1024 * 1024;
    if (bytes.lengthInBytes > maxBytes) {
      _showSnack('Pick an image smaller than 2 MB.', color: Colors.redAccent);
      return;
    }

    final response = await http.put(
      Uri.parse('http://localhost:8000/update-profile-picture/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'profile_picture': base64Encode(bytes)}),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _showSnack(
        data['detail'] ?? 'Failed to update profile picture.',
        color: Colors.redAccent,
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      profilePictureBytes = bytes;
    });
    _showSnack('Profile picture updated.');
  }

  Future<void> _showProfileEditDialog({
    required String title,
    required String label,
    required String initialValue,
    required TextInputType keyboardType,
    required Future<String> Function(String value) submit,
    String? helperText,
    bool obscureText = false,
  }) async {
    final controller = TextEditingController(text: initialValue);
    String? errorText;
    bool isSaving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFFD9D9D9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Colors.black, width: 3),
            ),
            title: Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.pixelifySans(fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: 320,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (helperText != null) ...[
                    Text(
                      helperText,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.pixelifySans(fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: controller,
                    obscureText: obscureText,
                    keyboardType: keyboardType,
                    decoration: InputDecoration(
                      labelText: label,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      errorText!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.pixelifySans(
                        fontSize: 12,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(ctx),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.pixelifySans(fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton(
                      onPressed: isSaving
                    ? null
                    : () async {
                        final value = controller.text.trim();
                        final navigator = Navigator.of(ctx);
                        final messenger = ScaffoldMessenger.of(context);
                        if (value.isEmpty) {
                          setDialogState(() {
                            errorText = '$label cannot be empty.';
                          });
                          return;
                        }

                        setDialogState(() {
                          isSaving = true;
                          errorText = null;
                        });

                        try {
                          final message = await submit(value);
                          if (!mounted) return;
                          navigator.pop();
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                message,
                                style: GoogleFonts.pixelifySans(fontWeight: FontWeight.bold),
                              ),
                              backgroundColor: const Color(0xFFB2B9D1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          setDialogState(() {
                            errorText = _extractErrorMessage(e);
                            isSaving = false;
                          });
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Colors.black, width: 2),
                ),
                child: Text(
                  isSaving ? 'Saving...' : 'Save',
                  style: GoogleFonts.pixelifySans(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    controller.dispose();
  }

  Future<String> _submitUsernameChange(String value) async {
    final response = await http.put(
      Uri.parse('http://localhost:8000/update-username/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': value}),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['detail'] ?? 'Failed to update username.');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (mounted) {
      setState(() {
        username = (data['username'] as String?) ?? username;
        lastUsernameChangeDate = data['last_username_change_date'] as String?;
      });
    }
    return 'Username updated.';
  }

  Future<String> _submitPasswordChange(String value) async {
    final response = await http.put(
      Uri.parse('http://localhost:8000/update-password/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'password': value}),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['detail'] ?? 'Failed to update password.');
    }
    return 'Password updated.';
  }

  Future<String> _submitEmailChange(String value) async {
    final response = await http.put(
      Uri.parse('http://localhost:8000/update-email/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': value}),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['detail'] ?? 'Failed to update email.');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (mounted) {
      setState(() {
        email = (data['email'] as String?) ?? email;
      });
    }
    return 'Email updated.';
  }

  Future<void> _confirmResetAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFD9D9D9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.black, width: 3),
        ),
        title: Text(
          'RESET ACCOUNT?',
          textAlign: TextAlign.center,
          style: GoogleFonts.pixelifySans(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This will clear your progress, unlocked themes, streak, and scores.',
          textAlign: TextAlign.center,
          style: GoogleFonts.pixelifySans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.pixelifySans(fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              side: const BorderSide(color: Colors.black, width: 2),
            ),
            child: Text(
              'Reset',
              style: GoogleFonts.pixelifySans(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final response = await http.post(Uri.parse('http://localhost:8000/reset-account/$userId'));
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _showSnack(data['detail'] ?? 'Failed to reset account.');
      return;
    }

    await _loadProfileData();
    _showSnack('Account progress reset.');
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFD9D9D9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.black, width: 3),
        ),
        title: Text(
          'LOG OUT?',
          textAlign: TextAlign.center,
          style: GoogleFonts.pixelifySans(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'You will return to the login screen.',
          textAlign: TextAlign.center,
          style: GoogleFonts.pixelifySans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.pixelifySans(fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              side: const BorderSide(color: Colors.black, width: 2),
            ),
            child: Text(
              'Logout',
              style: GoogleFonts.pixelifySans(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  String _rankLabel() {
    return leaderboardRank > 0 ? "#$leaderboardRank" : "--";
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade400,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 24),
      ),
    );
  }

  Widget _buildMenuButton() {
    return GestureDetector(
      onTap: _showEditMenu,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.25),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.black, width: 1.5),
        ),
        child: const Icon(Icons.menu_rounded, color: Colors.black, size: 24),
      ),
    );
  }

  Widget _buildPanelHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFAEC6FF),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
        border: Border(bottom: BorderSide(color: Colors.black, width: 3)),
      ),
      child: Text(
        isPublicProfile ? 'PLAYER PROFILE' : 'PROFILE',
        textAlign: TextAlign.center,
        style: GoogleFonts.pixelifySans(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: const Color(0xFFFCA016),
          shadows: const [Shadow(offset: Offset(2, 2), color: Colors.black)],
        ),
      ),
    );
  }

  Widget _buildHeroCard(Color themeColor, bool isLandscape) {
    final String initial = username.trim().isNotEmpty ? username.trim()[0].toUpperCase() : '?';
    final bool hasRank = leaderboardRank > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: isLandscape
          ? Row(
              children: [
                _buildAvatar(themeColor, initial),
                const SizedBox(width: 16),
                Expanded(child: _buildHeroCopy(themeColor, hasRank)),
              ],
            )
          : Column(
              children: [
                _buildAvatar(themeColor, initial),
                const SizedBox(height: 14),
                _buildHeroCopy(themeColor, hasRank),
              ],
            ),
    );
  }

  Widget _buildAvatar(Color themeColor, String initial) {
    return Container(
      width: 86,
      height: 86,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: themeColor,
        border: Border.all(color: Colors.black, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(
        child: profilePictureBytes != null
            ? Image.memory(
                profilePictureBytes!,
                width: 86,
                height: 86,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Center(
                    child: Text(
                      initial,
                      style: GoogleFonts.pixelifySans(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              )
            : Center(
                child: Text(
                  initial,
                  style: GoogleFonts.pixelifySans(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeroCopy(Color themeColor, bool hasRank) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          username,
          style: GoogleFonts.pixelifySans(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            shadows: const [Shadow(offset: Offset(1, 1), color: Colors.white70)],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          hasRank
              ? 'Global Rank ${_rankLabel()} of $leaderboardTotalPlayers'
              : 'Global Rank unavailable',
          style: GoogleFonts.pixelifySans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildHeroChip(
              icon: Icons.star,
              label: 'Highest Score',
              value: highestScore.toString(),
              accent: const Color(0xFFFCA016),
            ),
            _buildHeroChip(
              icon: Icons.flag,
              label: 'Best Level',
              value: highestLevel.toString(),
              accent: const Color(0xFF3F51B5),
            ),
            _buildHeroChip(
              icon: Icons.palette,
              label: 'Theme',
              value: _themeLabel(selectedTheme),
              accent: themeColor,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroChip({
    required IconData icon,
    required String label,
    required String value,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.black),
          const SizedBox(width: 8),
          Text(
            '$label: $value',
            style: GoogleFonts.pixelifySans(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementBar() {
    final progress = (achievementCount / 10).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Achievement Progress',
                style: GoogleFonts.pixelifySans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Text(
                '$achievementCount / 10',
                style: GoogleFonts.pixelifySans(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFCA016),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Stack(
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black, width: 1.2),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF98EE99), Color(0xFFFCA016)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color accent,
  }) {
    return Container(
      height: 92,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black, width: 1.5),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.pixelifySans(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: GoogleFonts.pixelifySans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsWrap(bool isLandscape) {
    final cardWidth = isLandscape ? 190.0 : 150.0;

    final cards = <Widget>[
      _buildStatCard(
        label: 'Box Tapped',
        value: boxesTapped.toString(),
        icon: Icons.touch_app,
        accent: const Color(0xFFFCA016),
      ),
      _buildStatCard(
        label: 'Global Rank',
        value: _rankLabel(),
        icon: Icons.emoji_events,
        accent: const Color(0xFF4C7CF3),
      ),
      _buildStatCard(
        label: 'Levels Cleared',
        value: levelsCleared.toString(),
        icon: Icons.check_circle,
        accent: const Color(0xFF98EE99),
      ),
      _buildStatCard(
        label: 'Highest Level',
        value: highestLevel.toString(),
        icon: Icons.flag,
        accent: const Color(0xFFEF6C00),
      ),
      _buildStatCard(
        label: 'Achievements',
        value: achievementCount.toString(),
        icon: Icons.military_tech,
        accent: const Color(0xFF7E57C2),
      ),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: cards
          .map(
            (card) => SizedBox(
              width: cardWidth,
              child: card,
            ),
          )
          .toList(),
    );
  }

  Widget _buildInfoPanel(Color themeColor) {
    final details = <Widget>[
      _buildInfoRow('Username', username),
      if (!isPublicProfile) _buildInfoRow('Gmail', email.isEmpty ? 'N/A' : email),
      if (!isPublicProfile) _buildInfoRow('Name Change', _usernameChangeStatusText()),
      _buildInfoRow('Current Theme', _themeLabel(selectedTheme)),
      _buildInfoRow('Themes Owned', availableThemesCount.toString()),
      _buildInfoRow('Member Since', _formatDate(createdAt)),
      _buildInfoRow('Last Challenge', _formatDate(lastChallengeDate)),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile Details',
            style: GoogleFonts.pixelifySans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: themeColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: details,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.pixelifySans(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.pixelifySans(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Text(
          'Loading profile...',
          style: GoogleFonts.pixelifySans(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;
    final themeColor = parseThemeColor(selectedTheme);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: buildThemeDecoration(selectedTheme),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                left: 20,
                top: 20,
                child: _buildBackButton(),
              ),
              if (!isPublicProfile)
                Positioned(
                  right: 20,
                  top: 20,
                  child: _buildMenuButton(),
                ),
              Center(
                child: Container(
                  width: isLandscape ? screenWidth * 0.78 : screenWidth * 0.9,
                  height: isLandscape ? screenHeight * 0.82 : screenHeight * 0.84,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE59A5A),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.black, width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildPanelHeader(),
                      Expanded(
                        child: isLoading
                            ? _buildLoadingView()
                            : SingleChildScrollView(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    _buildHeroCard(themeColor, isLandscape),
                                    const SizedBox(height: 16),
                                    _buildAchievementBar(),
                                    const SizedBox(height: 16),
                                    _buildStatsWrap(isLandscape),
                                    const SizedBox(height: 16),
                                    _buildInfoPanel(themeColor),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
