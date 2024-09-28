import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:green_terrace/services/firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'create_post_page.dart';
import 'post_widget.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  _CommunityPageState createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final Firestore _firestoreService = Firestore();
  String _searchTerm = '';

  // Function to display community posts
  Widget _buildCommunityPosts() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getCommunityPosts(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        final posts = snapshot.data!.docs;

        final filteredPosts = posts.where((post) {
          String postTitle = post['title'].toString().toLowerCase();
          return postTitle.contains(_searchTerm.toLowerCase());
        }).toList();

        if (filteredPosts.isEmpty) {
          return Center(child: Text('No posts found.'));
        }

        return ListView.builder(
          itemCount: filteredPosts.length,
          itemBuilder: (context, index) {
            final post = filteredPosts[index];
            final userId = FirebaseAuth.instance.currentUser?.uid;
            final isCurrentUser = post['authorId'] == userId;
            return PostWidget(post: post, isCurrentUser: isCurrentUser);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Community'),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Icon(Icons.search),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchTerm = value;
                });
              },
              decoration: InputDecoration(
                labelText: 'Search posts',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(child: _buildCommunityPosts()), // Scrollable posts
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => CreatePostPage()),
          );
        },
        tooltip: 'Create New Post',
        child: Icon(Icons.add),
      ),
    );
  }
}
