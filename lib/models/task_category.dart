import 'package:flutter/material.dart';

/// The fixed set of categories a task can belong to.
///
/// A task without a category stores null and is shown under
/// "Uncategorized" in the grouped home list.
///
/// The enum keeps everything type-safe and in one place: the dropdown,
/// the database value and the home list all share this definition.
enum TaskCategory {
  home('Home', Icons.home_outlined),
  car('Car', Icons.directions_car_outlined),
  health('Health', Icons.favorite_outline),
  personal('Personal', Icons.person_outline),
  work('Work', Icons.work_outline),
  finances('Finances', Icons.account_balance_wallet_outlined),
  pets('Pets', Icons.pets_outlined),
  tech('Tech', Icons.devices_outlined);

  const TaskCategory(this.label, this.icon);

  /// Display name, e.g. "Home".
  final String label;

  /// Material icon shown in the dropdown and the section headers.
  final IconData icon;
}
