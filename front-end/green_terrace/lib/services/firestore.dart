import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Firestore {
  final FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> addTerraceData(double size, double sunlightHours, double latitude, double longitude) async {
    final user = auth.currentUser;

    if (user != null) {
      String uid = user.uid;
      CollectionReference users = firestore.collection('users');
      DocumentReference doc = users.doc(uid);

      await doc.set({
        'email': user.email,
        'terrace-size': size,
        'sunlight-hours': sunlightHours,
        'latitude': latitude.round(),
        'longitude': longitude.round(),
      }, SetOptions(merge: true));
    } else {
      throw Exception("No user is logged in.");
    }
  }
}
