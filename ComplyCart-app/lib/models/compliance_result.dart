import 'compliance_field.dart';

class ComplianceResult {
  final int score;
  final String status;
  final List<ComplianceField> fields;

  ComplianceResult({
    required this.score,
    required this.status,
    required this.fields,
  });

  factory ComplianceResult.fromJson(Map<String, dynamic> json) {
    final rawFields = json['fields'];
    final fields = rawFields is List
        ? rawFields
            .whereType<Map>()
            .map((item) => ComplianceField.fromJson(Map<String, dynamic>.from(item)))
            .toList()
        : <ComplianceField>[];

    return ComplianceResult(
      score: int.tryParse(json['score']?.toString() ?? '') ?? 0,
      status: (json['status'] ?? '').toString(),
      fields: fields,
    );
  }
}
