import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class BatchActionsToolbar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onMarkAllAsPaid;
  final VoidCallback onDeleteAll;
  final VoidCallback onExportAll;
  final VoidCallback onClearSelection;

  const BatchActionsToolbar({
    Key? key,
    required this.selectedCount,
    required this.onMarkAllAsPaid,
    required this.onDeleteAll,
    required this.onExportAll,
    required this.onClearSelection,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.primary,
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.colorScheme.shadow,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Close selection button
            GestureDetector(
              onTap: onClearSelection,
              child: Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.onPrimary
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomIconWidget(
                  iconName: 'close',
                  color: AppTheme.lightTheme.colorScheme.onPrimary,
                  size: 5.w,
                ),
              ),
            ),

            SizedBox(width: 4.w),

            // Selected count
            Expanded(
              child: Text(
                '$selectedCount fatura seçildi',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Action buttons
            Row(
              children: [
                // Mark as paid
                GestureDetector(
                  onTap: onMarkAllAsPaid,
                  child: Container(
                    padding: EdgeInsets.all(2.5.w),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CustomIconWidget(
                      iconName: 'check_circle',
                      color: Colors.green.shade100,
                      size: 5.w,
                    ),
                  ),
                ),

                SizedBox(width: 3.w),

                // Export
                GestureDetector(
                  onTap: onExportAll,
                  child: Container(
                    padding: EdgeInsets.all(2.5.w),
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.onPrimary
                          .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CustomIconWidget(
                      iconName: 'file_download',
                      color: AppTheme.lightTheme.colorScheme.onPrimary,
                      size: 5.w,
                    ),
                  ),
                ),

                SizedBox(width: 3.w),

                // Delete
                GestureDetector(
                  onTap: () => _showDeleteConfirmation(context),
                  child: Container(
                    padding: EdgeInsets.all(2.5.w),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CustomIconWidget(
                      iconName: 'delete',
                      color: Colors.red.shade100,
                      size: 5.w,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Faturaları Sil',
            style: AppTheme.lightTheme.textTheme.titleLarge,
          ),
          content: Text(
            '$selectedCount faturayı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
            style: AppTheme.lightTheme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'İptal',
                style: TextStyle(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onDeleteAll();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );
  }
}
