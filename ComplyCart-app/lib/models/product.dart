enum ComplianceStatus { compliant, nonCompliant }

class Product {
  final String id;
  final String name;
  final String title;
  final String? brand;
  final String? category;
  final String? imageUrl;
  final int complianceScore;
  final ComplianceStatus status;
  final DateTime lastCheckedDate;
  final String? mrp;
  final String? netQuantity;
  final String? unit;
  final String? manufacturer;
  final String? manufacturerAddress;
  final String? countryOfOrigin;
  final String? consumerCareEmail;
  final String? consumerCarePhone;
  final String? mfgDate;
  final String? importer;
  final List<String> missingFields;

  Product({
    required this.id,
    required String name,
    String? title,
    this.imageUrl,
    required this.complianceScore,
    required this.status,
    required this.lastCheckedDate,
    this.brand,
    this.category,
    this.mrp,
    this.netQuantity,
    this.unit,
    this.manufacturer,
    this.manufacturerAddress,
    this.countryOfOrigin,
    this.consumerCareEmail,
    this.consumerCarePhone,
    this.mfgDate,
    this.importer,
    List<String>? missingFields,
  })  : name = name,
        title = title ?? name,
        missingFields = missingFields ?? const [];

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawConsumerCare = json['consumer_care'];
    final consumerCare = rawConsumerCare is Map<String, dynamic> ? rawConsumerCare : <String, dynamic>{};
    final rawMissingFields = json['missing_fields'];
    final missingFields = rawMissingFields is List
        ? rawMissingFields.map((field) => field.toString()).toList()
        : rawMissingFields is String && rawMissingFields.isNotEmpty
            ? [rawMissingFields]
            : <String>[];
    final rawStatus = (json['status'] ?? '').toString().toLowerCase();

    return Product(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? json['title'] ?? '').toString(),
      title: (json['title'] ?? json['name'] ?? '').toString(),
      imageUrl: json['image_url']?.toString(),
      complianceScore: _parseInt(json['compliance_score']),
      status: rawStatus == 'compliant' ? ComplianceStatus.compliant : ComplianceStatus.nonCompliant,
      lastCheckedDate: _parseDate(json['last_checked_date']),
      brand: json['brand']?.toString(),
      category: json['category']?.toString(),
      mrp: json['mrp']?.toString(),
      netQuantity: json['net_quantity']?.toString(),
      unit: json['unit']?.toString(),
      manufacturer: json['manufacturer']?.toString(),
      manufacturerAddress: json['manufacturer_address']?.toString(),
      countryOfOrigin: json['country_of_origin']?.toString(),
      consumerCareEmail: consumerCare['email']?.toString(),
      consumerCarePhone: consumerCare['phone']?.toString(),
      mfgDate: json['mfg_date']?.toString(),
      importer: json['importer']?.toString(),
      missingFields: missingFields,
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime _parseDate(dynamic value) {
    final text = value?.toString() ?? '';
    final parsed = DateTime.tryParse(text);
    if (parsed != null) return parsed;
    if (text.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);
    final parts = text.split('/');
    if (parts.length == 3) {
      final day = int.tryParse(parts[0]) ?? 1;
      final month = int.tryParse(parts[1]) ?? 1;
      final year = int.tryParse(parts[2]) ?? 1970;
      return DateTime(year, month, day);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
