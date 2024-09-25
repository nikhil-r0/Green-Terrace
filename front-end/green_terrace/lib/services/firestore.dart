import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Firestore {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addTerraceData(double size, double sunlightHours, double latitude, double longitude) async {
    final user = _auth.currentUser;
    if (user != null) {
      String uid = user.uid;
      CollectionReference users = _firestore.collection('users');
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

    // Add a new vegetable to the market (for sale or barter)
  Future<void> addVegetableToMarket(String vegetable, int quantity, double price, bool isBarter, bool isForSale) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('market').add({
        'vegetable': vegetable,
        'quantity': quantity,
        'price': price,
        'sellerId': user.uid,
        'isBarter': isBarter,
        'isForSale': isForSale,
      });
    }
  }

  // Fetch all available vegetables for the market
  Stream<QuerySnapshot> getMarketItems() {
    return _firestore.collection('market').snapshots();
  }

  // Add a community post
  Future<void> addCommunityPost(String title, String description) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('community').add({
        'title': title,
        'description': description,
        'authorId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Fetch all community posts
  Stream<QuerySnapshot> getCommunityPosts() {
    return _firestore.collection('community').orderBy('createdAt', descending: true).snapshots();
  }
}
