class ComplianceField {
  final String name;
  final bool isFound;
  final String? note;
  final String? extractedValue;

  ComplianceField({
    required this.name,
    required this.isFound,
    this.note,
    this.extractedValue,
  });

  factory ComplianceField.fromJson(Map<String, dynamic> json) {
    return ComplianceField(
      name: (json['name'] ?? json['field_name'] ?? '').toString(),
      isFound: json['isFound'] == true || json['is_found'] == true,
      note: (json['note'] ?? json['violated_clause'])?.toString(),
      extractedValue: json['extracted_value']?.toString(),
    );
  }
}
