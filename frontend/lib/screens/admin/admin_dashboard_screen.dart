import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/disaster_report.dart';
import '../../providers/auth_provider.dart';
import '../../providers/disaster_provider.dart';
import '../../providers/rescue_provider.dart';
import '../../widgets/kpi_card.dart';
import '../../widgets/severity_badge.dart';
import '../../widgets/priority_badge.dart';
import '../disaster/disaster_details_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAll();
    });
  }

  void _refreshAll() {
    final disaster = Provider.of<DisasterProvider>(context, listen: false);
    final rescue = Provider.of<RescueProvider>(context, listen: false);
    disaster.fetchDashboardSummary();
    disaster.fetchReports();
    rescue.fetchTeams();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final disaster = Provider.of<DisasterProvider>(context);
    final rescue = Provider.of<RescueProvider>(context);
    final summary = disaster.summary;
    final user = auth.currentUser;

    if (user?.isAdmin != true && user?.isRescueWorker != true) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Restricted'), backgroundColor: AppColors.secondary),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              '⚠️ Role Authorization Error\n\nThis command module is only accessible to Disaster Response Commanders and Rescue Officers.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: AppColors.severityCritical),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('🛡️ Emergency Operations Center', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: AppColors.secondary,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Operational KPIs'),
            Tab(text: 'Disaster Triage'),
            Tab(text: 'Team Assignment'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshAll),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Comprehensive KPI Overview
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Command Overview & Severity Breakdown',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.5,
                  children: [
                    KpiCard(
                      title: 'Critical P1 Cases',
                      value: '${summary.criticalCases}',
                      icon: Icons.warning_rounded,
                      color: AppColors.severityCritical,
                      subtitle: 'Requires immediate action',
                    ),
                    KpiCard(
                      title: 'High P2 Cases',
                      value: '${summary.highPriorityCases}',
                      icon: Icons.priority_high_rounded,
                      color: AppColors.severityHigh,
                      subtitle: 'Urgent response active',
                    ),
                    KpiCard(
                      title: 'Medium P3 Cases',
                      value: '${summary.mediumCases}',
                      icon: Icons.info_outline_rounded,
                      color: AppColors.severityMedium,
                    ),
                    KpiCard(
                      title: 'Low P4 Cases',
                      value: '${summary.lowCases}',
                      icon: Icons.check_circle_outline_rounded,
                      color: AppColors.severityLow,
                    ),
                    KpiCard(
                      title: 'Total Casualties',
                      value: '${summary.totalInjured}',
                      icon: Icons.healing_rounded,
                      color: AppColors.severityCritical,
                      subtitle: '${summary.peopleAffected} affected total',
                    ),
                    KpiCard(
                      title: 'Missing Persons',
                      value: '${summary.totalMissing}',
                      icon: Icons.person_search_rounded,
                      color: AppColors.severityHigh,
                      subtitle: 'Search & rescue active',
                    ),
                    KpiCard(
                      title: 'Active Rescue Crews',
                      value: '${summary.activeRescueTeams}',
                      icon: Icons.directions_boat_filled_rounded,
                      color: AppColors.statusInfo,
                      subtitle: '${summary.availableRescueTeams} units available',
                    ),
                    KpiCard(
                      title: 'Shelter Capacity',
                      value: '${summary.shelterSeatsAvailable}',
                      icon: Icons.night_shelter_rounded,
                      color: AppColors.statusSuccess,
                      subtitle: 'Free relief beds',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // Tab 2: Disaster Triage & Admin Status/Severity Management
          disaster.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: disaster.reports.length,
                  itemBuilder: (ctx, i) {
                    final report = disaster.reports[i];
                    return _buildTriageCard(context, report);
                  },
                ),

          // Tab 3: Rescue Team Assignment Matrix
          rescue.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: rescue.teams.length,
                  itemBuilder: (ctx, i) {
                    final team = rescue.teams[i];
                    return _buildTeamAssignmentCard(context, team, disaster.reports);
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildTriageCard(BuildContext context, DisasterReport report) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.forSeverity(report.severity).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${report.reportId} • ${report.disasterType}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              SeverityBadge(severity: report.severity),
            ],
          ),
          const SizedBox(height: 4),
          Text(report.locationDisplay, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Row(
            children: [
              PriorityBadge(priority: report.priority),
              const SizedBox(width: 8),
              Text('Status: ${report.status}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _showOverrideSeverityDialog(context, report),
                child: const Text('Override Severity', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 6),
              ElevatedButton(
                onPressed: () => _showUpdateReportStatusDialog(context, report),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: const Text('Update Status', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamAssignmentCard(BuildContext context, team, List<DisasterReport> reports) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(team.teamName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.forStatus(team.status).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(team.status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.forStatus(team.status))),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('Leader: ${team.leaderName} • ${team.membersCount} Crew Members', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Text(
            team.assignedDisaster != null
                ? 'Current Mission: ${team.assignedDisaster!['disaster_type']} (${team.assignedDisaster!['location']})'
                : 'Mission: Unassigned / Standing By',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: team.assignedDisaster != null ? AppColors.primary : AppColors.statusSuccess),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.assignment_turned_in_outlined, size: 16),
              label: const Text('Dispatch / Assign Mission', style: TextStyle(fontSize: 12)),
              onPressed: () => _showAssignTeamDialog(context, team, reports),
            ),
          ),
        ],
      ),
    );
  }

  void _showOverrideSeverityDialog(BuildContext context, DisasterReport report) {
    String newSeverity = report.severity;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text('Override Severity (${report.reportId})'),
            content: DropdownButtonFormField<String>(
              value: newSeverity,
              items: ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (val) {
                if (val != null) setDialogState(() => newSeverity = val);
              },
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  final disaster = Provider.of<DisasterProvider>(context, listen: false);
                  await disaster.overrideSeverity(report.id, newSeverity);
                  _refreshAll();
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showUpdateReportStatusDialog(BuildContext context, DisasterReport report) {
    String newStatus = report.status;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text('Update Status (${report.reportId})'),
            content: DropdownButtonFormField<String>(
              value: newStatus,
              items: ['Reported', 'Verified', 'Rescue in Progress', 'Resolved'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (val) {
                if (val != null) setDialogState(() => newStatus = val);
              },
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  final disaster = Provider.of<DisasterProvider>(context, listen: false);
                  await disaster.updateReportStatus(report.id, newStatus);
                  _refreshAll();
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAssignTeamDialog(BuildContext context, team, List<DisasterReport> reports) {
    if (reports.isEmpty) return;
    int selectedReportId = reports.first.id;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text('Assign ${team.teamName} to Incident'),
            content: DropdownButtonFormField<int>(
              value: selectedReportId,
              isExpanded: true,
              items: reports.map((r) {
                return DropdownMenuItem<int>(
                  value: r.id,
                  child: Text('${r.reportId}: ${r.disasterType} (${r.district}) - ${r.priority}', overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setDialogState(() => selectedReportId = val);
              },
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  final rescue = Provider.of<RescueProvider>(context, listen: false);
                  await rescue.assignTeam(team.id, selectedReportId);
                  _refreshAll();
                },
                child: const Text('Dispatch Team'),
              ),
            ],
          );
        },
      ),
    );
  }
}
