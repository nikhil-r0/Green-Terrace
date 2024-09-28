import 'package:flutter/material.dart';
import 'package:green_terrace/models/enter_terrace_size.dart'; // Import the updated TerraceSizeInput widget
import 'package:green_terrace/services/firestore.dart'; // Firestore service

class Home extends StatelessWidget {
  Home({super.key});

  final Firestore firestore = Firestore(); // Firestore instance

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Terrace Size Input')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: TerraceSizeInput(
            onDataEntered: (double size, double sunlightHours, double latitude, double longitude, double budget, List<String> types) async {
              try {
                // Save the data to Firestore
                await firestore.addTerraceData(
                  size: size,
                  sunlightHours: sunlightHours,
                  latitude: latitude,
                  longitude: longitude,
                  budget: budget,
                  types: types,
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Data saved successfully!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error saving data: $e')),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
