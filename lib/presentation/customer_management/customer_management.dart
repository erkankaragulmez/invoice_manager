import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../models/customer.dart';
import '../../services/customer_service.dart';
import './widgets/customer_card_widget.dart';
import './widgets/customer_creation_modal_widget.dart';
import './widgets/customer_empty_state_widget.dart';
import './widgets/customer_search_bar_widget.dart';

class CustomerManagement extends StatefulWidget {
  const CustomerManagement({Key? key}) : super(key: key);

  @override
  State<CustomerManagement> createState() => _CustomerManagementState();
}

class _CustomerManagementState extends State<CustomerManagement> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String _searchQuery = '';
  bool _isRefreshing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    setState(() {
      _searchQuery = query;
      _filterCustomers();
    });
  }

  void _filterCustomers() {
    if (_searchQuery.isEmpty) {
      _filteredCustomers = List.from(_customers);
    } else {
      _filteredCustomers = _customers.where((customer) {
        final name = customer.name.toLowerCase();
        final phone = customer.phone?.toLowerCase() ?? '';
        final searchLower = _searchQuery.toLowerCase();
        return name.contains(searchLower) || phone.contains(searchLower);
      }).toList();
    }
  }

  Future<void> _loadCustomers() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final customers = await CustomerService.instance.getCustomers();
      setState(() {
        _customers = customers;
        _filterCustomers();
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Müşteriler yüklenemedi: $error'),
          backgroundColor: AppTheme.lightTheme.colorScheme.error,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Tekrar Dene',
            onPressed: _loadCustomers,
          ),
        ),
      );
    }
  }

  Future<void> _refreshCustomers() async {
    try {
      setState(() {
        _isRefreshing = true;
        _errorMessage = null;
      });

      final customers = await CustomerService.instance.getCustomers();
      setState(() {
        _customers = customers;
        _filterCustomers();
        _isRefreshing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Müşteriler güncellendi'),
          backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (error) {
      setState(() {
        _isRefreshing = false;
        _errorMessage = error.toString();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Müşteriler güncellenemedi: $error'),
          backgroundColor: AppTheme.lightTheme.colorScheme.error,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Tekrar Dene',
            onPressed: _refreshCustomers,
          ),
        ),
      );
    }
  }

  Future<void> _showCustomerCreationModal() async {
    showDialog(
      context: context,
      builder: (context) => CustomerCreationModalWidget(
        onCustomerCreated: (customer) {
          setState(() {
            _customers.add(customer);
            _filterCustomers();
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${customer.name} başarıyla eklendi'),
              backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'Geri Al',
                onPressed: () => _undoCustomerCreation(customer.id),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _undoCustomerCreation(String customerId) async {
    try {
      await CustomerService.instance.deleteCustomer(customerId);
      setState(() {
        _customers.removeWhere((customer) => customer.id == customerId);
        _filterCustomers();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Müşteri kaldırıldı'),
          backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('İşlem geri alınamadı: $error'),
          backgroundColor: AppTheme.lightTheme.colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onCustomerUpdated(Customer updatedCustomer) {
    setState(() {
      final index = _customers.indexWhere((c) => c.id == updatedCustomer.id);
      if (index != -1) {
        _customers[index] = updatedCustomer;
        _filterCustomers();
      }
    });
  }

  void _onCustomerDeleted(String customerId) {
    setState(() {
      _customers.removeWhere((customer) => customer.id == customerId);
      _filterCustomers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Müşteri Yönetimi',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _refreshCustomers,
            icon: _isRefreshing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.lightTheme.primaryColor,
                      ),
                    ),
                  )
                : CustomIconWidget(
                    iconName: 'refresh',
                    color: AppTheme.lightTheme.primaryColor,
                    size: 24,
                  ),
            tooltip: 'Yenile',
          ),
          SizedBox(width: 2.w),
        ],
      ),
      body: Column(
        children: [
          // Preview Mode Banner for Development
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 4.w),
            color:
                AppTheme.lightTheme.colorScheme.primaryContainer.withAlpha(77),
            child: Row(
              children: [
                Icon(
                  Icons.preview,
                  size: 16,
                  color: AppTheme.lightTheme.primaryColor,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Preview Mode - Development Version',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: EdgeInsets.all(4.w),
            child: CustomerSearchBarWidget(
              controller: _searchController,
              onClear: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _filterCustomers();
                });
              },
            ),
          ),

          // Customer List
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _errorMessage != null
                    ? _buildErrorState()
                    : _filteredCustomers.isEmpty
                        ? CustomerEmptyStateWidget(
                            isSearching: _searchQuery.isNotEmpty,
                            onAddCustomer: _showCustomerCreationModal,
                          )
                        : RefreshIndicator(
                            onRefresh: _refreshCustomers,
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: EdgeInsets.symmetric(horizontal: 4.w),
                              itemCount: _filteredCustomers.length,
                              itemBuilder: (context, index) {
                                final customer = _filteredCustomers[index];
                                return CustomerCardWidget(
                                  customer: customer,
                                  onCustomerUpdated: _onCustomerUpdated,
                                  onCustomerDeleted: _onCustomerDeleted,
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCustomerCreationModal,
        tooltip: 'Yeni Müşteri Ekle',
        child: CustomIconWidget(
          iconName: 'add',
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.lightTheme.colorScheme.error,
            ),
            SizedBox(height: 2.h),
            Text(
              'Bir hata oluştu',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              _errorMessage ?? 'Bilinmeyen hata',
              style: AppTheme.lightTheme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),
            ElevatedButton(
              onPressed: _loadCustomers,
              child: Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      itemCount: 5,
      itemBuilder: (context, index) => _buildSkeletonCard(),
    );
  }

  Widget _buildSkeletonCard() {
    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 60.w,
              height: 16,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            SizedBox(height: 2.h),
            Container(
              width: 40.w,
              height: 12,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
