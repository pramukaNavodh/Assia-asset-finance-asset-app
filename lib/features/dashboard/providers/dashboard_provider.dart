//dashboard data holder. So, dashboard run smooth, and thread managed

//libraries
import 'dart:async';
import 'package:flutter/foundation.dart';

//internal resource files
import '../data/asset_repository.dart';
import '../models/asset_model.dart';
import '../models/branch_model.dart';

enum DashboardStatus { loading, ready, error }

class BranchCount {
  const BranchCount(this.branch, this.count);

  final Branch branch;
  final int count;
}

class DashboardProvider extends ChangeNotifier {
  DashboardProvider(this._repository) {
    load();
  }

  final AssetRepository _repository;
  StreamSubscription<List<Asset>>? _subscription;

  DashboardStatus _status = DashboardStatus.loading;
  List<Asset> _all = const [];
  List<Asset> _scoped = const []; // after branch filter
  List<Asset> _results = const []; // after branch filter + search
  String? _selectedBranchId; // null = all branches
  String _query = '';

  DashboardStatus get status => _status;
  String? get selectedBranchId => _selectedBranchId;
  List<Asset> get scopedAssets => _scoped;
  List<Asset> get results => _results;
  bool get isSearching => _query.isNotEmpty;
  String get scopeLabel =>
      Branches.byId(_selectedBranchId)?.name ?? 'All branches';

  //stat section

  int get totalCount => _scoped.length;

  double get totalValue => _scoped.fold<double>(0, (sum, a) => sum + a.price);

  int get vehicleCount =>
      _scoped.where((a) => a.category == AssetCategory.vehicle).length;

  int get recentCount {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    return _scoped.where((a) => a.dateObtained.isAfter(cutoff)).length;
  }

  Map<AssetCategory, int> get categoryCounts {
    final counts = <AssetCategory, int>{};
    for (final category in AssetCategory.values) {
      final n = _scoped.where((a) => a.category == category).length;
      if (n > 0) counts[category] = n;
    }
    return counts;
  }

  // Per-branch totals across ALL assets (used when no branch is selected)
  List<BranchCount> get branchCounts {
    final list = <BranchCount>[];
    for (final branch in Branches.all) {
      final n = _all.where((a) => a.branchId == branch.id).length;
      if (n > 0) list.add(BranchCount(branch, n));
    }
    list.sort((a, b) => b.count.compareTo(a.count));
    return list;
  }

  // actions section

  Future<void> load() async {
    _status = DashboardStatus.loading;
    notifyListeners();

    await _subscription?.cancel();
    _subscription = _repository.watchAssets().listen(
          (assets) {
        _all = assets;
        _recompute();
        _status = DashboardStatus.ready;
        notifyListeners();
      },
      onError: (Object _) {
        _status = DashboardStatus.error;
        notifyListeners();
      },
    );
  }

  void selectBranch(String? branchId) {
    if (branchId == _selectedBranchId) return;
    _selectedBranchId = branchId;
    _recompute();
    notifyListeners();
  }

  void setQuery(String query) {
    final cleaned = query.trim().toLowerCase();
    if (cleaned == _query) return;
    _query = cleaned;
    _recompute();
    notifyListeners();
  }

  void _recompute() {
    _scoped = _selectedBranchId == null
        ? _all
        : _all.where((a) => a.branchId == _selectedBranchId).toList();

    final matches = _query.isEmpty
        ? List<Asset>.of(_scoped)
        : _scoped.where((a) {
      final branchName =
          Branches.byId(a.branchId)?.name.toLowerCase() ?? '';
      return a.title.toLowerCase().contains(_query) ||
          a.category.label.toLowerCase().contains(_query) ||
          branchName.contains(_query);
    }).toList();

    matches.sort((a, b) => b.dateObtained.compareTo(a.dateObtained));
    _results = matches;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}