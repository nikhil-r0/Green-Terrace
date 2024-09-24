import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

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

  @override
  void dispose() {
    _sizeController.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    // Check location permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // Get the current position
    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _latitude = position.latitude;
      _longitude = position.longitude;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
            onPressed: () async {
              try {
                await _getLocation();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                      'Location obtained: ($_latitude, $_longitude)'),
                ));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Error getting location: $e'),
                ));
              }
            },
            child: Text("Get Current Location"),
          ),
          SizedBox(height: 20),

          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate() &&
                  _latitude != null &&
                  _longitude != null) {
                // On successful validation and location, parse the double and send it back to parent
                double terraceSize = double.parse(_sizeController.text);
                double sunlightHours = double.parse(_selectedSunlightHours!);

                // Pass the data back to parent
                widget.onDataEntered(terraceSize, sunlightHours, _latitude!, _longitude!);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Terrace Size: $terraceSize sq meters, Sunlight Hours: $sunlightHours, Location: ($_latitude, $_longitude)')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Please complete all fields and obtain location.')),
                );
              }
            },
            child: Text("Submit"),
          ),
        ],
      ),
    );
  }
}
