import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/sync_provider.dart';

class SyncStatusBadge extends ConsumerWidget {
  const SyncStatusBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(syncStatusProvider);
    final scheme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.bodySmall;

    Color color;
    IconData icon;
    String label;

    switch (status) {
      case SyncStatus.syncing:
        color = const Color(0xFF2D66B1);
        icon = Icons.sync;
        label = 'Syncing';
        break;
      case SyncStatus.success:
        color = const Color(0xFF2E8A6B);
        icon = Icons.check_circle;
        label = 'Live';
        break;
      case SyncStatus.error:
        color = const Color(0xFFBD4E57);
        icon = Icons.error;
        label = 'Retry';
        break;
      case SyncStatus.idle:
        color = const Color(0xFF7F8799);
        icon = Icons.circle;
        label = 'Idle';
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Icon(icon, key: ValueKey(icon), size: 14, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: textStyle?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
