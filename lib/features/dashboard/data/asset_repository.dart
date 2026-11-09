//the streamline for displaying asset collection data

//libraries
import 'package:cloud_firestore/cloud_firestore.dart';

//internal asset files
import '../models/asset_model.dart';
import '../models/branch_model.dart';

abstract class AssetRepository {
  Stream<List<Asset>> watchAssets();
}

//firestore connection
class FirestoreAssetRepository implements AssetRepository {
  FirestoreAssetRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Stream<List<Asset>> watchAssets() => _db
      .collection('assets')
      .snapshots()
      .map((s) => s.docs.map((d) => Asset.fromMap(d.id, d.data())).toList());
}

//sample values
class DemoAssetRepository implements AssetRepository {
  @override
  Stream<List<Asset>> watchAssets() => Stream.fromFuture(
    // delay to see the loading skeletons
    Future.delayed(const Duration(milliseconds: 1400), _build),
  );

  List<Asset> _build() {
    final now = DateTime.now();
    var counter = 0;

    Asset a(String title, AssetCategory category, double price,
        String branchId, int daysAgo,
        {double dLat = 0, double dLng = 0}) {
      final branch = Branches.byId(branchId)!;
      counter++;
      return Asset(
        id: 'demo-$counter',
        title: title,
        category: category,
        price: price,
        branchId: branchId,
        dateObtained: now.subtract(Duration(days: daysAgo)),
        latitude: branch.latitude + dLat,
        longitude: branch.longitude + dLng,
      );
    }

    const f = AssetCategory.furniture;
    const d = AssetCategory.digital;
    const e = AssetCategory.electrical;
    const v = AssetCategory.vehicle;
    //sample data
    return [
      a('Executive Desk', f, 145000, 'colombo', 420, dLat: 0.002, dLng: -0.003),
      a('Conference Table (12 seats)', f, 385000, 'colombo', 300, dLat: -0.002, dLng: 0.002),
      a('Dell Latitude 5440 Laptop', d, 389000, 'colombo', 25, dLat: 0.001, dLng: 0.004),
      a('HP LaserJet Pro Printer', d, 128000, 'colombo', 120, dLat: -0.003, dLng: -0.001),
      a('Toyota Hilux Double Cab', v, 14800000, 'colombo', 540, dLat: 0.012, dLng: 0.010),
      a('Daikin Split AC 18000 BTU', e, 215000, 'colombo', 6, dLat: 0.003, dLng: -0.002),
      a('Ergonomic Chairs (x10)', f, 320000, 'kandy', 90, dLat: 0.002, dLng: 0.001),
      a('Dell OptiPlex Desktop', d, 245000, 'kandy', 14, dLat: -0.001, dLng: 0.003),
      a('Toyota Axio', v, 7900000, 'kandy', 700, dLat: -0.010, dLng: 0.008),
      a('Generator 20kVA', e, 1250000, 'kandy', 365, dLat: 0.004, dLng: -0.003),
      a('Reception Counter', f, 210000, 'galle', 200, dLat: 0.001, dLng: 0.002),
      a('Lenovo ThinkPad E14', d, 298000, 'galle', 40, dLat: -0.002, dLng: -0.001),
      a('Honda Dio Scooter', v, 520000, 'galle', 260, dLat: 0.006, dLng: -0.008),
      a('Network Switch 48-port', d, 165000, 'jaffna', 8, dLat: 0.001, dLng: 0.001),
      a('Suzuki Wagon R', v, 5400000, 'jaffna', 480, dLat: 0.010, dLng: -0.006),
      a('Steel Cabinets (x6)', f, 168000, 'kurunegala', 150, dLat: 0.002, dLng: -0.002),
      a('CCTV System (8 cameras)', e, 275000, 'matara', 75, dLat: -0.001, dLng: 0.002),
      a('Fireproof Safe', AssetCategory.other, 350000, 'negombo', 600, dLat: 0.001, dLng: -0.002),
      a('Canon Document Scanner', d, 96000, 'anuradhapura', 4, dLat: 0.002, dLng: 0.001),
      a('UPS 3kVA', e, 185000, 'anuradhapura', 30, dLat: -0.002, dLng: -0.001),
    ];
  }
}