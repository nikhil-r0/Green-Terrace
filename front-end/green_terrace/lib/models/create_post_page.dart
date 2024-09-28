import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:green_terrace/services/firestore.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  _CreatePostPageState createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final quill.QuillController _controller = quill.QuillController.basic();
  final TextEditingController _titleController = TextEditingController();
  final Firestore _firestoreService = Firestore();

  void _createPost() async {
    if (_titleController.text.isNotEmpty) {
      final String postContent = _controller.document.toPlainText();
      await _firestoreService.addCommunityPost(_titleController.text, postContent);
      Navigator.of(context).pop(); // Go back to the CommunityPage
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Post'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _createPost,
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
                  scrollable: true, // Editor can be scrolled
                  autoFocus: true,  // Automatically focus the editor
                  expands: true,    // Expand the editor to fill available space
                  padding: EdgeInsets.all(10), // Padding inside the editor
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
