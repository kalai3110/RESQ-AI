import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class PriorityBadge extends StatelessWidget {
  final String priority;
  final bool showLabel;

  const PriorityBadge({
    super.key,
    required this.priority,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forPriority(priority);
    final prioUpper = priority.toUpperCase();

    String label;
    switch (prioUpper) {
      case 'P1':
        label = 'P1 – Critical';
        break;
      case 'P2':
        label = 'P2 – High';
        break;
      case 'P3':
        label = 'P3 – Medium';
        break;
      case 'P4':
        label = 'P4 – Low';
        break;
      default:
        label = prioUpper;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        showLabel ? label : prioUpper,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 11,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
