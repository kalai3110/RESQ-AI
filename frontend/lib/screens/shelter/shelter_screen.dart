import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/shelter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/shelter_provider.dart';
import '../../widgets/empty_state_widget.dart';

class ShelterScreen extends StatefulWidget {
  const ShelterScreen({super.key});

  @override
  State<ShelterScreen> createState() => _ShelterScreenState();
}

class _ShelterScreenState extends State<ShelterScreen> {
  String _selectedDistrict = 'All';
  final List<String> _districtFilters = ['All', 'Madurai', 'Chennai', 'Cuddalore', 'Nilgiris', 'Salem', 'Coimbatore'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadShelters();
    });
  }

  void _loadShelters() {
    final shelterProv = Provider.of<ShelterProvider>(context, listen: false);
    shelterProv.fetchShelters(district: _selectedDistrict == 'All' ? null : _selectedDistrict);
  }

  @override
  Widget build(BuildContext context) {
    final shelterProv = Provider.of<ShelterProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final canManage = user?.isAdmin == true || user?.isRescueWorker == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('🏕️ Shelter Availability Directory', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: AppColors.secondary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadShelters,
          ),
        ],
      ),
      body: Column(
        children: [
          // District Filter Bar
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            color: Colors.white,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _districtFilters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final dist = _districtFilters[i];
                final isSelected = _selectedDistrict == dist;
                return ChoiceChip(
                  label: Text(dist, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  selected: isSelected,
                  selectedColor: AppColors.statusSuccess.withOpacity(0.15),
                  labelStyle: TextStyle(color: isSelected ? AppColors.statusSuccess : AppColors.textSecondary),
                  onSelected: (val) {
                    if (val) {
                      setState(() => _selectedDistrict = dist);
                      _loadShelters();
                    }
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),

          // Shelters List
          Expanded(
            child: shelterProv.isLoading
                ? const Center(child: CircularProgressIndicator())
                : shelterProv.shelters.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.night_shelter_outlined,
                        title: 'No Shelters Found',
                        message: 'No relief shelters found in the selected district.',
                      )
                    : RefreshIndicator(
                        onRefresh: () async => _loadShelters(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(14),
                          itemCount: shelterProv.shelters.length,
                          itemBuilder: (ctx, i) {
                            final shelter = shelterProv.shelters[i];
                            return _buildShelterCard(context, shelter, canManage);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildShelterCard(BuildContext context, Shelter shelter, bool canManage) {
    Color statusColor;
    switch (shelter.status.toLowerCase()) {
      case 'available':
        statusColor = AppColors.statusSuccess;
        break;
      case 'limited':
        statusColor = AppColors.severityMedium;
        break;
      default:
        statusColor = AppColors.severityCritical;
    }

    final double occupancyFraction = (shelter.occupied / shelter.capacity).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
            // Shelter Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    shelter.shelterName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    shelter.status,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 15, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text('${shelter.location}, ${shelter.district}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 14),

            // Capacity Numbers
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Capacity', '${shelter.capacity}', AppColors.textPrimary),
                _buildStatItem('Occupied', '${shelter.occupied}', AppColors.severityHigh),
                _buildStatItem('Available Seats', '${shelter.available}', AppColors.statusSuccess),
              ],
            ),
            const SizedBox(height: 10),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: occupancyFraction,
                minHeight: 8,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(
                  occupancyFraction > 0.9 ? AppColors.severityCritical : (occupancyFraction > 0.7 ? AppColors.severityMedium : AppColors.statusSuccess),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Amenities Icons Badges
            Row(
              children: [
                _buildAmenityBadge('Food', shelter.foodAvailable, Icons.restaurant_outlined),
                const SizedBox(width: 8),
                _buildAmenityBadge('Water', shelter.waterAvailable, Icons.water_drop_outlined),
                const SizedBox(width: 8),
                _buildAmenityBadge('Medical', shelter.medicalAvailable, Icons.local_hospital_outlined),
              ],
            ),

            if (canManage) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.edit_note_outlined, size: 16),
                    label: const Text('Edit Capacity / Amenities', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () => _showEditShelterDialog(context, shelter),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildAmenityBadge(String label, bool isAvailable, IconData icon) {
    final color = isAvailable ? AppColors.statusSuccess : AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$label: ${isAvailable ? "Available" : "No"}',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  void _showEditShelterDialog(BuildContext context, Shelter shelter) {
    final capController = TextEditingController(text: shelter.capacity.toString());
    final occController = TextEditingController(text: shelter.occupied.toString());
    bool food = shelter.foodAvailable;
    bool water = shelter.waterAvailable;
    bool medical = shelter.medicalAvailable;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text('Edit ${shelter.shelterName}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: capController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Total Capacity'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: occController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Occupied Count'),
                  ),
                  const SizedBox(height: 10),
                  CheckboxListTile(
                    title: const Text('Food Available', style: TextStyle(fontSize: 13)),
                    value: food,
                    onChanged: (val) => setDialogState(() => food = val ?? true),
                  ),
                  CheckboxListTile(
                    title: const Text('Water Available', style: TextStyle(fontSize: 13)),
                    value: water,
                    onChanged: (val) => setDialogState(() => water = val ?? true),
                  ),
                  CheckboxListTile(
                    title: const Text('Medical Facilities Available', style: TextStyle(fontSize: 13)),
                    value: medical,
                    onChanged: (val) => setDialogState(() => medical = val ?? true),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  final shelterProv = Provider.of<ShelterProvider>(context, listen: false);
                  await shelterProv.updateShelterCapacity(
                    shelter.id,
                    capacity: int.tryParse(capController.text),
                    occupied: int.tryParse(occController.text),
                    food: food,
                    water: water,
                    medical: medical,
                  );
                  _loadShelters();
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
