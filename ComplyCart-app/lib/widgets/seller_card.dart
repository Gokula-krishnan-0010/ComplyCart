import 'package:flutter/material.dart';
import '../models/seller.dart';
import '../theme/app_theme.dart';
import '../screens/seller_detail_screen.dart';

class SellerCard extends StatefulWidget {
  final Seller seller;

  const SellerCard({super.key, required this.seller});

  @override
  State<SellerCard> createState() => _SellerCardState();
}

class _SellerCardState extends State<SellerCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final platformColor = widget.seller.platform.toLowerCase().contains('amazon')
        ? Colors.orange.shade800
        : Colors.blue.shade800;

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.95),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SellerDetailScreen(seller: widget.seller),
          ),
        );
      },
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: AppShadows.soft,
            border: Border.all(color: AppColors.surfaceVariant, width: 1),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              // 1. Avatar
              Hero(
                tag: 'seller_avatar_${widget.seller.name}',
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withOpacity(0.08),
                  child: Text(
                    widget.seller.avatarInitial,
                    style: AppTextStyles.h3.copyWith(color: AppColors.primary, fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              
              // 2. Seller Name
              Text(
                widget.seller.name,
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, height: 1.1),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xxs),
              
              // 3. Platform Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: platformColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  widget.seller.platform,
                  style: AppTextStyles.metadata.copyWith(
                    color: platformColor, 
                    fontSize: 9,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              
              // 4. Stars
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  IconData icon;
                  if (index < widget.seller.starRating.floor()) {
                    icon = Icons.star_rounded;
                  } else if (index < widget.seller.starRating) {
                    icon = Icons.star_half_rounded;
                  } else {
                    icon = Icons.star_outline_rounded;
                  }
                  return Icon(icon, color: Colors.amber, size: 14);
                }),
              ),
              const SizedBox(height: AppSpacing.xs),
              
              // 5. Product Count
              Text(
                '${widget.seller.productCount} products',
                style: AppTextStyles.metadata.copyWith(fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
