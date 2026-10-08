import 'package:flutter/material.dart';

class AppColors {
  // Brand & Emergency Primary Colors
  static const Color primary = Color(0xFFD32F2F); // Emergency Crimson Red
  static const Color primaryDark = Color(0xFF9A0007);
  static const Color primaryLight = Color(0xFFFF6659);
  
  static const Color secondary = Color(0xFF0F172A); // Dark Slate Command Navy
  static const Color secondaryLight = Color(0xFF1E293B);
  static const Color accent = Color(0xFF0284C7); // Tactical Sky Blue

  // Severity Level Colors
  static const Color severityCritical = Color(0xFFE53935); // P1 - Critical (Red)
  static const Color severityHigh = Color(0xFFFB8C00);     // P2 - High (Orange)
  static const Color severityMedium = Color(0xFFFFB300);   // P3 - Medium (Amber/Yellow)
  static const Color severityLow = Color(0xFF43A047);      // P4 - Low (Green)

  // Status Colors
  static const Color statusSuccess = Color(0xFF2E7D32);
  static const Color statusWarning = Color(0xFFF57C00);
  static const Color statusInfo = Color(0xFF0288D1);
  static const Color statusNeutral = Color(0xFF78909C);

  // Background & Surfaces
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE2E8F0);

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textLight = Color(0xFFFFFFFF);

  // Helper for Severity Color
  static Color forSeverity(String severity) {
    switch (severity.toUpperCase()) {
      case 'CRITICAL':
        return severityCritical;
      case 'HIGH':
        return severityHigh;
      case 'MEDIUM':
        return severityMedium;
      case 'LOW':
        return severityLow;
      default:
        return severityMedium;
    }
  }

  // Helper for Priority Color
  static Color forPriority(String priority) {
    switch (priority.toUpperCase()) {
      case 'P1':
        return severityCritical;
      case 'P2':
        return severityHigh;
      case 'P3':
        return severityMedium;
      case 'P4':
        return severityLow;
      default:
        return severityMedium;
    }
  }

  // Helper for Status Color
  static Color forStatus(String status) {
    switch (status.toLowerCase()) {
      case 'reported':
      case 'requested':
        return severityHigh;
      case 'assigned':
      case 'preparing':
        return statusInfo;
      case 'on the way':
      case 'rescue in progress':
      case 'verified':
        return statusWarning;
      case 'reached':
      case 'completed':
      case 'resolved':
      case 'available':
        return statusSuccess;
      case 'limited':
        return severityMedium;
      case 'full':
      case 'out of stock':
        return severityCritical;
      default:
        return statusNeutral;
    }
  }
}
