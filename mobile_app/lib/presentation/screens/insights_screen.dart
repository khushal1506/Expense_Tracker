import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/currency_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../utils/currency_formatter.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/error_state_widget.dart';
import '../widgets/loading_widget.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  bool _sameWeek(DateTime date, DateTime pivot) {
    final weekStart = DateTime(
      pivot.year,
      pivot.month,
      pivot.day,
    ).subtract(Duration(days: pivot.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    return !date.isBefore(weekStart) && date.isBefore(weekEnd);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txState = ref.watch(transactionProvider);
    final currencyCode = ref.watch(currencyProvider).valueOrNull ?? 'INR';
    final inrPerUnit = ref.watch(currencyRatesProvider).valueOrNull?.inrPerUnit;

    return txState.when(
      data: (transactions) {
        String money(double amount) =>
            formatCurrency(amount, currencyCode, inrPerUnit: inrPerUnit);

        if (transactions.isEmpty) {
          return const EmptyStateWidget(
            message: 'Add transactions to view insights',
          );
        }

        final expenseByCategory = <String, double>{};
        for (final tx in transactions.where((t) => t.type.name == 'expense')) {
          expenseByCategory[tx.category] =
              (expenseByCategory[tx.category] ?? 0) + tx.amount;
        }

        String topCategory = 'N/A';
        double maxValue = 0;
        expenseByCategory.forEach((category, amount) {
          if (amount > maxValue) {
            maxValue = amount;
            topCategory = category;
          }
        });

        final now = DateTime.now();
        final thisWeekExpense = transactions
            .where((t) => t.type.name == 'expense' && _sameWeek(t.date, now))
            .fold<double>(0, (sum, t) => sum + t.amount);

        final lastWeekPivot = now.subtract(const Duration(days: 7));
        final lastWeekExpense = transactions
            .where(
              (t) =>
                  t.type.name == 'expense' && _sameWeek(t.date, lastWeekPivot),
            )
            .fold<double>(0, (sum, t) => sum + t.amount);

        final weeklyChange = lastWeekExpense == 0
            ? 0.0
            : ((thisWeekExpense - lastWeekExpense) / lastWeekExpense) * 100;

        final sixMonthData = List.generate(6, (index) {
          final monthDate = DateTime(now.year, now.month - (5 - index), 1);
          final total = transactions
              .where(
                (t) =>
                    t.type.name == 'expense' &&
                    t.date.year == monthDate.year &&
                    t.date.month == monthDate.month,
              )
              .fold<double>(0, (sum, t) => sum + t.amount);
          return (monthDate, total);
        });
        final maxY = sixMonthData.fold<double>(
          0,
          (max, item) => item.$2 > max ? item.$2 : max,
        );

        final totalCategoryExpense = expenseByCategory.values.fold<double>(
          0,
          (sum, v) => sum + v,
        );
        final scheme = Theme.of(context).colorScheme;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          children: [
            // ── Header ─────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6E5AA8).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.insights_rounded,
                      color: Color(0xFF6E5AA8), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Spending Insights',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'A deeper look at your money flow.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Highlights Grid ────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _HighlightCard(
                    title: 'Top Category',
                    value: topCategory,
                    icon: Icons.star_border_rounded,
                    iconColor: const Color(0xFFD99058),
                    subtitle: 'Most spent on',
                    amount: money(maxValue),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _HighlightCard(
                    title: 'Weekly Change',
                    value:
                        '${weeklyChange >= 0 ? '+' : ''}${weeklyChange.toStringAsFixed(1)}%',
                    icon: weeklyChange <= 0
                        ? Icons.trending_down_rounded
                        : Icons.trending_up_rounded,
                    iconColor: weeklyChange > 0
                        ? const Color(0xFFBE4D58)
                        : const Color(0xFF0A8F64),
                    subtitle: 'vs Last Week',
                    amount: money(thisWeekExpense),
                  ),
                ),
              ],
            ),

            // ── Section Header ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 12),
              child: Row(
                children: [
                  Icon(Icons.bar_chart_rounded,
                      size: 18,
                      color: scheme.primary.withValues(alpha: 0.7)),
                  const SizedBox(width: 8),
                  Text(
                    '6-Month Trend',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          letterSpacing: 0.3,
                        ),
                  ),
                ],
              ),
            ),

            // ── 6 Month Chart Card ─────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: SizedBox(
                  height: 220,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY == 0 ? 10 : maxY * 1.2,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval:
                            maxY <= 0 ? 5 : (maxY * 1.2) / 4,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: scheme.primary.withValues(alpha: 0.08),
                            strokeWidth: 1,
                            dashArray: [4, 4],
                          );
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => scheme.primary,
                          getTooltipItem:
                              (group, groupIndex, rod, rodIndex) {
                            final item = sixMonthData[group.x.toInt()];
                            final monthLabel =
                                DateFormat.MMM().format(item.$1);
                            return BarTooltipItem(
                              '$monthLabel\n${money(item.$2)}',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 42,
                            interval: maxY <= 0 ? 5 : (maxY * 1.2) / 4,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                NumberFormat.compact().format(value),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: scheme.primary
                                          .withValues(alpha: 0.5),
                                    ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= sixMonthData.length) {
                                return const SizedBox.shrink();
                              }
                              final month = DateFormat.MMM()
                                  .format(sixMonthData[i].$1);
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  month,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: List.generate(sixMonthData.length, (i) {
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: sixMonthData[i].$2,
                              width: 14,
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  scheme.primary,
                                  const Color(0xFF6E5AA8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),

            // ── Section Header ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 12),
              child: Row(
                children: [
                  Icon(Icons.pie_chart_outline_rounded,
                      size: 18,
                      color: scheme.primary.withValues(alpha: 0.7)),
                  const SizedBox(width: 8),
                  Text(
                    'Category Breakdown',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          letterSpacing: 0.3,
                        ),
                  ),
                ],
              ),
            ),

            // ── Category List ──────────────────────────────────────
            ...(expenseByCategory.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
              .map((entry) {
                final pct = maxValue == 0
                    ? 0.0
                    : (entry.value / maxValue).toDouble();
                final actualPct = totalCategoryExpense == 0
                    ? 0.0
                    : (entry.value / totalCategoryExpense) * 100;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: scheme.primary
                                      .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.category_rounded,
                                  color: scheme.primary.withValues(alpha: 0.8),
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  entry.key,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontSize: 15),
                                ),
                              ),
                              Text(
                                '${actualPct.toStringAsFixed(1)}%',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: scheme.primary,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 6,
                              color: scheme.primary.withValues(alpha: 0.8),
                              backgroundColor:
                                  scheme.primary.withValues(alpha: 0.06),
                            ),
                          ),
                          const SizedBox(height: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              money(entry.value),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
          ],
        );
      },
      loading: () => const LoadingWidget(label: 'Analyzing spending...'),
      error: (e, _) => ErrorStateWidget(message: e.toString()),
    );
  }
}

// ── Highlight Card for top metrics ──────────────────────────────────────
class _HighlightCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final String subtitle;
  final String amount;

  const _HighlightCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.subtitle,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 18,
                    ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$subtitle $amount',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
