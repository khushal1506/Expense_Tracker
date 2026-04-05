import 'package:intl/intl.dart';

const String baseCurrencyCode = 'INR';

// Fallback FX rates relative to INR (INR required per 1 unit of target currency).
const Map<String, double> defaultInrPerUnit = {
  'INR': 1.0,
  'USD': 83.0,
  'EUR': 90.0,
  'GBP': 105.0,
  'JPY': 0.56,
  'AED': 22.6,
};

double _rateFor(String currencyCode, Map<String, double>? inrPerUnit) {
  final rates = inrPerUnit ?? defaultInrPerUnit;
  return rates[currencyCode] ?? 1.0;
}

double convertFromInr(
  double amountInInr,
  String toCurrencyCode, {
  Map<String, double>? inrPerUnit,
}) {
  final rate = _rateFor(toCurrencyCode, inrPerUnit);
  return amountInInr / rate;
}

double convertToInr(
  double amount,
  String fromCurrencyCode, {
  Map<String, double>? inrPerUnit,
}) {
  final rate = _rateFor(fromCurrencyCode, inrPerUnit);
  return amount * rate;
}

String formatCurrency(
  double amountInInr,
  String currencyCode, {
  Map<String, double>? inrPerUnit,
}) {
  final convertedAmount = convertFromInr(
    amountInInr,
    currencyCode,
    inrPerUnit: inrPerUnit,
  );
  try {
    return NumberFormat.simpleCurrency(
      name: currencyCode,
    ).format(convertedAmount);
  } catch (_) {
    return NumberFormat.simpleCurrency(name: 'INR').format(amountInInr);
  }
}

String currencySymbol(String currencyCode) {
  try {
    return NumberFormat.simpleCurrency(name: currencyCode).currencySymbol;
  } catch (_) {
    return NumberFormat.simpleCurrency(name: 'INR').currencySymbol;
  }
}
