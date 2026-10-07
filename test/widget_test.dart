import 'dart:convert';

import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/services/expense_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final row = {
    'id': '7b1c2f3e-0000-4000-8000-000000000001',
    'name': 'Groceries',
    'amount': 42.5,
    'category': 'Food',
    'is_expense': true,
    'created_at': '2026-10-05T12:00:00.000Z',
  };

  group('Expense', () {
    test('fromJson / toJson round-trip', () {
      final e = Expense.fromJson(row);
      expect(e.name, 'Groceries');
      expect(e.amount, 42.5);
      expect(e.isExpense, isTrue);
      expect(e.signedAmount, -42.5);
      expect(e.toJson(), row);
    });

    test('parses integer amounts from Supabase numeric', () {
      final e = Expense.fromJson({...row, 'amount': 100});
      expect(e.amount, 100.0);
    });

    test('toJson omits server-generated fields when null', () {
      const e = Expense(
        name: 'Paycheck',
        amount: 1000,
        category: 'Salary',
        isExpense: false,
      );
      expect(e.toJson().containsKey('id'), isFalse);
      expect(e.toJson().containsKey('created_at'), isFalse);
      expect(e.signedAmount, 1000);
    });
  });

  group('ExpenseService', () {
    ExpenseService serviceWith(MockClientHandler handler) => ExpenseService(
          client: MockClient(handler),
          baseUrl: 'https://example.supabase.co',
          anonKey: 'anon',
        );

    test('fetchExpenses sends auth headers and ordering', () async {
      late http.Request captured;
      final service = serviceWith((req) async {
        captured = req;
        return http.Response(jsonEncode([row]), 200);
      });

      final list = await service.fetchExpenses();

      expect(list, hasLength(1));
      expect(captured.method, 'GET');
      expect(captured.url.path, '/rest/v1/expenses');
      expect(captured.url.queryParameters['order'], 'created_at.desc');
      expect(captured.headers['apikey'], 'anon');
      expect(captured.headers['Authorization'], 'Bearer anon');
    });

    test('addExpense posts JSON and returns created row', () async {
      late http.Request captured;
      final service = serviceWith((req) async {
        captured = req;
        return http.Response(jsonEncode([row]), 201);
      });

      final created = await service.addExpense(
        const Expense(
          name: 'Groceries',
          amount: 42.5,
          category: 'Food',
          isExpense: true,
        ),
      );

      expect(captured.method, 'POST');
      expect(captured.headers['Prefer'], 'return=representation');
      expect(jsonDecode(captured.body)['is_expense'], isTrue);
      expect(created.id, row['id']);
    });

    test('deleteExpense filters by id', () async {
      late http.Request captured;
      final service = serviceWith((req) async {
        captured = req;
        return http.Response('', 204);
      });

      await service.deleteExpense('abc');

      expect(captured.method, 'DELETE');
      expect(captured.url.queryParameters['id'], 'eq.abc');
    });

    test('non-2xx responses throw ExpenseServiceException', () async {
      final service = serviceWith(
        (_) async => http.Response(jsonEncode({'message': 'nope'}), 401),
      );

      expect(
        service.fetchExpenses(),
        throwsA(
          isA<ExpenseServiceException>()
              .having((e) => e.statusCode, 'statusCode', 401)
              .having((e) => e.message, 'message', 'nope'),
        ),
      );
    });
  });
}
