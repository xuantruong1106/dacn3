import 'package:dacn3/connect/database_connect.dart';
import 'package:dacn3/screens/account_info/change_password.dart';
import 'package:dacn3/screens/account_info/edit_profile.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends StatefulWidget {
  final int userId;
  const SettingsScreen({super.key, required this.userId});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  bool _biometricEnabled = false;
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _isLoading = true;
  late List<Map<String, dynamic>> dataUser;

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    dataUser = [];

    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    // Start the animation
    _animationController.forward();

    _loadData();
  }

  Future<void> _loadData() async {
    try {
      await getInfoUser();
    } finally {
      setState(() {
        _isLoading = false;
      });
      _animationController.forward();
    }
  }

  Future<void> getInfoUser() async {
    try {
      await DatabaseConnection().connect();
      final results = await DatabaseConnection().executeQuery(
        'SELECT * FROM get_user_and_card_info(@id);',
        substitutionValues: {'id': widget.userId},
      );

      if (results.isNotEmpty) {
        setState(() {
          dataUser = results
              .map((row) => {
                    'username': row[0],
                    'phone': row[1],
                    'address': row[2],
                    'card_number': row[3],
                    'cvv': row[4],
                    'expiration_date': row[5]
                        .toString()
                        .substring(0, 10)
                        .split('-')
                        .reversed
                        .join('/'),
                    'total_amount': row[6],
                  })
              .toList();
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load user data');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Settings',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            color: const Color(0xFF4B5B98),
            onPressed: () {},
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Profile Section
              _buildProfileSection(),

              const SizedBox(height: 24),

              // General Settings
              _buildSettingsSection(
                title: 'General',
                children: [
                  // _buildSettingItem(
                  //   icon: Icons.language_rounded,
                  //   title: 'Language',
                  //   trailing: Row(
                  //     mainAxisSize: MainAxisSize.min,
                  //     children: [
                  //       Text(
                  //         'English',
                  //         style: GoogleFonts.inter(
                  //           color: Colors.grey[600],
                  //           fontSize: 14,
                  //         ),
                  //       ),
                  //       const SizedBox(width: 8),
                  //       Icon(Icons.chevron_right_rounded,
                  //           color: Colors.grey[400]),
                  //     ],
                  //   ),
                  //   onTap: () {},
                  // ),
                  _buildSettingItem(
                    icon: Icons.person_rounded,
                    title: 'My Profile',
                    trailing: Icon(Icons.chevron_right_rounded,
                        color: Colors.grey[400]),
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/editprofile',
                          arguments: widget.userId);
                    },
                  ),
                  // _buildSettingItem(
                  //   icon: Icons.support_agent_rounded,
                  //   title: 'Contact Us',
                  //   trailing: Icon(Icons.chevron_right_rounded,
                  //       color: Colors.grey[400]),
                  //   onTap: () {},
                  //   showDivider: false,
                  // ),
                ],
              ),

              const SizedBox(height: 24),

              // Security Settings
              _buildSettingsSection(
                title: 'Security',
                children: [
                  _buildSettingItem(
                    icon: Icons.lock_rounded,
                    title: 'Change Password',
                    trailing: Icon(Icons.chevron_right_rounded,
                        color: Colors.grey[400]),
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/changepassword',
                          arguments: widget.userId);
                    },
                  ),
                  // _buildSettingItem(
                  //   icon: Icons.fingerprint_rounded,
                  //   title: 'Biometric Authentication',
                  //   trailing: Switch(
                  //     value: _biometricEnabled,
                  //     onChanged: (value) {
                  //       setState(() {
                  //         _biometricEnabled = value;
                  //       });
                  //     },
                  //     activeColor: Colors.white,
                  //     activeTrackColor: const Color(0xFF4B5B98),
                  //     inactiveThumbColor: Colors.white,
                  //     inactiveTrackColor: Colors.grey[300],
                  //   ),
                  //   onTap: () {
                  //     setState(() {
                  //       _biometricEnabled = !_biometricEnabled;
                  //     });
                  //   },
                  // ),
                  // _buildSettingItem(
                  //   icon: Icons.privacy_tip_rounded,
                  //   title: 'Privacy Policy',
                  //   trailing: Icon(Icons.chevron_right_rounded,
                  //       color: Colors.grey[400]),
                  //   onTap: () {},
                  //   showDivider: false,
                  // ),
                ],
              ),

              const SizedBox(height: 24),

              // // Preferences
              // _buildSettingsSection(
              //   title: 'Preferences',
              //   children: [
              //     _buildSettingItem(
              //       icon: Icons.notifications_rounded,
              //       title: 'Notifications',
              //       trailing: Switch(
              //         value: _notificationsEnabled,
              //         onChanged: (value) {
              //           setState(() {
              //             _notificationsEnabled = value;
              //           });
              //         },
              //         activeColor: Colors.white,
              //         activeTrackColor: const Color(0xFF4B5B98),
              //         inactiveThumbColor: Colors.white,
              //         inactiveTrackColor: Colors.grey[300],
              //       ),
              //       onTap: () {
              //         setState(() {
              //           _notificationsEnabled = !_notificationsEnabled;
              //         });
              //       },
              //     ),
              //     _buildSettingItem(
              //       icon: Icons.dark_mode_rounded,
              //       title: 'Dark Mode',
              //       trailing: Switch(
              //         value: _darkModeEnabled,
              //         onChanged: (value) {
              //           setState(() {
              //             _darkModeEnabled = value;
              //           });
              //         },
              //         activeColor: Colors.white,
              //         activeTrackColor: const Color(0xFF4B5B98),
              //         inactiveThumbColor: Colors.white,
              //         inactiveTrackColor: Colors.grey[300],
              //       ),
              //       onTap: () {
              //         setState(() {
              //           _darkModeEnabled = !_darkModeEnabled;
              //         });
              //       },
              //       showDivider: false,
              //     ),
              //   ],
              // ),

              // const SizedBox(height: 24),

              // About Section
              _buildSettingsSection(
                title: 'About',
                children: [
                  _buildSettingItem(
                    icon: Icons.info_rounded,
                    title: 'App Version',
                    trailing: Text(
                      '1.0.0',
                      style: GoogleFonts.inter(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    onTap: () {},
                    showDivider: false,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Logout Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/sign_in');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[50],
                    foregroundColor: Colors.red[700],
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Log Out',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF4B5B98).withOpacity(0.1),
              image: const DecorationImage(
                image: AssetImage('assets/user.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dataUser.isNotEmpty ? dataUser[0]['username'] : '',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dataUser.isNotEmpty ? dataUser[0]['phone'] : '',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            color: const Color(0xFF4B5B98),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/editprofile',
                  arguments: widget.userId);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 12),
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required Widget trailing,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: showDivider
              ? const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                )
              : BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4B5B98).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF4B5B98),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
                trailing,
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            indent: 76,
            endIndent: 20,
          ),
      ],
    );
  }
}
