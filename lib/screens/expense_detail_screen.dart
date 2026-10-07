import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../services/expense_service.dart';
import '../utils/formatters.dart';

class ExpenseDetailScreen extends StatefulWidget {
  const ExpenseDetailScreen({
    super.key,
    required this.service,
    required this.expense,
  });

  final ExpenseService service;
  final Expense expense;

  @override
  State<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen> {
  bool _deleting = false;

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete entry?'),
        content: Text('"${widget.expense.name}" will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await widget.service.deleteExpense(widget.expense.id!);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.expense;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Details'),
        actions: [
          IconButton(
            tooltip: 'Delete',
            onPressed: _deleting || e.id == null ? null : _delete,
            icon: _deleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          CircleAvatar(
            radius: 36,
            child: Icon(ExpenseCategory.iconFor(e.category), size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            formatSignedAmount(e),
            textAlign: TextAlign.center,
            style: theme.textTheme.displaySmall?.copyWith(
              color: amountColor(e),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            e.name,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.category_outlined),
                  title: const Text('Category'),
                  trailing: Text(e.category),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    e.isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                  ),
                  title: const Text('Type'),
                  trailing: Text(
                    e.isExpense ? 'Expense' : 'Income',
                    style: TextStyle(color: amountColor(e)),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: const Text('Date'),
                  subtitle: Text(formatFullDate(e.createdAt)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
