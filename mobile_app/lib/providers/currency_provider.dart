import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import 'core_providers.dart';
import '../utils/currency_formatter.dart';

class CurrencyRatesState {
  final Map<String, double> inrPerUnit;
  final DateTime? lastUpdated;
  final bool usingCachedRates;

  const CurrencyRatesState({
    required this.inrPerUnit,
    required this.lastUpdated,
    required this.usingCachedRates,
  });

  CurrencyRatesState copyWith({
    Map<String, double>? inrPerUnit,
    DateTime? lastUpdated,
    bool? usingCachedRates,
  }) {
    return CurrencyRatesState(
      inrPerUnit: inrPerUnit ?? this.inrPerUnit,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      usingCachedRates: usingCachedRates ?? this.usingCachedRates,
    );
  }
}

class CurrencyNotifier extends StateNotifier<AsyncValue<String>> {
  final Ref ref;

  static const _currencyKey = 'selected_currency_code';

  CurrencyNotifier(this.ref) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await ref.read(sharedPreferencesProvider.future);
      state = AsyncValue.data(prefs.getString(_currencyKey) ?? 'INR');
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setCurrencyCode(String currencyCode) async {
    state = AsyncValue.data(currencyCode);
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString(_currencyKey, currencyCode);
  }
}

final supportedCurrenciesProvider = Provider<List<String>>((ref) {
  return const ['INR', 'USD', 'EUR', 'GBP', 'JPY', 'AED'];
});

class CurrencyRatesNotifier
    extends StateNotifier<AsyncValue<CurrencyRatesState>> {
  final Ref ref;
  Timer? _refreshTimer;

  static const _ratesCacheKey = 'currency_rates_cache';
  static const _ratesUpdatedAtKey = 'currency_rates_updated_at';

  CurrencyRatesNotifier(this.ref) : super(const AsyncValue.loading()) {
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadCachedRates();
    await refreshRates();

    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      refreshRates();
    });
  }

  Future<void> _loadCachedRates() async {
    try {
      final prefs = await ref.read(sharedPreferencesProvider.future);
      final raw = prefs.getString(_ratesCacheKey);
      final updatedAtMs = prefs.getInt(_ratesUpdatedAtKey);

      if (raw == null) {
        state = AsyncValue.data(
          CurrencyRatesState(
            inrPerUnit: defaultInrPerUnit,
            lastUpdated: null,
            usingCachedRates: true,
          ),
        );
        return;
      }

      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final rates = <String, double>{
        for (final entry in decoded.entries)
          entry.key: (entry.value as num).toDouble(),
      };

      rates[baseCurrencyCode] = 1.0;

      state = AsyncValue.data(
        CurrencyRatesState(
          inrPerUnit: rates,
          lastUpdated: updatedAtMs == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(updatedAtMs),
          usingCachedRates: true,
        ),
      );
    } catch (_) {
      state = AsyncValue.data(
        CurrencyRatesState(
          inrPerUnit: defaultInrPerUnit,
          lastUpdated: null,
          usingCachedRates: true,
        ),
      );
    }
  }

  Future<void> refreshRates() async {
    try {
      final symbols = List<String>.from(ref.read(supportedCurrenciesProvider))
        ..remove(baseCurrencyCode);

      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          responseType: ResponseType.json,
        ),
      );

      final response = await dio.get(
        'https://api.frankfurter.app/latest',
        queryParameters: {'from': baseCurrencyCode, 'to': symbols.join(',')},
      );

      final data = response.data as Map<String, dynamic>;
      final ratesFromInr = (data['rates'] as Map<String, dynamic>?) ?? {};

      final inrPerUnit = <String, double>{baseCurrencyCode: 1.0};
      for (final entry in ratesFromInr.entries) {
        final fromInr = (entry.value as num).toDouble();
        if (fromInr > 0) {
          inrPerUnit[entry.key] = 1 / fromInr;
        }
      }

      for (final code in ref.read(supportedCurrenciesProvider)) {
        inrPerUnit.putIfAbsent(code, () => defaultInrPerUnit[code] ?? 1.0);
      }

      final now = DateTime.now();
      state = AsyncValue.data(
        CurrencyRatesState(
          inrPerUnit: inrPerUnit,
          lastUpdated: now,
          usingCachedRates: false,
        ),
      );

      final prefs = await ref.read(sharedPreferencesProvider.future);
      await prefs.setString(_ratesCacheKey, jsonEncode(inrPerUnit));
      await prefs.setInt(_ratesUpdatedAtKey, now.millisecondsSinceEpoch);
    } catch (_) {
      if (state.valueOrNull == null) {
        state = AsyncValue.data(
          CurrencyRatesState(
            inrPerUnit: defaultInrPerUnit,
            lastUpdated: null,
            usingCachedRates: true,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}

final currencyProvider =
    StateNotifierProvider<CurrencyNotifier, AsyncValue<String>>((ref) {
      return CurrencyNotifier(ref);
    });

final currencyRatesProvider =
    StateNotifierProvider<
      CurrencyRatesNotifier,
      AsyncValue<CurrencyRatesState>
    >((ref) {
      return CurrencyRatesNotifier(ref);
    });
