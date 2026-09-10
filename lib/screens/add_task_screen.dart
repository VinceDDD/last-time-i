import 'package:flutter/material.dart';

import '../models/task_item.dart';
import '../repositories/task_repository.dart';
import '../utils/date_formatter.dart';

/// Screen for adding a new task: a name plus the date it was last completed.
class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key, this.repository});

  /// Allows tests to supply their own repository (and database).
  /// The app itself leaves this null and uses the real repository.
  final TaskRepository? repository;

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  late final TaskRepository _repository =
      widget.repository ?? TaskRepository();

  /// The selected date. Defaults to today; the picker forbids the future.
  DateTime _lastCompletedAt = DateTime.now();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// Opens the date picker and stores the chosen date.
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _lastCompletedAt,
      firstDate: DateTime(2000),
      lastDate: now, // future dates are not allowed
      helpText: 'When did you last do it?',
    );
    if (picked != null) {
      setState(() => _lastCompletedAt = picked);
    }
  }

  /// Validates, saves to the database, and closes the screen.
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return; // the form has already shown the error messages
    }
    final task = TaskItem(
      name: _nameController.text.trim(),
      lastCompletedAt: _lastCompletedAt,
    );
    final saved = await _repository.insertTask(task);
    if (!mounted) return; // screen may have closed while awaiting
    Navigator.of(context).pop(saved);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Item')),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'What did you do?',
                  hintText: 'e.g. Change air filter',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name cannot be blank';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                title: const Text('When did you last do it?'),
                subtitle: Text(formatDate(_lastCompletedAt)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _save,
                child: const Text('SAVE'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
