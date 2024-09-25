import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class TerraceSizeInput extends StatefulWidget {
  final Function(double, double, double, double) onDataEntered; // Callback to pass the data back to parent

  const TerraceSizeInput({required this.onDataEntered, super.key});

  @override
  _TerraceSizeInputState createState() => _TerraceSizeInputState();
}

class _TerraceSizeInputState extends State<TerraceSizeInput> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _sizeController = TextEditingController();
  String? _selectedSunlightHours;
  double? _latitude;
  double? _longitude;
  bool _isFetchingLocation = false; // Loading state for fetching location
  bool _isSubmitting = false; // Loading state for submitting data
  String? _output; // Variable to store API output

  @override
  void dispose() {
    _sizeController.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    setState(() {
      _isFetchingLocation = true; // Show loading indicator
    });
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // If location services are disabled, show a dialog prompting the user to enable it
        _showLocationServiceDialog();
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied.';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied.';
      }

      // Get the current position
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error getting location: $e'),
      ));
    } finally {
      setState(() {
        _isFetchingLocation = false; // Hide loading indicator
      });
    }
  }

  // Function to show dialog if location services are disabled
  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enable Location Services'),
          content: Text('Location services are disabled. Please enable them in settings.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate() || _latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please complete all fields and obtain location.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true; // Show loading indicator during submission
    });

    double terraceSize = double.parse(_sizeController.text);
    double sunlightHours = double.parse(_selectedSunlightHours!);

    // Send the data to the parent widget via callback
    widget.onDataEntered(terraceSize, sunlightHours, _latitude!, _longitude!);

    // Prepare the data for the HTTP POST request
    Map<String, dynamic> requestData = {
      'latitude': _latitude,
      'longitude': _longitude,
      'sunlight': sunlightHours,
      'area': terraceSize,
    };

    try {
      // Send the HTTP POST request
      var url = Uri.parse('http://192.168.45.89:5000/predict_crops');
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        // Parse the response data
        var responseData = jsonDecode(response.body);
        setState(() {
          // var _predicted_crops;
          // for(var plant in responseData['recommended_crops']){
          //   _predicted_crops += '${plant}\n';
          // } 
          _output = 'Crops Predicted: ${responseData['recommended_crops']}\n'
              'Total Savings: ${responseData['total_savings']}\n';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting data: $e')),
      );
    } finally {
      setState(() {
        _isSubmitting = false; // Hide loading indicator after submission
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        children: [
          // Terrace Size Input
          TextFormField(
            controller: _sizeController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Terrace Size (in sq meters)',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a terrace size';
              }
              final size = double.tryParse(value);
              if (size == null || size <= 0) {
                return 'Please enter a valid number';
              }
              return null;
            },
          ),
          SizedBox(height: 20),

          // Dropdown for sunlight hours
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Average Sunlight Hours',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: '4', child: Text('4 Hours')),
              DropdownMenuItem(value: '6', child: Text('6 Hours')),
              DropdownMenuItem(value: '8', child: Text('8 Hours')),
              DropdownMenuItem(value: '10', child: Text('10+ Hours')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedSunlightHours = value;
              });
            },
            validator: (value) {
              if (value == null) {
                return 'Please select sunlight hours';
              }
              return null;
            },
          ),
          SizedBox(height: 20),

          // Button to get location
          ElevatedButton(
            onPressed: _isFetchingLocation
                ? null // Disable button while fetching location
                : () async {
                    await _getLocation();
                    if (_latitude != null && _longitude != null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            'Location obtained: (${_latitude!.toStringAsFixed(2)}, ${_longitude!.toStringAsFixed(2)})'),
                      ));
                    }
                  },
            child: _isFetchingLocation
                ? CircularProgressIndicator(color: Colors.white)
                : Text("Get Current Location"),
          ),
          SizedBox(height: 20),

          // Submit Button
          ElevatedButton(
            onPressed: _isSubmitting
                ? null // Disable button while submitting data
                : _submitData,
            child: _isSubmitting
                ? CircularProgressIndicator(color: Colors.white)
                : Text("Submit"),
          ),

          // Output Display
          if (_output != null) ...[
            SizedBox(height: 20),
            Text(
              _output!,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }
}
