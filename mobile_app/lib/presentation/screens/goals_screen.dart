import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/currency_provider.dart';
import '../../providers/goal_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../utils/currency_formatter.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/error_state_widget.dart';
import '../widgets/loading_widget.dart';
import 'package:flutter/services.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Set appropriate status bar icons based on the theme
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.light,
      ),
    );

    final goalState = ref.watch(goalProvider);
    final txState = ref.watch(transactionProvider);
    final currencyCode = ref.watch(currencyProvider).valueOrNull ?? 'INR';
    final inrPerUnit = ref.watch(currencyRatesProvider).valueOrNull?.inrPerUnit;

    String money(double amount) =>
        formatCurrency(amount, currencyCode, inrPerUnit: inrPerUnit);

    final savings = txState.maybeWhen(
      data: (tx) {
        final income = tx
            .where((t) => t.type.name == 'income')
            .fold<double>(0, (a, b) => a + b.amount);
        final expense = tx
            .where((t) => t.type.name == 'expense')
            .fold<double>(0, (a, b) => a + b.amount);
        return income - expense;
      },
      orElse: () => 0.0,
    );

    return goalState.when(
      data: (goals) {
        if (goals.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Savings Goals')),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => context.push('/goals/new'),
              icon: const Icon(Icons.add),
              label: const Text('Add Goal'),
            ),
            body: EmptyStateWidget(
              message: 'No goals yet',
              ctaLabel: 'Add Goal',
              onTap: () => context.push('/goals/new'),
            ),
          );
        }

        final activeGoal = goals.first;
        final progress = activeGoal.targetAmount == 0
            ? 0.0
            : (savings / activeGoal.targetAmount).clamp(0.0, 1.0);
        final progressPct = (progress * 100).toStringAsFixed(0);
        final scheme = Theme.of(context).colorScheme;

        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push('/goals/new'),
            icon: const Icon(Icons.add),
            label: const Text('Add Goal'),
            elevation: 4,
          ),
          body: CustomScrollView(
            slivers: [
              // ── Immersive Header & Floating Active Goal ──────────
              SliverToBoxAdapter(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Deep gradient background
                    Container(
                      width: double.infinity,
                      height: 340,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            scheme.primary,
                            scheme.secondary.withValues(alpha: isDark ? 0.6 : 0.9),
                            scheme.primary.withValues(alpha: isDark ? 0.4 : 0.8),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(40),
                          bottomRight: Radius.circular(40),
                        ),
                      ),
                    ),
                    SafeArea(
                      bottom: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Savings Goals',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.military_tech_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 8),
                            child: Text(
                              'Stay focused on what matters most.',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Glassmorphic Active Goal
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: isDark 
                                        ? Colors.black.withValues(alpha: 0.25)
                                        : Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.3),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.15),
                                        blurRadius: 30,
                                        spreadRadius: 5,
                                        offset: const Offset(0, 10),
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
                                              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              Icons.star_rounded,
                                              color: isDark ? Colors.white : scheme.secondary,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              'Active Priority',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge
                                                  ?.copyWith(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                    letterSpacing: 0.5,
                                                  ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: isDark ? scheme.primary.withValues(alpha: 0.8) : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              '$progressPct%',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    color: isDark ? Colors.white : scheme.secondary,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 24),
                                      Text(
                                        activeGoal.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                            ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 24),
                                      Stack(
                                        children: [
                                          Container(
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: Colors.black
                                                  .withValues(alpha: 0.3),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          LayoutBuilder(
                                              builder: (ctx, constraints) {
                                            return AnimatedContainer(
                                              duration: const Duration(
                                                  milliseconds: 1200),
                                              curve: Curves.easeOutCubic,
                                              height: 12,
                                              width:
                                                  constraints.maxWidth * progress,
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [Color(0xFF34D399), Color(0xFF10B981)],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: const Color(0xFF10B981)
                                                        .withValues(alpha: 0.5),
                                                    blurRadius: 10,
                                                    offset: const Offset(0, 2),
                                                  )
                                                ],
                                              ),
                                            );
                                          }),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Saved: ${money(savings)}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.9),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          Text(
                                            'Target: ${money(activeGoal.targetAmount)}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Remaining Goals Grid ──────────────────────────────
              if (goals.length > 1) ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Icon(Icons.dashboard_customize_rounded,
                            size: 20,
                            color: scheme.primary.withValues(alpha: 0.8)),
                        const SizedBox(width: 10),
                        Text(
                          'Vision Board',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    letterSpacing: 0.3,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final g = goals[index + 1]; // Skip active goal
                        final itemProgress = g.targetAmount == 0
                            ? 0.0
                            : (savings / g.targetAmount).clamp(0.0, 1.0);
                        final itemPct = (itemProgress * 100).toStringAsFixed(0);

                        return Material(
                          color: scheme.surface,
                          elevation: isDark ? 2 : 4,
                          shadowColor: isDark ? Colors.black.withValues(alpha: 0.5) : scheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(24),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => context.push('/goals/edit', extra: g),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: scheme.primary.withValues(alpha: 0.05),
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: scheme.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.flag_rounded,
                                          color: scheme.primary,
                                          size: 18,
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete_outline_rounded,
                                          color:
                                              scheme.error.withValues(alpha: 0.8),
                                          size: 18,
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () {
                                          ref
                                              .read(goalProvider.notifier)
                                              .deleteGoal(g.id);
                                        },
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Text(
                                    g.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          height: 1.2,
                                        ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 14),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: LinearProgressIndicator(
                                      value: itemProgress,
                                      minHeight: 6,
                                      color: scheme.primary,
                                      backgroundColor:
                                          scheme.primary.withValues(alpha: 0.15),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Text(
                                        '$itemPct%',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w900,
                                              color: scheme.primary,
                                            ),
                                      ),
                                      const Spacer(),
                                      Flexible(
                                        flex: 3,
                                        child: Text(
                                          money(g.targetAmount),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Theme.of(context).textTheme.bodySmall?.color,
                                                fontWeight: FontWeight.w600,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: goals.length - 1,
                    ),
                  ),
                ),
              ] else ...[
                // Empty state if only 1 goal exists
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Text(
                        'Keep it up! Add more goals\nto see your Vision Board.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).textTheme.bodySmall?.color,
                              height: 1.5,
                            ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const LoadingWidget(label: 'Loading goals...'),
      error: (e, _) => ErrorStateWidget(message: e.toString()),
    );
  }
}
