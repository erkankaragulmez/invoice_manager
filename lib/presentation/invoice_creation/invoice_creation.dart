import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/customer_service.dart';
import './widgets/customer_selection_widget.dart';
import './widgets/invoice_totals_widget.dart';
import './widgets/line_item_widget.dart';
import './widgets/payment_terms_dropdown_widget.dart';
import './widgets/tax_rate_dropdown_widget.dart';

class InvoiceCreation extends StatefulWidget {
  const InvoiceCreation({Key? key}) : super(key: key);

  @override
  State<InvoiceCreation> createState() => _InvoiceCreationState();
}

class _InvoiceCreationState extends State<InvoiceCreation> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Form controllers
  final _invoiceNumberController = TextEditingController();
  final _notesController = TextEditingController();

  // Form data
  String? _selectedCustomer;
  DateTime _invoiceDate = DateTime.now();
  List<Map<String, dynamic>> _lineItems = [];
  double _taxRate = 18.0;
  String _paymentTerms = 'net30';
  bool _isDraft = false;
  bool _hasUnsavedChanges = false;

  // Auto-save timer
  Timer? _autoSaveTimer;

  // Character counter for notes
  final int _maxNotesLength = 500;

  @override
  void initState() {
    super.initState();
    _generateInvoiceNumber();
    _addInitialLineItem();
    _startAutoSave();

    // Listen for changes to mark as unsaved
    _invoiceNumberController.addListener(_markAsUnsaved);
    _notesController.addListener(_markAsUnsaved);
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _invoiceNumberController.dispose();
    _notesController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _generateInvoiceNumber() {
    final now = DateTime.now();
    final invoiceNumber =
        'INV-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(8)}';
    _invoiceNumberController.text = invoiceNumber;
  }

  void _addInitialLineItem() {
    _lineItems.add({
      'id': 1,
      'description': '',
      'quantity': 1.0,
      'unitPrice': 0.0,
      'total': 0.0,
    });
  }

  void _startAutoSave() {
    _autoSaveTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (_hasUnsavedChanges) {
        _saveDraft();
      }
    });
  }

  void _markAsUnsaved() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  void _saveDraft() {
    setState(() {
      _isDraft = true;
      _hasUnsavedChanges = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Taslak otomatik kaydedildi'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  double get _subtotal {
    return _lineItems.fold(
        0.0, (sum, item) => sum + (item['total'] as double? ?? 0.0));
  }

  double get _taxAmount {
    return _subtotal * (_taxRate / 100);
  }

  double get _grandTotal {
    return _subtotal + _taxAmount;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _invoiceDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: Locale('tr', 'TR'),
    );
    if (picked != null && picked != _invoiceDate) {
      setState(() {
        _invoiceDate = picked;
        _markAsUnsaved();
      });
    }
  }

  void _addLineItem() {
    setState(() {
      _lineItems.add({
        'id': _lineItems.length + 1,
        'description': '',
        'quantity': 1.0,
        'unitPrice': 0.0,
        'total': 0.0,
      });
      _markAsUnsaved();
    });

    // Scroll to bottom to show new item
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _updateLineItem(int index, Map<String, dynamic> updatedItem) {
    setState(() {
      _lineItems[index] = updatedItem;
      _markAsUnsaved();
    });
  }

  void _deleteLineItem(int index) {
    if (_lineItems.length > 1) {
      setState(() {
        _lineItems.removeAt(index);
        // Reindex items
        for (int i = 0; i < _lineItems.length; i++) {
          _lineItems[i]['id'] = i + 1;
        }
        _markAsUnsaved();
      });
    }
  }

  void _showAddCustomerDialog() {
    // This method is now handled by the CustomerSelectionWidget internally
    // No action needed here - kept for backward compatibility
  }

  bool _validateForm() {
    if (_selectedCustomer == null || _selectedCustomer!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lütfen bir müşteri seçin')),
      );
      return false;
    }

    if (_invoiceNumberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fatura numarası gerekli')),
      );
      return false;
    }

    bool hasValidItems = _lineItems.any((item) =>
        (item['description'] as String).isNotEmpty &&
        (item['unitPrice'] as double) > 0);

    if (!hasValidItems) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('En az bir geçerli ürün/hizmet ekleyin')),
      );
      return false;
    }

    return true;
  }

  void _saveInvoice() {
    if (!_validateForm()) return;

    // Handle free text customer creation before saving invoice
    _handleCustomerCreationBeforeSave();

    setState(() {
      _hasUnsavedChanges = false;
    });

    _showSuccessDialog();
  }

  Future<void> _handleCustomerCreationBeforeSave() async {
    if (_selectedCustomer == null || _selectedCustomer!.isEmpty) return;

    try {
      // Check if the selected customer exists in the database
      final customers =
          await CustomerService.instance.searchCustomers(_selectedCustomer!);

      // If customer doesn't exist, create it automatically
      if (customers.isEmpty) {
        await CustomerService.instance.createCustomer(name: _selectedCustomer!);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Müşteri "$_selectedCustomer" kataloga eklendi'),
              backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (error) {
      // Don't block invoice creation if customer creation fails
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Müşteri kataloga eklenemedi, ancak fatura kaydedildi'),
            backgroundColor: AppTheme.lightTheme.colorScheme.error,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'check_circle',
              color: AppTheme.lightTheme.colorScheme.tertiary,
              size: 24,
            ),
            SizedBox(width: 2.w),
            Text('Fatura Kaydedildi'),
          ],
        ),
        content:
            Text('Faturanız başarıyla kaydedildi. Ne yapmak istiyorsunuz?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacementNamed('/dashboard');
            },
            child: Text('Ana Sayfa'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetForm();
            },
            child: Text('Yeni Fatura'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _shareInvoice();
            },
            child: Text('Paylaş'),
          ),
        ],
      ),
    );
  }

  void _shareInvoice() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Paylaşım özelliği yakında eklenecek')),
    );
  }

  void _resetForm() {
    setState(() {
      _selectedCustomer = null;
      _invoiceDate = DateTime.now();
      _lineItems.clear();
      _taxRate = 18.0;
      _paymentTerms = 'net30';
      _isDraft = false;
      _hasUnsavedChanges = false;
    });

    _invoiceNumberController.clear();
    _notesController.clear();
    _generateInvoiceNumber();
    _addInitialLineItem();
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Kaydedilmemiş Değişiklikler'),
        content:
            Text('Değişiklikleriniz kaydedilmedi. Ne yapmak istiyorsunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Kaydetme'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              _saveDraft();
              Navigator.of(context).pop(true);
            },
            child: Text('Kaydet'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text('Yeni Fatura'),
          leading: IconButton(
            icon: CustomIconWidget(
              iconName: 'arrow_back',
              color: AppTheme.lightTheme.colorScheme.onSurface,
              size: 24,
            ),
            onPressed: () async {
              if (await _onWillPop()) {
                Navigator.of(context).pop();
              }
            },
          ),
          actions: [
            if (_hasUnsavedChanges)
              Container(
                margin: EdgeInsets.only(right: 2.w),
                child: TextButton.icon(
                  onPressed: _saveDraft,
                  icon: CustomIconWidget(
                    iconName: 'save',
                    color: AppTheme.lightTheme.colorScheme.tertiary,
                    size: 20,
                  ),
                  label: Text(
                    'Taslak',
                    style: TextStyle(
                        color: AppTheme.lightTheme.colorScheme.tertiary),
                  ),
                ),
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer Selection
                CustomerSelectionWidget(
                  selectedCustomer: _selectedCustomer,
                  onCustomerSelected: (customer) {
                    setState(() {
                      _selectedCustomer = customer;
                      _markAsUnsaved();
                    });
                  },
                  onAddNewCustomer: _showAddCustomerDialog,
                ),

                SizedBox(height: 3.h),

                // Invoice Number and Date
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fatura No',
                            style: AppTheme.lightTheme.textTheme.titleMedium
                                ?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 1.h),
                          TextField(
                            controller: _invoiceNumberController,
                            decoration: InputDecoration(
                              hintText: 'Fatura numarası',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 3.w, vertical: 1.h),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fatura Tarihi',
                            style: AppTheme.lightTheme.textTheme.titleMedium
                                ?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 1.h),
                          InkWell(
                            onTap: _selectDate,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 3.w, vertical: 1.5.h),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: AppTheme.lightTheme.dividerColor),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _formatDate(_invoiceDate),
                                      style: AppTheme
                                          .lightTheme.textTheme.bodyMedium,
                                    ),
                                  ),
                                  CustomIconWidget(
                                    iconName: 'calendar_today',
                                    color: AppTheme.lightTheme.colorScheme
                                        .onSurfaceVariant,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 3.h),

                // Line Items Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ürün/Hizmetler',
                      style:
                          AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _addLineItem,
                      icon: CustomIconWidget(
                        iconName: 'add',
                        color: AppTheme.lightTheme.primaryColor,
                        size: 20,
                      ),
                      label: Text('Ekle'),
                    ),
                  ],
                ),

                SizedBox(height: 2.h),

                // Line Items List
                ...(_lineItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;

                  return LineItemWidget(
                    key: Key('line_item_$index'),
                    item: item,
                    onItemUpdated: (updatedItem) =>
                        _updateLineItem(index, updatedItem),
                    onItemDeleted: () => _deleteLineItem(index),
                    isLast: index == _lineItems.length - 1,
                  );
                }).toList()),

                SizedBox(height: 3.h),

                // Tax Rate
                TaxRateDropdownWidget(
                  selectedTaxRate: _taxRate,
                  onTaxRateChanged: (rate) {
                    setState(() {
                      _taxRate = rate;
                      _markAsUnsaved();
                    });
                  },
                ),

                SizedBox(height: 3.h),

                // Payment Terms
                PaymentTermsDropdownWidget(
                  selectedPaymentTerm: _paymentTerms,
                  onPaymentTermChanged: (terms) {
                    setState(() {
                      _paymentTerms = terms;
                      _markAsUnsaved();
                    });
                  },
                ),

                SizedBox(height: 3.h),

                // Notes
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notlar',
                      style:
                          AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    TextField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        hintText: 'Ek bilgiler, özel talimatlar...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 3.w, vertical: 1.h),
                        counterText:
                            '${_notesController.text.length}/$_maxNotesLength',
                      ),
                      maxLines: 3,
                      maxLength: _maxNotesLength,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(_maxNotesLength),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: 3.h),

                // Invoice Totals
                InvoiceTotalsWidget(
                  subtotal: _subtotal,
                  taxRate: _taxRate,
                  taxAmount: _taxAmount,
                  grandTotal: _grandTotal,
                ),

                SizedBox(height: 4.h),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 6.h,
                  child: ElevatedButton(
                    onPressed: _saveInvoice,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.lightTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Faturayı Kaydet',
                      style:
                          AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 2.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
