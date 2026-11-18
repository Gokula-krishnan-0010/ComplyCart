import 'package:flutter/material.dart';
import '../models/analysis_record.dart';
import '../theme/app_theme.dart';
import 'package:timeago/timeago.dart' as timeago;

class QuickStatsRow extends StatelessWidget {
  final int total;
  final int compliant;
  final int nonCompliant;

  const QuickStatsRow({
    super.key,
    required this.total,
    required this.compliant,
    required this.nonCompliant,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.soft,
        border: Border.all(color: AppColors.surfaceVariant.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statBlock(context, Icons.analytics_outlined, 'Total Scans', total.toString(), AppColors.primary),
          _verticalDivider(),
          _statBlock(context, Icons.check_circle_outline, 'Compliant', compliant.toString(), AppColors.success),
          _verticalDivider(),
          _statBlock(context, Icons.error_outline, 'Non-Compliant', nonCompliant.toString(), AppColors.error),
        ],
      ),
    );
  }

  Widget _statBlock(BuildContext context, IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color.withOpacity(0.7), size: 20),
        const SizedBox(height: AppSpacing.xs),
        Text(value, style: AppTextStyles.h3.copyWith(fontSize: 16)),
        Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10)),
      ],
    );
  }

  Widget _verticalDivider() {
    return Container(
      height: 30,
      width: 1,
      color: AppColors.surfaceVariant,
    );
  }
}

class AnalysisHistoryCard extends StatelessWidget {
  final AnalysisRecord record;
  final VoidCallback onTap;

  const AnalysisHistoryCard({
    super.key,
    required this.record,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = record.status == 'Compliant' ? AppColors.success : AppColors.error;
    final platform = record.url.contains('amazon') ? 'Amazon' : (record.url.contains('flipkart') ? 'Flipkart' : 'Web');
    final platformColor = platform == 'Amazon' ? Colors.orange.shade800 : (platform == 'Flipkart' ? Colors.blue.shade800 : AppColors.textTertiary);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.soft,
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Platform Icon/Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: platformColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  platform == 'Amazon' ? Icons.shopping_basket_outlined : Icons.shopping_bag_outlined,
                  color: platformColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.productName,
                      style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: platformColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            platform,
                            style: AppTextStyles.metadata.copyWith(color: platformColor, fontSize: 9),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          timeago.format(record.timestamp),
                          style: AppTextStyles.caption.copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Score Badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${record.complianceScore}',
                    style: AppTextStyles.h3.copyWith(color: statusColor, fontSize: 18),
                  ),
                  Text(
                    record.status,
                    style: AppTextStyles.metadata.copyWith(color: statusColor, fontSize: 9),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HowItWorksGuide extends StatelessWidget {
  const HowItWorksGuide({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('How it works', style: AppTextStyles.h3),
        const SizedBox(height: AppSpacing.lg),
        _guideStep(
          context,
          Icons.link,
          'Paste URL',
          'Copy the product URL from Amazon or Flipkart and paste it above.',
        ),
        _guideStep(
          context,
          Icons.auto_awesome,
          'AI Extraction',
          'Our AI engine scans the product page for mandatory compliance labels.',
        ),
        _guideStep(
          context,
          Icons.assignment_turned_in,
          'Compliance Report',
          'Get a detailed report on missing fields and overall compliance score.',
          isLast: true,
        ),
      ],
    );
  }

  Widget _guideStep(BuildContext context, IconData icon, String title, String desc, {bool isLast = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.surfaceVariant,
                    margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(desc, style: AppTextStyles.bodyMedium),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
