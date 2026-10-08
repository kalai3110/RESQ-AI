import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/relief_resource.dart';
import '../../providers/auth_provider.dart';
import '../../providers/resource_provider.dart';
import '../../widgets/empty_state_widget.dart';

class ReliefResourcesScreen extends StatefulWidget {
  const ReliefResourcesScreen({super.key});

  @override
  State<ReliefResourcesScreen> createState() => _ReliefResourcesScreenState();
}

class _ReliefResourcesScreenState extends State<ReliefResourcesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadResources();
    });
  }

  void _loadResources() {
    final res = Provider.of<ResourceProvider>(context, listen: false);
    res.fetchResources();
  }

  @override
  Widget build(BuildContext context) {
    final res = Provider.of<ResourceProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final canManage = user?.isAdmin == true || user?.isRescueWorker == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('📦 Relief Resources Inventory', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: AppColors.secondary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadResources,
          ),
        ],
      ),
      body: res.isLoading
          ? const Center(child: CircularProgressIndicator())
          : res.resources.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.inventory_2_outlined,
                  title: 'No Relief Resources',
                  message: 'Inventory records empty.',
                )
              : RefreshIndicator(
                  onRefresh: () async => _loadResources(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: res.resources.length,
                    itemBuilder: (ctx, i) {
                      final item = res.resources[i];
                      return _buildResourceCard(context, item, canManage);
                    },
                  ),
                ),
    );
  }

  Widget _buildResourceCard(BuildContext context, ReliefResource item, bool canManage) {
    Color statusColor;
    IconData iconData;

    switch (item.category.toLowerCase()) {
      case 'nutrition':
        iconData = Icons.fastfood_outlined;
        break;
      case 'hydration':
        iconData = Icons.water_drop_outlined;
        break;
      case 'medical':
        iconData = Icons.medical_services_outlined;
        break;
      case 'shelter & bedding':
        iconData = Icons.bed_outlined;
        break;
      case 'rescue equipment':
        iconData = Icons.handyman_outlined;
        break;
      default:
        iconData = Icons.inventory_2_outlined;
    }

    switch (item.status.toLowerCase()) {
      case 'available':
        statusColor = AppColors.statusSuccess;
        break;
      case 'limited':
        statusColor = AppColors.severityMedium;
        break;
      case 'low':
        statusColor = AppColors.severityHigh;
        break;
      default:
        statusColor = AppColors.severityCritical;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1.2),
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(iconData, color: statusColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.resourceName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                      ),
                      Text(
                        'Category: ${item.category} • ${item.location}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.status,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Quantity Display Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Available Stock:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                Text(
                  item.displayQuantity,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: statusColor),
                ),
              ],
            ),

            if (canManage) ...[
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                    label: const Text('Restock / Update Quantity', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () => _showUpdateQuantityDialog(context, item),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showUpdateQuantityDialog(BuildContext context, ReliefResource item) {
    final qtyController = TextEditingController(text: item.quantity.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Update ${item.resourceName}'),
        content: TextField(
          controller: qtyController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'New Available Quantity (${item.unit})',
            hintText: 'e.g. 500',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final qty = int.tryParse(qtyController.text);
              if (qty != null) {
                final res = Provider.of<ResourceProvider>(context, listen: false);
                await res.updateResource(item.id, qty);
                _loadResources();
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
