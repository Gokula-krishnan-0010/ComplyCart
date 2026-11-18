import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/seller_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/seller_card.dart';

class VerifiedSellersView extends StatefulWidget {
  const VerifiedSellersView({super.key});

  @override
  State<VerifiedSellersView> createState() => _VerifiedSellersViewState();
}

class _VerifiedSellersViewState extends State<VerifiedSellersView> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Refresh sellers list on entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SellerProvider>().fetchSellers();
    });
    
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    setState(() {
      _searchQuery = query;
    });

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      context.read<SellerProvider>().fetchSellers(search: query.isEmpty ? null : query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. Search Bar Section (High Visibility)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.background,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: AppShadows.soft,
            ),
            child: TextField(
              controller: _searchController,
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                hintText: 'Search verified sellers...',
                hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                suffixIcon: _searchQuery.isNotEmpty 
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ),

        // 2. Grid Section
        Expanded(
          child: Consumer<SellerProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (provider.error != null) {
                return Center(child: Text(provider.error!));
              }

              if (provider.sellers.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_rounded, size: 64, color: AppColors.textTertiary.withOpacity(0.5)),
                      const SizedBox(height: AppSpacing.md),
                      Text('No sellers found for "$_searchQuery"', style: AppTextStyles.bodyMedium),
                    ],
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(AppSpacing.lg),
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,           // 2-Column Split
                  crossAxisSpacing: AppSpacing.lg,
                  mainAxisSpacing: AppSpacing.lg,
                  childAspectRatio: 1.0,       // Perfectly Square Cards
                ),
                itemCount: provider.sellers.length,
                itemBuilder: (context, index) {
                  return SellerCard(seller: provider.sellers[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
