import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:green_terrace/services/firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MarketPage extends StatefulWidget {
  const MarketPage({super.key});

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

  @override
  void dispose() {
    super.dispose();
  }

  // Fetch crop types from Firestore for dropdown
  void _loadCropTypes() async {
    List<String> cropTypes = await _firestoreService.getCropTypes();
    if(mounted){
      setState(() {
        _cropTypes = cropTypes;
      });
    }
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
        collapsedTextColor: Colors.green,
        backgroundColor: Colors.grey[900],
        textColor: Colors.green,
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
    final TextEditingController quantityController = TextEditingController(text: item['quantity'].toString());
    final TextEditingController priceController = TextEditingController(text: item['price'].toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Offer'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: quantityController,
                  decoration: InputDecoration(labelText: 'Quantity (in kg)'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: priceController,
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
                  'quantity': int.parse(quantityController.text),
                  'price': double.parse(priceController.text),
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
        tooltip: 'Post New Offer',
        child: Icon(Icons.add),
      ),
    );
  }

  // Function to open dialog for posting new offer
  void _openPostDialog(BuildContext context) {
    final TextEditingController quantityController = TextEditingController();
    final TextEditingController priceController = TextEditingController();
    bool isBarter = false;
    bool isForSale = true;
    String? selectedBarterCrop;

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
                          selectedBarterCrop = null; // Reset barter crop if the vegetable being sold is changed
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Select Vegetable to Sell',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    TextField(
                      controller: quantityController,
                      decoration: InputDecoration(labelText: 'Quantity (in kg)'),
                      keyboardType: TextInputType.number,
                    ),
                    
                    // If Barter is selected, show dropdown to select barter vegetable
                    if (isBarter) 
                      DropdownButtonFormField<String>(
                        value: selectedBarterCrop,
                        items: _cropTypes
                            .where((crop) => crop != _selectedCrop) // Exclude the selected vegetable
                            .map((crop) {
                              return DropdownMenuItem(value: crop, child: Text(crop));
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedBarterCrop = value!;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Vegetable to Trade',
                          border: OutlineInputBorder(),
                        ),
                      )
                    else 
                      TextField(
                        controller: priceController,
                        decoration: InputDecoration(labelText: 'Price (₹ per kg)'),
                        keyboardType: TextInputType.number,
                        enabled: isForSale, // Disable price if barter is selected
                      ),
                    
                    Row(
                      children: [
                        Checkbox(
                          value: isBarter,
                          onChanged: (value) {
                            setState(() {
                              isBarter = value!;
                              isForSale = !isBarter; // Automatically uncheck "For Sale"
                              selectedBarterCrop = null; // Reset barter crop when switching to barter
                            });
                          },
                        ),
                        Text('Barter'),
                        Checkbox(
                          value: isForSale,
                          onChanged: (value) {
                            setState(() {
                              isForSale = value!;
                              isBarter = !isForSale; // Automatically uncheck "Barter"
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
                    if (quantityController.text.isNotEmpty &&
                        (priceController.text.isNotEmpty || isBarter)) {
                      // Ensure the barter crop is selected if barter is chosen
                      if (isBarter && selectedBarterCrop == null) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select a vegetable to barter with.')));
                        return;
                      }

                      await _firestoreService.addVegetableToMarket(
                        _selectedCrop!,
                        double.parse(quantityController.text),
                        isBarter ? 0.0 : double.parse(priceController.text),
                        isBarter,
                        isForSale,
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