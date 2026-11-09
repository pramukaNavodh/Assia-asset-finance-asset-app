//the skeleton of assets view

//libraries
import 'dart:math' as math;

//internal resource files
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_assets.dart';

//cat list
enum AssetCategory { furniture, digital, electrical, vehicle, other }

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

  /// Electrical and electronic devices need serial number + manufacturer.
  bool get isDevice =>
      this == AssetCategory.digital || this == AssetCategory.electrical;
}

enum DepreciationMethod { none, straightLine, decliningBalance }

extension DepreciationMethodLabel on DepreciationMethod {
  String get label => switch (this) {
    DepreciationMethod.none => 'No depreciation',
    DepreciationMethod.straightLine => 'Straight-line',
    DepreciationMethod.decliningBalance => 'Declining balance',
  };
}

/// Book value today for the chosen depreciation method (never below salvage).
double depreciatedValue({
  required double price,
  required DateTime obtained,
  required DepreciationMethod method,
  int? usefulLifeYears,
  double salvageValue = 0,
  DateTime? now,
}) {
  final life = usefulLifeYears ?? 0;
  if (method == DepreciationMethod.none || life <= 0) return price;

  final years = math.max(0.0, (now ?? DateTime.now()).difference(obtained).inDays / 365.25);
  final salvage = salvageValue.clamp(0.0, price).toDouble();
  final value = switch (method) {
    DepreciationMethod.straightLine => price - (price - salvage) / life * years,
    DepreciationMethod.decliningBalance =>
    price * math.pow(1 - math.min(2 / life, 0.9), years).toDouble(),
    DepreciationMethod.none => price,
  };
  return math.max(salvage, value);
}

class ServiceRecord {
  const ServiceRecord({required this.date, required this.description, this.cost = 0});

  final DateTime date;
  final String description;
  final double cost;

  Map<String, dynamic> toMap() =>
      {'date': Timestamp.fromDate(date), 'description': description, 'cost': cost};

  factory ServiceRecord.fromMap(Map<String, dynamic> map) => ServiceRecord(
    date: map['date'] is Timestamp ? (map['date'] as Timestamp).toDate() : DateTime.now(),
    description: (map['description'] as String?) ?? '',
    cost: (map['cost'] as num?)?.toDouble() ?? 0,
  );
}

class Asset {
  const Asset({
    required this.id,
    required this.title,
    required this.category,
    required this.price,
    required this.branchId,
    required this.dateObtained,
    this.description = '',
    this.latitude,
    this.longitude,
    this.depreciationMethod = DepreciationMethod.none,
    this.usefulLifeYears,
    this.salvageValue = 0,
    this.warrantyProvider,
    this.warrantyExpiry,
    this.warrantyNotes,
    this.serialNumber,
    this.manufacturer,
    this.additionalInfo,
    this.numberPlate,
    this.insuranceProvider,
    this.insurancePolicyNumber,
    this.insuranceExpiry,
    this.serviceRecords = const [],
    this.imageUrls = const [],
  });

  final String id;
  final String title;
  final String description;
  final AssetCategory category;
  final double price;
  final String branchId;
  final DateTime dateObtained;
  final double? latitude;
  final double? longitude;

  // Depreciation
  final DepreciationMethod depreciationMethod;
  final int? usefulLifeYears;
  final double salvageValue;

  // Warranty
  final String? warrantyProvider;
  final DateTime? warrantyExpiry;
  final String? warrantyNotes;

  // Electrical / electronic devices
  final String? serialNumber;
  final String? manufacturer;
  final String? additionalInfo;

  // Vehicles
  final String? numberPlate;
  final String? insuranceProvider;
  final String? insurancePolicyNumber;
  final DateTime? insuranceExpiry;
  final List<ServiceRecord> serviceRecords;

  final List<String> imageUrls;

  bool get hasLocation => latitude != null && longitude != null;

  double get currentValue => depreciatedValue(
    price: price,
    obtained: dateObtained,
    method: depreciationMethod,
    usefulLifeYears: usefulLifeYears,
    salvageValue: salvageValue,
  );

  /// Defensive parsing: a missing or wrong-typed field never crashes the app.
  factory Asset.fromMap(String id, Map<String, dynamic> map) {
    String? text(String key) {
      final v = (map[key] as String?)?.trim();
      return (v == null || v.isEmpty) ? null : v;
    }

    DateTime? date(String key) {
      final v = map[key];
      return v is Timestamp ? v.toDate() : null;
    }

    final location = map['location'];
    final records = map['serviceRecords'];
    final images = map['imageUrls'];

    return Asset(
      id: id,
      title: text('title') ?? 'Untitled asset',
      description: text('description') ?? '',
      category: AssetCategory.values.firstWhere(
            (c) => c.name == map['category'],
        orElse: () => AssetCategory.other,
      ),
      price: (map['price'] as num?)?.toDouble() ?? 0,
      branchId: (map['branchId'] as String?) ?? '',
      dateObtained: date('dateObtained') ?? DateTime.now(),
      latitude: location is GeoPoint ? location.latitude : null,
      longitude: location is GeoPoint ? location.longitude : null,
      depreciationMethod: DepreciationMethod.values.firstWhere(
            (m) => m.name == map['depreciationMethod'],
        orElse: () => DepreciationMethod.none,
      ),
      usefulLifeYears: (map['usefulLifeYears'] as num?)?.toInt(),
      salvageValue: (map['salvageValue'] as num?)?.toDouble() ?? 0,
      warrantyProvider: text('warrantyProvider'),
      warrantyExpiry: date('warrantyExpiry'),
      warrantyNotes: text('warrantyNotes'),
      serialNumber: text('serialNumber'),
      manufacturer: text('manufacturer'),
      additionalInfo: text('additionalInfo'),
      numberPlate: text('numberPlate'),
      insuranceProvider: text('insuranceProvider'),
      insurancePolicyNumber: text('insurancePolicyNumber'),
      insuranceExpiry: date('insuranceExpiry'),
      serviceRecords: records is List
          ? records.whereType<Map<String, dynamic>>().map(ServiceRecord.fromMap).toList()
          : const [],
      imageUrls: images is List ? images.whereType<String>().toList() : const [],
    );
  }

  /// Firestore document for a new asset.
  Map<String, dynamic> toMap({required String createdBy, required List<String> imageUrls}) => {
    'title': title,
    'description': description,
    'category': category.name,
    'price': price,
    'branchId': branchId,
    'dateObtained': Timestamp.fromDate(dateObtained),
    if (hasLocation) 'location': GeoPoint(latitude!, longitude!),
    'depreciationMethod': depreciationMethod.name,
    'usefulLifeYears': usefulLifeYears,
    'salvageValue': salvageValue,
    'warrantyProvider': warrantyProvider,
    'warrantyExpiry': warrantyExpiry == null ? null : Timestamp.fromDate(warrantyExpiry!),
    'warrantyNotes': warrantyNotes,
    'serialNumber': serialNumber,
    'manufacturer': manufacturer,
    'additionalInfo': additionalInfo,
    'numberPlate': numberPlate,
    'insuranceProvider': insuranceProvider,
    'insurancePolicyNumber': insurancePolicyNumber,
    'insuranceExpiry': insuranceExpiry == null ? null : Timestamp.fromDate(insuranceExpiry!),
    'serviceRecords': serviceRecords.map((r) => r.toMap()).toList(),
    'imageUrls': imageUrls,
    'createdBy': createdBy,
    'createdAt': FieldValue.serverTimestamp(),
  };
}