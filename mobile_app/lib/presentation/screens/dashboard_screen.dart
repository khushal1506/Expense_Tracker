import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/model/transaction_model.dart';
import '../../providers/challenge_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/goal_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/export_service.dart';
import '../../utils/currency_formatter.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/error_state_widget.dart';
import '../widgets/loading_widget.dart';
import '../widgets/transaction_tile.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  DateTime _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  int _noSpendStreak({
    required Set<DateTime> expenseDays,
    required DateTime? startDate,
  }) {
    if (startDate == null) {
      return 0;
    }

    final start = _startOfDay(startDate);
    var cursor = _startOfDay(DateTime.now()).subtract(const Duration(days: 1));
    if (cursor.isBefore(start)) {
      return 0;
    }
    var streak = 0;

    while (!cursor.isBefore(start)) {
      if (expenseDays.contains(cursor)) {
        break;
      }
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return streak;
  }

  int _savingStreak(List<Transaction> transactions) {
    final dailyNet = <DateTime, double>{};

    for (final tx in transactions) {
      final day = _startOfDay(tx.date);
      final signedAmount = tx.type == TransactionType.income
          ? tx.amount
          : -tx.amount;
      dailyNet[day] = (dailyNet[day] ?? 0) + signedAmount;
    }

    var cursor = _startOfDay(DateTime.now());
    var streak = 0;

    while (dailyNet.containsKey(cursor) && (dailyNet[cursor] ?? 0) > 0) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return streak;
  }

  bool _sameWeek(DateTime date, DateTime pivot) {
    final weekStart = DateTime(
      pivot.year,
      pivot.month,
      pivot.day,
    ).subtract(Duration(days: pivot.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    return !date.isBefore(weekStart) && date.isBefore(weekEnd);
  }

  Future<void> _showBudgetLimitDialog(
    BuildContext context,
    WidgetRef ref,
    double initialValue,
    String currencyCode,
    Map<String, double>? inrPerUnit,
  ) async {
    final initialDisplayValue = convertFromInr(
      initialValue,
      currencyCode,
      inrPerUnit: inrPerUnit,
    );
    final controller = TextEditingController(
      text: initialDisplayValue > 0
          ? initialDisplayValue.toStringAsFixed(2)
          : '',
    );
    final symbol = currencySymbol(currencyCode);

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Set Monthly Budget Limit'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Budget Limit',
              prefixText: '$symbol ',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final parsed = double.tryParse(controller.text.trim());
                if (parsed == null || parsed < 0) {
                  return;
                }

                final parsedInInr = convertToInr(
                  parsed,
                  currencyCode,
                  inrPerUnit: inrPerUnit,
                );

                await ref
                    .read(challengeProvider.notifier)
                    .setMonthlyBudgetLimit(parsedInInr);

                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showNoSpendChallengeDialog(
    BuildContext context,
    WidgetRef ref,
    ChallengeSettings current,
  ) async {
    var enabled = current.noSpendChallengeEnabled;
    var selectedTarget = current.noSpendTargetDays;
    const targetOptions = [3, 5, 7, 10, 14, 21, 30];

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('No-Spend Challenge'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Enable challenge'),
                    value: enabled,
                    onChanged: (value) {
                      setState(() => enabled = value);
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    initialValue: selectedTarget,
                    decoration: const InputDecoration(
                      labelText: 'Target no-spend days',
                    ),
                    items: targetOptions
                        .map(
                          (days) => DropdownMenuItem<int>(
                            value: days,
                            child: Text('$days days'),
                          ),
                        )
                        .toList(),
                    onChanged: enabled
                        ? (value) {
                            if (value != null) {
                              setState(() => selectedTarget = value);
                            }
                          }
                        : null,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    await ref
                        .read(challengeProvider.notifier)
                        .configureNoSpendChallenge(
                          enabled: enabled,
                          targetDays: selectedTarget,
                        );

                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── Section header builder ──────────────────────────────────────────
  Widget _sectionHeader(BuildContext context, String title,
      {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 10),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7)),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  letterSpacing: 0.3,
                ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txState = ref.watch(transactionProvider);
    final goalState = ref.watch(goalProvider);
    final challengeState = ref.watch(challengeProvider);
    final currencyState = ref.watch(currencyProvider);
    final ratesState = ref.watch(currencyRatesProvider);
    final supportedCurrencies = ref.watch(supportedCurrenciesProvider);
    final currencyCode = currencyState.valueOrNull ?? 'INR';
    final inrPerUnit = ratesState.valueOrNull?.inrPerUnit;

    return txState.when(
      data: (transactions) {
        String money(double amount) =>
            formatCurrency(amount, currencyCode, inrPerUnit: inrPerUnit);

        final now = DateTime.now();
        final monthlyTransactions = transactions
            .where((t) => t.date.year == now.year && t.date.month == now.month)
            .toList();

        final income = transactions
            .where((t) => t.type.name == 'income')
            .fold<double>(0, (sum, t) => sum + t.amount);
        final expense = transactions
            .where((t) => t.type.name == 'expense')
            .fold<double>(0, (sum, t) => sum + t.amount);
        final balance = income - expense;

        final monthlyIncome = monthlyTransactions
            .where((t) => t.type.name == 'income')
            .fold<double>(0, (sum, t) => sum + t.amount);
        final monthlyExpense = monthlyTransactions
            .where((t) => t.type.name == 'expense')
            .fold<double>(0, (sum, t) => sum + t.amount);

        final settings =
            challengeState.valueOrNull ?? const ChallengeSettings.initial();

        final monthlyBudgetLimit = settings.monthlyBudgetLimit;
        final spentRatio = monthlyBudgetLimit <= 0
            ? 0.0
            : monthlyExpense / monthlyBudgetLimit;
        final spentPercentage = spentRatio.clamp(0.0, 1.0);
        final remainingBudget = monthlyBudgetLimit - monthlyExpense;
        final isOverBudget = monthlyBudgetLimit > 0 && remainingBudget < 0;

        final expenseDays = transactions
            .where((t) => t.type == TransactionType.expense)
            .map((t) => _startOfDay(t.date))
            .toSet();

        final currentNoSpendStreak = _noSpendStreak(
          expenseDays: expenseDays,
          startDate: settings.noSpendStartedAt,
        );

        final savingStreak = _savingStreak(transactions);

        final thisWeekExpense = transactions
            .where(
              (t) =>
                  t.type == TransactionType.expense && _sameWeek(t.date, now),
            )
            .fold<double>(0, (sum, t) => sum + t.amount);
        final lastWeekPivot = now.subtract(const Duration(days: 7));
        final lastWeekExpense = transactions
            .where(
              (t) =>
                  t.type == TransactionType.expense &&
                  _sameWeek(t.date, lastWeekPivot),
            )
            .fold<double>(0, (sum, t) => sum + t.amount);
        final weeklyChange = thisWeekExpense - lastWeekExpense;
        final weeklyChangePct = lastWeekExpense == 0
            ? 0.0
            : (weeklyChange / lastWeekExpense) * 100;

        final monthlyExpenseByCategory = <String, double>{};
        for (final tx in monthlyTransactions.where(
          (t) => t.type.name == 'expense',
        )) {
          monthlyExpenseByCategory[tx.category] =
              (monthlyExpenseByCategory[tx.category] ?? 0) + tx.amount;
        }
        final scheme = Theme.of(context).colorScheme;
        const chartPalette = [
          Color(0xFF224A82),
          Color(0xFFD99058),
          Color(0xFF3E8B75),
          Color(0xFF6E5AA8),
          Color(0xFFBE4D58),
          Color(0xFF4A7BCE),
        ];

        final firstGoal = goalState.maybeWhen(
          data: (goals) => goals.isNotEmpty ? goals.first : null,
          orElse: () => null,
        );

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            // ── Greeting + Currency Picker ──────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Finance Snapshot',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Track trends, goals & smart habits.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                // Theme toggle
                IconButton(
                  icon: Icon(
                    Theme.of(context).brightness == Brightness.dark
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                    color: scheme.primary,
                  ),
                  onPressed: () {
                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    ref.read(themeProvider.notifier).state = isDark ? ThemeMode.light : ThemeMode.dark;
                  },
                ),
                // Export Button
                IconButton(
                  icon: Icon(
                    Icons.file_download_outlined,
                    color: scheme.primary,
                  ),
                  onPressed: () async {
                    try {
                      await ref.read(exportServiceProvider).exportTransactionsToCSV(transactions);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to export: $e')),
                        );
                      }
                    }
                  },
                ),
                const SizedBox(width: 4),
                // Compact currency selector
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: scheme.primary.withValues(alpha: 0.15)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: currencyCode,
                      isDense: true,
                      icon: Icon(Icons.unfold_more_rounded,
                          size: 16,
                          color: scheme.primary),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: scheme.primary,
                          ),
                      items: supportedCurrencies
                          .map(
                            (code) => DropdownMenuItem<String>(
                              value: code,
                              child: Text(
                                  '$code ${currencySymbol(code)}'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          ref
                              .read(currencyProvider.notifier)
                              .setCurrencyCode(value);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // ── Hero Balance Card ───────────────────────────────────
            _HeroBalanceCard(
              balance: balance,
              currencyCode: currencyCode,
              inrPerUnit: inrPerUnit,
            ),

            const SizedBox(height: 12),

            // ── Income / Expense Row ────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'Monthly Income',
                    value: monthlyIncome,
                    currencyCode: currencyCode,
                    inrPerUnit: inrPerUnit,
                    icon: Icons.south_west_rounded,
                    iconColor: const Color(0xFF0A8F64),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricCard(
                    title: 'Monthly Expense',
                    value: monthlyExpense,
                    currencyCode: currencyCode,
                    inrPerUnit: inrPerUnit,
                    icon: Icons.north_east_rounded,
                    iconColor: const Color(0xFFBE4D58),
                  ),
                ),
              ],
            ),

            // ── Challenges & Habits Section ─────────────────────────
            _sectionHeader(context, 'Challenges & Habits',
                icon: Icons.emoji_events_outlined),

            // Budget Limit Tracker
            _BudgetTrackerCard(
              monthlyExpense: monthlyExpense,
              monthlyBudgetLimit: monthlyBudgetLimit,
              spentPercentage: spentPercentage,
              spentRatio: spentRatio,
              remainingBudget: remainingBudget,
              isOverBudget: isOverBudget,
              money: money,
              onEdit: () {
                _showBudgetLimitDialog(
                  context,
                  ref,
                  monthlyBudgetLimit,
                  currencyCode,
                  inrPerUnit,
                );
              },
            ),

            const SizedBox(height: 10),

            // No-Spend Challenge
            _NoSpendCard(
              settings: settings,
              currentStreak: currentNoSpendStreak,
              onConfigure: () {
                _showNoSpendChallengeDialog(context, ref, settings);
              },
              onRestart: () async {
                await ref
                    .read(challengeProvider.notifier)
                    .restartNoSpendChallenge();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Challenge restarted'),
                    ),
                  );
                }
              },
            ),

            const SizedBox(height: 10),

            // Streak + Weekly Comparison — side by side
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Saving Streak
                Expanded(
                  child: _CompactStatCard(
                    icon: Icons.local_fire_department_rounded,
                    iconColor: const Color(0xFFD99058),
                    label: 'Saving Streak',
                    value: '$savingStreak day${savingStreak == 1 ? '' : 's'}',
                    subtitle: savingStreak == 0
                        ? 'End with net savings to start'
                        : 'Keep it up!',
                  ),
                ),
                const SizedBox(width: 10),
                // Weekly Change
                Expanded(
                  child: _CompactStatCard(
                    icon: weeklyChange <= 0
                        ? Icons.trending_down_rounded
                        : Icons.trending_up_rounded,
                    iconColor: weeklyChange > 0
                        ? const Color(0xFFBE4D58)
                        : const Color(0xFF0A8F64),
                    label: 'Week vs Week',
                    value:
                        '${weeklyChangePct >= 0 ? '+' : ''}${weeklyChangePct.toStringAsFixed(1)}%',
                    subtitle:
                        'This: ${money(thisWeekExpense)}',
                  ),
                ),
              ],
            ),

            // ── Goal Progress ───────────────────────────────────────
            if (firstGoal != null) ...[
              _sectionHeader(context, 'Goal Progress',
                  icon: Icons.flag_outlined),
              _GoalProgressCard(
                goalName: firstGoal.name,
                balance: balance,
                targetAmount: firstGoal.targetAmount,
                money: money,
              ),
            ],

            // ── Spending Breakdown ──────────────────────────────────
            _sectionHeader(context, 'Spending by Category',
                icon: Icons.pie_chart_outline_rounded),
            Text(
              DateFormat.MMMM().format(now),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),

            if (monthlyExpenseByCategory.isEmpty)
              const EmptyStateWidget(
                message: 'No expense data for current month',
              )
            else
              _SpendingChart(
                categoryData: monthlyExpenseByCategory,
                chartPalette: chartPalette,
                scheme: scheme,
              ),

            // ── Recent Transactions ─────────────────────────────────
            _sectionHeader(context, 'Recent Transactions',
                icon: Icons.receipt_long_outlined),

            if (transactions.isEmpty)
              const EmptyStateWidget(message: 'No transactions yet')
            else
              ...transactions
                  .take(5)
                  .map((t) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: TransactionTile(transaction: t),
                      )),
          ],
        );
      },
      loading: () => const LoadingWidget(label: 'Loading dashboard...'),
      error: (e, _) => ErrorStateWidget(message: e.toString()),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// HERO BALANCE CARD — gradient background, large readable balance
// ═══════════════════════════════════════════════════════════════════════

class _HeroBalanceCard extends StatelessWidget {
  final double balance;
  final String currencyCode;
  final Map<String, double>? inrPerUnit;

  const _HeroBalanceCard({
    required this.balance,
    required this.currencyCode,
    this.inrPerUnit,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isPositive = balance >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary,
            scheme.primary.withValues(alpha: 0.85),
            const Color(0xFF3E8B75).withValues(alpha: 0.7),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Current Balance',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              Icon(
                isPositive
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                color: Colors.white.withValues(alpha: 0.7),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatCurrency(balance, currencyCode, inrPerUnit: inrPerUnit),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 32,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// METRIC CARD — income / expense with icon
// ═══════════════════════════════════════════════════════════════════════

class _MetricCard extends StatelessWidget {
  final String title;
  final double value;
  final String currencyCode;
  final Map<String, double>? inrPerUnit;
  final IconData icon;
  final Color iconColor;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.currencyCode,
    this.inrPerUnit,
    required this.icon,
    required this.iconColor,
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
                Flexible(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                formatCurrency(value, currencyCode, inrPerUnit: inrPerUnit),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 20,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// BUDGET TRACKER CARD
// ═══════════════════════════════════════════════════════════════════════

class _BudgetTrackerCard extends StatelessWidget {
  final double monthlyExpense;
  final double monthlyBudgetLimit;
  final double spentPercentage;
  final double spentRatio;
  final double remainingBudget;
  final bool isOverBudget;
  final String Function(double) money;
  final VoidCallback onEdit;

  const _BudgetTrackerCard({
    required this.monthlyExpense,
    required this.monthlyBudgetLimit,
    required this.spentPercentage,
    required this.spentRatio,
    required this.remainingBudget,
    required this.isOverBudget,
    required this.money,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.pie_chart_rounded,
                      color: scheme.primary, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Budget Limit Tracker',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 15,
                        ),
                  ),
                ),
                SizedBox(
                  width: 34,
                  height: 34,
                  child: IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    padding: EdgeInsets.zero,
                    tooltip: 'Set budget',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (monthlyBudgetLimit <= 0)
              Text(
                'Set your monthly budget limit to start tracking.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else ...[
              // Spent vs limit text — overflow-safe
              Row(
                children: [
                  Flexible(
                    child: Text(
                      'Spent: ${money(monthlyExpense)} of ${money(monthlyBudgetLimit)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(spentRatio * 100).toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isOverBudget ? Colors.red : scheme.primary,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: spentPercentage,
                  minHeight: 8,
                  color: isOverBudget ? Colors.red : null,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isOverBudget
                    ? 'Over budget by ${money(-remainingBudget)}'
                    : 'Remaining: ${money(remainingBudget)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isOverBudget
                          ? Colors.red
                          : const Color(0xFF0A8F64),
                      fontWeight: FontWeight.w700,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// NO-SPEND CHALLENGE CARD
// ═══════════════════════════════════════════════════════════════════════

class _NoSpendCard extends StatelessWidget {
  final ChallengeSettings settings;
  final int currentStreak;
  final VoidCallback onConfigure;
  final VoidCallback onRestart;

  const _NoSpendCard({
    required this.settings,
    required this.currentStreak,
    required this.onConfigure,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = settings.noSpendTargetDays == 0
        ? 0.0
        : (currentStreak / settings.noSpendTargetDays).clamp(0.0, 1.0);
    final achieved = currentStreak >= settings.noSpendTargetDays;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6E5AA8).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.block_rounded,
                      color: Color(0xFF6E5AA8), size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No-Spend Challenge',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 15,
                        ),
                  ),
                ),
                TextButton(
                  onPressed: onConfigure,
                  child: Text(
                    settings.noSpendChallengeEnabled ? 'Edit' : 'Start',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (!settings.noSpendChallengeEnabled)
              Text(
                'Challenge is off. Start one to build discipline.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else ...[
              Text(
                '$currentStreak / ${settings.noSpendTargetDays} no-spend days',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  color: achieved
                      ? const Color(0xFF0A8F64)
                      : scheme.tertiary,
                ),
              ),
              const SizedBox(height: 10),
              if (settings.noSpendStartedAt != null)
                Text(
                  'Started: ${DateFormat.yMMMd().format(settings.noSpendStartedAt!)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              const SizedBox(height: 10),
              // Wrap in a Wrap to avoid Row overflow
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonal(
                    onPressed: onRestart,
                    child: const Text('Restart'),
                  ),
                  if (achieved)
                    Chip(
                      avatar: const Icon(Icons.check_circle,
                          size: 16, color: Color(0xFF0A8F64)),
                      label: const Text('Target Achieved'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// COMPACT STAT CARD — for streak / weekly comparison
// ═══════════════════════════════════════════════════════════════════════

class _CompactStatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String subtitle;

  const _CompactStatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 20,
                    ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
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

// ═══════════════════════════════════════════════════════════════════════
// GOAL PROGRESS CARD
// ═══════════════════════════════════════════════════════════════════════

class _GoalProgressCard extends StatelessWidget {
  final String goalName;
  final double balance;
  final double targetAmount;
  final String Function(double) money;

  const _GoalProgressCard({
    required this.goalName,
    required this.balance,
    required this.targetAmount,
    required this.money,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = targetAmount == 0
        ? 0.0
        : (balance / targetAmount).clamp(0.0, 1.0);
    final pct = (progress * 100).toStringAsFixed(0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: scheme.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      Icon(Icons.flag_rounded, color: scheme.secondary, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    goalName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 15,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '$pct%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                value: progress,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${money(balance)} / ${money(targetAmount)}',
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// SPENDING PIE CHART CARD
// ═══════════════════════════════════════════════════════════════════════

class _SpendingChart extends StatelessWidget {
  final Map<String, double> categoryData;
  final List<Color> chartPalette;
  final ColorScheme scheme;

  const _SpendingChart({
    required this.categoryData,
    required this.chartPalette,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Column(
            children: [
              Expanded(
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 48,
                    startDegreeOffset: -90,
                    sections: categoryData.entries
                        .toList()
                        .asMap()
                        .entries
                        .map((item) {
                          final idx = item.key;
                          final entry = item.value;
                          final value = entry.value;
                          final total = categoryData.values
                              .fold<double>(0, (a, b) => a + b);
                          final pct =
                              total == 0 ? 0 : (value / total) * 100;
                          return PieChartSectionData(
                            color: chartPalette[idx % chartPalette.length],
                            value: value,
                            title: '${pct.toStringAsFixed(0)}%',
                            radius: 68,
                            titleStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                            borderSide: BorderSide(
                              color: scheme.surface,
                              width: 2,
                            ),
                          );
                        })
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: categoryData.entries
                    .toList()
                    .asMap()
                    .entries
                    .map((item) {
                      final idx = item.key;
                      final entry = item.value;
                      final color =
                          chartPalette[idx % chartPalette.length];
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            entry.key,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      );
                    })
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
