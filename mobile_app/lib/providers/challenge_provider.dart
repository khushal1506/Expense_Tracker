import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core_providers.dart';

class ChallengeSettings {
  final double monthlyBudgetLimit;
  final bool noSpendChallengeEnabled;
  final int noSpendTargetDays;
  final DateTime? noSpendStartedAt;

  const ChallengeSettings({
    required this.monthlyBudgetLimit,
    required this.noSpendChallengeEnabled,
    required this.noSpendTargetDays,
    required this.noSpendStartedAt,
  });

  const ChallengeSettings.initial()
    : monthlyBudgetLimit = 0,
      noSpendChallengeEnabled = false,
      noSpendTargetDays = 7,
      noSpendStartedAt = null;

  ChallengeSettings copyWith({
    double? monthlyBudgetLimit,
    bool? noSpendChallengeEnabled,
    int? noSpendTargetDays,
    DateTime? noSpendStartedAt,
    bool clearNoSpendStart = false,
  }) {
    return ChallengeSettings(
      monthlyBudgetLimit: monthlyBudgetLimit ?? this.monthlyBudgetLimit,
      noSpendChallengeEnabled:
          noSpendChallengeEnabled ?? this.noSpendChallengeEnabled,
      noSpendTargetDays: noSpendTargetDays ?? this.noSpendTargetDays,
      noSpendStartedAt: clearNoSpendStart
          ? null
          : (noSpendStartedAt ?? this.noSpendStartedAt),
    );
  }
}

class ChallengeNotifier extends StateNotifier<AsyncValue<ChallengeSettings>> {
  final Ref ref;

  static const _budgetLimitKey = 'monthly_budget_limit';
  static const _noSpendEnabledKey = 'no_spend_enabled';
  static const _noSpendTargetKey = 'no_spend_target_days';
  static const _noSpendStartKey = 'no_spend_started_at';

  ChallengeNotifier(this.ref) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<SharedPreferences> _prefs() =>
      ref.read(sharedPreferencesProvider.future);

  Future<void> _load() async {
    try {
      final prefs = await _prefs();
      final startedAtMs = prefs.getInt(_noSpendStartKey);

      state = AsyncValue.data(
        ChallengeSettings(
          monthlyBudgetLimit: prefs.getDouble(_budgetLimitKey) ?? 0,
          noSpendChallengeEnabled: prefs.getBool(_noSpendEnabledKey) ?? false,
          noSpendTargetDays: prefs.getInt(_noSpendTargetKey) ?? 7,
          noSpendStartedAt: startedAtMs == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(startedAtMs),
        ),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setMonthlyBudgetLimit(double budgetLimit) async {
    final current = state.valueOrNull ?? const ChallengeSettings.initial();
    final next = current.copyWith(monthlyBudgetLimit: budgetLimit);

    state = AsyncValue.data(next);
    final prefs = await _prefs();
    await prefs.setDouble(_budgetLimitKey, budgetLimit);
  }

  Future<void> configureNoSpendChallenge({
    required bool enabled,
    required int targetDays,
  }) async {
    final current = state.valueOrNull ?? const ChallengeSettings.initial();

    final start = enabled
        ? (current.noSpendChallengeEnabled
              ? current.noSpendStartedAt ?? DateTime.now()
              : DateTime.now())
        : null;

    final next = current.copyWith(
      noSpendChallengeEnabled: enabled,
      noSpendTargetDays: targetDays,
      noSpendStartedAt: start,
      clearNoSpendStart: !enabled,
    );

    state = AsyncValue.data(next);

    final prefs = await _prefs();
    await prefs.setBool(_noSpendEnabledKey, enabled);
    await prefs.setInt(_noSpendTargetKey, targetDays);

    if (start == null) {
      await prefs.remove(_noSpendStartKey);
    } else {
      await prefs.setInt(_noSpendStartKey, start.millisecondsSinceEpoch);
    }
  }

  Future<void> restartNoSpendChallenge() async {
    final current = state.valueOrNull ?? const ChallengeSettings.initial();
    if (!current.noSpendChallengeEnabled) {
      return;
    }

    final now = DateTime.now();
    state = AsyncValue.data(current.copyWith(noSpendStartedAt: now));

    final prefs = await _prefs();
    await prefs.setInt(_noSpendStartKey, now.millisecondsSinceEpoch);
  }
}

final challengeProvider =
    StateNotifierProvider<ChallengeNotifier, AsyncValue<ChallengeSettings>>((
      ref,
    ) {
      return ChallengeNotifier(ref);
    });
