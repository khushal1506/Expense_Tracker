import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/model/transaction_model.dart';
import '../../providers/currency_provider.dart';
import '../../utils/currency_formatter.dart';

class TransactionTile extends ConsumerWidget {
  final Transaction transaction;

  const TransactionTile({super.key, required this.transaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIncome = transaction.type == TransactionType.income;
    final currencyCode = ref.watch(currencyProvider).valueOrNull ?? 'INR';
    final inrPerUnit = ref.watch(currencyRatesProvider).valueOrNull?.inrPerUnit;
    final date = DateFormat.yMMMd().format(transaction.date);
    final scheme = Theme.of(context).colorScheme;
    final amountColor = isIncome
        ? const Color(0xFF0A8F64)
        : const Color(0xFFB83A4B);

    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, scheme.primary.withValues(alpha: 0.03)],
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 6,
          ),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: amountColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isIncome ? Icons.south_west_rounded : Icons.north_east_rounded,
              color: amountColor,
            ),
          ),
          title: Text(
            transaction.category,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontSize: 15),
          ),
          subtitle: Text(
            '${transaction.notes ?? 'No notes'} • $date',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            '${isIncome ? '+' : '-'}${formatCurrency(transaction.amount, currencyCode, inrPerUnit: inrPerUnit)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: amountColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
