import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../models/customer.dart';
import '../../../services/customer_service.dart';
import './customer_creation_modal.dart';

class CustomerSelectionWidget extends StatefulWidget {
  final String? selectedCustomer;
  final Function(String) onCustomerSelected;
  final VoidCallback onAddNewCustomer;

  const CustomerSelectionWidget({
    Key? key,
    this.selectedCustomer,
    required this.onCustomerSelected,
    required this.onAddNewCustomer,
  }) : super(key: key);

  @override
  State<CustomerSelectionWidget> createState() =>
      _CustomerSelectionWidgetState();
}

class _CustomerSelectionWidgetState extends State<CustomerSelectionWidget> {
  List<Customer> customers = [];
  bool _isExpanded = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  bool _isFreeTextMode = false;
  final TextEditingController _freeTextController = TextEditingController();
  bool _isCreatingCustomer = false;

  @override
  void initState() {
    super.initState();
    _loadCustomers();

    // Initialize free text controller with selected customer if any
    if (widget.selectedCustomer != null) {
      _freeTextController.text = widget.selectedCustomer!;
      _isFreeTextMode = true;
    }
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final loadedCustomers = await CustomerService.instance.getCustomers();
      setState(() {
        customers = loadedCustomers;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Müşteriler yüklenemedi: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Customer> get filteredCustomers {
    if (_searchQuery.isEmpty) return customers;
    return customers.where((customer) {
      final name = customer.name.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query);
    }).toList();
  }

  void _showAddCustomerDialog() {
    showDialog(
      context: context,
      builder: (context) => CustomerCreationModal(
        onCustomerCreated: (Customer newCustomer) {
          setState(() {
            customers.add(newCustomer);
            _isExpanded = false;
            _searchQuery = '';
            _searchController.clear();
            _isFreeTextMode = true;
            _freeTextController.text = newCustomer.name;
          });
          widget.onCustomerSelected(newCustomer.name);
        },
      ),
    );
  }

  // New method to handle free text customer creation
  Future<void> _handleFreeTextCustomerCreation(String customerName) async {
    if (customerName.trim().isEmpty) return;

    // Check if customer already exists
    final existingCustomer = customers.firstWhere(
      (customer) =>
          customer.name.toLowerCase() == customerName.toLowerCase().trim(),
      orElse: () => Customer(
        id: '',
        businessId: '',
        name: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    if (existingCustomer.id.isNotEmpty) {
      // Customer exists, just select it
      widget.onCustomerSelected(existingCustomer.name);
      return;
    }

    // Customer doesn't exist, create new one
    setState(() {
      _isCreatingCustomer = true;
    });

    try {
      final newCustomer = await CustomerService.instance.createCustomer(
        name: customerName.trim(),
      );

      setState(() {
        customers.add(newCustomer);
        _isCreatingCustomer = false;
      });

      widget.onCustomerSelected(newCustomer.name);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Yeni müşteri "${newCustomer.name}" kataloga eklendi'),
          backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
        ),
      );
    } catch (error) {
      setState(() {
        _isCreatingCustomer = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Müşteri oluşturulamadı: $error'),
          backgroundColor: AppTheme.lightTheme.colorScheme.error,
        ),
      );
    }
  }

  void _toggleMode() {
    setState(() {
      _isFreeTextMode = !_isFreeTextMode;
      if (_isFreeTextMode) {
        _isExpanded = false;
        if (widget.selectedCustomer != null) {
          _freeTextController.text = widget.selectedCustomer!;
        }
      } else {
        _freeTextController.clear();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _freeTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Müşteri',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            TextButton.icon(
              onPressed: _toggleMode,
              icon: CustomIconWidget(
                iconName: _isFreeTextMode ? 'list' : 'edit',
                color: AppTheme.lightTheme.primaryColor,
                size: 16,
              ),
              label: Text(
                _isFreeTextMode ? 'Listeden Seç' : 'Serbest Metin',
                style: TextStyle(
                  color: AppTheme.lightTheme.primaryColor,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),

        // Free Text Mode
        if (_isFreeTextMode) ...[
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.lightTheme.dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _freeTextController,
                  decoration: InputDecoration(
                    hintText: 'Müşteri adını yazın...',
                    prefixIcon: CustomIconWidget(
                      iconName: 'person',
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    suffixIcon: _isCreatingCustomer
                        ? Container(
                            width: 20,
                            height: 20,
                            padding: EdgeInsets.all(2.w),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 1.5.h,
                    ),
                  ),
                  textCapitalization: TextCapitalization.words,
                  onSubmitted: _handleFreeTextCustomerCreation,
                  onChanged: (value) {
                    widget.onCustomerSelected(value);
                  },
                ),
                if (_freeTextController.text.isNotEmpty) ...[
                  Divider(height: 1, color: AppTheme.lightTheme.dividerColor),
                  Container(
                    padding: EdgeInsets.all(3.w),
                    child: Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'info_outline',
                          color: AppTheme.lightTheme.colorScheme.primary,
                          size: 16,
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: Text(
                            'Enter tuşuna basın veya faturayı kaydedin. Müşteri yoksa otomatik kataloga eklenecek.',
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(
                              color: AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        if (_freeTextController.text.trim().isNotEmpty)
                          TextButton(
                            onPressed: () => _handleFreeTextCustomerCreation(
                                _freeTextController.text),
                            child: Text(
                              'Ekle',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ]

        // List Selection Mode
        else ...[
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.lightTheme.dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.selectedCustomer ?? 'Müşteri Seçin',
                            style: AppTheme.lightTheme.textTheme.bodyMedium
                                ?.copyWith(
                              color: widget.selectedCustomer != null
                                  ? AppTheme.lightTheme.colorScheme.onSurface
                                  : AppTheme
                                      .lightTheme.colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        CustomIconWidget(
                          iconName: _isExpanded
                              ? 'keyboard_arrow_up'
                              : 'keyboard_arrow_down',
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isExpanded) ...[
                  Divider(height: 1, color: AppTheme.lightTheme.dividerColor),
                  Container(
                    padding: EdgeInsets.all(3.w),
                    child: Column(
                      children: [
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Müşteri ara...',
                            prefixIcon: CustomIconWidget(
                              iconName: 'search',
                              color: AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                  color: AppTheme.lightTheme.dividerColor),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 3.w, vertical: 1.h),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                        SizedBox(height: 2.h),
                        Container(
                          constraints: BoxConstraints(maxHeight: 30.h),
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                InkWell(
                                  onTap: _showAddCustomerDialog,
                                  child: Container(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 1.5.h),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(2.w),
                                          decoration: BoxDecoration(
                                            color: AppTheme
                                                .lightTheme.primaryColor
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: CustomIconWidget(
                                            iconName: 'add',
                                            color: AppTheme
                                                .lightTheme.primaryColor,
                                            size: 20,
                                          ),
                                        ),
                                        SizedBox(width: 3.w),
                                        Text(
                                          'Yeni Müşteri Ekle',
                                          style: AppTheme
                                              .lightTheme.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: AppTheme
                                                .lightTheme.primaryColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (_isLoading) ...[
                                  Divider(
                                      color: AppTheme.lightTheme.dividerColor),
                                  Container(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 2.h),
                                    child: CircularProgressIndicator(),
                                  ),
                                ] else if (filteredCustomers.isNotEmpty) ...[
                                  Divider(
                                      color: AppTheme.lightTheme.dividerColor),
                                  ...filteredCustomers
                                      .map((customer) => InkWell(
                                            onTap: () {
                                              widget.onCustomerSelected(
                                                  customer.name);
                                              setState(() {
                                                _isExpanded = false;
                                                _searchQuery = '';
                                                _searchController.clear();
                                              });
                                            },
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 1.5.h),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 10.w,
                                                    height: 10.w,
                                                    decoration: BoxDecoration(
                                                      color: AppTheme.lightTheme
                                                          .colorScheme.surface,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                      border: Border.all(
                                                        color: AppTheme
                                                            .lightTheme
                                                            .dividerColor,
                                                      ),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        customer.name
                                                            .substring(0, 1)
                                                            .toUpperCase(),
                                                        style: AppTheme
                                                            .lightTheme
                                                            .textTheme
                                                            .titleMedium
                                                            ?.copyWith(
                                                          color: AppTheme
                                                              .lightTheme
                                                              .primaryColor,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(width: 3.w),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          customer.name,
                                                          style: AppTheme
                                                              .lightTheme
                                                              .textTheme
                                                              .bodyMedium
                                                              ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                        if (customer.phone !=
                                                            null) ...[
                                                          SizedBox(
                                                              height: 0.5.h),
                                                          Text(
                                                            customer.phone!,
                                                            style: AppTheme
                                                                .lightTheme
                                                                .textTheme
                                                                .bodySmall,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ))
                                      .toList(),
                                ] else if (_searchQuery.isNotEmpty) ...[
                                  Divider(
                                      color: AppTheme.lightTheme.dividerColor),
                                  Container(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 2.h),
                                    child: Column(
                                      children: [
                                        Text(
                                          'Müşteri bulunamadı',
                                          style: AppTheme
                                              .lightTheme.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: AppTheme.lightTheme
                                                .colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        SizedBox(height: 1.h),
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            setState(() {
                                              _isExpanded = false;
                                              _isFreeTextMode = true;
                                              _freeTextController.text =
                                                  _searchQuery;
                                              _searchController.clear();
                                              _searchQuery = '';
                                            });
                                            widget.onCustomerSelected(
                                                _freeTextController.text);
                                          },
                                          icon: CustomIconWidget(
                                            iconName: 'add',
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                          label: Text(
                                            '"$_searchQuery" adıyla oluştur',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme
                                                .lightTheme.primaryColor,
                                            foregroundColor: Colors.white,
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 3.w,
                                              vertical: 1.h,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else if (customers.isEmpty) ...[
                                  Divider(
                                      color: AppTheme.lightTheme.dividerColor),
                                  Container(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 2.h),
                                    child: Text(
                                      'Henüz müşteri bulunmuyor',
                                      style: AppTheme
                                          .lightTheme.textTheme.bodyMedium
                                          ?.copyWith(
                                        color: AppTheme.lightTheme.colorScheme
                                            .onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
