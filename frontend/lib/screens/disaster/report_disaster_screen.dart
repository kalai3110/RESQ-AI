import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/disaster_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/ai_prediction_dialog.dart';
import 'disaster_details_screen.dart';

class ReportDisasterScreen extends StatefulWidget {
  const ReportDisasterScreen({super.key});

  @override
  State<ReportDisasterScreen> createState() => _ReportDisasterScreenState();
}

class _ReportDisasterScreenState extends State<ReportDisasterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Disaster Types
  final List<String> _disasterTypes = [
    'Flood',
    'Cyclone',
    'Earthquake',
    'Fire',
    'Landslide',
    'Accident',
    'Other'
  ];
  String _selectedDisasterType = 'Flood';

  // Districts (Standard predefined list for quick selection)
  final List<String> _districts = [
    'Madurai',
    'Chennai',
    'Cuddalore',
    'Nilgiris',
    'Salem',
    'Coimbatore',
    'Tiruchirappalli',
    'Tirunelveli',
    'Kanyakumari',
    'Thanjavur',
    'Vellore',
    'Erode',
    'Dindigul'
  ];
  String _selectedDistrict = 'Madurai';

  // Form Controllers
  final _areaController = TextEditingController(text: 'Goripalayam Lowlands');
  final _addressController = TextEditingController(text: 'Near Vaigai River Bridge, Sector 4');
  final _peopleAffectedController = TextEditingController(text: '150');
  final _injuredController = TextEditingController(text: '25');
  final _missingController = TextEditingController(text: '8');
  final _immediateHelpController = TextEditingController(text: '40');
  final _descriptionController = TextEditingController(text: 'Water level rising rapidly over 4 feet. Several residents stranded on upper floors.');

  // Damage Information
  bool _propertyDamage = true;
  bool _infrastructureDamage = true;
  String _selectedDamageLevel = 'High'; // Low, Medium, High, Critical
  final List<String> _damageLevels = ['Low', 'Medium', 'High', 'Critical'];

  // Image evidence
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _areaController.dispose();
    _addressController.dispose();
    _peopleAffectedController.dispose();
    _injuredController.dispose();
    _missingController.dispose();
    _immediateHelpController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, maxWidth: 1200, imageQuality: 80);
      if (picked != null) {
        setState(() {
          _selectedImage = File(picked.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _handleAIPreview() async {
    if (!_formKey.currentState!.validate()) return;

    final disasterProvider = Provider.of<DisasterProvider>(context, listen: false);
    final prediction = await disasterProvider.predictSeverity(
      disasterType: _selectedDisasterType,
      peopleAffected: int.tryParse(_peopleAffectedController.text) ?? 0,
      injured: int.tryParse(_injuredController.text) ?? 0,
      missing: int.tryParse(_missingController.text) ?? 0,
      immediateHelpRequired: int.tryParse(_immediateHelpController.text) ?? 0,
      damageLevel: _selectedDamageLevel,
      infrastructureDamage: _infrastructureDamage,
      propertyDamage: _propertyDamage,
    );

    if (prediction != null && mounted) {
      AIPredictionDialog.show(context, prediction, onConfirm: _submitReport);
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final disaster = Provider.of<DisasterProvider>(context, listen: false);
    final userId = auth.currentUser?.id ?? 4;

    final result = await disaster.submitReport(
      userId: userId,
      disasterType: _selectedDisasterType,
      district: _selectedDistrict,
      area: _areaController.text,
      address: _addressController.text,
      peopleAffected: int.tryParse(_peopleAffectedController.text) ?? 0,
      injured: int.tryParse(_injuredController.text) ?? 0,
      missing: int.tryParse(_missingController.text) ?? 0,
      immediateHelpRequired: int.tryParse(_immediateHelpController.text) ?? 0,
      propertyDamage: _propertyDamage,
      infrastructureDamage: _infrastructureDamage,
      damageLevel: _selectedDamageLevel,
      description: _descriptionController.text,
      imageFile: _selectedImage,
    );

    if (!mounted) return;

    if (result['success'] == true && result['report'] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Disaster Report #${result['report'].id} registered! AI Classification: ${result['report'].severity} (${result['report'].priority})'),
          backgroundColor: AppColors.statusSuccess,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => DisasterDetailsScreen(reportId: result['report'].id),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to submit report'),
          backgroundColor: AppColors.severityCritical,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final disasterProvider = Provider.of<DisasterProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🚨 Report Disaster Incident', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: AppColors.secondary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Notice Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.privacy_tip_outlined, color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Please provide accurate manual location and damage details. Your report will be classified by Decision Tree AI.',
                        style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Section 1: Disaster Type
              _buildSectionCard(
                title: '1. Disaster Classification',
                icon: Icons.category_rounded,
                children: [
                  const Text('Disaster Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _selectedDisasterType,
                    decoration: const InputDecoration(filled: true, fillColor: Colors.white),
                    items: _disasterTypes.map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedDisasterType = val);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Section 2: Disaster Location
              _buildSectionCard(
                title: '2. Disaster Location (Manual Entry)',
                icon: Icons.place_rounded,
                children: [
                  const Text('District', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _selectedDistrict,
                    decoration: const InputDecoration(filled: true, fillColor: Colors.white),
                    items: _districts.map((dist) {
                      return DropdownMenuItem(value: dist, child: Text(dist));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedDistrict = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _areaController,
                    label: 'Area / Ward / Neighborhood',
                    hint: 'e.g. Goripalayam Riverbed Sector 4',
                    prefixIcon: Icons.location_city_rounded,
                    validator: (val) => val == null || val.trim().isEmpty ? 'Please enter area' : null,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _addressController,
                    label: 'Address / Specific Landmark',
                    hint: 'e.g. Near Goripalayam Bridge & Govt College',
                    prefixIcon: Icons.signpost_rounded,
                    maxLines: 2,
                    validator: (val) => val == null || val.trim().isEmpty ? 'Please enter landmark' : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Section 3: People Information
              _buildSectionCard(
                title: '3. People Impact Information',
                icon: Icons.people_alt_rounded,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _peopleAffectedController,
                          label: 'People Affected',
                          hint: '0',
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.groups_outlined,
                          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          controller: _injuredController,
                          label: 'Injured People',
                          hint: '0',
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.healing_outlined,
                          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _missingController,
                          label: 'Missing People',
                          hint: '0',
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.person_search_outlined,
                          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          controller: _immediateHelpController,
                          label: 'Immediate Help Needed',
                          hint: '0',
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.emergency_outlined,
                          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Section 4: Damage Information
              _buildSectionCard(
                title: '4. Structural & Infrastructure Damage',
                icon: Icons.domain_disabled_rounded,
                children: [
                  const Text('Damage Level', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _selectedDamageLevel,
                    decoration: const InputDecoration(filled: true, fillColor: Colors.white),
                    items: _damageLevels.map((lvl) {
                      return DropdownMenuItem(value: lvl, child: Text('$lvl Severity Damage'));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedDamageLevel = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Property / Residential Damage', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Houses or commercial buildings collapsed or inundated', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    value: _propertyDamage,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _propertyDamage = val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Infrastructure Damage', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Roads blocked, bridges damaged, power/water grid cut', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    value: _infrastructureDamage,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _infrastructureDamage = val),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Section 5: Additional Info & Image Evidence
              _buildSectionCard(
                title: '5. Evidence & Situation Description',
                icon: Icons.add_photo_alternate_rounded,
                children: [
                  CustomTextField(
                    controller: _descriptionController,
                    label: 'Detailed Situation Description',
                    hint: 'Provide specifics regarding current ground reality...',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 14),
                  const Text('Disaster Photo Evidence', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),

                  if (_selectedImage != null) ...[
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_selectedImage!, height: 180, width: double.infinity, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: CircleAvatar(
                            backgroundColor: Colors.black54,
                            radius: 16,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.close, color: Colors.white, size: 18),
                              onPressed: () => setState(() => _selectedImage = null),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt_outlined, size: 18),
                          label: const Text('Take Photo', style: TextStyle(fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_outlined, size: 18),
                          label: const Text('Gallery Upload', style: TextStyle(fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // AI Preview Button
              OutlinedButton.icon(
                onPressed: disasterProvider.isPredicting ? null : _handleAIPreview,
                icon: const Icon(Icons.psychology_rounded, color: AppColors.primary),
                label: disasterProvider.isPredicting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('PREVIEW AI SEVERITY & PRIORITY', style: TextStyle(fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),

              // Submit Report Button
              CustomButton(
                text: 'SUBMIT DISASTER REPORT',
                icon: Icons.send_rounded,
                isLoading: disasterProvider.isSubmitting,
                onPressed: _submitReport,
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}
