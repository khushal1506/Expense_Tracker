import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/model/transaction_model.dart';
import '../../providers/transaction_provider.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/error_state_widget.dart';
import '../widgets/loading_widget.dart';
import '../widgets/transaction_tile.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

enum _TransactionFilter { all, income, expense }

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final _searchController = TextEditingController();
  _TransactionFilter _filter = _TransactionFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getDateGroup(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return 'Today';
    } else if (dateToCheck == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat.yMMMMd().format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final txState = ref.watch(transactionProvider);
    final search = _searchController.text.trim().toLowerCase();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/transactions/new'),
        icon: const Icon(Icons.add),
        label: const Text('Add Transaction'),
      ),
      body: Stack(
        children: [
          // ── Background list with grouping ──────────────────────────
          txState.when(
            data: (transactions) {
              var filtered = transactions;

              if (_filter == _TransactionFilter.income) {
                filtered = filtered
                    .where((t) => t.type == TransactionType.income)
                    .toList();
              } else if (_filter == _TransactionFilter.expense) {
                filtered = filtered
                    .where((t) => t.type == TransactionType.expense)
                    .toList();
              }

              if (search.isNotEmpty) {
                filtered = filtered.where((t) {
                  final notes = (t.notes ?? '').toLowerCase();
                  final category = t.category.toLowerCase();
                  return notes.contains(search) || category.contains(search);
                }).toList();
              }

              if (filtered.isEmpty) {
                return const Center(child: EmptyStateWidget(message: 'No transactions found'));
              }

              // Group transactions by date string
              final Map<String, List<Transaction>> grouped = {};
              for (final tx in filtered) {
                final group = _getDateGroup(tx.date);
                grouped.putIfAbsent(group, () => []).add(tx);
              }

              // Build grouped list items
              final listItems = <Widget>[];
              grouped.forEach((dateString, dailyTx) {
                // Header
                listItems.add(
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                    child: Text(
                      dateString,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.grey.shade600,
                            letterSpacing: 0.5,
                          ),
                    ),
                  ),
                );

                // Transactions
                for (int i = 0; i < dailyTx.length; i++) {
                  final tx = dailyTx[i];
                  final isLast = i == dailyTx.length - 1;

                  listItems.add(
                    Dismissible(
                      key: ValueKey(tx.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: scheme.error,
                        child: const Icon(Icons.delete_rounded, color: Colors.white),
                      ),
                      onDismissed: (_) {
                        ref.read(transactionProvider.notifier).deleteTransaction(tx.id);
                      },
                      child: InkWell(
                        onTap: () => context.push('/transactions/edit', extra: tx),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              TransactionTile(transaction: tx),
                              if (!isLast)
                                Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: scheme.primary.withValues(alpha: 0.05),
                                  indent: 64, // visually align under icon
                                  endIndent: 16,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }
              });

              return ListView.builder(
                padding: const EdgeInsets.only(top: 140, bottom: 90),
                itemCount: listItems.length,
                itemBuilder: (context, index) => listItems[index],
              );
            },
            loading: () => const LoadingWidget(label: 'Loading transactions...'),
            error: (e, _) => ErrorStateWidget(message: e.toString()),
          ),

          // ── Sticky Header Overlay (Search & Filters) ─────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 16,
                    bottom: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8),
                    border: Border(
                      bottom: BorderSide(
                        color: scheme.primary.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: scheme.primary.withValues(alpha: 0.1),
                            ),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                            style: Theme.of(context).textTheme.bodyMedium,
                            decoration: InputDecoration(
                              hintText: 'Search transactions...',
                              hintStyle: TextStyle(color: Colors.grey.shade500),
                              prefixIcon: Icon(Icons.search_rounded,
                                  color: scheme.primary.withValues(alpha: 0.6)),
                              suffixIcon: search.isEmpty
                                  ? null
                                  : IconButton(
                                      icon: const Icon(Icons.clear_rounded, size: 20),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {});
                                      },
                                    ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            _FilterChip(
                              label: 'All',
                              selected: _filter == _TransactionFilter.all,
                              onTap: () => setState(() => _filter = _TransactionFilter.all),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Income',
                              icon: Icons.south_west_rounded,
                              iconColor: const Color(0xFF0A8F64),
                              selected: _filter == _TransactionFilter.income,
                              onTap: () => setState(() => _filter = _TransactionFilter.income),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Expense',
                              icon: Icons.north_east_rounded,
                              iconColor: const Color(0xFFBE4D58),
                              selected: _filter == _TransactionFilter.expense,
                              onTap: () => setState(() => _filter = _TransactionFilter.expense),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Custom filter chip with icon and premium look ───────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? iconColor;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    this.icon,
    this.iconColor,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? scheme.primary : scheme.primary.withValues(alpha: 0.15),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: selected ? Colors.white : (iconColor ?? scheme.primary)),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected ? Colors.white : scheme.primary.withValues(alpha: 0.8),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
