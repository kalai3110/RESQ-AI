import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/rescue_team.dart';
import '../../providers/auth_provider.dart';
import '../../providers/rescue_provider.dart';
import '../../widgets/empty_state_widget.dart';

class RescueTeamScreen extends StatefulWidget {
  const RescueTeamScreen({super.key});

  @override
  State<RescueTeamScreen> createState() => _RescueTeamScreenState();
}

class _RescueTeamScreenState extends State<RescueTeamScreen> {
  String _selectedStatusFilter = 'All';
  final List<String> _filterOptions = ['All', 'Available', 'Assigned', 'Preparing', 'On the Way', 'Reached', 'Completed'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTeams();
    });
  }

  void _loadTeams() {
    final rescue = Provider.of<RescueProvider>(context, listen: false);
    rescue.fetchTeams(status: _selectedStatusFilter == 'All' ? null : _selectedStatusFilter);
  }

  @override
  Widget build(BuildContext context) {
    final rescue = Provider.of<RescueProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final canManage = user?.isAdmin == true || user?.isRescueWorker == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('🚑 Rescue Team Deployments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: AppColors.secondary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTeams,
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Filters Horizontal Bar
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            color: Colors.white,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _filterOptions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final status = _filterOptions[i];
                final isSelected = _selectedStatusFilter == status;
                return ChoiceChip(
                  label: Text(status, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  selected: isSelected,
                  selectedColor: AppColors.primary.withOpacity(0.15),
                  labelStyle: TextStyle(color: isSelected ? AppColors.primary : AppColors.textSecondary),
                  onSelected: (val) {
                    if (val) {
                      setState(() => _selectedStatusFilter = status);
                      _loadTeams();
                    }
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),

          // Rescue Teams List
          Expanded(
            child: rescue.isLoading
                ? const Center(child: CircularProgressIndicator())
                : rescue.teams.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.directions_boat_outlined,
                        title: 'No Rescue Teams Found',
                        message: 'No rescue teams currently match the selected status filter.',
                      )
                    : RefreshIndicator(
                        onRefresh: () async => _loadTeams(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(14),
                          itemCount: rescue.teams.length,
                          itemBuilder: (ctx, i) {
                            final team = rescue.teams[i];
                            return _buildTeamCard(context, team, canManage);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamCard(BuildContext context, RescueTeam team, bool canManage) {
    final statusColor = AppColors.forStatus(team.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Team Header & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.shield_outlined, color: statusColor, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          team.teamName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                        ),
                        Text(
                          '${team.leaderName} (Leader) • ${team.membersCount} Crew',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    team.status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Assigned Disaster Mission Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.campaign_outlined, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        team.assignedDisaster != null
                            ? 'Mission: ${team.assignedDisaster!['disaster_type']} – ${team.assignedDisaster!['location']}'
                            : 'Status: On Standby / Available for Deployment',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: team.assignedDisaster != null ? AppColors.primary : AppColors.statusSuccess,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.near_me_outlined, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Location: ${team.currentLocation}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Status Step Progression Timeline
            if (team.isActive) ...[
              const Text('Deployment Lifecycle:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
              const SizedBox(height: 6),
              _buildStepProgress(team.status),
              const SizedBox(height: 8),
            ],

            // Manage Actions (Admin / Rescue)
            if (canManage) ...[
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.edit_location_alt_outlined, size: 16),
                    label: const Text('Update Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    onPressed: () => _showStatusUpdateDialog(context, team),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStepProgress(String currentStatus) {
    final stages = ['Assigned', 'Preparing', 'On the Way', 'Reached', 'Completed'];
    int currentIndex = stages.indexOf(currentStatus);
    if (currentIndex == -1) currentIndex = 0;

    return Row(
      children: List.generate(stages.length * 2 - 1, (i) {
        if (i % 2 == 1) {
          final stepIndex = i ~/ 2;
          return Expanded(
            child: Container(
              height: 3,
              color: stepIndex < currentIndex ? AppColors.statusSuccess : AppColors.border,
            ),
          );
        } else {
          final stepIndex = i ~/ 2;
          final isCompleted = stepIndex <= currentIndex;
          final isCurrent = stepIndex == currentIndex;

          return Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: isCompleted ? (isCurrent ? AppColors.primary : AppColors.statusSuccess) : AppColors.surfaceElevated,
              shape: BoxShape.circle,
              border: Border.all(
                color: isCompleted ? Colors.transparent : AppColors.border,
                width: 1.5,
              ),
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : Text('${stepIndex + 1}', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
            ),
          );
        }
      }),
    );
  }

  void _showStatusUpdateDialog(BuildContext context, RescueTeam team) {
    String newStatus = team.status;
    final locController = TextEditingController(text: team.currentLocation);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text('Update ${team.teamName}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Operational Status:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: newStatus,
                  decoration: const InputDecoration(filled: true, fillColor: Colors.white),
                  items: ['Available', 'Assigned', 'Preparing', 'On the Way', 'Reached', 'Completed'].map((s) {
                    return DropdownMenuItem(value: s, child: Text(s));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => newStatus = val);
                  },
                ),
                const SizedBox(height: 12),
                const Text('Current Location:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: locController,
                  decoration: const InputDecoration(hintText: 'e.g. En route to Madurai Sector 4'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  final rescue = Provider.of<RescueProvider>(context, listen: false);
                  await rescue.updateTeamStatus(team.id, newStatus, currentLocation: locController.text);
                  _loadTeams();
                },
                child: const Text('Save Status'),
              ),
            ],
          );
        },
      ),
    );
  }
}
