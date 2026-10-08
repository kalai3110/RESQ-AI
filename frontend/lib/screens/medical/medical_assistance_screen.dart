import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/medical_request.dart';
import '../../providers/auth_provider.dart';
import '../../providers/medical_provider.dart';
import '../../widgets/priority_badge.dart';
import '../../widgets/severity_badge.dart';
import '../../widgets/empty_state_widget.dart';

class MedicalAssistanceScreen extends StatefulWidget {
  const MedicalAssistanceScreen({super.key});

  @override
  State<MedicalAssistanceScreen> createState() => _MedicalAssistanceScreenState();
}

class _MedicalAssistanceScreenState extends State<MedicalAssistanceScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Requested', 'Assigned', 'On the Way', 'Completed'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRequests();
    });
  }

  void _loadRequests() {
    final med = Provider.of<MedicalProvider>(context, listen: false);
    med.fetchRequests(status: _selectedFilter == 'All' ? null : _selectedFilter);
  }

  @override
  Widget build(BuildContext context) {
    final med = Provider.of<MedicalProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final canManage = user?.isAdmin == true || user?.isRescueWorker == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('🏥 Medical Assistance Dispatch', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: AppColors.secondary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRequests,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            color: Colors.white,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final status = _filters[i];
                final isSelected = _selectedFilter == status;
                return ChoiceChip(
                  label: Text(status, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  selected: isSelected,
                  selectedColor: AppColors.severityCritical.withOpacity(0.15),
                  labelStyle: TextStyle(color: isSelected ? AppColors.severityCritical : AppColors.textSecondary),
                  onSelected: (val) {
                    if (val) {
                      setState(() => _selectedFilter = status);
                      _loadRequests();
                    }
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),

          // Requests List
          Expanded(
            child: med.isLoading
                ? const Center(child: CircularProgressIndicator())
                : med.requests.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.medical_services_outlined,
                        title: 'No Medical Requests',
                        message: 'No emergency medical assistance requests currently active.',
                      )
                    : RefreshIndicator(
                        onRefresh: () async => _loadRequests(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(14),
                          itemCount: med.requests.length,
                          itemBuilder: (ctx, i) {
                            final request = med.requests[i];
                            return _buildMedicalCard(context, request, canManage);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalCard(BuildContext context, MedicalRequest req, bool canManage) {
    final statusColor = AppColors.forStatus(req.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.severityCritical.withOpacity(0.3), width: 1.2),
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
            // Top Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.severityCritical.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.local_hospital_rounded, color: AppColors.severityCritical, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${req.injuredCount} Casualties Injured',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                        ),
                        Text(
                          '${req.disasterType} • ${req.location}',
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
                    req.status,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Flags Grid
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (req.ambulanceRequired)
                  _buildTag('🚑 Ambulance Required', AppColors.severityCritical),
                if (req.emergencyTreatmentRequired)
                  _buildTag('⚡ Emergency Treatment Needed', AppColors.severityHigh),
                if (req.firstAidRequired)
                  _buildTag('🩹 First Aid Kit Required', AppColors.statusInfo),
              ],
            ),
            const SizedBox(height: 12),

            // Dispatch Information
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_shipping_outlined, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          req.assignedHospital != null
                              ? 'Assigned: ${req.assignedHospital}'
                              : 'Hospital Assignment: Pending Dispatch',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        if (req.ambulancesDispatched > 0)
                          Text(
                            '${req.ambulancesDispatched} Ambulance units in route',
                            style: const TextStyle(fontSize: 11, color: AppColors.statusSuccess, fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (canManage) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.send_rounded, size: 16),
                    label: const Text('Update Dispatch Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () => _showUpdateMedicalDialog(context, req),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  void _showUpdateMedicalDialog(BuildContext context, MedicalRequest req) {
    String newStatus = req.status;
    final hospController = TextEditingController(text: req.assignedHospital ?? 'GRH Emergency Hospital');
    final ambController = TextEditingController(text: req.ambulancesDispatched.toString());

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Update Medical Dispatch'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: newStatus,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: ['Requested', 'Assigned', 'On the Way', 'Completed'].map((s) {
                    return DropdownMenuItem(value: s, child: Text(s));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => newStatus = val);
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: hospController,
                  decoration: const InputDecoration(labelText: 'Assigned Hospital / Base'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: ambController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Ambulances Dispatched'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  final med = Provider.of<MedicalProvider>(context, listen: false);
                  await med.updateMedicalStatus(
                    req.id,
                    newStatus,
                    hospital: hospController.text,
                    ambulances: int.tryParse(ambController.text),
                  );
                  _loadRequests();
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }
}
