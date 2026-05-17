class FarmerModel {
  final String uid;
  final String name;
  final String email;
  final String? farmName;
  final double? latitude;
  final double? longitude;
  final String? cropType;
  final DateTime? plantingDate;

  FarmerModel({
    required this.uid,
    required this.name,
    required this.email,
    this.farmName,
    this.latitude,
    this.longitude,
    this.cropType,
    this.plantingDate,
  });

  // تحويل البيانات إلى Map لحفظها في Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'farmName': farmName,
      'latitude': latitude,
      'longitude': longitude,
      'cropType': cropType,
      'plantingDate': plantingDate?.toIso8601String(),
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }
}
