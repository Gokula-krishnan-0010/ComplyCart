import 'package:flutter/material.dart';
import '../models/seller.dart';
import '../services/api_service.dart';

class SellerProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Seller> _sellers = [];
  bool _isLoading = false;
  String? _error;

  List<Seller> get sellers => _sellers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchSellers({String? search}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _sellers = await _apiService.getSellers(search: search);
      _isLoading = false;
    } on ApiServiceError catch (e) {
      _error = e.toString();
      _isLoading = false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
    }
    notifyListeners();
  }
}
