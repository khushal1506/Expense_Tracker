
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/model/transaction_model.dart';

class ExportService {
  Future<void> exportTransactionsToCSV(List<Transaction> transactions) async {
    List<List<dynamic>> rows = [];
    rows.add([
      "ID",
      "Amount",
      "Type",
      "Category",
      "Date",
      "Notes",
      "Created/Updated"
    ]);

    for (var tx in transactions) {
      rows.add([
        tx.id,
        tx.amount,
        tx.type.name,
        tx.category,
        tx.date.toIso8601String().split('T')[0],
        tx.notes ?? '',
        tx.updatedAt.toIso8601String(),
      ]);
    }

    String csvData = const ListToCsvConverter().convert(rows);

    final directory = await getApplicationDocumentsDirectory();
    final path = "${directory.path}/finance_export_${DateTime.now().millisecondsSinceEpoch}.csv";
    final file = File(path);
    await file.writeAsString(csvData);

    await Share.shareXFiles([XFile(path)], text: 'Here is your transactions export.');
  }
}

final exportServiceProvider = Provider((ref) => ExportService());
