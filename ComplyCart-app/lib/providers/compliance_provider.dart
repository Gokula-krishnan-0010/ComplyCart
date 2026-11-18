import 'package:flutter/material.dart';
import '../models/compliance_result.dart';
import '../models/analysis_record.dart';
import '../services/api_service.dart';

class ComplianceProvider with ChangeNotifier {
  ComplianceResult? _analysisResult;
  bool _isLoading = false;
  String? _error;
  final List<AnalysisRecord> _history = [];
  final ApiService _apiService = ApiService();

  int _totalScans = 0;
  int _compliantCount = 0;
  int _nonCompliantCount = 0;

  ComplianceResult? get analysisResult => _analysisResult;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<AnalysisRecord> get history => _history;

  int get totalScans => _totalScans;
  int get compliantCount => _compliantCount;
  int get nonCompliantCount => _nonCompliantCount;

  Future<void> refreshData() async {
    try {
      final historyList = await _apiService.getRecentAnalyses();
      _history.clear();
      _history.addAll(historyList);

      final statsMap = await _apiService.getAnalysisStats();
      _totalScans = statsMap['total'] ?? 0;
      _compliantCount = statsMap['compliant'] ?? 0;
      _nonCompliantCount = statsMap['non_compliant'] ?? 0;

      _error = null;
      notifyListeners();
    } catch (e) {
      _error = "Failed to load history or stats: ${e.toString()}";
      notifyListeners();
    }
  }

  Future<void> analyzeUrl(String url, {bool forceRefresh = false}) async {
    if (url.isEmpty) return;

    _isLoading = true;
    _error = null;
    _analysisResult = null;
    notifyListeners();

    try {
      final response = await _apiService.analyzeUrl(url, forceRefresh: forceRefresh);
      _analysisResult = response.result;
      _isLoading = false;
      
      // Refresh history and stats after successful analysis!
      await refreshData();
    } catch (e) {
      _isLoading = false;
      if (e is AnalysisException) {
        _error = e.message;
        notifyListeners();
        rethrow;
      }
      _error = "Failed to analyze URL: ${e.toString()}";
      notifyListeners();
      rethrow;
    }
  }

  void selectResult(AnalysisRecord record) {
    _analysisResult = record.result;
    notifyListeners();
  }

  void clearResult() {
    _analysisResult = null;
    notifyListeners();
  }
}

