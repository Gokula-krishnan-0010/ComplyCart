import 'product.dart';

class Seller {
  final String id;
  final String name;
  final String platform;
  final String complianceScore; // Keep as String for UI compatibility for now
  final int complianceScoreValue;
  final bool isVerified;
  final String avatarInitial;
  final int productCount;
  final String activeSince;
  final int totalComplianceChecks;
  final double starRating;
  final List<Product> products;

  Seller({
    this.id = '',
    required this.name,
    required this.platform,
    String? complianceScore,
    int? complianceScoreValue,
    this.isVerified = false,
    String? avatarInitial,
    this.productCount = 0,
    String? activeSince,
    this.totalComplianceChecks = 0,
    double? starRating,
    List<Product>? products,
  })  : complianceScoreValue = complianceScoreValue ?? _parseScore(complianceScore),
        complianceScore = complianceScore ?? '${complianceScoreValue ?? _parseScore(complianceScore)}%',
        avatarInitial = avatarInitial ?? _deriveAvatarInitial(name),
        activeSince = activeSince ?? '',
        starRating = starRating ?? ((complianceScoreValue ?? _parseScore(complianceScore)) / 20.0),
        products = products ?? const [];

  // Factory constructor to handle derived starRating and other fields easily
  factory Seller.create({
    required String name,
    required String platform,
    required int score,
    required bool isVerified,
    required String avatarInitial,
    required int productCount,
    required String activeSince,
    required int totalChecks,
    required List<Product> products,
  }) {
    return Seller(
      id: '',
      name: name,
      platform: platform,
      complianceScore: '$score%',
      complianceScoreValue: score,
      isVerified: isVerified,
      avatarInitial: avatarInitial,
      productCount: productCount,
      activeSince: activeSince,
      totalComplianceChecks: totalChecks,
      starRating: score / 20.0,
      products: products,
    );
  }

  factory Seller.fromJson(Map<String, dynamic> json) {
    final rawProducts = json['products'];
    final products = rawProducts is List
        ? rawProducts
            .whereType<Map>()
            .map((item) => Product.fromJson(Map<String, dynamic>.from(item)))
            .toList()
        : <Product>[];
    final score = _parseScore(json['compliance_score']?.toString());

    return Seller(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      platform: (json['platform'] ?? '').toString(),
      complianceScore: '$score%',
      complianceScoreValue: score,
      isVerified: json['is_verified'] == true,
      avatarInitial: (json['name'] ?? '').toString().trim().isEmpty
          ? '?'
          : (json['name'] as String).trim().substring(0, 1).toUpperCase(),
      productCount: int.tryParse(json['product_count']?.toString() ?? '') ?? products.length,
      activeSince: json['active_since']?.toString() ?? '',
      totalComplianceChecks: int.tryParse(json['total_compliance_checks']?.toString() ?? '') ?? 0,
      starRating: (json['star_rating'] as num?)?.toDouble() ?? (score / 20.0),
      products: products,
    );
  }

  static int _parseScore(String? value) {
    if (value == null || value.isEmpty) return 0;
    return int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }

  static String _deriveAvatarInitial(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed[0].toUpperCase();
  }
}
