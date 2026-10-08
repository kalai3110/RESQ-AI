import 'package:flutter/material.dart';
import '../models/ai_prediction.dart';
import '../constants/app_colors.dart';
import 'severity_badge.dart';
import 'priority_badge.dart';

class AIPredictionDialog extends StatelessWidget {
  final AIPrediction prediction;
  final VoidCallback? onConfirmSubmit;

  const AIPredictionDialog({
    super.key,
    required this.prediction,
    this.onConfirmSubmit,
  });

  static Future<void> show(BuildContext context, AIPrediction prediction, {VoidCallback? onConfirm}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AIPredictionDialog(prediction: prediction, onConfirmSubmit: onConfirm),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sevColor = AppColors.forSeverity(prediction.severity);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(22.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: sevColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.psychology_rounded, color: sevColor, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AI Severity Analysis',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          prediction.algorithm,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Severity & Priority Result Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: sevColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: sevColor.withOpacity(0.4), width: 1.5),
                ),
                child: Column(
                  children: [
                    Text(
                      'CLASSIFIED RESULT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: sevColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SeverityBadge(severity: prediction.severity, isLarge: true),
                        const SizedBox(width: 12),
                        PriorityBadge(priority: prediction.priority),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      prediction.responseTimeline,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: sevColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Incident Parameter Recap Grid
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildParamRow('Disaster Type', prediction.disasterType),
                    _buildParamRow('People Affected', prediction.peopleAffected.toString()),
                    _buildParamRow('Injured Casualties', prediction.injured.toString()),
                    _buildParamRow('Missing Persons', prediction.missing.toString()),
                    _buildParamRow('Damage Level', prediction.damageLevel),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Contributing Factors
              if (prediction.contributingFactors.isNotEmpty) ...[
                const Text(
                  'Decision Tree Factors:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                ...prediction.contributingFactors.map((factor) => Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.arrow_right, color: sevColor, size: 18),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              factor,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 12),
              ],

              // Recommendations
              if (prediction.recommendations.isNotEmpty) ...[
                const Text(
                  'Automated Dispatch Action Plan:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                ...prediction.recommendations.map((rec) => Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_rounded, color: AppColors.statusSuccess, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              rec,
                              style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 16),
              ],

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Back / Edit'),
                    ),
                  ),
                  if (onConfirmSubmit != null) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onConfirmSubmit!();
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: sevColor),
                        child: const Text('Confirm & Dispatch'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParamRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
