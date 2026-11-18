import '../models/seller.dart';
import '../models/product.dart';
import '../models/compliance_result.dart';
import '../models/compliance_field.dart';

class MockDataService {
  static List<Product> _generateMockProducts(String sellerName, int count) {
    return List.generate(count, (index) {
      final score = 70 + (index * 7) % 31; // Scores between 70 and 100
      return Product(
        id: '${sellerName.toLowerCase().replaceAll(' ', '_')}_p$index',
        name: 'Product ${index + 1} from $sellerName',
        imageUrl: null, // Placeholder
        complianceScore: score,
        status: score >= 90 ? ComplianceStatus.compliant : ComplianceStatus.nonCompliant,
        lastCheckedDate: DateTime.now().subtract(Duration(days: index * 2)),
      );
    });
  }

  static List<Seller> getMockSellers() {
    return [
      Seller.create(
        name: 'Cloudtail India',
        platform: 'Amazon',
        score: 98,
        isVerified: true,
        avatarInitial: 'C',
        productCount: 1250,
        activeSince: 'Jan 2018',
        totalChecks: 4500,
        products: _generateMockProducts('Cloudtail India', 8),
      ),
      Seller.create(
        name: 'RetailNet',
        platform: 'Flipkart',
        score: 95,
        isVerified: true,
        avatarInitial: 'R',
        productCount: 850,
        activeSince: 'Mar 2019',
        totalChecks: 3200,
        products: _generateMockProducts('RetailNet', 6),
      ),
      Seller.create(
        name: 'Appario Retail',
        platform: 'Amazon',
        score: 92,
        isVerified: true,
        avatarInitial: 'A',
        productCount: 1100,
        activeSince: 'Jun 2018',
        totalChecks: 3800,
        products: _generateMockProducts('Appario Retail', 7),
      ),
      Seller.create(
        name: 'SuperComNet',
        platform: 'Flipkart',
        score: 90,
        isVerified: true,
        avatarInitial: 'S',
        productCount: 600,
        activeSince: 'Oct 2020',
        totalChecks: 1500,
        products: _generateMockProducts('SuperComNet', 5),
      ),
      Seller.create(
        name: 'Omnitech Retail',
        platform: 'Amazon',
        score: 94,
        isVerified: true,
        avatarInitial: 'O',
        productCount: 450,
        activeSince: 'Feb 2021',
        totalChecks: 1200,
        products: _generateMockProducts('Omnitech Retail', 4),
      ),
    ];
  }

  static ComplianceResult getMockAnalysisResult() {
    return ComplianceResult(
      score: 85,
      status: 'Non-Compliant',
      fields: [
        ComplianceField(name: 'MRP', isFound: true),
        ComplianceField(name: 'Net Quantity', isFound: true),
        ComplianceField(name: 'Country of Origin', isFound: true),
        ComplianceField(name: 'Consumer Care Details', isFound: true),
        ComplianceField(
          name: 'Importer Details',
          isFound: false,
          note: 'Missing "Importer Details" which is mandatory for imported products under Legal Metrology Rules.',
        ),
      ],
    );
  }
}
