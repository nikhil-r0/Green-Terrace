import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:green_terrace/services/firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MarketPage extends StatefulWidget {
  @override
  _MarketPageState createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage> {
  final Firestore _firestoreService = Firestore();
  String _searchTerm = '';
  List<String> _cropTypes = [];
  String? _selectedCrop;

  @override
  void initState() {
    super.initState();
    _loadCropTypes();
  }

  // Fetch crop types from Firestore for dropdown
  void _loadCropTypes() async {
    List<String> cropTypes = await _firestoreService.getCropTypes();
    setState(() {
      _cropTypes = cropTypes;
    });
  }

  // Function to display the market items
  Widget _buildMarketItems() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getMarketItems(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        final items = snapshot.data!.docs;
        final filteredItems = items.where((item) {
          String vegName = item['vegetable'].toString().toLowerCase();
          return vegName.contains(_searchTerm.toLowerCase());
        }).toList();
        if (filteredItems.isEmpty) {
          return Center(child: Text('No items found.'));
        }
        return ListView.builder(
          itemCount: filteredItems.length,
          itemBuilder: (context, index) {
            final item = filteredItems[index];
            final sellerId = item['sellerId'];
            final isCurrentUser = sellerId == FirebaseAuth.instance.currentUser?.uid;
            return _buildMarketCard(item, isCurrentUser);
          },
        );
      },
    );
  }

  // Function to build each card with drop-down arrow for more info
  Widget _buildMarketCard(QueryDocumentSnapshot item, bool isCurrentUser) {
    return Card(
      child: ExpansionTile(
        title: Text('${item['vegetable']}'),
        subtitle: Text(item['isBarter'] ? 'Barter' : 'Price: ₹${item['price']} per kg'),
        trailing: Icon(Icons.arrow_drop_down),
        children: [
          ListTile(
            title: Text('Seller: ${item['sellerName']}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Location: ${item['location']}'),
                Text('Description: ${item['description']}'),
                Text('Quantity: ${item['quantity']} kg'),
              ],
            ),
          ),
          if (isCurrentUser) _buildEditButtons(item),
        ],
      ),
    );
  }

  // Function to build Edit and Delete buttons for current user's items
  Widget _buildEditButtons(QueryDocumentSnapshot item) {
    return OverflowBar(
      children: [
        ElevatedButton(
          onPressed: () => _openEditDialog(item),
          child: Text('Edit'),
        ),
        ElevatedButton(
          onPressed: () => _firestoreService.deleteMarketItem(item.id),
          child: Text('Delete'),
        ),
      ],
    );
  }

  // Function to open dialog to edit a post
  void _openEditDialog(QueryDocumentSnapshot item) {
    final TextEditingController _quantityController = TextEditingController(text: item['quantity'].toString());
    final TextEditingController _priceController = TextEditingController(text: item['price'].toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Offer'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _quantityController,
                  decoration: InputDecoration(labelText: 'Quantity (in kg)'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _priceController,
                  decoration: InputDecoration(labelText: 'Price (₹ per kg)'),
                  keyboardType: TextInputType.number,
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
                Map<String, dynamic> updatedData = {
                  'quantity': int.parse(_quantityController.text),
                  'price': double.parse(_priceController.text),
                };
                await _firestoreService.updateMarketItem(item.id, updatedData);
                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Market')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchTerm = value;
                });
              },
              decoration: InputDecoration(
                labelText: 'Search by crop',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(child: _buildMarketItems()), // Scrollable market items
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openPostDialog(context),
        child: Icon(Icons.add),
        tooltip: 'Post New Offer',
      ),
    );
  }

  // Function to open dialog for posting new offer
  void _openPostDialog(BuildContext context) {
    final TextEditingController _quantityController = TextEditingController();
    final TextEditingController _priceController = TextEditingController();
    bool _isBarter = false;
    bool _isForSale = true;
    String? _selectedBarterCrop;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Post Offer'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    // Dropdown for selecting vegetable to sell
                    DropdownButtonFormField<String>(
                      value: _selectedCrop,
                      items: _cropTypes.map((crop) {
                        return DropdownMenuItem(value: crop, child: Text(crop));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCrop = value!;
                          _selectedBarterCrop = null; // Reset barter crop if the vegetable being sold is changed
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Select Vegetable to Sell',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    TextField(
                      controller: _quantityController,
                      decoration: InputDecoration(labelText: 'Quantity (in kg)'),
                      keyboardType: TextInputType.number,
                    ),
                    
                    // If Barter is selected, show dropdown to select barter vegetable
                    if (_isBarter) 
                      DropdownButtonFormField<String>(
                        value: _selectedBarterCrop,
                        items: _cropTypes
                            .where((crop) => crop != _selectedCrop) // Exclude the selected vegetable
                            .map((crop) {
                              return DropdownMenuItem(value: crop, child: Text(crop));
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedBarterCrop = value!;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Vegetable to Trade',
                          border: OutlineInputBorder(),
                        ),
                      )
                    else 
                      TextField(
                        controller: _priceController,
                        decoration: InputDecoration(labelText: 'Price (₹ per kg)'),
                        keyboardType: TextInputType.number,
                        enabled: _isForSale, // Disable price if barter is selected
                      ),
                    
                    Row(
                      children: [
                        Checkbox(
                          value: _isBarter,
                          onChanged: (value) {
                            setState(() {
                              _isBarter = value!;
                              _isForSale = !_isBarter; // Automatically uncheck "For Sale"
                              _selectedBarterCrop = null; // Reset barter crop when switching to barter
                            });
                          },
                        ),
                        Text('Barter'),
                        Checkbox(
                          value: _isForSale,
                          onChanged: (value) {
                            setState(() {
                              _isForSale = value!;
                              _isBarter = !_isForSale; // Automatically uncheck "Barter"
                            });
                          },
                        ),
                        Text('For Sale'),
                      ],
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
                    if (_quantityController.text.isNotEmpty &&
                        (_priceController.text.isNotEmpty || _isBarter)) {
                      // Ensure the barter crop is selected if barter is chosen
                      if (_isBarter && _selectedBarterCrop == null) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select a vegetable to barter with.')));
                        return;
                      }

                      await _firestoreService.addVegetableToMarket(
                        _selectedCrop!,
                        double.parse(_quantityController.text),
                        _isBarter ? 0.0 : double.parse(_priceController.text),
                        _isBarter,
                        _isForSale,
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
      },
    );
  }
}
