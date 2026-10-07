import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../services/expense_service.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key, required this.service});

  final ExpenseService service;

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  String _category = ExpenseCategory.all.first;
  bool _isExpense = true;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  double? _parseAmount(String? value) =>
      double.tryParse((value ?? '').trim().replaceAll(',', '.'));

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.service.addExpense(
        Expense(
          name: _nameController.text.trim(),
          amount: _parseAmount(_amountController.text)!,
          category: _category,
          isExpense: _isExpense,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New entry')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: true,
                  label: Text('Expense'),
                  icon: Icon(Icons.arrow_downward),
                ),
                ButtonSegment(
                  value: false,
                  label: Text('Income'),
                  icon: Icon(Icons.arrow_upward),
                ),
              ],
              selected: {_isExpense},
              onSelectionChanged: (s) => setState(() => _isExpense = s.first),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                final amount = _parseAmount(v);
                if (amount == null) return 'Enter a valid number';
                if (amount <= 0) return 'Amount must be greater than 0';
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final c in ExpenseCategory.all)
                  DropdownMenuItem(
                    value: c,
                    child: Row(
                      children: [
                        Icon(ExpenseCategory.iconFor(c), size: 20),
                        const SizedBox(width: 12),
                        Text(c),
                      ],
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
