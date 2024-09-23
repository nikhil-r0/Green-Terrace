import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Firestore {
  final FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> addTerraceSize(double size) async {
    final user = auth.currentUser;

    if (user != null) {
      String uid = user.uid;
      CollectionReference users = firestore.collection('users');
      DocumentReference doc = users.doc(uid);

      await doc.set({
        'email': user.email,
        'terrace-size': size,
      }, SetOptions(merge: true));  // Merge to avoid overwriting other fields
    } else {
      throw Exception("No user is logged in.");
    }
  }
}
