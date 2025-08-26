import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class LineItemWidget extends StatefulWidget {
  final Map<String, dynamic> item;
  final Function(Map<String, dynamic>) onItemUpdated;
  final VoidCallback onItemDeleted;
  final bool isLast;

  const LineItemWidget({
    Key? key,
    required this.item,
    required this.onItemUpdated,
    required this.onItemDeleted,
    this.isLast = false,
  }) : super(key: key);

  @override
  State<LineItemWidget> createState() => _LineItemWidgetState();
}

class _LineItemWidgetState extends State<LineItemWidget> {
  late TextEditingController _descriptionController;
  late TextEditingController _quantityController;
  late TextEditingController _unitPriceController;

  bool _showDeleteButton = false;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
        text: widget.item['description'] as String? ?? '');
    _quantityController = TextEditingController(
        text: (widget.item['quantity'] as double?)?.toString() ?? '1');
    _unitPriceController = TextEditingController(
        text: (widget.item['unitPrice'] as double?)?.toString() ?? '');
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    super.dispose();
  }

  void _updateItem() {
    final quantity = double.tryParse(_quantityController.text) ?? 1.0;
    final unitPrice = double.tryParse(_unitPriceController.text) ?? 0.0;
    final total = quantity * unitPrice;

    final updatedItem = Map<String, dynamic>.from(widget.item);
    updatedItem['description'] = _descriptionController.text;
    updatedItem['quantity'] = quantity;
    updatedItem['unitPrice'] = unitPrice;
    updatedItem['total'] = total;

    widget.onItemUpdated(updatedItem);
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(2).replaceAll('.', ',')} ₺';
  }

  @override
  Widget build(BuildContext context) {
    final total = (widget.item['quantity'] as double? ?? 1.0) *
        (widget.item['unitPrice'] as double? ?? 0.0);

    return Dismissible(
      key: Key(widget.item['id'].toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 4.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.error,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'delete',
              color: Colors.white,
              size: 24,
            ),
            SizedBox(height: 0.5.h),
            Text(
              'Sil',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Ürünü Sil'),
                content: Text(
                    'Bu ürünü faturadan silmek istediğinizden emin misiniz?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text('İptal'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(
                      'Sil',
                      style: TextStyle(
                          color: AppTheme.lightTheme.colorScheme.error),
                    ),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (direction) {
        widget.onItemDeleted();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ürün silindi'),
            action: SnackBarAction(
              label: 'Geri Al',
              onPressed: () {
                // This would need to be handled by parent widget
              },
            ),
          ),
        );
      },
      child: GestureDetector(
        onLongPress: () {
          setState(() {
            _showDeleteButton = !_showDeleteButton;
          });
        },
        child: Container(
          margin: EdgeInsets.only(bottom: widget.isLast ? 0 : 2.h),
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.lightTheme.dividerColor),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Ürün/Hizmet ${widget.item['id']}',
                      style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (_showDeleteButton)
                    InkWell(
                      onTap: widget.onItemDeleted,
                      child: Container(
                        padding: EdgeInsets.all(1.w),
                        decoration: BoxDecoration(
                          color: AppTheme.lightTheme.colorScheme.error
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: CustomIconWidget(
                          iconName: 'delete',
                          color: AppTheme.lightTheme.colorScheme.error,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 2.h),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Açıklama',
                  hintText: 'Ürün veya hizmet açıklaması',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                ),
                maxLines: 2,
                onChanged: (value) => _updateItem(),
              ),
              SizedBox(height: 2.h),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _quantityController,
                      decoration: InputDecoration(
                        labelText: 'Miktar',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 3.w, vertical: 1.h),
                      ),
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*')),
                      ],
                      onChanged: (value) => _updateItem(),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _unitPriceController,
                      decoration: InputDecoration(
                        labelText: 'Birim Fiyat (₺)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 3.w, vertical: 1.h),
                      ),
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*')),
                      ],
                      onChanged: (value) => _updateItem(),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color:
                      AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Toplam:',
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _formatCurrency(total),
                      style:
                          AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.lightTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
