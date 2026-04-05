import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/model/goal_model.dart';
import '../../data/model/transaction_model.dart';
import 'add_edit_goal_screen.dart';
import 'add_edit_transaction_screen.dart';
import 'dashboard_screen.dart';
import 'goals_screen.dart';
import 'home_shell_screen.dart';
import 'insights_screen.dart';
import 'transactions_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

CustomTransitionPage buildFadeTransition(Widget child) {
  return CustomTransitionPage(
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

CustomTransitionPage buildSlideTransition(Widget child) {
  return CustomTransitionPage(
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 1.0);
      const end = Offset.zero;
      const curve = Curves.easeOutCubic;
      final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      final offsetAnimation = animation.drive(tween);
      return SlideTransition(position: offsetAnimation, child: child);
    },
  );
}

final GoRouter appRouter = GoRouter(
  initialLocation: '/dashboard',
  navigatorKey: _rootNavigatorKey,
  routes: [
    ShellRoute(
      builder: (context, state, child) => HomeShellScreen(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          name: 'dashboard',
          pageBuilder: (context, state) => buildFadeTransition(const DashboardScreen()),
        ),
        GoRoute(
          path: '/transactions',
          name: 'transactions',
          pageBuilder: (context, state) => buildFadeTransition(const TransactionsScreen()),
        ),
        GoRoute(
          path: '/goals',
          name: 'goals',
          pageBuilder: (context, state) => buildFadeTransition(const GoalsScreen()),
        ),
        GoRoute(
          path: '/insights',
          name: 'insights',
          pageBuilder: (context, state) => buildFadeTransition(const InsightsScreen()),
        ),
      ],
    ),
    GoRoute(
      path: '/transactions/new',
      pageBuilder: (context, state) => buildSlideTransition(const AddEditTransactionScreen()),
    ),
    GoRoute(
      path: '/transactions/edit',
      pageBuilder: (context, state) {
        final tx = state.extra as Transaction;
        return buildSlideTransition(AddEditTransactionScreen(initial: tx));
      },
    ),
    GoRoute(
      path: '/goals/new',
      pageBuilder: (context, state) => buildSlideTransition(const AddEditGoalScreen()),
    ),
    GoRoute(
      path: '/goals/edit',
      pageBuilder: (context, state) {
        final goal = state.extra as Goal;
        return buildSlideTransition(AddEditGoalScreen(initial: goal));
      },
    ),
  ],
);
