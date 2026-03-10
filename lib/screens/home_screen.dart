// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart'; // MODIFIKASI: Import package
import '../models/user.dart';
import 'dashboard_home_screen.dart';
import 'unit_assets/unit_assets_screen.dart';
import 'update_job/update_job_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import 'admin_dashboard_screen.dart';
import 'deepseek/deepseek_chat_screen.dart';
import '../constants/colors.dart';
import '../widgets/custom_app_bar.dart';

class HomeScreen extends StatefulWidget {
  final User user;
  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late List<Widget> _pages;
  
  // MODIFIKASI: Variable untuk app version
  String _appVersion = '';
  String _buildNumber = '';
  String _appName = '';

  @override
  void initState() {
    super.initState();
    _pages = [
      DashboardHomeScreen(user: widget.user),
      UnitAssetsScreen(user: widget.user),
      UpdateJobScreen(user: widget.user),
      ProfileScreen(user: widget.user),
    ];
    _loadAppVersion(); // MODIFIKASI: Load version saat init
  }

  // MODIFIKASI: Method untuk load app version
  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = packageInfo.version;
          _buildNumber = packageInfo.buildNumber;
          _appName = packageInfo.appName;
        });
      }
    } catch (e) {
      // Fallback jika gagal load
      setState(() {
        _appVersion = '1.2.0';
        _buildNumber = '1';
        _appName = 'DRR Sakti';
      });
    }
  }

  void _performLogout(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.logout, color: AppColors.error),
              SizedBox(width: 8),
              Text('Konfirmasi Logout'),
            ],
          ),
          content: Text(
            'Apakah Anda yakin ingin logout dari akun ${widget.user.name}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Batal',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performLogout(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return CustomAppBar(
      title: 'DRR Sakti',
      subtitle: '${widget.user.name} • ${widget.user.branch}',
      actions: [UserRoleBadge(role: widget.user.statusUser)],
    );
  }

  void _openDeepSeek() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeepSeekChatScreen(
          userId: widget.user.id.toString(),
        ),
      ),
    );
  }

  Drawer _buildDrawer() {
    bool canAccessAdmin = widget.user.isSuperAdmin || widget.user.isCoordinator;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primary),
            accountName: Text(
              widget.user.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            accountEmail: Text(
              '${_formatRole(widget.user.statusUser)} • ${widget.user.branch}',
              style: const TextStyle(fontSize: 14),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                widget.user.name.isNotEmpty
                    ? widget.user.name[0].toUpperCase()
                    : 'U',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.dashboard, color: Colors.blue),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedIndex = 0);
            },
          ),
          ListTile(
            leading: const Icon(Icons.inventory_2, color: Colors.blue),
            title: const Text('Unit Assets'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedIndex = 1);
            },
          ),
          ListTile(
            leading: const Icon(Icons.build_circle, color: Colors.orange),
            title: const Text('Update Jobs'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedIndex = 2);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person, color: Colors.teal),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedIndex = 3);
            },
          ),

          if (canAccessAdmin)
            ListTile(
              leading: const Icon(
                Icons.admin_panel_settings,
                color: AppColors.warning,
              ),
              title: const Text(
                'Admin Dashboard',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withAlpha(51),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Admin',
                  style: TextStyle(
                    color: AppColors.warning,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AdminDashboardScreen(user: widget.user),
                  ),
                );
              },
            ),

          const Divider(thickness: 1),

          // AI Assistant Menu
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withAlpha(77),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
            ),
            title: const Row(
              children: [
                Text(
                  'AI Assistant',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                SizedBox(width: 8),
                Icon(Icons.stars, size: 16, color: Colors.amber),
              ],
            ),
            subtitle: const Text(
              'Tanya tentang unit, battery, jobs',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade600],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'NEW',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onTap: _openDeepSeek,
          ),

          const Divider(thickness: 1),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
            onTap: () {
              Navigator.pop(context);
              _handleLogout();
            },
          ),
          const Divider(),
          
          // MODIFIKASI: About menu dengan icon info
          ListTile(
            leading: const Icon(Icons.info_outline, color: AppColors.disabled),
            title: const Text('About'),
            subtitle: Text(
              _appVersion.isEmpty 
                  ? 'Loading...' 
                  : 'Version $_appVersion',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            onTap: () {
              Navigator.pop(context);
              _showAboutDialog();
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _formatRole(String status) {
    switch (status.toLowerCase()) {
      case 'superadmin':
      case 'admin drr':
        return 'Super Admin';
      case 'koordinator':
        return 'Koordinator';
      case 'field service':
        return 'Field Service';
      case 'fmc':
        return 'FMC';
      default:
        return status;
    }
  }

  // MODIFIKASI: About dialog dengan data dinamis
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.info_outline,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(_appName.isEmpty ? 'DRR Sakti' : _appName),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // MODIFIKASI: App info dengan data dinamis
            _buildInfoRow('Version', _appVersion.isEmpty ? '1.2.0' : _appVersion),
            const SizedBox(height: 8),
            _buildInfoRow('Build', _buildNumber.isEmpty ? '1' : _buildNumber),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'DRR Unit Assets Management System',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              '© 2025 DRR SAKTI',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // MODIFIKASI: Helper method untuk info row
  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: _pages[_selectedIndex],
    );
  }
}