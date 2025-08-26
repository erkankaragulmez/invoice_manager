import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/app_export.dart';
import '../../../models/customer.dart';
import '../../../services/customer_service.dart';
import './customer_edit_modal_widget.dart';

class CustomerCardWidget extends StatelessWidget {
  final Customer customer;
  final Function(Customer) onCustomerUpdated;
  final Function(String) onCustomerDeleted;

  const CustomerCardWidget({
    Key? key,
    required this.customer,
    required this.onCustomerUpdated,
    required this.onCustomerDeleted,
  }) : super(key: key);

  String _formatPhone(String? phone) {
    if (phone == null || phone.isEmpty) return '';

    // Remove all non-digit characters
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');

    // Format as Turkish phone number
    if (digits.length == 11 && digits.startsWith('0')) {
      // Format: 0XXX XXX XX XX
      return '${digits.substring(0, 4)} ${digits.substring(4, 7)} ${digits.substring(7, 9)} ${digits.substring(9)}';
    } else if (digits.length == 13 && digits.startsWith('90')) {
      // Format: +90 XXX XXX XX XX
      return '+90 ${digits.substring(2, 5)} ${digits.substring(5, 8)} ${digits.substring(8, 10)} ${digits.substring(10)}';
    }

    return phone; // Return original if formatting fails
  }

  Future<void> _makePhoneCall(String phone) async {
    try {
      final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
      final phoneUrl = 'tel:$cleanPhone';
      if (await canLaunchUrl(Uri.parse(phoneUrl))) {
        await launchUrl(Uri.parse(phoneUrl));
      } else {
        throw 'Telefon araması yapılamıyor';
      }
    } catch (error) {
      // Silently fail - don't show error to user
    }
  }

  void _showEditModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CustomerEditModalWidget(
        customer: customer,
        onCustomerUpdated: onCustomerUpdated,
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'warning',
              color: AppTheme.lightTheme.colorScheme.error,
              size: 24,
            ),
            SizedBox(width: 2.w),
            Text(
              'Müşteri Sil',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          '${customer.name} müşterisini silmek istediğinizden emin misiniz?\n\nBu işlem geri alınamaz ve müşteriyle ilgili tüm faturalar etkilenebilir.',
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
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteCustomer(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lightTheme.colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: Text('Sil'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCustomer(BuildContext context) async {
    try {
      await CustomerService.instance.deleteCustomer(customer.id);
      onCustomerDeleted(customer.id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${customer.name} silindi'),
          backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Müşteri silinemedi: $error'),
          backgroundColor: AppTheme.lightTheme.colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedPhone = _formatPhone(customer.phone);
    final hasPhone = customer.phone?.isNotEmpty == true;

    return Dismissible(
      key: Key(customer.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 4.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'delete',
              color: AppTheme.lightTheme.colorScheme.error,
              size: 24,
            ),
            SizedBox(height: 0.5.h),
            Text(
              'Sil',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        _showDeleteConfirmation(context);
        return false; // Don't auto-dismiss, wait for confirmation
      },
      child: Card(
        margin: EdgeInsets.only(bottom: 2.h),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _showEditModal(context),
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              children: [
                // Customer Avatar
                Container(
                  width: 12.w,
                  height: 12.w,
                  decoration: BoxDecoration(
                    color:
                        AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.w),
                  ),
                  child: Center(
                    child: Text(
                      customer.name.isNotEmpty
                          ? customer.name.substring(0, 1).toUpperCase()
                          : 'M',
                      style:
                          AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.lightTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 4.w),

                // Customer Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customer Name
                      Text(
                        customer.name,
                        style:
                            AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      if (hasPhone) ...[
                        SizedBox(height: 0.5.h),
                        Row(
                          children: [
                            CustomIconWidget(
                              iconName: 'phone',
                              color: AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                              size: 14,
                            ),
                            SizedBox(width: 1.w),
                            Expanded(
                              child: Text(
                                formattedPhone,
                                style: AppTheme.lightTheme.textTheme.bodyMedium
                                    ?.copyWith(
                                  color: AppTheme
                                      .lightTheme.colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],

                      if (customer.email?.isNotEmpty == true) ...[
                        SizedBox(height: 0.5.h),
                        Row(
                          children: [
                            CustomIconWidget(
                              iconName: 'email',
                              color: AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                              size: 14,
                            ),
                            SizedBox(width: 1.w),
                            Expanded(
                              child: Text(
                                customer.email!,
                                style: AppTheme.lightTheme.textTheme.bodySmall
                                    ?.copyWith(
                                  color: AppTheme
                                      .lightTheme.colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Action Buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasPhone)
                      IconButton(
                        onPressed: () => _makePhoneCall(customer.phone!),
                        icon: CustomIconWidget(
                          iconName: 'call',
                          color: AppTheme.lightTheme.colorScheme.tertiary,
                          size: 20,
                        ),
                        tooltip: 'Ara',
                        visualDensity: VisualDensity.compact,
                      ),
                    PopupMenuButton<String>(
                      icon: CustomIconWidget(
                        iconName: 'more_vert',
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      tooltip: 'Seçenekler',
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              CustomIconWidget(
                                iconName: 'edit',
                                color: AppTheme.lightTheme.colorScheme.primary,
                                size: 16,
                              ),
                              SizedBox(width: 2.w),
                              Text('Düzenle'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              CustomIconWidget(
                                iconName: 'delete',
                                color: AppTheme.lightTheme.colorScheme.error,
                                size: 16,
                              ),
                              SizedBox(width: 2.w),
                              Text(
                                'Sil',
                                style: TextStyle(
                                  color: AppTheme.lightTheme.colorScheme.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _showEditModal(context);
                            break;
                          case 'delete':
                            _showDeleteConfirmation(context);
                            break;
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
