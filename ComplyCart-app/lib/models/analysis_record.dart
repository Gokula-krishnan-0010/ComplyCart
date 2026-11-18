import 'compliance_result.dart';

class AnalysisRecord {
  final int id;
  final String productName;
  final String url;
  final int complianceScore;
  final String status;
  final DateTime timestamp;
  final ComplianceResult result; // Store full result for re-displaying

  AnalysisRecord({
    required this.id,
    required this.productName,
    required this.url,
    required this.complianceScore,
    required this.status,
    required this.timestamp,
    required this.result,
  });
}
