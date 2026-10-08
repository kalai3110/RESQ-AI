import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../constants/api_constants.dart';
import '../../models/disaster_report.dart';
import '../../providers/disaster_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/severity_badge.dart';
import '../../widgets/priority_badge.dart';

class DisasterDetailsScreen extends StatefulWidget {
  final int reportId;

  const DisasterDetailsScreen({super.key, required this.reportId});

  @override
  State<DisasterDetailsScreen> createState() => _DisasterDetailsScreenState();
}

class _DisasterDetailsScreenState extends State<DisasterDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DisasterProvider>(context, listen: false).fetchReportDetail(widget.reportId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final disasterProvider = Provider.of<DisasterProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final report = disasterProvider.currentReport;

    if (disasterProvider.isLoading || report == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Report #DR-${widget.reportId}'), backgroundColor: AppColors.secondary),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final sevColor = AppColors.forSeverity(report.severity);

    return Scaffold(
      appBar: AppBar(
        title: Text('${report.reportId} – ${report.disasterType}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: AppColors.secondary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => disasterProvider.fetchReportDetail(widget.reportId),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // AI Severity & Priority Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: sevColor.withOpacity(0.5), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: sevColor.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.psychology_rounded, color: sevColor, size: 24),
                          const SizedBox(width: 8),
                          const Text(
                            'AI Decision Tree Analysis',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.forStatus(report.status).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          report.status,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.forStatus(report.status),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      SeverityBadge(severity: report.severity, isLarge: true),
                      const SizedBox(width: 10),
                      PriorityBadge(priority: report.priority),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Disaster: ${report.disasterType} • Location: ${report.locationDisplay}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Disaster Image Evidence
            if (report.imageUrl != null && report.imageUrl!.isNotEmpty) ...[
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    ApiConstants.imageUrl(report.imageUrl!),
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, _, __) => Container(
                      height: 140,
                      color: AppColors.surfaceElevated,
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.photo_library_outlined, size: 36, color: AppColors.textMuted),
                            SizedBox(height: 6),
                            Text('Disaster photo uploaded and verified on server', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // People Impact & Damage Statistics
            _buildSection(
              title: 'Impact & Damage Metrics',
              icon: Icons.analytics_outlined,
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildMetricTile('People Affected', '${report.peopleAffected}', Icons.groups, AppColors.accent),
                      const SizedBox(width: 10),
                      _buildMetricTile('Injured', '${report.injured}', Icons.healing, AppColors.severityCritical),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildMetricTile('Missing Persons', '${report.missing}', Icons.person_search, AppColors.severityHigh),
                      const SizedBox(width: 10),
                      _buildMetricTile('Urgent Help', '${report.immediateHelpRequired}', Icons.emergency, AppColors.severityCritical),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildDamageRow('Structural Damage Level', report.damageLevel),
                  _buildDamageRow('Property Damage', report.propertyDamage ? 'Reported (Active)' : 'None'),
                  _buildDamageRow('Infrastructure Damage', report.infrastructureDamage ? 'Reported (Active)' : 'None'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Incident Description & Address
            _buildSection(
              title: 'Location & Description',
              icon: Icons.pin_drop_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Address / Landmark:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                  const SizedBox(height: 3),
                  Text(report.address, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  if (report.description != null && report.description!.isNotEmpty) ...[
                    const Text('Field Description:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                    const SizedBox(height: 3),
                    Text(report.description!, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    'Reported by: ${report.reporterName} • ${report.createdAt != null ? DateFormat.yMMMd().add_jm().format(DateTime.parse(report.createdAt!)) : ""}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Assigned Rescue Teams
            _buildSection(
              title: 'Assigned Rescue Teams',
              icon: Icons.health_and_safety_outlined,
              child: report.rescueTeamsList != null && report.rescueTeamsList!.isNotEmpty
                  ? Column(
                      children: report.rescueTeamsList!.map((team) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.directions_boat_filled, color: AppColors.statusInfo),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(team.teamName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    Text('${team.leaderName} • ${team.membersCount} members', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.forStatus(team.status).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  team.status,
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.forStatus(team.status)),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    )
                  : const Text('No rescue team assigned yet. Dispatch pending.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ),
            const SizedBox(height: 16),

            // District Relief Shelters
            _buildSection(
              title: 'Nearby District Shelters',
              icon: Icons.night_shelter_outlined,
              child: report.districtShelters != null && report.districtShelters!.isNotEmpty
                  ? Column(
                      children: report.districtShelters!.map((s) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.shelterName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                    Text('${s.location} (${s.district})', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.forStatus(s.status).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text('${s.available} seats (${s.status})', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.forStatus(s.status))),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    )
                  : const Text('No shelters found in this district.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDamageRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
