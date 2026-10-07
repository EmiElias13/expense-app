import 'package:flutter/material.dart';

import '../config.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';
import '../utils/formatters.dart';
import 'add_expense_screen.dart';
import 'expense_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.service});

  final ExpenseService service;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Expense>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Expense>> _load() {
    if (!Config.isConfigured) {
      return Future.error(
        'Supabase is not configured.\nRun with --dart-define=SUPABASE_URL=... '
        '--dart-define=SUPABASE_ANON_KEY=...',
      );
    }
    return widget.service.fetchExpenses();
  }

  Future<void> _refresh() async {
    final future = _load();
    setState(() => _future = future);
    try {
      await future;
    } catch (_) {}
  }

  Future<void> _openAdd() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddExpenseScreen(service: widget.service),
      ),
    );
    if (added == true) _refresh();
  }

  Future<void> _openDetail(Expense expense) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            ExpenseDetailScreen(service: widget.service, expense: expense),
      ),
    );
    if (changed == true) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Expenses')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAdd,
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: FutureBuilder<List<Expense>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorView(
              message: snapshot.error.toString(),
              onRetry: _refresh,
            );
          }
          final expenses = snapshot.data ?? const [];
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                _SummaryCard(expenses: expenses),
                if (expenses.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(
                      child: Text('No entries yet. Tap "Add" to create one.'),
                    ),
                  )
                else
                  for (final e in expenses)
                    ListTile(
                      leading: CircleAvatar(
                        child: Icon(ExpenseCategory.iconFor(e.category)),
                      ),
                      title: Text(e.name),
                      subtitle:
                          Text('${e.category} - ${formatShortDate(e.createdAt)}'),
                      trailing: Text(
                        formatSignedAmount(e),
                        style: TextStyle(
                          color: amountColor(e),
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      onTap: () => _openDetail(e),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.expenses});

  final List<Expense> expenses;

  @override
  Widget build(BuildContext context) {
    double income = 0, spent = 0;
    for (final e in expenses) {
      if (e.isExpense) {
        spent += e.amount;
      } else {
        income += e.amount;
      }
    }
    final balance = income - spent;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Balance', style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(
              formatMoney(balance),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: balance < 0 ? expenseColor : incomeColor,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SummaryItem(
                    label: 'Income',
                    value: formatMoney(income),
                    color: incomeColor,
                  ),
                ),
                Expanded(
                  child: _SummaryItem(
                    label: 'Expenses',
                    value: formatMoney(spent),
                    color: expenseColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        Text(
          value,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
