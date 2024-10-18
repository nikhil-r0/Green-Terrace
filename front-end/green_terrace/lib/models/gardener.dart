import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Gardener extends StatefulWidget {
  @override
  _GardenerState createState() => _GardenerState();
}

class _GardenerState extends State<Gardener> {
  final TextEditingController _questionController = TextEditingController();
  String? _responseText;
  bool _isLoading = false;
  List<Map<String, String>> _chatMessages = [];

  Future<void> _sendQuestion() async {
    if (_questionController.text.isEmpty) {
      return;
    }

    setState(() {
      _chatMessages.add({"role": "user", "text": _questionController.text});
      _isLoading = true;
    });

    final apiUrl = Uri.parse('http://192.168.4.89:4000/chatbot'); // Flask server's API endpoint

    try {
      final response = await http.post(
        apiUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'question': _questionController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _chatMessages.add({"role": "bot", "text": data['answer'] ?? 'No answer available'});
        });
      } else {
        setState(() {
          _chatMessages.add({"role": "bot", "text": 'Error: ${response.statusCode}'});
        });
      }
    } catch (e) {
      setState(() {
        _chatMessages.add({"role": "bot", "text": 'Error sending request: $e'});
      });
    } finally {
      setState(() {
        _isLoading = false;
        _questionController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gardener'),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _chatMessages.length,
              itemBuilder: (context, index) {
                final message = _chatMessages[index];
                final isUserMessage = message['role'] == 'user';
                return Align(
                  alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    padding: EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: isUserMessage ? Colors.grey[900] : Colors.grey[700], // User message has a darker background
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                    child: Text(
                      message['text']!,
                      style: TextStyle(
                        color: Colors.white, // White text for both user and bot
                        fontSize: 16.0,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircularProgressIndicator(color: Colors.green),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _questionController,
                    decoration: InputDecoration(
                      labelText: 'Ask a question',
                      labelStyle: TextStyle(color: Colors.green),
                      filled: true,
                      fillColor: Colors.grey[900],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: Colors.green),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: Colors.green),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: Colors.green),
                      ),
                    ),
                    style: TextStyle(color: Colors.green),
                    cursorColor: Colors.green,
                  ),
                ),
                SizedBox(width: 8.0),
                ElevatedButton(
                  onPressed: _isLoading ? null : _sendQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    textStyle: TextStyle(
                      color: Colors.white,
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                    shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: Colors.black,
    );
  }
}
