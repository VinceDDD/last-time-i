import 'package:flutter/material.dart';

import '../models/task_item.dart';
import '../repositories/task_repository.dart';
import '../services/task_service.dart';
import '../utils/date_formatter.dart';

/// Screen for editing an existing task: rename it, change the date,
/// or delete it (with confirmation).
class EditTaskScreen extends StatefulWidget {
  const EditTaskScreen({super.key, required this.task, this.repository});

  /// The task being edited.
  final TaskItem task;

  /// Allows tests to supply their own repository (and database).
  final TaskRepository? repository;

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TaskRepository _repository =
      widget.repository ?? TaskRepository();
  late final TaskService _service = TaskService(repository: _repository);

  /// The name field, pre-filled with the current name.
  late final TextEditingController _nameController =
      TextEditingController(text: widget.task.name);

  /// The selected date, starting from the current one.
  late DateTime _lastCompletedAt = widget.task.lastCompletedAt;

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

  /// Validates, saves changes, and closes the screen.
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return; // the form has already shown the error messages
    }
    final updated = await _service.updateTask(
      widget.task.copyWith(
        name: _nameController.text.trim(),
        lastCompletedAt: _lastCompletedAt,
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop(updated);
  }

  /// Asks for confirmation, then deletes the task and closes the screen.
  Future<void> _delete() async {
    // showDialog returns the value the dialog pops — true or false.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${widget.task.name}"?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _service.deleteTask(widget.task.id!);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Item')),
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
              const SizedBox(height: 8),
              TextButton(
                onPressed: _delete,
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('DELETE'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
