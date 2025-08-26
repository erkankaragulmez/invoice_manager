import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../models/expense.dart';
import '../../services/auth_service.dart';
import '../../services/expense_service.dart';
import './widgets/expense_creation_modal.dart';
import './widgets/expense_empty_state.dart';
import './widgets/expense_header.dart';
import './widgets/expense_list_item.dart';
import './widgets/expense_pie_chart.dart';
import './widgets/expense_search_bar.dart';

class ExpenseTrackingScreen extends StatefulWidget {
  const ExpenseTrackingScreen({Key? key}) : super(key: key);

  @override
  State<ExpenseTrackingScreen> createState() => _ExpenseTrackingState();
}

class _ExpenseTrackingState extends State<ExpenseTrackingScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'Bu Ay';
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _periods = [
    'Bu Ay',
    'Geçen Ay',
    'Son 3 Ay',
    'Bu Yıl',
    'Geçen Yıl',
  ];

  List<Expense> _allExpenses = [];
  List<Expense> _filteredExpenses = [];

  @override
  void initState() {
    super.initState();
    // Check authentication on screen load
    if (!AuthService.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, AppRoutes.userLogin);
      });
      return;
    }
    _tabController = TabController(length: 2, vsync: this);
    _loadExpenses();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  double get _totalAmount {
    return _filteredExpenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  Future<void> _loadExpenses() async {
    if (!AuthService.isAuthenticated) {
      setState(() {
        _errorMessage = 'Lütfen giriş yapın';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dateRange = _getDateRangeForPeriod(_selectedPeriod);
      final expenses = await ExpenseService.getAllExpenses();

      setState(() {
        _allExpenses = expenses;
        _isLoading = false;
      });
      _filterExpenses();
    } catch (e) {
      setState(() {
        _errorMessage = 'Veriler yüklenirken hata oluştu: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Map<String, DateTime?> _getDateRangeForPeriod(String period) {
    final now = DateTime.now();
    DateTime? start;
    DateTime? end;

    switch (period) {
      case 'Bu Ay':
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 0);
        break;
      case 'Geçen Ay':
        start = DateTime(now.year, now.month - 1, 1);
        end = DateTime(now.year, now.month, 0);
        break;
      case 'Son 3 Ay':
        start = DateTime(now.year, now.month - 2, 1);
        end = now;
        break;
      case 'Bu Yıl':
        start = DateTime(now.year, 1, 1);
        end = DateTime(now.year, 12, 31);
        break;
      case 'Geçen Yıl':
        start = DateTime(now.year - 1, 1, 1);
        end = DateTime(now.year - 1, 12, 31);
        break;
    }

    return {'start': start, 'end': end};
  }

  void _filterExpenses() {
    setState(() {
      _filteredExpenses = _allExpenses.where((expense) {
        final matchesSearch = _searchQuery.isEmpty ||
            expense.description
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            expense.category
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            (expense.notes
                    ?.toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ??
                false);

        return matchesSearch;
      }).toList();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterExpenses();
  }

  void _onPeriodChanged(String period) {
    setState(() {
      _selectedPeriod = period;
    });
    _loadExpenses();
  }

  void _onRefresh() async {
    await _loadExpenses();
  }

  void _showExpenseCreationModal() {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) =>
            ExpenseCreationModal(onExpenseCreated: (expenseData) async {
              try {
                await ExpenseService.addExpense(
                    category: expenseData['category'],
                    description: expenseData['description'],
                    amount: expenseData['amount'].toDouble(),
                    notes: expenseData['notes'],
                    date: DateTime.now());
                _loadExpenses(); // Refresh the list
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Gider eklenirken hata oluştu: $e'),
                      backgroundColor: AppTheme.lightTheme.colorScheme.error));
                }
              }
            }));
  }

  void _showFilterDialog() {
    showModalBottomSheet(
        context: context,
        backgroundColor: AppTheme.lightTheme.cardColor,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) => Container(
            padding: EdgeInsets.all(4.w),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 12.w,
                  height: 0.5.h,
                  decoration: BoxDecoration(
                      color: AppTheme.lightTheme.dividerColor,
                      borderRadius: BorderRadius.circular(2))),
              SizedBox(height: 3.h),
              Text('Filtrele', style: AppTheme.lightTheme.textTheme.titleLarge),
              SizedBox(height: 2.h),
              ListTile(
                  leading: CustomIconWidget(
                      iconName: 'date_range',
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 6.w),
                  title: Text('Tarih Aralığı',
                      style: AppTheme.lightTheme.textTheme.titleMedium),
                  onTap: () {
                    Navigator.pop(context);
                    // Implement date range picker
                  }),
              ListTile(
                  leading: CustomIconWidget(
                      iconName: 'category',
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 6.w),
                  title: Text('Kategori',
                      style: AppTheme.lightTheme.textTheme.titleMedium),
                  onTap: () {
                    Navigator.pop(context);
                    // Implement category filter
                  }),
              ListTile(
                  leading: CustomIconWidget(
                      iconName: 'attach_money',
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 6.w),
                  title: Text('Tutar Aralığı',
                      style: AppTheme.lightTheme.textTheme.titleMedium),
                  onTap: () {
                    Navigator.pop(context);
                    // Implement amount range filter
                  }),
              SizedBox(height: 2.h),
            ])));
  }

  void _editExpense(Expense expense) async {
    try {
      // For now, just show a message. In a full implementation, you'd show an edit modal
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${expense.description} düzenleniyor...'),
          backgroundColor: AppTheme.lightTheme.colorScheme.primary));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Düzenleme sırasında hata: $e'),
          backgroundColor: AppTheme.lightTheme.colorScheme.error));
    }
  }

  void _changeCategory(Expense expense) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${expense.description} kategorisi değiştiriliyor...'),
          backgroundColor: AppTheme.lightTheme.colorScheme.primary));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Kategori değiştirilirken hata: $e'),
          backgroundColor: AppTheme.lightTheme.colorScheme.error));
    }
  }

  void _addPhoto(Expense expense) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${expense.description} için fotoğraf ekleniyor...'),
          backgroundColor: AppTheme.lightTheme.colorScheme.primary));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Fotoğraf eklenirken hata: $e'),
          backgroundColor: AppTheme.lightTheme.colorScheme.error));
    }
  }

  void _deleteExpense(Expense expense) async {
    try {
      await ExpenseService.removeExpense(expense.id);
      _loadExpenses(); // Refresh the list

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Gider silindi'),
            backgroundColor: AppTheme.lightTheme.colorScheme.error));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Gider silinirken hata: $e'),
            backgroundColor: AppTheme.lightTheme.colorScheme.error));
      }
    }
  }

  void _onCategoryTap(String category) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$category kategorisi seçildi'),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary));
  }

  // Convert Expense model to Map for widgets that expect Map format
  List<Map<String, dynamic>> get _expensesAsMap {
    return _filteredExpenses
        .map((expense) => {
              'id': expense.id,
              'category': _getCategoryDisplayName(expense.category),
              'description': expense.description,
              'amount': expense.amount,
              'date': expense.expenseDate,
              'hasPhoto': expense.receiptUrl != null,
              'notes': expense.notes,
            })
        .toList();
  }

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'office':
        return 'Ofis';
      case 'transportation':
        return 'Ulaşım';
      case 'materials':
        return 'Malzeme';
      case 'utilities':
        return 'Faturalar';
      case 'marketing':
        return 'Pazarlama';
      case 'other':
        return 'Diğer';
      default:
        return category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        body: Column(children: [
          ExpenseHeader(
              totalAmount: _totalAmount,
              selectedPeriod: _selectedPeriod,
              periods: _periods,
              onPeriodChanged: _onPeriodChanged,
              onRefresh: _onRefresh),
          ExpenseSearchBar(
              onSearchChanged: _onSearchChanged,
              onFilterTap: _showFilterDialog),
          Expanded(child: _buildContent()),
        ]),
        floatingActionButton: FloatingActionButton(
            onPressed: _showExpenseCreationModal,
            child: CustomIconWidget(
                iconName: 'add', color: Colors.white, size: 6.w)));
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        CircularProgressIndicator(
            color: AppTheme.lightTheme.colorScheme.primary),
        SizedBox(height: 2.h),
        Text('Giderler yükleniyor...',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurface
                    .withValues(alpha: 0.6))),
      ]));
    }

    if (_errorMessage != null) {
      return Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        CustomIconWidget(
            iconName: 'error_outline',
            color: AppTheme.lightTheme.colorScheme.error,
            size: 15.w),
        SizedBox(height: 2.h),
        Text(_errorMessage!,
            textAlign: TextAlign.center,
            style: AppTheme.lightTheme.textTheme.bodyLarge
                ?.copyWith(color: AppTheme.lightTheme.colorScheme.error)),
        SizedBox(height: 3.h),
        ElevatedButton(onPressed: _loadExpenses, child: Text('Tekrar Dene')),
      ]));
    }

    if (_filteredExpenses.isEmpty) {
      return ExpenseEmptyState(onAddExpense: _showExpenseCreationModal);
    }

    return Column(children: [
      Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          decoration: BoxDecoration(
              color: AppTheme.lightTheme.cardColor,
              borderRadius: BorderRadius.circular(12)),
          child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.lightTheme.colorScheme.primary,
              unselectedLabelColor: AppTheme.lightTheme.colorScheme.onSurface
                  .withValues(alpha: 0.6),
              indicator: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.primary
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12)),
              tabs: const [
                Tab(text: 'Liste'),
                Tab(text: 'Grafik'),
              ])),
      SizedBox(height: 2.h),
      Expanded(
          child: TabBarView(controller: _tabController, children: [
        _buildExpenseList(),
        _buildExpenseChart(),
      ])),
    ]);
  }

  Widget _buildExpenseList() {
    return RefreshIndicator(
        onRefresh: () => _loadExpenses(),
        color: AppTheme.lightTheme.colorScheme.primary,
        child: ListView.builder(
            padding: EdgeInsets.only(bottom: 10.h),
            itemCount: _expensesAsMap.length,
            itemBuilder: (context, index) {
              final expenseMap = _expensesAsMap[index];
              final expense = _filteredExpenses[index];
              return ExpenseListItem(
                  expense: expenseMap,
                  onEdit: () => _editExpense(expense),
                  onChangeCategory: () => _changeCategory(expense),
                  onAddPhoto: () => _addPhoto(expense),
                  onDelete: () => _deleteExpense(expense));
            }));
  }

  Widget _buildExpenseChart() {
    return SingleChildScrollView(
        padding: EdgeInsets.only(bottom: 10.h),
        child: ExpensePieChart(
            expenses: _expensesAsMap, onCategoryTap: _onCategoryTap));
  }
}