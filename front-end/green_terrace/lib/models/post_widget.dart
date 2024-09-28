import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_post_page.dart';
import 'package:green_terrace/services/firestore.dart';

class PostWidget extends StatelessWidget {
  final QueryDocumentSnapshot post;
  final bool isCurrentUser;
  final Firestore _firestoreService = Firestore();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  PostWidget({super.key, required this.post, required this.isCurrentUser});

  @override
  Widget build(BuildContext context) {
    final List likedBy = post['likedBy'] ?? [];
    final currentUserId = _auth.currentUser?.uid;
    final bool hasLiked = likedBy.contains(currentUserId);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(post['title']),
            subtitle: Text(post['description']), // This can be formatted using rich text
            trailing: isCurrentUser
                ? IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => EditPostPage(post: post)));
                    },
                  )
                : null,
          ),
          Row(
            children: [
              // Like Button with Icon and Number of Likes
              IconButton(
                icon: Icon(hasLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined),
                color: hasLiked ? Colors.blue : null, // Color when liked
                onPressed: () {
                  _toggleLike(post.id, likedBy, post['likes']);
                },
              ),
              Text('${post['likes'] ?? 0}'), // Show the number of likes

              // Comment Button with Icon
              IconButton(
                icon: Icon(Icons.comment),
                onPressed: () {
                  _showComments(context, post.id);
                },
              ),
              Text('Comments'), // You can dynamically display comment count if needed
            ],
          ),
        ],
      ),
    );
  }

  // Function to handle like toggling
  void _toggleLike(String postId, List likedBy, int currentLikes) async {
    await _firestoreService.toggleLike(postId, likedBy, currentLikes);
  }

  // Function to show comments and comment input
  void _showComments(BuildContext context, String postId) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          children: [
            Expanded(
              child: _buildCommentsList(postId), // Display list of comments
            ),
            _buildCommentInput(postId, context), // Comment input at the bottom
            SizedBox(
              height: MediaQuery.of(context).viewInsets.bottom,
            )
          ],
        );
      },
    );
  }

  // Build the list of comments
  Widget _buildCommentsList(String postId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getComments(postId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final comments = snapshot.data!.docs;
        if (comments.isEmpty) {
          return Center(child: Text('No comments yet.'));
        }

        return ListView.builder(
          itemCount: comments.length,
          itemBuilder: (context, index) {
            final comment = comments[index];
            return ListTile(
              title: Text(comment['authorName']),
              subtitle: Text(comment['commentText']),
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: Colors.grey,
                  width: 1.0,
                )
              ),
              // trailing: Text(
              //   (comment['createdAt'] as Timestamp).toDate().toString(), // Show comment date
              //   style: TextStyle(fontSize: 12),
              // ),
            );
          },
        );
      },
    );
  }

  // Build the comment input field
  Widget _buildCommentInput(String postId , BuildContext context){
    final TextEditingController commentController = TextEditingController();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: commentController,
              decoration: InputDecoration(
                labelText: 'Add a comment...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () async {
              if (commentController.text.isNotEmpty) {
                await _firestoreService.addComment(postId, commentController.text);
                commentController.clear(); // Clear the input after submitting
              }
            },
          ),
        ],
      ),
    );
  }
}
