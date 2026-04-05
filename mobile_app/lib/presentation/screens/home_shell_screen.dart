import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/sync_status_badge.dart';

class HomeShellScreen extends StatelessWidget {
  final Widget child;

  const HomeShellScreen({super.key, required this.child});

  static const _paths = ['/dashboard', '/transactions', '/goals', '/insights'];

  static const _titles = ['Dashboard', 'Transactions', 'Goals', 'Insights'];

  int _locationToIndex(String location) {
    if (location.startsWith('/transactions')) return 1;
    if (location.startsWith('/goals')) return 2;
    if (location.startsWith('/insights')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final index = _locationToIndex(location);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[index]),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.secondary.withValues(alpha: 0.2),
                scheme.primary.withValues(alpha: 0.1),
                Colors.transparent,
              ],
            ),
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: SyncStatusBadge(),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              scheme.secondary.withValues(alpha: 0.08),
              scheme.primary.withValues(alpha: 0.06),
              scheme.surface,
            ],
            stops: const [0.0, 0.18, 1.0],
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (widget, animation) {
            final offsetTween = Tween<Offset>(
              begin: const Offset(0.0, 0.015),
              end: Offset.zero,
            );

            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: offsetTween.animate(animation),
                child: widget,
              ),
            );
          },
          child: KeyedSubtree(key: ValueKey<int>(index), child: child),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        height: 74,
        onDestinationSelected: (newIndex) {
          if (newIndex == index) return;
          context.go(_paths[newIndex]);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Transactions',
          ),
          NavigationDestination(
            icon: Icon(Icons.flag_outlined),
            label: 'Goals',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            label: 'Insights',
          ),
        ],
      ),
    );
  }
}
