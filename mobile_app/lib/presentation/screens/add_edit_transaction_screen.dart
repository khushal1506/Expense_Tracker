import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/model/transaction_model.dart';
import '../../providers/transaction_provider.dart';

class AddEditTransactionScreen extends ConsumerStatefulWidget {
  final Transaction? initial;

  const AddEditTransactionScreen({super.key, this.initial});

  @override
  ConsumerState<AddEditTransactionScreen> createState() =>
      _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState
    extends ConsumerState<AddEditTransactionScreen> {
  static const _categories = [
    'Food',
    'Transport',
    'Housing',
    'Health',
    'Entertainment',
    'Salary',
    'Other',
  ];

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  TransactionType _type = TransactionType.expense;
  String _category = _categories.first;
  DateTime _selectedDate = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final tx = widget.initial;
    if (tx != null) {
      _amountController.text = tx.amount.toStringAsFixed(2);
      _notesController.text = tx.notes ?? '';
      _type = tx.type;
      _category = tx.category;
      _selectedDate = tx.date;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);

    final amount = double.parse(_amountController.text.trim());
    final existing = widget.initial;

    final tx = Transaction(
      id: existing?.id ?? const Uuid().v4(),
      amount: amount,
      type: _type,
      category: _category,
      date: _selectedDate,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      isSynced: false,
      isDeleted: false,
      updatedAt: DateTime.now(),
    );

    try {
      if (existing == null) {
        await ref.read(transactionProvider.notifier).addTransaction(tx);
      } else {
        await ref.read(transactionProvider.notifier).updateTransaction(tx);
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Transaction' : 'Add Transaction'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                isEdit ? 'Update entry' : 'New entry',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                'Capture amount, category, and notes in seconds.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          prefixIcon: Icon(
                            Icons.payments_outlined,
                            color: scheme.primary,
                          ),
                        ),
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isEmpty) {
                            return 'Amount is required';
                          }
                          final parsed = double.tryParse(text);
                          if (parsed == null || parsed <= 0) {
                            return 'Enter a valid amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<TransactionType>(
                        segments: const [
                          ButtonSegment(
                            value: TransactionType.income,
                            label: Text('Income'),
                            icon: Icon(Icons.south_west_rounded),
                          ),
                          ButtonSegment(
                            value: TransactionType.expense,
                            label: Text('Expense'),
                            icon: Icon(Icons.north_east_rounded),
                          ),
                        ],
                        selected: {_type},
                        onSelectionChanged: (set) =>
                            setState(() => _type = set.first),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _category,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                        ),
                        items: _categories
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _category = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: _pickDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Date'),
                          child: Text(
                            '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _saving ? null : _submit,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  _saving ? 'Saving...' : (isEdit ? 'Update' : 'Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
