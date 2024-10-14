import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class TerraceSizeInput extends StatefulWidget {
  final Function(double, double, double, double, double, List<String>) onDataEntered; // Callback to pass data back to parent

  const TerraceSizeInput({required this.onDataEntered, super.key});

  @override
  _TerraceSizeInputState createState() => _TerraceSizeInputState();
}

class _TerraceSizeInputState extends State<TerraceSizeInput> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _sizeController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();

  String? _selectedMaximizeOption;
  List<String> _selectedTypes = [];
  double? _latitude;
  double? _longitude;
  bool _isFetchingLocation = false;
  bool _isSubmitting = false;
  List<Map<String, dynamic>>? _recommendedPlants;
  String? _outputMessage;

  @override
  void dispose() {
    _sizeController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  // Simulate available types for selection
  final List<String> _allTypes = ['Vegetables', 'Fruits', 'Legumes', 'Flowers', 'Medicinal'];

  Future<void> _getLocation() async {
    setState(() {
      _isFetchingLocation = true;
    });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationServiceDialog();
        return;
      }

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
        _isFetchingLocation = false;
      });
    }
  }

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
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showMultiSelectDialog() async {
    final List<String> selectedValues = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return MultiSelectDialog(
          allItems: _allTypes,
          initiallySelectedItems: _selectedTypes,
        );
      },
    );

    setState(() {
      _selectedTypes = selectedValues;
    });
    }

  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate() || _latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please complete all fields and obtain location.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _recommendedPlants = null;
      _outputMessage = null;
    });

    double terraceSize = double.parse(_sizeController.text);
    double budget = double.parse(_budgetController.text);

    // Determine weights based on the selected maximize option
    double weightSavings = _selectedMaximizeOption == 'Savings' ? 0.6 : 0.4;
    double weightCarbonAbsorption = _selectedMaximizeOption == 'Carbon Absorption' ? 0.6 : 0.4;

    // Prepare the request data
    Map<String, dynamic> requestData = {
      'terrace_size': terraceSize,
      'budget': budget,
      'latitude': _latitude,
      'longitude': _longitude,
      'savings_weight': weightSavings,
      'weight_carbon_absorption': weightCarbonAbsorption,
      'types': _selectedTypes,
    };

    try {
      var url = Uri.parse('http://192.168.1.101:4000/recommend_crops');
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);

        if (responseData.containsKey('error')) {
          setState(() {
            _outputMessage = responseData['error'];
          });
        } else if (responseData['recommended_plants'].isEmpty) {
          setState(() {
            _outputMessage = "No plants were recommended based on your criteria.";
          });
        } else {
          setState(() {
            _recommendedPlants = List<Map<String, dynamic>>.from(responseData['recommended_plants']);
            _outputMessage = null;
          });
        }
      } else {
        setState(() {
          _outputMessage = 'Error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _outputMessage = 'Error submitting data: $e';
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
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
          TextFormField(
            controller: _budgetController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Budget',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a budget';
              }
              final budget = double.tryParse(value);
              if (budget == null || budget <= 0) {
                return 'Please enter a valid number';
              }
              return null;
            },
          ),
          SizedBox(height: 20),

          // Dropdown for Maximize Option
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'What do you want to maximize?',
              border: OutlineInputBorder(),
            ),
            dropdownColor: Colors.grey[900],
            style: TextStyle(
              color: Colors.green,
            ),
            items: const [
              DropdownMenuItem(
              value: 'Savings', 
              child: Text('Savings')
            ),
              DropdownMenuItem(
                value: 'Carbon Absorption', 
                child: Text('Carbon Absorption')
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedMaximizeOption = value;
              });
            },
            validator: (value) {
              if (value == null) {
                return 'Please select an option';
              }
              return null;
            },
          ),
          SizedBox(height: 20),

          // Custom Button for selecting multiple crop types
          ListTile(
            title: Text("Select Crop Types"),
            subtitle: Text(_selectedTypes.isNotEmpty ? _selectedTypes.join(", ") : "None selected"),
            trailing: Icon(Icons.arrow_drop_down),
            onTap: _showMultiSelectDialog,
          ),
          SizedBox(height: 20),

          SizedBox(height: 20),

          // Button to get location
          ElevatedButton(
            onPressed: _isFetchingLocation
                ? null
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
            onPressed: _isSubmitting ? null : _submitData,
            child: _isSubmitting
                ? CircularProgressIndicator(color: Colors.white)
                : Text("Submit"),
          ),

          SizedBox(height: 20),

          // Display the output
          _buildOutput(),
        ],
      ),
    );
  }

  Widget _buildOutput() {
    if (_outputMessage != null) {
      return Text(
        _outputMessage!,
        style: TextStyle(color: Colors.red, fontSize: 16),
      );
    }

    if (_recommendedPlants != null && _recommendedPlants!.isNotEmpty) {
      return Column(
        children: _recommendedPlants!.map((plant) {
          return Card(
            color: Colors.grey[900],
            margin: EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plant['label'],
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text('Savings: ${plant['savings'].toStringAsFixed(2)}'),
                  Text(
                      'Carbon Absorption: ${plant['carbon_absorption']} kg'),
                  Text('Growing Price: ${plant['growing_price'].toStringAsFixed(2)}'),
                ],
              ),
            ),
          );
        }).toList(),
      );
    }

    return SizedBox.shrink(); // Return an empty widget if nothing to display
  }
}

class _MultiSelectDialogState extends State<MultiSelectDialog> {
  late List<String> _selectedItems;

  @override
  void initState() {
    super.initState();
    _selectedItems = widget.initiallySelectedItems.toList();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Select Crop Types",style: TextStyle(color: Colors.green),),
      content: SingleChildScrollView(
        child: ListBody(
          children: widget.allItems.map((type) {
            return CheckboxListTile(
              title: Text(type,style: TextStyle(color: Colors.green),),
              value: _selectedItems.contains(type),
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    _selectedItems.add(type);
                  } else {
                    _selectedItems.remove(type);
                  }
                });
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(_selectedItems);
          },
          child: Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(_selectedItems);
          },
          child: Text("OK"),
        ),
      ],
    );
  }
}

class MultiSelectDialog extends StatefulWidget {
  final List<String> allItems;
  final List<String> initiallySelectedItems;

  const MultiSelectDialog({
    required this.allItems,
    required this.initiallySelectedItems,
    super.key,
  });

  @override
  _MultiSelectDialogState createState() => _MultiSelectDialogState();
}
