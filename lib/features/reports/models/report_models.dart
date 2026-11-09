//model arch for report

//libraries
import 'package:flutter/material.dart';

//internal resource files
import '../../dashboard/models/asset_model.dart';

enum ReportType { register, valuation, expiries }

extension ReportTypeInfo on ReportType {
  String get label => switch (this) {
    ReportType.register => 'Asset register',
    ReportType.valuation => 'Valuation',
    ReportType.expiries => 'Expiries',
  };

  String get description => switch (this) {
    ReportType.register => 'Every asset with branch, date, price and current value',
    ReportType.valuation => 'Purchase vs current value, grouped by category',
    ReportType.expiries => 'Warranties and vehicle insurance due soon or expired',
  };

  IconData get icon => switch (this) {
    ReportType.register => Icons.list_alt_rounded,
    ReportType.valuation => Icons.trending_down_rounded,
    ReportType.expiries => Icons.event_busy_outlined,
  };
}

class ExpiryItem {
  const ExpiryItem(this.asset, this.kind, this.date);

  final Asset asset;
  final String kind; // 'Warranty' or 'Insurance'
  final DateTime date;

  int get daysLeft => date.difference(DateTime.now()).inDays;
}

// Warranties/insurance due within [withinDays] (and, optionally, expired no
//more than [pastDays] ago), soonest first.
List<ExpiryItem> findExpiries(Iterable<Asset> assets,
    {required int withinDays, int? pastDays}) {
  final items = <ExpiryItem>[];

  void add(Asset a, String kind, DateTime? date) {
    if (date == null) return;
    final item = ExpiryItem(a, kind, date);
    if (item.daysLeft > withinDays) return;
    if (pastDays != null && item.daysLeft < -pastDays) return;
    items.add(item);
  }

  for (final a in assets) {
    add(a, 'Warranty', a.warrantyExpiry);
    add(a, 'Insurance', a.insuranceExpiry);
  }
  items.sort((a, b) => a.date.compareTo(b.date));
  return items;
}

class CategoryValuation {
  const CategoryValuation(this.category, this.count, this.purchase, this.current);

  final AssetCategory category;
  final int count;
  final double purchase;
  final double current;

  double get depreciation => purchase - current;
  double get remainingPercent => purchase <= 0 ? 100 : current / purchase * 100;
}

// Assets (after filters) plus everything the report screens need.
class ReportData {
  ReportData._(this.assets, this.expiries);

  final List<Asset> assets;
  final List<ExpiryItem> expiries;

  factory ReportData.build(
      List<Asset> all, {
        String? branchId,
        AssetCategory? category,
        DateTimeRange? range,
      }) {
    final filtered = all.where((a) {
      if (branchId != null && a.branchId != branchId) return false;
      if (category != null && a.category != category) return false;
      if (range != null) {
        if (a.dateObtained.isBefore(range.start)) return false;
        if (!a.dateObtained.isBefore(range.end.add(const Duration(days: 1)))) return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => b.dateObtained.compareTo(a.dateObtained));

    return ReportData._(filtered, findExpiries(filtered, withinDays: 90));
  }

  double get totalPurchase => assets.fold<double>(0, (s, a) => s + a.price);
  double get totalCurrent => assets.fold<double>(0, (s, a) => s + a.currentValue);
  double get totalDepreciation => totalPurchase - totalCurrent;

  Map<AssetCategory, int> get categoryCounts {
    final counts = <AssetCategory, int>{};
    for (final c in AssetCategory.values) {
      final n = assets.where((a) => a.category == c).length;
      if (n > 0) counts[c] = n;
    }
    return counts;
  }

  List<CategoryValuation> get valuation {
    final list = <CategoryValuation>[];
    for (final c in AssetCategory.values) {
      final items = assets.where((a) => a.category == c).toList();
      if (items.isEmpty) continue;
      list.add(CategoryValuation(
        c,
        items.length,
        items.fold<double>(0, (s, a) => s + a.price),
        items.fold<double>(0, (s, a) => s + a.currentValue),
      ));
    }
    return list;
  }
}