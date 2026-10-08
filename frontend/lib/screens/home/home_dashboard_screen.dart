import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/disaster_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/kpi_card.dart';
import '../disaster/report_disaster_screen.dart';
import '../disaster/my_reports_screen.dart';
import '../disaster/disaster_map_screen.dart';
import '../rescue/rescue_team_screen.dart';
import '../shelter/shelter_screen.dart';
import '../medical/medical_assistance_screen.dart';
import '../relief/relief_resources_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../notifications/notifications_screen.dart';
import '../settings/settings_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final disaster = Provider.of<DisasterProvider>(context, listen: false);
    final notif = Provider.of<NotificationProvider>(context, listen: false);

    disaster.fetchDashboardSummary();
    disaster.fetchReports();
    if (auth.currentUser != null) {
      disaster.fetchMyReports(auth.currentUser!.id);
      notif.fetchNotifications(userId: auth.currentUser!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final disaster = Provider.of<DisasterProvider>(context);
    final notif = Provider.of<NotificationProvider>(context);
    final summary = disaster.summary;
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shield_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Disaster Response Assistant',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    'AI-Powered Emergency Management',
                    style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Notifications Action with Badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                tooltip: 'Notifications',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  ).then((_) => _loadData());
                },
              ),
              if (notif.unreadCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.severityCritical,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${notif.unreadCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ).then((_) => _loadData());
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Greeting Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.secondary, AppColors.secondaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primary.withOpacity(0.25),
                      child: const Icon(Icons.person, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, ${user?.name ?? "Officer"}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.primary.withOpacity(0.5)),
                            ),
                            child: Text(
                              user?.roleDisplay ?? 'Citizen Reporter',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Summary KPI Cards Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Incident Overview & KPIs',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  Text(
                    'Live Updates',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.statusSuccess),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 8 Summary Cards Grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  KpiCard(
                    title: 'Total Disaster Reports',
                    value: '${summary.totalDisasterReports}',
                    icon: Icons.report_problem_rounded,
                    color: AppColors.primary,
                    subtitle: 'Incidents logged',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyReportsScreen())),
                  ),
                  KpiCard(
                    title: 'Critical Cases (P1)',
                    value: '${summary.criticalCases}',
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.severityCritical,
                    subtitle: 'Immediate Response',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyReportsScreen())),
                  ),
                  KpiCard(
                    title: 'High Priority Cases (P2)',
                    value: '${summary.highPriorityCases}',
                    icon: Icons.priority_high_rounded,
                    color: AppColors.severityHigh,
                    subtitle: 'Very Urgent Response',
                  ),
                  KpiCard(
                    title: 'People Affected',
                    value: '${summary.peopleAffected}',
                    icon: Icons.groups_rounded,
                    color: AppColors.accent,
                    subtitle: '${summary.totalInjured} injured, ${summary.totalMissing} missing',
                  ),
                  KpiCard(
                    title: 'Active Rescue Teams',
                    value: '${summary.activeRescueTeams} / ${summary.totalRescueTeams}',
                    icon: Icons.health_and_safety_rounded,
                    color: AppColors.statusInfo,
                    subtitle: '${summary.availableRescueTeams} available units',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RescueTeamScreen())),
                  ),
                  KpiCard(
                    title: 'Available Shelters',
                    value: '${summary.availableShelters}',
                    icon: Icons.night_shelter_rounded,
                    color: AppColors.statusSuccess,
                    subtitle: '${summary.shelterSeatsAvailable} seats free',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ShelterScreen())),
                  ),
                  KpiCard(
                    title: 'Medical Assistance Req.',
                    value: '${summary.medicalAssistanceRequired}',
                    icon: Icons.medical_services_rounded,
                    color: AppColors.severityCritical,
                    subtitle: '${summary.ambulanceRequests} ambulances needed',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MedicalAssistanceScreen())),
                  ),
                  KpiCard(
                    title: 'Relief Resources',
                    value: '${summary.availableResourcesCount}',
                    icon: Icons.inventory_2_rounded,
                    color: AppColors.statusWarning,
                    subtitle: '${summary.reliefResourcesCount} categories tracked',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReliefResourcesScreen())),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Emergency Dispatch Action Modules Header
              const Text(
                'Emergency Response Modules',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),

              // 7 Navigation Module Tiles
              _buildModuleTile(
                title: '🚨 Report Disaster',
                subtitle: 'Submit incident report, upload photo & get instant AI severity prediction',
                icon: Icons.emergency_rounded,
                color: AppColors.primary,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReportDisasterScreen())),
              ),
              _buildModuleTile(
                title: '🚑 Rescue Team Status',
                subtitle: 'Track deployed rescue units, lifecycle & operational assignments',
                icon: Icons.directions_boat_filled_rounded,
                color: AppColors.statusInfo,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RescueTeamScreen())),
              ),
              _buildModuleTile(
                title: '🏕️ Shelter Availability',
                subtitle: 'View relief shelters, available seats, food, water & medical amenities',
                icon: Icons.night_shelter_rounded,
                color: AppColors.statusSuccess,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ShelterScreen())),
              ),
              _buildModuleTile(
                title: '🏥 Medical Assistance',
                subtitle: 'Emergency triage requests, ambulance dispatch & critical medical aid',
                icon: Icons.local_hospital_rounded,
                color: AppColors.severityCritical,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MedicalAssistanceScreen())),
              ),
              _buildModuleTile(
                title: '📦 Relief Resources',
                subtitle: 'Monitor stock levels for food packets, water, medicines & rescue tools',
                icon: Icons.inventory_rounded,
                color: AppColors.severityHigh,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReliefResourcesScreen())),
              ),
              _buildModuleTile(
                title: '🗺️ Disaster Map',
                subtitle: 'Interactive map with severity-coded color markers (Green, Yellow, Orange, Red)',
                icon: Icons.map_rounded,
                color: AppColors.accent,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DisasterMapScreen())),
              ),
              _buildModuleTile(
                title: '📜 My Reports & History',
                subtitle: 'View previously submitted disaster incident reports & AI priority status',
                icon: Icons.history_edu_rounded,
                color: AppColors.secondaryLight,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyReportsScreen())),
              ),

              // Admin / Rescue Command Center Button (if authorized role)
              if (user?.isAdmin == true || user?.isRescueWorker == true) ...[
                const SizedBox(height: 8),
                _buildModuleTile(
                  title: '🛡️ Admin / Rescue Command Center',
                  subtitle: 'Operational control hub: assign teams, triage reports, manage resources',
                  icon: Icons.admin_panel_settings_rounded,
                  color: AppColors.secondary,
                  isHighlighted: true,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminDashboardScreen())),
                ),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReportDisasterScreen()));
          } else if (index == 2) {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DisasterMapScreen()));
          } else if (index == 3) {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyReportsScreen()));
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.add_alert_rounded), label: 'Report'),
          BottomNavigationBarItem(icon: Icon(Icons.map_rounded), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt_rounded), label: 'My Reports'),
        ],
      ),
    );
  }

  Widget _buildModuleTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isHighlighted = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isHighlighted ? AppColors.secondary : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isHighlighted ? AppColors.primary : AppColors.border,
          width: isHighlighted ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isHighlighted ? AppColors.primary : color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: isHighlighted ? Colors.white : color, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isHighlighted ? Colors.white : AppColors.textPrimary,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3.0),
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: isHighlighted ? AppColors.textMuted : AppColors.textSecondary,
            ),
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: isHighlighted ? Colors.white70 : AppColors.textSecondary,
        ),
      ),
    );
  }
}
