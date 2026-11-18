import 'package:flutter/material.dart';
import '../models/compliance_field.dart';
import '../theme/app_theme.dart';

class ComplianceFieldTile extends StatelessWidget {
  final ComplianceField field;

  const ComplianceFieldTile({super.key, required this.field});

  @override
  Widget build(BuildContext context) {
    final fieldColor = field.isFound ? AppColors.success : AppColors.error;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm / 1.3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Icon(
              field.isFound ? Icons.check_circle : Icons.cancel,
              color: fieldColor,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(field.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                if (field.isFound &&
                    field.extractedValue != null &&
                    field.extractedValue!.isNotEmpty &&
                    field.extractedValue != 'null' &&
                    field.extractedValue != 'None')
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      field.extractedValue!,
                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            field.isFound ? 'Found' : 'Missing',
            style: TextStyle(color: fieldColor, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
