import 'package:flutter/material.dart';
import 'package:green_terrace/models/enter_terrace_size.dart'; // Import TerraceSizeInput widget
import 'package:green_terrace/services/firestore.dart'; // Import Firestore service

class Home extends StatelessWidget {
  Home({super.key});

  final Firestore firestore = Firestore(); // Firestore instance

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Terrace Size Input')),  // Optional: Add an app bar
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: TerraceSizeInput(
            onSizeEntered: (double size) async {
              try {
                // Attempt to save the terrace size to Firestore
                await firestore.addTerraceSize(size);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Terrace size of $size sq meters saved!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error saving terrace size: $e')),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
