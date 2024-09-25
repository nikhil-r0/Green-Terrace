import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:green_terrace/services/firestore.dart';

class CommunityPage extends StatelessWidget {
  final Firestore _firestoreService = Firestore();

  // Function to display community posts
  Widget _buildCommunityPosts() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getCommunityPosts(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        final posts = snapshot.data!.docs;
        if (posts.isEmpty) {
          return Center(child: Text('No tips or guides available.'));
        }
        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return Card(
              child: ListTile(
                title: Text(post['title']),
                subtitle: Text(post['description']),
              ),
            );
          },
        );
      },
    );
  }

  // Function to open a dialog for posting a new community guide
  void _openPostDialog(BuildContext context) {
    final TextEditingController _titleController = TextEditingController();
    final TextEditingController _descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Post Guide or Tip'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(labelText: 'Description'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (_titleController.text.isNotEmpty && _descriptionController.text.isNotEmpty) {
                  await _firestoreService.addCommunityPost(
                    _titleController.text,
                    _descriptionController.text,
                  );
                  Navigator.of(context).pop();
                }
              },
              child: Text('Post'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Community')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _buildCommunityPosts(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openPostDialog(context),
        child: Icon(Icons.add),
        tooltip: 'Post New Tip',
      ),
    );
  }
}
