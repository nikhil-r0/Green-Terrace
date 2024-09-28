import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Firestore {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Function to add terrace data to Firestore
  Future<void> addTerraceData({
    required double size,
    required double sunlightHours,
    required double latitude,
    required double longitude,
    required double budget, // New field for budget
    required List<String> types, // Added to capture types of crops
  }) async {
    try {
      await _firestore.collection('terrace_data').add({
        'size': size,
        'sunlight_hours': sunlightHours,
        'latitude': latitude,
        'longitude': longitude,
        'budget': budget, // Add budget to Firestore
        'types': types, // Add selected types of crops
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error adding terrace data: $e');
    }
  }


  // Add a new vegetable to the market (for sale or barter)
  Future<void> addVegetableToMarket(String vegetable, double quantity, double price, bool isBarter, bool isForSale) async {
    final user = _auth.currentUser;
    
    if (user != null) {
      await _firestore.collection('market').add({
        'vegetable': vegetable,
        'quantity': quantity,
        'price': price,
        'sellerId': user.uid,
        'sellerName': user.displayName ?? "Unknown Seller",
        'isBarter': isBarter,
        'isForSale': isForSale,
        'location': 'Bengaluru', // Add location field
        'description': 'Sample Description', // Add description field
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Fetch all available vegetables for the market
  Stream<QuerySnapshot> getMarketItems() {
    return _firestore.collection('market').orderBy('createdAt', descending: true).snapshots();
  }

  // Fetch available crop types for dropdown from Firestore
  Future<List<String>> getCropTypes() async {
    QuerySnapshot query = await _firestore.collection('cropTypes').get();
    List<String> cropTypes = [];
    for (var doc in query.docs) {
      cropTypes.add(doc['name']); // Assuming crop name is stored as 'name'
    }
    return cropTypes;
  }

  // Fetch only the current user's posts
  Stream<QuerySnapshot> getUserMarketItems(String userId) {
    return _firestore.collection('market').where('sellerId', isEqualTo: userId).snapshots();
  }

  // Update a user's post
  Future<void> updateMarketItem(String docId, Map<String, dynamic> updatedData) async {
    await _firestore.collection('market').doc(docId).update(updatedData);
  }

  // Delete a user's post
  Future<void> deleteMarketItem(String docId) async {
    await _firestore.collection('market').doc(docId).delete();
  }
  // Add a community post
  Future<void> addCommunityPost(String title, String description) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('community').add({
        'title': title,
        'description': description,
        'authorId': user.uid,
        'likes': 0, // Initialize likes count
        'likedBy': [], // Track users who liked the post
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Update likes for a post, checking if the user has already liked it
  Future<void> toggleLike(String postId, List likedBy, int currentLikes) async {
    final user = _auth.currentUser;
    if (user != null) {
      final String userId = user.uid;

      if (likedBy.contains(userId)) {
        // User already liked this post, so unlike it
        await _firestore.collection('community').doc(postId).update({
          'likes': currentLikes - 1,
          'likedBy': FieldValue.arrayRemove([userId]), // Remove user ID from likedBy list
        });
      } else {
        // User hasn't liked the post, so like it
        await _firestore.collection('community').doc(postId).update({
          'likes': currentLikes + 1,
          'likedBy': FieldValue.arrayUnion([userId]), // Add user ID to likedBy list
        });
      }
    }
  }

  // Submit a comment to the post's comments sub-collection
  Future<void> addComment(String postId, String commentText) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('community').doc(postId).collection('comments').add({
        'commentText': commentText,
        'authorId': user.uid,
        'authorName': user.displayName ?? 'Anonymous',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Fetch comments for a post
  Stream<QuerySnapshot> getComments(String postId) {
    return _firestore
        .collection('community')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // FirestoreService update method
  Future<void> updatePost(String postId, Map<String, dynamic> updatedData) async {
    await _firestore.collection('community').doc(postId).update(updatedData);
  }

  // Fetch all community posts
  Stream<QuerySnapshot> getCommunityPosts() {
    return _firestore.collection('community').orderBy('createdAt', descending: true).snapshots();
  }
}
