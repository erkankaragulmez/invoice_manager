import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../models/customer.dart';
import '../../../services/customer_service.dart';

class CustomerCreationModalWidget extends StatefulWidget {
  final Function(Customer) onCustomerCreated;

  const CustomerCreationModalWidget({
    Key? key,
    required this.onCustomerCreated,
  }) : super(key: key);

  @override
  State<CustomerCreationModalWidget> createState() =>
      _CustomerCreationModalWidgetState();
}

class _CustomerCreationModalWidgetState
    extends State<CustomerCreationModalWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _createCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Check if customer with same name already exists
      final existingCustomerExists = await CustomerService.instance
          .customerExistsByName(_nameController.text.trim());

      if (existingCustomerExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bu isimde bir müşteri zaten mevcut'),
            backgroundColor: AppTheme.lightTheme.colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final customer = await CustomerService.instance.createCustomer(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
      );

      widget.onCustomerCreated(customer);
      Navigator.of(context).pop();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Müşteri oluşturulamadı: $error'),
          backgroundColor: AppTheme.lightTheme.colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }

    final cleanPhone = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleanPhone.length < 10) {
      return 'Geçerli bir telefon numarası girin';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          CustomIconWidget(
            iconName: 'person_add',
            color: AppTheme.lightTheme.primaryColor,
            size: 24,
          ),
          SizedBox(width: 2.w),
          Text(
            'Yeni Müşteri',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 85.w,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customer Name Field (Required)
              Text(
                'Müşteri Ünvanı *',
                style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 1.h),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Müşteri ünvanını girin',
                  prefixIcon: CustomIconWidget(
                    iconName: 'business',
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 3.w,
                    vertical: 1.5.h,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Müşteri ünvanı gereklidir';
                  }
                  if (value.trim().length < 2) {
                    return 'Müşteri ünvanı en az 2 karakter olmalıdır';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
                enabled: !_isLoading,
                autofocus: true,
              ),

              SizedBox(height: 3.h),

              // Phone Field (Optional)
              Text(
                'Telefon Numarası',
                style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                'İsteğe bağlı - fatura oluşturmak için yeterli',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 1.h),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  hintText: '+90 532 123 45 67',
                  prefixIcon: CustomIconWidget(
                    iconName: 'phone',
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 3.w,
                    vertical: 1.5.h,
                  ),
                ),
                keyboardType: TextInputType.phone,
                enabled: !_isLoading,
                validator: _validatePhone,
              ),

              SizedBox(height: 3.h),

              // Information Note
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.primary
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'info',
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 20,
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        'Fatura oluştururken müşteri katalogunundan seçebilirsiniz. Müşteri yoksa fatura oluştururken yeni müşteri otomatik olarak eklenecektir.',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(
            'İptal',
            style: TextStyle(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createCustomer,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.lightTheme.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'Oluştur',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
        ),
      ],
    );
  }
}
