import 'package:dio/dio.dart';

import '../core/api_config.dart';
import '../models/compliance_result.dart';
import '../models/product.dart';
import '../models/seller.dart';
import '../models/analysis_record.dart';

class ApiServiceError implements Exception {
  final String message;

  const ApiServiceError(this.message);

  @override
  String toString() => message;
}

class ApiHttpException extends ApiServiceError {
  final int? statusCode;
  final dynamic responseBody;

  const ApiHttpException({
    required String message,
    this.statusCode,
    this.responseBody,
  }) : super(message);
}

class ApiParseException extends ApiServiceError {
  final Object? originalError;

  const ApiParseException({
    required String message,
    this.originalError,
  }) : super(message);
}

class AnalysisException implements Exception {
  final String errorCode;
  final String message;

  const AnalysisException(this.errorCode, this.message);

  @override
  String toString() => 'AnalysisException($errorCode): $message';
}

class AnalysisResponse {
  final String productName;
  final bool cached;
  final String extractionMethod;
  final ComplianceResult result;

  AnalysisResponse({
    required this.productName,
    required this.cached,
    required this.extractionMethod,
    required this.result,
  });
}

class ApiService {
  ApiService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiConfig.baseUrl,
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 35), // Increased timeout for live scraping
                sendTimeout: const Duration(seconds: 20),
                responseType: ResponseType.json,
                headers: const {'Accept': 'application/json'},
              ),
            );

  final Dio _dio;

  Future<List<Seller>> getSellers({String? search}) async {
    try {
      final response = await _dio.get(
        '/sellers',
        queryParameters: search == null || search.isEmpty ? null : {'search': search},
      );
      return _parseList(response.data, Seller.fromJson);
    } on DioException catch (error) {
      throw _mapDioError(error);
    } catch (error) {
      throw ApiParseException(message: 'Failed to parse sellers response.', originalError: error);
    }
  }

  Future<Seller> getSellerById(String id) async {
    try {
      final response = await _dio.get('/sellers/$id');
      return _parseObject(response.data, Seller.fromJson);
    } on DioException catch (error) {
      throw _mapDioError(error);
    } catch (error) {
      throw ApiParseException(message: 'Failed to parse seller response.', originalError: error);
    }
  }

  Future<List<Product>> getSellerProducts(String sellerId) async {
    try {
      final response = await _dio.get('/sellers/$sellerId/products');
      return _parseList(response.data, Product.fromJson);
    } on DioException catch (error) {
      throw _mapDioError(error);
    } catch (error) {
      throw ApiParseException(message: 'Failed to parse seller products response.', originalError: error);
    }
  }

  Future<ComplianceResult> getProductCompliance(String productId) async {
    try {
      final response = await _dio.get('/products/$productId/compliance');
      return _parseComplianceResult(response.data);
    } on DioException catch (error) {
      throw _mapDioError(error);
    } catch (error) {
      if (error is Exception) rethrow;
      throw ApiParseException(message: 'Failed to parse product compliance response.', originalError: error);
    }
  }

  Future<AnalysisResponse> analyzeUrl(String url, {bool forceRefresh = false}) async {
    try {
      final response = await _dio.post(
        '/api/v1/analyze/url',
        data: {
          'url': url,
          'force_refresh': forceRefresh,
        },
      );
      final map = Map<String, dynamic>.from(response.data);
      final result = _parseComplianceResult(map);
      return AnalysisResponse(
        productName: (map['product_name'] ?? 'Unknown Product').toString(),
        cached: map['cached'] == true,
        extractionMethod: (map['extraction_method'] ?? 'unknown').toString(),
        result: result,
      );
    } on DioException catch (error) {
      throw _mapDioError(error);
    } catch (error) {
      if (error is Exception) rethrow;
      throw ApiParseException(message: 'Failed to parse analyze response.', originalError: error);
    }
  }

  Future<List<AnalysisRecord>> getRecentAnalyses({int limit = 10}) async {
    try {
      final response = await _dio.get('/api/v1/analyses', queryParameters: {'limit': limit});
      final list = _normalizeList(response.data);
      return list.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        final result = ComplianceResult.fromJson(map);
        return AnalysisRecord(
          id: int.tryParse(map['id']?.toString() ?? '') ?? 0,
          productName: (map['product_name'] ?? 'Unknown Product').toString(),
          url: (map['normalized_url'] ?? map['url'] ?? '').toString(),
          complianceScore: int.tryParse(map['score']?.toString() ?? '') ?? 0,
          status: (map['status'] ?? '').toString(),
          timestamp: DateTime.tryParse(map['timestamp']?.toString() ?? '') ?? DateTime.now(),
          result: result,
        );
      }).toList();
    } on DioException catch (error) {
      throw _mapDioError(error);
    } catch (error) {
      throw ApiParseException(message: 'Failed to parse recent analyses.', originalError: error);
    }
  }

  Future<AnalysisRecord> getAnalysisById(int id) async {
    try {
      final response = await _dio.get('/api/v1/analyses/$id');
      final map = Map<String, dynamic>.from(response.data);
      final result = ComplianceResult.fromJson(map);
      return AnalysisRecord(
        id: int.tryParse(map['id']?.toString() ?? '') ?? 0,
        productName: (map['product_name'] ?? 'Unknown Product').toString(),
        url: (map['url'] ?? '').toString(),
        complianceScore: int.tryParse(map['score']?.toString() ?? '') ?? 0,
        status: (map['status'] ?? '').toString(),
        timestamp: DateTime.tryParse(map['timestamp']?.toString() ?? '') ?? DateTime.now(),
        result: result,
      );
    } on DioException catch (error) {
      throw _mapDioError(error);
    } catch (error) {
      throw ApiParseException(message: 'Failed to parse analysis detail.', originalError: error);
    }
  }

  Future<Map<String, int>> getAnalysisStats() async {
    try {
      final response = await _dio.get('/api/v1/analyses/stats');
      final map = Map<String, dynamic>.from(response.data);
      return {
        'total': int.tryParse(map['total']?.toString() ?? '') ?? 0,
        'compliant': int.tryParse(map['compliant']?.toString() ?? '') ?? 0,
        'non_compliant': int.tryParse(map['non_compliant']?.toString() ?? '') ?? 0,
      };
    } on DioException catch (error) {
      throw _mapDioError(error);
    } catch (error) {
      throw ApiParseException(message: 'Failed to parse stats.', originalError: error);
    }
  }

  List<T> _parseList<T>(dynamic data, T Function(Map<String, dynamic>) parser) {
    final list = _normalizeList(data);
    try {
      return list.map((item) => parser(Map<String, dynamic>.from(item as Map))).toList();
    } catch (error) {
      throw ApiParseException(message: 'Failed to convert list response.', originalError: error);
    }
  }

  T _parseObject<T>(dynamic data, T Function(Map<String, dynamic>) parser) {
    try {
      if (data is Map<String, dynamic>) {
        return parser(data);
      }
      if (data is Map) {
        return parser(Map<String, dynamic>.from(data));
      }
      throw const FormatException('Expected an object response.');
    } catch (error) {
      if (error is ApiParseException) rethrow;
      throw ApiParseException(message: 'Failed to convert object response.', originalError: error);
    }
  }

  ComplianceResult _parseComplianceResult(dynamic data) {
    try {
      if (data is Map<String, dynamic>) {
        return ComplianceResult.fromJson(data);
      }
      if (data is Map) {
        return ComplianceResult.fromJson(Map<String, dynamic>.from(data));
      }
      throw const FormatException('Expected a compliance object response.');
    } catch (error) {
      if (error is ApiParseException) rethrow;
      throw ApiParseException(message: 'Failed to convert compliance response.', originalError: error);
    }
  }

  List<dynamic> _normalizeList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['items'] is List) {
      return data['items'] as List;
    }
    if (data is Map && data['items'] is List) {
      return data['items'] as List;
    }
    throw const FormatException('Expected a list response.');
  }

  Exception _mapDioError(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;

    if (data is Map) {
      if (data['error_code'] != null) {
        final errorCode = data['error_code'].toString();
        final detail = data['detail']?.toString() ?? data['message']?.toString() ?? 'Request failed.';
        return AnalysisException(errorCode, detail);
      }
    }

    final message = data is Map && data['detail'] != null
        ? data['detail'].toString()
        : error.message ?? 'Request failed.';

    return ApiHttpException(
      message: message,
      statusCode: statusCode,
      responseBody: error.response?.data,
    );
  }
}
