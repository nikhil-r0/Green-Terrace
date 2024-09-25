import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:green_terrace/services/firestore.dart';

class MarketPage extends StatelessWidget {
  final Firestore _firestoreService = Firestore();

  // Function to display market items
  Widget _buildMarketItems() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getMarketItems(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        final items = snapshot.data!.docs;
        if (items.isEmpty) {
          return Center(child: Text('No items available in the market.'));
        }
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              child: ListTile(
                title: Text('${item['vegetable']} (${item['quantity']} units)'),
                subtitle: Text(item['isBarter'] ? 'Barter' : 'Price: \$${item['price']}'),
                trailing: Text(item['isForSale'] ? 'For Sale' : ''),
              ),
            );
          },
        );
      },
    );
  }

  // Function to open a dialog for posting a new vegetable offer
  void _openPostDialog(BuildContext context) {
    final TextEditingController _vegController = TextEditingController();
    final TextEditingController _quantityController = TextEditingController();
    final TextEditingController _priceController = TextEditingController();
    bool _isBarter = false;
    bool _isForSale = true;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Post Vegetable Offer'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _vegController,
                  decoration: InputDecoration(labelText: 'Vegetable'),
                ),
                TextField(
                  controller: _quantityController,
                  decoration: InputDecoration(labelText: 'Quantity'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _priceController,
                  decoration: InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
                ),
                Row(
                  children: [
                    Checkbox(
                      value: _isBarter,
                      onChanged: (value) {
                        _isBarter = value!;
                      },
                    ),
                    Text('Barter'),
                    Checkbox(
                      value: _isForSale,
                      onChanged: (value) {
                        _isForSale = value!;
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
                if (_vegController.text.isNotEmpty && _quantityController.text.isNotEmpty && _priceController.text.isNotEmpty) {
                  await _firestoreService.addVegetableToMarket(
                    _vegController.text,
                    int.parse(_quantityController.text),
                    double.parse(_priceController.text),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Market')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _buildMarketItems(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openPostDialog(context),
        child: Icon(Icons.add),
        tooltip: 'Post New Offer',
      ),
    );
  }
}
