import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_selectos/models/selectos_branch.dart';

class StoreSelectionController extends ChangeNotifier {
  StoreSelectionController._();

  static final StoreSelectionController instance = StoreSelectionController._();

  static const _selectedBranchIdKey = 'selected_branch_id';

  List<SelectosBranch> _branches = const [];
  SelectosBranch? _selectedBranch;

  List<SelectosBranch> get branches => _branches;
  SelectosBranch? get selectedBranch => _selectedBranch;
  String? get selectedBranchId => _selectedBranch?.id;

  Future<void> initialize() async {
    final raw = await rootBundle.loadString('assets/selectos_branches.json');
    final decoded = jsonDecode(raw) as List<dynamic>;
    _branches =
        decoded
            .whereType<Map<String, dynamic>>()
            .map(SelectosBranch.fromJson)
            .where((branch) => branch.id.isNotEmpty && branch.name.isNotEmpty)
            .toList(growable: false)
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );

    final preferences = await SharedPreferences.getInstance();
    final storedId = preferences.getString(_selectedBranchIdKey);
    _selectedBranch = _findBranch(storedId);
  }

  Future<void> selectBranch(SelectosBranch branch) async {
    if (_selectedBranch?.id == branch.id) return;
    _selectedBranch = branch;
    notifyListeners();

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_selectedBranchIdKey, branch.id);
  }

  SelectosBranch? _findBranch(String? id) {
    if (id == null) return null;
    for (final branch in _branches) {
      if (branch.id == id) return branch;
    }
    return null;
  }
}
