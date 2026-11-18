import 'package:flutter/material.dart';
import '../models/compliance_result.dart';
import '../models/compliance_field.dart';
import '../theme/app_theme.dart';
import 'compliance_field_tile.dart';

class ComplianceScoreCard extends StatelessWidget {
  final ComplianceResult result;

  const ComplianceScoreCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final isCompliant = result.status == 'Compliant';
    final statusColor = isCompliant ? AppColors.success : AppColors.error;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.soft,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Compliance Score', style: AppTextStyles.caption),
                    Text(
                      '${result.score}/100',
                      style: AppTextStyles.h2,
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    result.status,
                    style: AppTextStyles.metadata.copyWith(color: statusColor),
                  ),
                ),
              ],
            ),
            const Divider(height: AppSpacing.xxxl, color: AppColors.surfaceVariant),
            ...result.fields.map((field) => ComplianceFieldTile(field: field)),
            if (!isCompliant) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Reason: ${result.fields.firstWhere((f) => !f.isFound, orElse: () => ComplianceField(name: '', isFound: true, note: 'Unknown reason')).note ?? "Unknown compliance issue."}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.warning,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
