import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/api_constants.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _urlController = TextEditingController();
  bool _isTesting = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    _urlController.text = ApiConstants.baseUrl;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testAndSaveServerUrl() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    final newUrl = _urlController.text.trim();
    await ApiService().updateBaseUrl(newUrl);

    final res = await ApiService().get(ApiConstants.dashboardSummary);

    setState(() {
      _isTesting = false;
      if (res['success'] == true) {
        _testResult = '✅ Connected successfully to Flask Backend!';
      } else {
        _testResult = '❌ Connection failed: ${res['message']}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('⚙️ Settings & Configuration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: AppColors.secondary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Profile Section
            if (user != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primary.withOpacity(0.12),
                      child: const Icon(Icons.person, color: AppColors.primary, size: 32),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                          const SizedBox(height: 2),
                          Text(user.email, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(user.roleDisplay, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Backend Server Configuration
            const Text(
              'Backend API Server Connection',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Configure the Flask backend address for testing on Emulator (10.0.2.2), Web/Desktop (localhost), or LAN Phone IP.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      labelText: 'Flask Server Base URL',
                      hintText: 'http://localhost:5000',
                      prefixIcon: Icon(Icons.dns_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Quick presets
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _buildPresetChip('Localhost (Desktop/Web)', 'http://localhost:5000'),
                      _buildPresetChip('Android Emulator', 'http://10.0.2.2:5000'),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (_testResult != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _testResult!.startsWith('✅') ? AppColors.statusSuccess.withOpacity(0.1) : AppColors.severityCritical.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _testResult!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _testResult!.startsWith('✅') ? AppColors.statusSuccess : AppColors.severityCritical,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isTesting ? null : _testAndSaveServerUrl,
                      icon: _isTesting
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.cloud_sync_outlined, size: 18),
                      label: const Text('Test Connection & Save URL'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // System Information
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('System Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  SizedBox(height: 8),
                  Text('Project: AI-Based Disaster Response Assistant', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  Text('ML Engine: Decision Tree Algorithm (Scikit-Learn)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  Text('Backend: Python Flask + MySQL', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  Text('Frontend: Flutter Mobile Application', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  Text('Authentication: Firebase / Role-Based Authorization', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Logout Button
            if (user != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmLogout(context),
                  icon: const Icon(Icons.logout_rounded, color: AppColors.severityCritical),
                  label: const Text('LOGOUT FROM ACCOUNT', style: TextStyle(color: AppColors.severityCritical, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.severityCritical),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String title, String url) {
    return ActionChip(
      label: Text(title, style: const TextStyle(fontSize: 11)),
      onPressed: () => setState(() => _urlController.text = url),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out of your disaster assistant session?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final auth = Provider.of<AuthProvider>(context, listen: false);
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.severityCritical),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
