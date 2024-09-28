import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:green_terrace/services/firestore.dart';

class EditPostPage extends StatefulWidget {
  final QueryDocumentSnapshot post;
  EditPostPage({required this.post});

  @override
  _EditPostPageState createState() => _EditPostPageState();
}

class _EditPostPageState extends State<EditPostPage> {
  late quill.QuillController _controller;
  final TextEditingController _titleController = TextEditingController();
  final Firestore _firestoreService = Firestore();

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.post['title'];
    _controller = quill.QuillController(
      document: quill.Document()..insert(0, widget.post['description']),
      selection: TextSelection.collapsed(offset: 0),
    );
  }

  void _updatePost() async {
    if (_titleController.text.isNotEmpty) {
      final String updatedContent = _controller.document.toPlainText();
      await _firestoreService.updatePost(widget.post.id, {
        'title': _titleController.text,
        'description': updatedContent,
      });
      Navigator.of(context).pop(); // Go back to the CommunityPage
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Post'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _updatePost,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Post Title'),
            ),
            Expanded(
              child: quill.QuillEditor(
                controller: _controller,
                scrollController: ScrollController(),
                configurations: const quill.QuillEditorConfigurations(
                  scrollable: true,
                  autoFocus: true,
                  expands: true,   // Expands to fill available space
                  padding: EdgeInsets.all(10),
                ),
                focusNode: FocusNode(),
              ),
            ),
            quill.QuillToolbar.simple(
              controller: _controller,
              configurations: quill.QuillSimpleToolbarConfigurations(
                multiRowsDisplay: false
              )
              ),

          ],
        ),
      ),
    );
  }
}
