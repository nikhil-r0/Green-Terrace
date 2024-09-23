import 'package:flutter/material.dart';

class TerraceSizeInput extends StatefulWidget {
  final Function(double) onSizeEntered; // Callback to pass the size back to parent

  const TerraceSizeInput({required this.onSizeEntered, super.key});

  @override
  // ignore: library_private_types_in_public_api
  _TerraceSizeInputState createState() => _TerraceSizeInputState();
}

class _TerraceSizeInputState extends State<TerraceSizeInput> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _sizeController = TextEditingController();

  @override
  void dispose() {
    _sizeController.dispose();
    super.dispose();
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
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                // On successful validation, parse the double and send it back to parent
                double terraceSize = double.parse(_sizeController.text);
                widget.onSizeEntered(terraceSize);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Terrace Size: $terraceSize sq meters entered')),
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
