import 'package:equatable/equatable.dart';

/// Shared id + name + optional code for FK pickers (employee, project, …).
class NamedRef extends Equatable {
  const NamedRef({required this.id, required this.name, this.code});

  final int id;
  final String name;
  final String? code;

  String get label => (code == null || code!.isEmpty) ? name : '$code — $name';

  @override
  List<Object?> get props => [id, name, code];
}
