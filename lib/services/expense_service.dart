import '../models/expense.dart';
import './auth_service.dart';
import './supabase_service.dart';

class ExpenseService {
  static ExpenseService? _instance;
  static ExpenseService get instance => _instance ??= ExpenseService._();
  ExpenseService._();

  final _client = SupabaseService.instance.client;

  // Create a new expense
  Future<Expense?> createExpense({
    required String description,
    required double amount,
    required String category,
    required DateTime date,
    String? receipt,
    String? notes,
  }) async {
    try {
      // Initialize auth if needed (development mode)
      if (!AuthService.isLoggedIn) {
        final authSuccess = await AuthService.initializeAuth();
        if (!authSuccess) {
          throw Exception('Authentication required');
        }
      }

      final businessId = await AuthService.getUserBusinessId();
      if (businessId == null) {
        throw Exception('No business profile found');
      }

      final response = await _client
          .from('expenses')
          .insert({
            'business_id': businessId,
            'category': category,
            'description': description,
            'amount': amount,
            'expense_date': date.toIso8601String().split('T')[0],
            'receipt_url': receipt,
            'notes': notes,
          })
          .select()
          .single();

      return Expense.fromJson(response);
    } catch (e) {
      throw Exception('Gider oluşturulamadı: $e');
    }
  }

  // Get all expenses for the current business
  Future<List<Expense>> getExpenses({
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  }) async {
    try {
      if (!AuthService.isLoggedIn) {
        final authSuccess = await AuthService.initializeAuth();
        if (!authSuccess) {
          return [];
        }
      }

      final businessId = await AuthService.getUserBusinessId();
      if (businessId == null) {
        return [];
      }

      var query =
          _client.from('expenses').select().eq('business_id', businessId);

      // Apply filters first
      if (category != null) {
        query = query.eq('category', category);
      }

      if (startDate != null) {
        query = query.gte(
          'expense_date',
          startDate.toIso8601String().split('T')[0],
        );
      }

      if (endDate != null) {
        query = query.lte(
          'expense_date',
          endDate.toIso8601String().split('T')[0],
        );
      }

      // Apply ordering and pagination without reassignment
      if (limit != null && offset != null) {
        final response = await query
            .order('expense_date', ascending: false)
            .range(offset, offset + limit - 1);
        return response.map((json) => Expense.fromJson(json)).toList();
      } else if (limit != null) {
        final response =
            await query.order('expense_date', ascending: false).limit(limit);
        return response.map((json) => Expense.fromJson(json)).toList();
      } else {
        final response = await query.order('expense_date', ascending: false);
        return response.map((json) => Expense.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error fetching expenses: $e');
      return [];
    }
  }

  // Update an existing expense
  Future<Expense?> updateExpense({
    required String id,
    String? description,
    double? amount,
    String? category,
    DateTime? date,
    String? receipt,
    String? notes,
  }) async {
    try {
      if (!AuthService.isLoggedIn) {
        final authSuccess = await AuthService.initializeAuth();
        if (!authSuccess) {
          throw Exception('Authentication required');
        }
      }

      final businessId = await AuthService.getUserBusinessId();
      if (businessId == null) {
        throw Exception('No business profile found');
      }

      final response = await _client
          .from('expenses')
          .update({
            'category': category,
            'description': description,
            'amount': amount,
            'expense_date': date?.toIso8601String().split('T')[0],
            'receipt_url': receipt,
            'notes': notes,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .eq('business_id', businessId)
          .select()
          .single();

      return Expense.fromJson(response);
    } catch (e) {
      throw Exception('Gider güncellenemedi: $e');
    }
  }

  // Delete an expense
  Future<bool> deleteExpense(String id) async {
    try {
      if (!AuthService.isLoggedIn) {
        final authSuccess = await AuthService.initializeAuth();
        if (!authSuccess) {
          return false;
        }
      }

      final businessId = await AuthService.getUserBusinessId();
      if (businessId == null) {
        return false;
      }

      await _client
          .from('expenses')
          .delete()
          .eq('id', id)
          .eq('business_id', businessId);
      return true;
    } catch (e) {
      print('Error deleting expense: $e');
      return false;
    }
  }

  // Get expenses by category
  Future<List<Expense>> getExpensesByCategory(String category) async {
    try {
      if (!AuthService.isLoggedIn) {
        final authSuccess = await AuthService.initializeAuth();
        if (!authSuccess) {
          return [];
        }
      }

      final businessId = await AuthService.getUserBusinessId();
      if (businessId == null) {
        return [];
      }

      final response = await _client
          .from('expenses')
          .select()
          .eq('business_id', businessId)
          .eq('category', category)
          .order('expense_date', ascending: false);

      return response.map((json) => Expense.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching expenses by category: $e');
      return [];
    }
  }

  // Get expenses by date range
  Future<List<Expense>> getExpensesByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      if (!AuthService.isLoggedIn) {
        final authSuccess = await AuthService.initializeAuth();
        if (!authSuccess) {
          return [];
        }
      }

      final businessId = await AuthService.getUserBusinessId();
      if (businessId == null) {
        return [];
      }

      final response = await _client
          .from('expenses')
          .select()
          .eq('business_id', businessId)
          .gte('expense_date', startDate.toIso8601String().split('T')[0])
          .lte('expense_date', endDate.toIso8601String().split('T')[0])
          .order('expense_date', ascending: false);

      return response.map((json) => Expense.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching expenses by date range: $e');
      return [];
    }
  }

  // Get total expenses for a given period
  Future<double> getTotalExpenses({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      if (!AuthService.isLoggedIn) {
        final authSuccess = await AuthService.initializeAuth();
        if (!authSuccess) {
          return 0.0;
        }
      }

      final businessId = await AuthService.getUserBusinessId();
      if (businessId == null) {
        return 0.0;
      }

      var query = _client
          .from('expenses')
          .select('amount')
          .eq('business_id', businessId);

      if (startDate != null) {
        query = query.gte(
          'expense_date',
          startDate.toIso8601String().split('T')[0],
        );
      }

      if (endDate != null) {
        query = query.lte(
          'expense_date',
          endDate.toIso8601String().split('T')[0],
        );
      }

      final response = await query;

      double totalAmount = 0.0;
      for (final expense in response) {
        final amount = (expense['amount'] as num).toDouble();
        totalAmount += amount;
      }

      return totalAmount;
    } catch (e) {
      print('Error calculating total expenses: $e');
      return 0.0;
    }
  }

  // Get expense categories with totals
  Future<Map<String, double>> getExpensesByCategories({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      if (!AuthService.isLoggedIn) {
        final authSuccess = await AuthService.initializeAuth();
        if (!authSuccess) {
          return {};
        }
      }

      final businessId = await AuthService.getUserBusinessId();
      if (businessId == null) {
        return {};
      }

      var query = _client
          .from('expenses')
          .select('category, amount')
          .eq('business_id', businessId);

      if (startDate != null) {
        query = query.gte(
          'expense_date',
          startDate.toIso8601String().split('T')[0],
        );
      }

      if (endDate != null) {
        query = query.lte(
          'expense_date',
          endDate.toIso8601String().split('T')[0],
        );
      }

      final response = await query;

      Map<String, double> categoryTotals = {};

      for (final expense in response) {
        final category = expense['category'] as String;
        final amount = (expense['amount'] as num).toDouble();

        categoryTotals[category] = (categoryTotals[category] ?? 0.0) + amount;
      }

      return categoryTotals;
    } catch (e) {
      print('Error fetching expenses by categories: $e');
      return {};
    }
  }

  // Compatibility methods for existing code
  // getAllExpenses - wrapper for getExpenses
  static Future<List<Expense>> getAllExpenses({
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  }) async {
    return ExpenseService.instance.getExpenses(
      category: category,
      startDate: startDate,
      endDate: endDate,
      limit: limit,
      offset: offset,
    );
  }

  // addExpense - wrapper for createExpense
  static Future<Expense?> addExpense({
    required String category,
    required String description,
    required double amount,
    required DateTime date,
    String? receipt,
    String? notes,
  }) async {
    return ExpenseService.instance.createExpense(
      category: category,
      description: description,
      amount: amount,
      date: date,
      receipt: receipt,
      notes: notes,
    );
  }

  // removeExpense - wrapper for deleteExpense
  static Future<bool> removeExpense(String id) async {
    return ExpenseService.instance.deleteExpense(id);
  }
}
