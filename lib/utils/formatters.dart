import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';

final _currency = NumberFormat.simpleCurrency();

String formatMoney(double value) => _currency.format(value);

String formatSignedAmount(Expense e) =>
    '${e.isExpense ? '-' : '+'}${_currency.format(e.amount)}';

String formatShortDate(DateTime? d) =>
    d == null ? '' : DateFormat.yMMMd().format(d.toLocal());

String formatFullDate(DateTime? d) =>
    d == null ? '-' : DateFormat.yMMMMEEEEd().add_jm().format(d.toLocal());

const incomeColor = Color(0xFF2E7D32);
const expenseColor = Color(0xFFC62828);

Color amountColor(Expense e) => e.isExpense ? expenseColor : incomeColor;
