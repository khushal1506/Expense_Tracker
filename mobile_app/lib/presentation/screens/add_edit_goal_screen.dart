import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/model/goal_model.dart';
import '../../providers/goal_provider.dart';

class AddEditGoalScreen extends ConsumerStatefulWidget {
  final Goal? initial;

  const AddEditGoalScreen({super.key, this.initial});

  @override
  ConsumerState<AddEditGoalScreen> createState() => _AddEditGoalScreenState();
}

class _AddEditGoalScreenState extends ConsumerState<AddEditGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  late DateTime _monthDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final goal = widget.initial;
    if (goal != null) {
      _nameController.text = goal.name;
      _targetController.text = goal.targetAmount.toStringAsFixed(2);
      final parts = goal.month.split('-');
      _monthDate = DateTime(int.parse(parts[0]), int.parse(parts[1]));
    } else {
      final now = DateTime.now();
      _monthDate = DateTime(now.year, now.month);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _monthDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      setState(() => _monthDate = DateTime(picked.year, picked.month));
    }
  }

  String get _monthLabel =>
      '${_monthDate.year}-${_monthDate.month.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);

    final existing = widget.initial;
    final goal = Goal(
      id: existing?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      targetAmount: double.parse(_targetController.text.trim()),
      month: _monthLabel,
      isSynced: false,
      isDeleted: false,
      updatedAt: DateTime.now(),
    );

    try {
      if (existing == null) {
        await ref.read(goalProvider.notifier).addGoal(goal);
      } else {
        await ref.read(goalProvider.notifier).updateGoal(goal);
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
      appBar: AppBar(title: Text(isEdit ? 'Edit Goal' : 'Add Goal')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                isEdit ? 'Refine your goal' : 'Create a new goal',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                'Set a focused monthly target and track momentum.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Goal Name',
                          prefixIcon: Icon(
                            Icons.flag_outlined,
                            color: scheme.primary,
                          ),
                        ),
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'Goal name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _targetController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Target Amount',
                          prefixIcon: Icon(
                            Icons.track_changes_outlined,
                            color: scheme.secondary,
                          ),
                        ),
                        validator: (value) {
                          final text = (value ?? '').trim();
                          if (text.isEmpty) {
                            return 'Target amount is required';
                          }
                          final parsed = double.tryParse(text);
                          if (parsed == null || parsed <= 0) {
                            return 'Enter a valid amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: _pickMonth,
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Month'),
                          child: Text(_monthLabel),
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
