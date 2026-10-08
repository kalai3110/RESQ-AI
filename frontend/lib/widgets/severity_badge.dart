import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class SeverityBadge extends StatelessWidget {
  final String severity;
  final bool isLarge;

  const SeverityBadge({
    super.key,
    required this.severity,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forSeverity(severity);
    final sevUpper = severity.toUpperCase();

    IconData iconData;
    switch (sevUpper) {
      case 'CRITICAL':
        iconData = Icons.warning_rounded;
        break;
      case 'HIGH':
        iconData = Icons.error_outline_rounded;
        break;
      case 'MEDIUM':
        iconData = Icons.info_outline_rounded;
        break;
      default:
        iconData = Icons.check_circle_outline_rounded;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? 14 : 10,
        vertical: isLarge ? 8 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, color: color, size: isLarge ? 18 : 14),
          const SizedBox(width: 5),
          Text(
            sevUpper,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: isLarge ? 14 : 11,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
