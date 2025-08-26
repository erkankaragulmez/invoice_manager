import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ExpenseListItem extends StatelessWidget {
  final Map<String, dynamic> expense;
  final VoidCallback? onEdit;
  final VoidCallback? onChangeCategory;
  final VoidCallback? onAddPhoto;
  final VoidCallback? onDelete;

  const ExpenseListItem({
    Key? key,
    required this.expense,
    this.onEdit,
    this.onChangeCategory,
    this.onAddPhoto,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(expense['id'].toString()),
      background: _buildRightSwipeBackground(),
      secondaryBackground: _buildLeftSwipeBackground(),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          return await _showDeleteConfirmation(context);
        } else if (direction == DismissDirection.startToEnd) {
          _showActionSheet(context);
          return false;
        }
        return false;
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppTheme.lightTheme.shadowColor,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          leading: Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              color: _getCategoryColor(expense['category'] as String)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: _getCategoryIcon(expense['category'] as String),
                color: _getCategoryColor(expense['category'] as String),
                size: 6.w,
              ),
            ),
          ),
          title: Text(
            expense['description'] as String,
            style: AppTheme.lightTheme.textTheme.titleMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            _formatDate(expense['date'] as DateTime),
            style: AppTheme.lightTheme.textTheme.bodySmall,
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(expense['amount'] as double).toStringAsFixed(2).replaceAll('.', ',')} ₺',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lightTheme.colorScheme.error,
                ),
              ),
              if (expense['hasPhoto'] == true)
                Container(
                  margin: EdgeInsets.only(top: 0.5.h),
                  child: CustomIconWidget(
                    iconName: 'photo_camera',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 4.w,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRightSwipeBackground() {
    return Container(
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.only(left: 6.w),
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomIconWidget(
            iconName: 'edit',
            color: Colors.white,
            size: 6.w,
          ),
          SizedBox(width: 2.w),
          Text(
            'Düzenle',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftSwipeBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: EdgeInsets.only(right: 6.w),
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.error,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Sil',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 2.w),
          CustomIconWidget(
            iconName: 'delete',
            color: Colors.white,
            size: 6.w,
          ),
        ],
      ),
    );
  }

  void _showActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.lightTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 3.h),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'edit',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 6.w,
              ),
              title: Text(
                'Düzenle',
                style: AppTheme.lightTheme.textTheme.titleMedium,
              ),
              onTap: () {
                Navigator.pop(context);
                onEdit?.call();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'category',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 6.w,
              ),
              title: Text(
                'Kategori Değiştir',
                style: AppTheme.lightTheme.textTheme.titleMedium,
              ),
              onTap: () {
                Navigator.pop(context);
                onChangeCategory?.call();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'photo_camera',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 6.w,
              ),
              title: Text(
                'Fotoğraf Ekle',
                style: AppTheme.lightTheme.textTheme.titleMedium,
              ),
              onTap: () {
                Navigator.pop(context);
                onAddPhoto?.call();
              },
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.lightTheme.dialogBackgroundColor,
        title: Text(
          'Gideri Sil',
          style: AppTheme.lightTheme.textTheme.titleLarge,
        ),
        content: Text(
          'Bu gideri silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
          style: AppTheme.lightTheme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'İptal',
              style: TextStyle(
                color: AppTheme.lightTheme.colorScheme.onSurface,
                fontSize: 12.sp,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
              onDelete?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lightTheme.colorScheme.error,
            ),
            child: Text(
              'Sil',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'ofis':
        return 'business';
      case 'ulaşım':
        return 'directions_car';
      case 'yemek':
        return 'restaurant';
      case 'kırtasiye':
        return 'edit';
      case 'teknoloji':
        return 'computer';
      case 'pazarlama':
        return 'campaign';
      case 'sağlık':
        return 'local_hospital';
      case 'eğitim':
        return 'school';
      default:
        return 'receipt';
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'ofis':
        return const Color(0xFF2196F3);
      case 'ulaşım':
        return const Color(0xFF4CAF50);
      case 'yemek':
        return const Color(0xFFFF9800);
      case 'kırtasiye':
        return const Color(0xFF9C27B0);
      case 'teknoloji':
        return const Color(0xFF607D8B);
      case 'pazarlama':
        return const Color(0xFFE91E63);
      case 'sağlık':
        return const Color(0xFFF44336);
      case 'eğitim':
        return const Color(0xFF3F51B5);
      default:
        return const Color(0xFF757575);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
