import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/expense.dart';

class ExpenseServiceException implements Exception {
  final String message;
  final int? statusCode;

  ExpenseServiceException(this.message, {this.statusCode});

  @override
  String toString() => statusCode == null
      ? 'ExpenseServiceException: $message'
      : 'ExpenseServiceException ($statusCode): $message';
}

/// Talks to the Supabase `expenses` table through the PostgREST API.
class ExpenseService {
  ExpenseService({
    http.Client? client,
    this.baseUrl = Config.supabaseUrl,
    this.anonKey = Config.supabaseAnonKey,
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;
  final String anonKey;

  Uri _uri([Map<String, String>? query]) =>
      Uri.parse('$baseUrl/rest/v1/expenses').replace(queryParameters: query);

  Map<String, String> get _headers => {
        'apikey': anonKey,
        'Authorization': 'Bearer $anonKey',
        'Content-Type': 'application/json',
      };

  Future<List<Expense>> fetchExpenses() async {
    final res = await _client.get(
      _uri({'select': '*', 'order': 'created_at.desc'}),
      headers: _headers,
    );
    _check(res);
    final data = jsonDecode(res.body) as List<dynamic>;
    return data
        .map((e) => Expense.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Expense> addExpense(Expense expense) async {
    final res = await _client.post(
      _uri(),
      headers: {..._headers, 'Prefer': 'return=representation'},
      body: jsonEncode(expense.toJson()),
    );
    _check(res);
    final data = jsonDecode(res.body) as List<dynamic>;
    return Expense.fromJson(data.first as Map<String, dynamic>);
  }

  Future<void> deleteExpense(String id) async {
    final res = await _client.delete(
      _uri({'id': 'eq.$id'}),
      headers: _headers,
    );
    _check(res);
  }

  void _check(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      String message = res.body;
      try {
        final body = jsonDecode(res.body);
        if (body is Map && body['message'] != null) {
          message = body['message'] as String;
        }
      } catch (_) {}
      throw ExpenseServiceException(message, statusCode: res.statusCode);
    }
  }
}
