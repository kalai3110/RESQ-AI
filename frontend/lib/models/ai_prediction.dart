class AIPrediction {
  final String disasterType;
  final int peopleAffected;
  final int injured;
  final int missing;
  final int immediateHelpRequired;
  final String damageLevel;
  final String severity; // 'LOW', 'MEDIUM', 'HIGH', 'CRITICAL'
  final String severityDisplay;
  final String priority; // 'P1', 'P2', 'P3', 'P4'
  final String priorityTitle;
  final String priorityDisplay;
  final String responseTimeline;
  final String colorHex;
  final double confidence;
  final Map<String, double> classProbabilities;
  final List<String> contributingFactors;
  final List<String> recommendations;
  final String algorithm;

  AIPrediction({
    required this.disasterType,
    required this.peopleAffected,
    required this.injured,
    required this.missing,
    required this.immediateHelpRequired,
    required this.damageLevel,
    required this.severity,
    required this.severityDisplay,
    required this.priority,
    required this.priorityTitle,
    required this.priorityDisplay,
    required this.responseTimeline,
    required this.colorHex,
    required this.confidence,
    required this.classProbabilities,
    required this.contributingFactors,
    required this.recommendations,
    required this.algorithm,
  });

  factory AIPrediction.fromJson(Map<String, dynamic> json) {
    Map<String, double> probs = {};
    if (json['class_probabilities'] is Map) {
      json['class_probabilities'].forEach((k, v) {
        probs[k.toString()] = (v is num) ? v.toDouble() : 0.0;
      });
    }

    return AIPrediction(
      disasterType: json['disaster_type'] ?? '',
      peopleAffected: json['people_affected'] is int ? json['people_affected'] : int.tryParse(json['people_affected'].toString()) ?? 0,
      injured: json['injured'] is int ? json['injured'] : int.tryParse(json['injured'].toString()) ?? 0,
      missing: json['missing'] is int ? json['missing'] : int.tryParse(json['missing'].toString()) ?? 0,
      immediateHelpRequired: json['immediate_help_required'] is int ? json['immediate_help_required'] : int.tryParse(json['immediate_help_required'].toString()) ?? 0,
      damageLevel: json['damage_level'] ?? 'Medium',
      severity: (json['severity'] ?? 'MEDIUM').toString().toUpperCase(),
      severityDisplay: json['severity_display'] ?? '${json['severity']} SEVERITY',
      priority: json['priority'] ?? 'P3',
      priorityTitle: json['priority_title'] ?? 'Medium',
      priorityDisplay: json['priority_display'] ?? '${json['priority']} – ${json['priority_title']}',
      responseTimeline: json['response_timeline'] ?? 'Normal Response',
      colorHex: json['color'] ?? '#FFB300',
      confidence: (json['confidence'] is num) ? (json['confidence'] as num).toDouble() : 0.90,
      classProbabilities: probs,
      contributingFactors: (json['contributing_factors'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      recommendations: (json['recommendations'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      algorithm: json['algorithm'] ?? 'Decision Tree Classifier (Scikit-Learn)',
    );
  }
}
