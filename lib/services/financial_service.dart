import './auth_service.dart';
import './supabase_service.dart';

class FinancialService {
  static FinancialService? _instance;
  static FinancialService get instance => _instance ??= FinancialService._();

  FinancialService._();

  final _client = SupabaseService.instance.client;
  final _authService = AuthService.instance;

  /// Get receivables (only from issued invoices, not drafts)
  Future<double> getReceivables(
      {DateTime? startDate, DateTime? endDate}) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('Kullanıcı giriş yapmamış');
      }

      var query = _client
          .from('invoices')
          .select('total_amount')
          .neq('status', 'draft') // Only issued invoices
          .neq('payment_status', 'paid'); // Exclude fully paid invoices

      if (startDate != null) {
        query =
            query.gte('issue_date', startDate.toIso8601String().split('T')[0]);
      }

      if (endDate != null) {
        query =
            query.lte('issue_date', endDate.toIso8601String().split('T')[0]);
      }

      final response = await query;

      double totalReceivables = 0.0;
      for (final invoice in response) {
        totalReceivables += (invoice['total_amount'] as num).toDouble();
      }

      return totalReceivables;
    } catch (error) {
      throw Exception('Alacaklar hesaplanamadı: $error');
    }
  }

  /// Get total expenses
  Future<double> getTotalExpenses(
      {DateTime? startDate, DateTime? endDate}) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('Kullanıcı giriş yapmamış');
      }

      var query = _client.from('expenses').select('amount');

      if (startDate != null) {
        query = query.gte(
            'expense_date', startDate.toIso8601String().split('T')[0]);
      }

      if (endDate != null) {
        query =
            query.lte('expense_date', endDate.toIso8601String().split('T')[0]);
      }

      final response = await query;

      double totalExpenses = 0.0;
      for (final expense in response) {
        totalExpenses += (expense['amount'] as num).toDouble();
      }

      return totalExpenses;
    } catch (error) {
      throw Exception('Giderler hesaplanamadı: $error');
    }
  }

  /// Calculate profit/loss: Receivables - Expenses
  Future<double> getProfitLoss({DateTime? startDate, DateTime? endDate}) async {
    try {
      final receivables =
          await getReceivables(startDate: startDate, endDate: endDate);
      final expenses =
          await getTotalExpenses(startDate: startDate, endDate: endDate);

      return receivables - expenses;
    } catch (error) {
      throw Exception('Kar/zarar hesaplanamadı: $error');
    }
  }

  /// Get count of pending invoices
  Future<int> getPendingInvoicesCount(
      {DateTime? startDate, DateTime? endDate}) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('Kullanıcı giriş yapmamış');
      }

      var query = _client
          .from('invoices')
          .select('id')
          .neq('status', 'draft')
          .neq('payment_status', 'paid');

      if (startDate != null) {
        query =
            query.gte('issue_date', startDate.toIso8601String().split('T')[0]);
      }

      if (endDate != null) {
        query =
            query.lte('issue_date', endDate.toIso8601String().split('T')[0]);
      }

      final response = await query;
      return response.length;
    } catch (error) {
      throw Exception('Bekleyen fatura sayısı alınamadı: $error');
    }
  }

  /// Get financial summary for dashboard
  Future<Map<String, dynamic>> getFinancialSummary(
      {DateTime? startDate, DateTime? endDate}) async {
    try {
      final receivables =
          await getReceivables(startDate: startDate, endDate: endDate);
      final expenses =
          await getTotalExpenses(startDate: startDate, endDate: endDate);
      final profitLoss = receivables - expenses;
      final pendingCount =
          await getPendingInvoicesCount(startDate: startDate, endDate: endDate);

      // Calculate profit change percentage (mock for now, would need historical data)
      final profitChangePercentage = profitLoss > 0 ? 15.0 : -10.0;

      return {
        'receivables': receivables,
        'expenses': expenses,
        'profit_loss': profitLoss,
        'pending_invoices_count': pendingCount,
        'profit_change_percentage': profitChangePercentage,
      };
    } catch (error) {
      throw Exception('Finansal özet alınamadı: $error');
    }
  }

  /// Get recent invoices for dashboard
  Future<List<Map<String, dynamic>>> getRecentInvoices({int limit = 5}) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('Kullanıcı giriş yapmamış');
      }

      final response = await _client
          .from('invoices')
          .select('''
            id,
            invoice_number,
            total_amount,
            payment_status,
            issue_date,
            customers(name)
          ''')
          .neq('status', 'draft')
          .order('issue_date', ascending: false)
          .limit(limit);

      return response.map<Map<String, dynamic>>((invoice) {
        final customer = invoice['customers'] as Map<String, dynamic>?;
        return {
          'id': invoice['id'],
          'customerName': customer?['name'] ?? 'Bilinmeyen Müşteri',
          'invoiceNumber': invoice['invoice_number'],
          'amount':
              '₺${(invoice['total_amount'] as num).toStringAsFixed(2).replaceAll('.', ',').replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}',
          'status': invoice['payment_status'],
          'date': invoice['issue_date'],
        };
      }).toList();
    } catch (error) {
      throw Exception('Son faturalar alınamadı: $error');
    }
  }

  /// Get expense summary for dashboard
  Future<List<Map<String, dynamic>>> getExpenseSummary() async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('Kullanıcı giriş yapmamış');
      }

      final response =
          await _client.from('expenses').select('category, amount');

      Map<String, double> categoryTotals = {};
      double totalAmount = 0.0;

      for (final expense in response) {
        final category = expense['category'] as String;
        final amount = (expense['amount'] as num).toDouble();

        // Convert category to Turkish
        String turkishCategory;
        switch (category) {
          case 'office':
            turkishCategory = 'Ofis Giderleri';
            break;
          case 'transportation':
            turkishCategory = 'Ulaşım';
            break;
          case 'materials':
            turkishCategory = 'Malzeme';
            break;
          case 'utilities':
            turkishCategory = 'Faturalar';
            break;
          case 'marketing':
            turkishCategory = 'Pazarlama';
            break;
          default:
            turkishCategory = 'Diğer';
        }

        categoryTotals[turkishCategory] =
            (categoryTotals[turkishCategory] ?? 0.0) + amount;
        totalAmount += amount;
      }

      return categoryTotals.entries.map((entry) {
        final percentage =
            totalAmount > 0 ? (entry.value / totalAmount) * 100 : 0.0;
        return {
          'category': entry.key,
          'amount':
              '₺${entry.value.toStringAsFixed(2).replaceAll('.', ',').replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}',
          'percentage': percentage,
        };
      }).toList();
    } catch (error) {
      throw Exception('Gider özeti alınamadı: $error');
    }
  }

  /// Format currency for Turkish locale
  String formatCurrency(double amount) {
    return '₺${amount.toStringAsFixed(2).replaceAll('.', ',').replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}';
  }
}