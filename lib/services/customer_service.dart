import '../models/customer.dart';
import './auth_service.dart';
import './supabase_service.dart';

class CustomerService {
  static CustomerService? _instance;
  static CustomerService get instance => _instance ??= CustomerService._();

  CustomerService._();

  final _client = SupabaseService.instance.client;

  // Get all customers for current user's business
  Future<List<Customer>> getCustomers({
    String? searchQuery,
    int? limit,
    int? offset,
  }) async {
    try {
      // Initialize auth if needed (development mode)
      if (!AuthService.isLoggedIn) {
        final authSuccess = await AuthService.initializeAuth();
        if (!authSuccess) {
          throw Exception(
              'Authentication required. Please sign in to continue.');
        }
      }

      // Get business ID safely
      final businessId = await AuthService.getUserBusinessId();
      if (businessId == null) {
        throw Exception(
            'No business profile found. Please set up your business first.');
      }

      var query =
          _client.from('customers').select().eq('business_id', businessId);

      // Apply search filter first before any modifiers
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('name', '%$searchQuery%');
      }

      // Apply ordering, limit, and range in one chain without reassignment
      if (limit != null && offset != null) {
        final response = await query
            .order('name', ascending: true)
            .range(offset, offset + limit - 1);
        return response.map((json) => Customer.fromJson(json)).toList();
      } else if (limit != null) {
        final response =
            await query.order('name', ascending: true).limit(limit);
        return response.map((json) => Customer.fromJson(json)).toList();
      } else {
        final response = await query.order('name', ascending: true);
        return response.map((json) => Customer.fromJson(json)).toList();
      }
    } catch (error) {
      throw Exception('Müşteriler alınamadı: $error');
    }
  }

  // Get single customer
  Future<Customer?> getCustomerById(String customerId) async {
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
          .from('customers')
          .select()
          .eq('id', customerId)
          .eq('business_id', businessId)
          .single();

      return Customer.fromJson(response);
    } catch (error) {
      throw Exception('Müşteri bulunamadı: $error');
    }
  }

  // Create new customer
  Future<Customer> createCustomer({
    required String name,
    String? email,
    String? phone,
    String? address,
    String? taxNumber,
  }) async {
    try {
      // Initialize auth if needed (development mode)
      if (!AuthService.isLoggedIn) {
        final authSuccess = await AuthService.initializeAuth();
        if (!authSuccess) {
          throw Exception('Authentication required');
        }
      }

      // Get the current user's business ID
      final businessId = await AuthService.getUserBusinessId();
      if (businessId == null) {
        throw Exception(
            'No business profile found. Please set up your business first.');
      }

      final response = await _client
          .from('customers')
          .insert({
            'business_id': businessId,
            'name': name,
            'email': email,
            'phone': phone,
            'address': address,
            'tax_number': taxNumber,
          })
          .select()
          .single();

      return Customer.fromJson(response);
    } catch (error) {
      throw Exception('Müşteri oluşturulamadı: $error');
    }
  }

  // Check if customer exists by name
  Future<bool> customerExistsByName(String name) async {
    try {
      if (!AuthService.isLoggedIn) {
        await AuthService.initializeAuth();
      }

      final businessId = await AuthService.getUserBusinessId();
      if (businessId == null) return false;

      final response = await _client
          .from('customers')
          .select('id')
          .eq('business_id', businessId)
          .ilike('name', name.trim())
          .limit(1);

      return response.isNotEmpty;
    } catch (error) {
      print('Error checking customer existence: $error');
      return false;
    }
  }

  // Get or create customer by name
  Future<Customer> getOrCreateCustomerByName(String name) async {
    try {
      if (!AuthService.isLoggedIn) {
        final authSuccess = await AuthService.initializeAuth();
        if (!authSuccess) {
          throw Exception('Authentication required');
        }
      }

      // First try to find existing customer
      final searchResults = await searchCustomers(name);

      // Find exact match
      final exactMatch = searchResults.firstWhere(
        (customer) => customer.name.toLowerCase() == name.toLowerCase().trim(),
        orElse: () => Customer(
          id: '',
          businessId: '',
          name: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      if (exactMatch.id.isNotEmpty) {
        return exactMatch;
      }

      // Customer doesn't exist, create new one
      return await createCustomer(name: name.trim());
    } catch (error) {
      throw Exception('Müşteri oluşturulamadı veya bulunamadı: $error');
    }
  }

  // Update customer
  Future<Customer> updateCustomer({
    required String customerId,
    required String name,
    String? email,
    String? phone,
    String? address,
    String? taxNumber,
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
          .from('customers')
          .update({
            'name': name,
            'email': email,
            'phone': phone,
            'address': address,
            'tax_number': taxNumber,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', customerId)
          .eq('business_id', businessId)
          .select()
          .single();

      return Customer.fromJson(response);
    } catch (error) {
      throw Exception('Müşteri güncellenemedi: $error');
    }
  }

  // Delete customer
  Future<void> deleteCustomer(String customerId) async {
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

      await _client
          .from('customers')
          .delete()
          .eq('id', customerId)
          .eq('business_id', businessId);
    } catch (error) {
      throw Exception('Müşteri silinemedi: $error');
    }
  }

  // Get customer statistics
  Future<Map<String, dynamic>> getCustomerStatistics(String customerId) async {
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

      // Get all invoices for this customer in current business
      final response = await _client
          .from('invoices')
          .select('total_amount, payment_status, status')
          .eq('customer_id', customerId)
          .eq('business_id', businessId);

      double totalAmount = 0.0;
      double paidAmount = 0.0;
      double pendingAmount = 0.0;
      int totalInvoices = response.length;
      int paidInvoices = 0;
      int pendingInvoices = 0;

      for (final invoice in response) {
        final amount = (invoice['total_amount'] as num).toDouble();
        final paymentStatus = invoice['payment_status'] as String;
        final status = invoice['status'] as String;

        totalAmount += amount;

        if (paymentStatus == 'paid') {
          paidAmount += amount;
          paidInvoices++;
        } else if (status == 'pending') {
          pendingAmount += amount;
          pendingInvoices++;
        }
      }

      return {
        'total_amount': totalAmount,
        'paid_amount': paidAmount,
        'pending_amount': pendingAmount,
        'total_invoices': totalInvoices,
        'paid_invoices': paidInvoices,
        'pending_invoices': pendingInvoices,
      };
    } catch (error) {
      throw Exception('Müşteri istatistikleri alınamadı: $error');
    }
  }

  // Search customers
  Future<List<Customer>> searchCustomers(String query) async {
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
          .from('customers')
          .select()
          .eq('business_id', businessId)
          .ilike('name', '%$query%')
          .order('name', ascending: true);

      return response.map((json) => Customer.fromJson(json)).toList();
    } catch (error) {
      throw Exception('Müşteri araması yapılamadı: $error');
    }
  }
}
