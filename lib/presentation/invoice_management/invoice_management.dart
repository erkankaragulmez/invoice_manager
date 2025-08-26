import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../models/invoice.dart';
import '../../services/auth_service.dart';
import '../../services/invoice_service.dart';
import '../invoice_creation/widgets/customer_creation_modal.dart';
import './widgets/batch_actions_toolbar.dart';
import './widgets/empty_state_widget.dart';
import './widgets/invoice_card_widget.dart';
import './widgets/invoice_filter_bottom_sheet.dart';
import './widgets/invoice_search_bar.dart';

class InvoiceManagement extends StatefulWidget {
  const InvoiceManagement({Key? key}) : super(key: key);

  @override
  State<InvoiceManagement> createState() => _InvoiceManagementState();
}

class _InvoiceManagementState extends State<InvoiceManagement> {
  // Initialize all variables to prevent LateInitializationError
  String _searchQuery = '';
  String _selectedFilter = 'Tümü';
  bool _isMultiSelectMode = false;
  final Set<String> _selectedInvoices = <String>{};
  bool _isLoading = false;
  bool _isRefreshing = false;
  List<Invoice> _allInvoices = <Invoice>[];
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _safeInitializeAndLoadData();
    });
  }

  Future<void> _safeInitializeAndLoadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _isInitialized = false;
    });

    try {
      // Initialize auth with timeout
      bool authInitialized = false;
      try {
        authInitialized = await AuthService.initializeAuth().timeout(
          const Duration(seconds: 10),
        );
      } catch (timeoutError) {
        print('Auth initialization timeout: $timeoutError');
        authInitialized = false;
      }

      if (mounted) {
        if (authInitialized || AuthService.isLoggedIn) {
          await _loadInvoices();
        }

        setState(() {
          _isInitialized = true;
        });
      }
    } catch (error) {
      if (mounted) {
        _showErrorMessage('Sistem başlatılırken hata oluştu: $error');
        setState(() {
          _isInitialized = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadInvoices() async {
    if (!mounted) return;

    try {
      final invoices = await InvoiceService.instance.getInvoices().timeout(
        const Duration(seconds: 15),
      );

      if (mounted) {
        setState(() {
          _allInvoices = invoices;
        });
      }
    } catch (error) {
      if (mounted) {
        print('Invoice loading error: $error');
        _showErrorMessage('Faturalar yüklenirken hata oluştu. Tekrar deneyin.');
        // Keep empty list instead of breaking the app
        setState(() {
          _allInvoices = <Invoice>[];
        });
      }
    }
  }

  List<Invoice> get _filteredInvoices {
    if (!_isInitialized || _allInvoices.isEmpty) {
      return <Invoice>[];
    }

    List<Invoice> filtered = List<Invoice>.from(_allInvoices);

    // Apply search filter with null safety
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((invoice) {
        final customerName = invoice.customer?.name.toLowerCase() ?? '';
        final invoiceNumber = invoice.invoiceNumber.toLowerCase();
        final amount = invoice.totalAmount.toString().toLowerCase();
        final query = _searchQuery.toLowerCase();

        return customerName.contains(query) ||
            invoiceNumber.contains(query) ||
            amount.contains(query);
      }).toList();
    }

    // Apply status filter
    if (_selectedFilter != 'Tümü') {
      String filterStatus = _getFilterStatus(_selectedFilter);
      if (filterStatus.isNotEmpty) {
        filtered = filtered
            .where((invoice) => invoice.status == filterStatus)
            .toList();
      }
    }

    return filtered;
  }

  String _getFilterStatus(String filterText) {
    switch (filterText) {
      case 'Ödendi':
        return 'paid';
      case 'Beklemede':
        return 'pending';
      case 'Gecikmiş':
        return 'overdue';
      case 'Taslak':
        return 'draft';
      case 'İptal':
        return 'cancelled';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: _isMultiSelectMode ? null : _buildAppBar(),
      body: Column(
        children: [
          if (!_isMultiSelectMode) ...[
            InvoiceSearchBar(
              searchQuery: _searchQuery,
              onSearchChanged: (query) {
                if (mounted) {
                  setState(() {
                    _searchQuery = query;
                  });
                }
              },
              onFilterTap: _showFilterBottomSheet,
            ),
          ],
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
      bottomNavigationBar:
          _isMultiSelectMode ? _buildBatchActionsToolbar() : null,
      floatingActionButton:
          _isMultiSelectMode ? null : _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Faturalar',
        style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        // Add Customer Button
        GestureDetector(
          onTap: _showCustomerCreationModal,
          child: Container(
            margin: EdgeInsets.only(right: 2.w),
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.secondary
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomIconWidget(
              iconName: 'person_add',
              color: AppTheme.lightTheme.colorScheme.secondary,
              size: 5.w,
            ),
          ),
        ),
        GestureDetector(
          onTap: _refreshInvoices,
          child: Container(
            margin: EdgeInsets.only(right: 4.w),
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.primary
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomIconWidget(
              iconName: _isRefreshing ? 'refresh' : 'sync',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 5.w,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (!_isInitialized) {
      return _buildInitializingState();
    }

    if (_allInvoices.isEmpty &&
        _searchQuery.isEmpty &&
        _selectedFilter == 'Tümü') {
      return EmptyStateWidget(
        onCreateInvoice: () =>
            Navigator.pushNamed(context, '/invoice-creation'),
      );
    }

    if (_filteredInvoices.isEmpty) {
      return _buildNoResultsState();
    }

    return RefreshIndicator(
      onRefresh: _refreshInvoices,
      color: AppTheme.lightTheme.colorScheme.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _filteredInvoices.length,
        itemBuilder: (context, index) {
          final invoice = _filteredInvoices[index];
          final isSelected = _selectedInvoices.contains(invoice.id);

          return InvoiceCardWidget(
            invoice: _invoiceToMap(invoice),
            isSelected: isSelected,
            onTap: () => _handleInvoiceTap(invoice),
            onLongPress: () => _handleInvoiceLongPress(invoice.id),
            onMarkAsPaid: () => _markInvoiceAsPaid(invoice.id),
            onEdit: () => _editInvoice(invoice.id),
            onShare: () => _shareInvoice(invoice.id),
            onDelete: () => _deleteInvoice(invoice.id),
          );
        },
      ),
    );
  }

  Widget _buildInitializingState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppTheme.lightTheme.colorScheme.primary,
            ),
            SizedBox(height: 4.h),
            Text(
              'Sistem başlatılıyor...',
              style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _invoiceToMap(Invoice invoice) {
    String statusText = _getStatusText(invoice.status);

    return {
      "id": invoice.id,
      "customerName": invoice.customer?.name ?? 'Bilinmeyen Müşteri',
      "invoiceNumber": invoice.invoiceNumber,
      "amount": _formatCurrency(invoice.totalAmount),
      "dueDate": _formatDate(invoice.dueDate),
      "status": statusText,
      "createdDate": _formatDate(invoice.issueDate),
    };
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'paid':
        return 'Ödendi';
      case 'pending':
        return 'Beklemede';
      case 'overdue':
        return 'Gecikmiş';
      case 'draft':
        return 'Taslak';
      case 'cancelled':
        return 'İptal';
      default:
        return 'Bilinmeyen';
    }
  }

  String _formatCurrency(double amount) {
    return '₺${amount.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _showCustomerCreationModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CustomerCreationModal(
        onCustomerCreated: (customer) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('${customer.name} müşterisi başarıyla oluşturuldu'),
                backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppTheme.lightTheme.colorScheme.shadow,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60.w,
                height: 2.h,
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              SizedBox(height: 1.h),
              Container(
                width: 40.w,
                height: 1.5.h,
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              SizedBox(height: 2.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 25.w,
                    height: 1.5.h,
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Container(
                    width: 20.w,
                    height: 1.5.h,
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 30.w,
              height: 30.w,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(15.w),
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: 'search_off',
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  size: 15.w,
                ),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Sonuç Bulunamadı',
              style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            Text(
              'Arama kriterlerinize uygun fatura bulunamadı. Farklı anahtar kelimeler deneyin.',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            OutlinedButton(
              onPressed: () {
                if (mounted) {
                  setState(() {
                    _searchQuery = '';
                    _selectedFilter = 'Tümü';
                  });
                }
              },
              child: const Text('Filtreleri Temizle'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBatchActionsToolbar() {
    return BatchActionsToolbar(
      selectedCount: _selectedInvoices.length,
      onMarkAllAsPaid: _markSelectedInvoicesAsPaid,
      onDeleteAll: _deleteSelectedInvoices,
      onExportAll: _exportSelectedInvoices,
      onClearSelection: _clearSelection,
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () => Navigator.pushNamed(context, '/invoice-creation'),
      child: CustomIconWidget(
        iconName: 'add',
        color: AppTheme.lightTheme.colorScheme.onPrimary,
        size: 6.w,
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InvoiceFilterBottomSheet(
        selectedFilter: _selectedFilter,
        onFilterChanged: (filter) {
          if (mounted) {
            setState(() {
              _selectedFilter = filter;
            });
          }
        },
      ),
    );
  }

  void _handleInvoiceTap(Invoice invoice) {
    if (_isMultiSelectMode) {
      _toggleInvoiceSelection(invoice.id);
    } else {
      // Navigate to invoice detail
      Navigator.pushNamed(context, '/invoice-detail',
          arguments: _invoiceToMap(invoice));
    }
  }

  void _handleInvoiceLongPress(String invoiceId) {
    if (!_isMultiSelectMode) {
      setState(() {
        _isMultiSelectMode = true;
        _selectedInvoices.add(invoiceId);
      });
    }
  }

  void _toggleInvoiceSelection(String invoiceId) {
    setState(() {
      if (_selectedInvoices.contains(invoiceId)) {
        _selectedInvoices.remove(invoiceId);
        if (_selectedInvoices.isEmpty) {
          _isMultiSelectMode = false;
        }
      } else {
        _selectedInvoices.add(invoiceId);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _isMultiSelectMode = false;
      _selectedInvoices.clear();
    });
  }

  Future<void> _refreshInvoices() async {
    if (!mounted) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      await _loadInvoices();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Faturalar güncellendi'),
            backgroundColor: AppTheme.lightTheme.colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        _showErrorMessage('Faturalar güncellenirken hata oluştu: $error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  void _markInvoiceAsPaid(String invoiceId) async {
    try {
      await InvoiceService.instance.updateInvoiceStatus(invoiceId, 'paid');
      await _loadInvoices();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Fatura ödendi olarak işaretlendi'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        _showErrorMessage('Fatura güncellenirken hata oluştu: $error');
      }
    }
  }

  void _markSelectedInvoicesAsPaid() async {
    try {
      for (final invoiceId in _selectedInvoices) {
        await InvoiceService.instance.updateInvoiceStatus(invoiceId, 'paid');
      }

      final count = _selectedInvoices.length;
      await _loadInvoices();
      _clearSelection();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$count fatura ödendi olarak işaretlendi'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        _showErrorMessage('Faturalar güncellenirken hata oluştu: $error');
      }
    }
  }

  void _editInvoice(String invoiceId) {
    Navigator.pushNamed(context, '/invoice-creation',
        arguments: {'editId': invoiceId});
  }

  void _shareInvoice(String invoiceId) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Fatura paylaşıldı'),
          backgroundColor: AppTheme.lightTheme.colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _deleteInvoice(String invoiceId) async {
    try {
      await InvoiceService.instance.deleteInvoice(invoiceId);
      await _loadInvoices();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Fatura silindi'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Geri Al',
              textColor: Colors.white,
              onPressed: () {
                // Implement undo functionality if needed
              },
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        _showErrorMessage('Fatura silinirken hata oluştu: $error');
      }
    }
  }

  void _deleteSelectedInvoices() async {
    try {
      for (final invoiceId in _selectedInvoices) {
        await InvoiceService.instance.deleteInvoice(invoiceId);
      }

      final count = _selectedInvoices.length;
      await _loadInvoices();
      _clearSelection();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$count fatura silindi'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        _showErrorMessage('Faturalar silinirken hata oluştu: $error');
      }
    }
  }

  void _exportSelectedInvoices() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selectedInvoices.length} fatura dışa aktarıldı'),
          backgroundColor: AppTheme.lightTheme.colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );

      _clearSelection();
    }
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.lightTheme.colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}