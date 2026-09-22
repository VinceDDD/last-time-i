import 'package:flutter/material.dart';

import '../repositories/task_repository.dart';
import '../services/task_service.dart';
import '../utils/date_formatter.dart';

/// Screen for adding a new task: a name, the date it was last completed,
/// and an optional target interval ("every N days").
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
  final _intervalController = TextEditingController();
  late final TaskRepository _repository = widget.repository ?? TaskRepository();
  late final TaskService _service = TaskService(repository: _repository);

  /// The selected date. Defaults to today; the picker forbids the future.
  DateTime _lastCompletedAt = DateTime.now();

  @override
  void dispose() {
    _nameController.dispose();
    _intervalController.dispose();
    super.dispose();
  }

  /// Reads the interval field: empty -> null, otherwise the number.
  int? _parseInterval(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return int.tryParse(trimmed);
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

  /// Validates, saves through the service, and closes the screen.
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return; // the form has already shown the error messages
    }
    final saved = await _service.addTask(
      _nameController.text,
      _lastCompletedAt,
      intervalDays: _parseInterval(_intervalController.text),
    );
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
                key: const Key('taskNameField'),
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'What did you do?',
                  hintText: 'e.g. Change air filter',
                ),
                validator: TaskService.validateName,
              ),
              const SizedBox(height: 8),
              ListTile(
                title: const Text('When did you last do it?'),
                subtitle: Text(formatDate(_lastCompletedAt)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('intervalField'),
                controller: _intervalController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Every N days (optional)',
                  hintText: 'e.g. 90',
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) {
                    return null;
                  }
                  final parsed = int.tryParse(text);
                  if (parsed == null) {
                    return 'Must be a whole number';
                  }
                  return TaskService.validateInterval(parsed);
                },
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: _save, child: const Text('SAVE')),
            ],
          ),
        ),
      ),
    );
  }
}
