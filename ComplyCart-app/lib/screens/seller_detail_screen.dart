import 'package:flutter/material.dart';

import '../models/compliance_result.dart';
import '../models/product.dart';
import '../models/seller.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/compliance_score_card.dart';

class SellerDetailScreen extends StatefulWidget {
  final Seller seller;

  const SellerDetailScreen({super.key, required this.seller});

  @override
  State<SellerDetailScreen> createState() => _SellerDetailScreenState();
}

class _SellerDetailScreenState extends State<SellerDetailScreen> {
  final ApiService _apiService = ApiService();
  List<Product> _products = [];
  bool _isLoadingProducts = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoadingProducts = true;
      _error = null;
    });

    try {
      final products = await _apiService.getSellerProducts(widget.seller.id);
      if (!mounted) return;
      setState(() {
        _products = products;
        _isLoadingProducts = false;
      });
    } on ApiServiceError catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isLoadingProducts = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isLoadingProducts = false;
      });
    }
  }

  Future<void> _showProductCompliance(BuildContext context, Product product) async {
    final complianceFuture = _apiService.getProductCompliance(product.id);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.86,
          minChildSize: 0.55,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: AppShadows.soft,
              ),
              child: FutureBuilder<ComplianceResult>(
                future: complianceFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Center(
                        child: Text(
                          snapshot.error.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    );
                  }

                  final result = snapshot.data!;
                  return SafeArea(
                    top: false,
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              width: 44,
                              height: 5,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            product.title,
                            style: AppTextStyles.h3,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            product.brand ?? product.category ?? 'Product compliance',
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          ComplianceScoreCard(result: result),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Real field breakdown from the backend',
                            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Products', style: AppTextStyles.h3),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ),
          if (_isLoadingProducts)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              ),
            )
          else
            _buildProductList(context),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 340,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Hero(
                      tag: 'seller_avatar_${widget.seller.name}',
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        decoration: const BoxDecoration(
                          color: Colors.white24,
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.white,
                          child: Text(
                            widget.seller.avatarInitial,
                            style: AppTextStyles.h1.copyWith(color: AppColors.primary, fontSize: 32),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.seller.name,
                          style: AppTextStyles.h2.copyWith(color: Colors.white),
                        ),
                        if (widget.seller.isVerified) ...[
                          const SizedBox(width: AppSpacing.xs),
                          const Icon(Icons.verified_rounded, color: Colors.white, size: 20),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.seller.platform,
                          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white.withOpacity(0.9)),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        _buildStars(widget.seller.starRating),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    _buildStatsRow(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStars(double rating) {
    return Row(
      children: List.generate(5, (index) {
        IconData icon;
        if (index < rating.floor()) {
          icon = Icons.star_rounded;
        } else if (index < rating) {
          icon = Icons.star_half_rounded;
        } else {
          icon = Icons.star_outline_rounded;
        }
        return Icon(icon, color: Colors.amber, size: 16);
      }),
    );
  }

  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statBlock(Icons.inventory_2_outlined, 'Products', widget.seller.productCount.toString()),
          _verticalDivider(),
          _statBlock(Icons.verified_outlined, 'Rate', widget.seller.complianceScore),
          _verticalDivider(),
          _statBlock(Icons.calendar_today_outlined, 'Since', widget.seller.activeSince),
        ],
      ),
    );
  }

  Widget _statBlock(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: AppSpacing.xs),
        Text(value, style: AppTextStyles.metadata.copyWith(color: Colors.white, fontSize: 13)),
        Text(label, style: AppTextStyles.caption.copyWith(color: Colors.white60, fontSize: 10)),
      ],
    );
  }

  Widget _verticalDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.white24,
    );
  }

  Widget _buildProductList(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final product = _products[index];
            return _buildProductCard(context, product);
          },
          childCount: _products.length,
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    final statusColor = product.status == ComplianceStatus.compliant ? AppColors.success : AppColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.soft,
      ),
      child: InkWell(
        onTap: () => _showProductCompliance(context, product),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(Icons.image_outlined, color: AppColors.textTertiary, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Checked: ${product.lastCheckedDate.day}/${product.lastCheckedDate.month}/${product.lastCheckedDate.year}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  product.status == ComplianceStatus.compliant ? 'Compliant' : 'Risk',
                  style: AppTextStyles.metadata.copyWith(color: statusColor, fontSize: 10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
