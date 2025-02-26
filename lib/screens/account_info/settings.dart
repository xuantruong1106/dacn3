import 'package:dacn3/screens/account_info/change_password.dart';
import 'package:dacn3/screens/account_info/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _biometricEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(
          color: Colors.black,
          onPressed: () => Navigator.pop(context), 
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
            child: Text(
              'General',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          _buildListItem(
            title: 'Language',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'English',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
            onTap: () {},
          ),
          _buildListItem(
            title: 'My Profile',
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return const ProfileScreen();
              }));
            },
          ),
          _buildListItem(
            title: 'Contact Us',
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {},
          ),
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
            child: Text(
              'Security',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          _buildListItem(
            title: 'Change Password',
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return const ChangePasswordScreen();
              }));
            },
          ),
          _buildListItem(
            title: 'Privacy Policy',
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {},
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose what data you share with us',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                _buildListItem(
                  title: 'Biometric',
                  trailing: CupertinoSwitch(
                    value: _biometricEnabled,
                    onChanged: (value) {
                      setState(() {
                        _biometricEnabled = value;
                      });
                    },
                    activeTrackColor: Colors.blue,
                  ),
                  onTap: () {
                    setState(() {
                      _biometricEnabled = !_biometricEnabled;
                    });
                  },
                  showBorder: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem({
    required String title,
    required Widget trailing,
    required VoidCallback onTap,
    bool showBorder = true,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: trailing,
          onTap: onTap,
        ),
        if (showBorder)
          const Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
          ),
      ],
    );
  }
}
