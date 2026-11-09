//the skeleton of assets view

//libraries
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

//internal resource files
import '../../../core/constants/app_assets.dart';

//cat list
enum AssetCategory { furniture, digital, electrical, vehicle, other }

// Display info for each category (label, colour, icon).
extension AssetCategoryStyle on AssetCategory {
  String get label => switch (this) {
    AssetCategory.furniture => 'Furniture',
    AssetCategory.digital => 'Digital devices',
    AssetCategory.electrical => 'Electrical',
    AssetCategory.vehicle => 'Vehicles',
    AssetCategory.other => 'Other',
  };

  Color get color => switch (this) {
    AssetCategory.furniture => const Color(0xFFE08E45),
    AssetCategory.digital => const Color(0xFF3B82F6),
    AssetCategory.electrical => const Color(0xFF8B5CF6),
    AssetCategory.vehicle => const Color(0xFF10B981),
    AssetCategory.other => const Color(0xFF64748B),
  };

  IconData get fallbackIcon => switch (this) {
    AssetCategory.furniture => Icons.chair_alt_outlined,
    AssetCategory.digital => Icons.laptop_mac_outlined,
    AssetCategory.electrical => Icons.electrical_services_outlined,
    AssetCategory.vehicle => Icons.directions_car_outlined,
    AssetCategory.other => Icons.category_outlined,
  };

  String get iconPath => switch (this) {
    AssetCategory.furniture => AppAssets.catFurniture,
    AssetCategory.digital => AppAssets.catDigital,
    AssetCategory.electrical => AppAssets.catElectrical,
    AssetCategory.vehicle => AppAssets.catVehicle,
    AssetCategory.other => AppAssets.catOther,
  };
}

class Asset {
  const Asset({
    required this.id,
    required this.title,
    required this.category,
    required this.price,
    required this.branchId,
    required this.dateObtained,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String title;
  final AssetCategory category;
  final double price;
  final String branchId;
  final DateTime dateObtained;
  final double? latitude;
  final double? longitude;

  bool get hasLocation => latitude != null && longitude != null;

  // Defensive parsing: a missing or wrong-typed field never crashes the app.
  factory Asset.fromMap(String id, Map<String, dynamic> map) {
    final title = (map['title'] as String?)?.trim() ?? '';
    final location = map['location'];
    final obtained = map['dateObtained'];

    return Asset(
      id: id,
      title: title.isEmpty ? 'Untitled asset' : title,
      category: AssetCategory.values.firstWhere(
            (c) => c.name == map['category'],
        orElse: () => AssetCategory.other,
      ),
      price: (map['price'] as num?)?.toDouble() ?? 0,
      branchId: (map['branchId'] as String?) ?? '',
      dateObtained: obtained is Timestamp ? obtained.toDate() : DateTime.now(),
      latitude: location is GeoPoint ? location.latitude : null,
      longitude: location is GeoPoint ? location.longitude : null,
    );
  }
}