import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../models/disaster_report.dart';
import '../../providers/auth_provider.dart';
import '../../providers/disaster_provider.dart';
import '../../widgets/severity_badge.dart';
import '../../widgets/priority_badge.dart';
import '../../widgets/empty_state_widget.dart';
import 'disaster_details_screen.dart';
import 'report_disaster_screen.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  void _fetchData() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final disaster = Provider.of<DisasterProvider>(context, listen: false);
    if (auth.currentUser != null) {
      disaster.fetchMyReports(auth.currentUser!.id);
      disaster.fetchReports(); // also fetch all reports
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final disaster = Provider.of<DisasterProvider>(context);
    final user = auth.currentUser;

    // If citizen, show their reports; if admin/rescue, show all with toggle
    final List<DisasterReport> displayList = (user?.isAdmin == true || user?.isRescueWorker == true)
        ? disaster.reports
        : (disaster.myReports.isNotEmpty ? disaster.myReports : disaster.reports);

    return Scaffold(
      appBar: AppBar(
        title: const Text('📜 Disaster Reports & History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: AppColors.secondary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchData,
          ),
        ],
      ),
      body: disaster.isLoading && displayList.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : displayList.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.assignment_outlined,
                  title: 'No Reports Found',
                  message: 'You have not submitted any disaster incident reports yet.',
                  actionText: 'Report a Disaster Now',
                  onAction: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ReportDisasterScreen()),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async => _fetchData(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: displayList.length,
                    itemBuilder: (ctx, i) {
                      final report = displayList[i];
                      return _buildReportCard(context, report);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ReportDisasterScreen()),
          ).then((_) => _fetchData());
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_alert_rounded, color: Colors.white),
        label: const Text('Report Disaster', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, DisasterReport report) {
    final rescueTeam = report.assignedTeams.isNotEmpty ? report.assignedTeams.join(', ') : 'Pending Assignment';
    final formattedDate = report.createdAt != null ? DateFormat('MMM dd, yyyy • hh:mm a').format(DateTime.parse(report.createdAt!)) : 'Recent';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.forSeverity(report.severity).withOpacity(0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => DisasterDetailsScreen(reportId: report.id)),
            );
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Report ID & Report Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Report ID: ${report.reportId}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.forStatus(report.status).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        report.status,
                        style: TextStyle(
                          color: AppColors.forStatus(report.status),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Disaster Type & Location
                Text(
                  '${report.disasterType} – ${report.locationDisplay}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  report.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),

                // Severity and Priority Badges
                Row(
                  children: [
                    SeverityBadge(severity: report.severity),
                    const SizedBox(width: 8),
                    PriorityBadge(priority: report.priority),
                    const Spacer(),
                    Text(
                      formattedDate,
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 8),

                // Rescue Team Status Line
                Row(
                  children: [
                    const Icon(Icons.directions_boat_filled_outlined, size: 16, color: AppColors.statusInfo),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Rescue Status: $rescueTeam',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textMuted),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
