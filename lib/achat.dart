import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Achat extends StatefulWidget {
  const Achat({super.key});

  @override
  _AchatState createState() => _AchatState();
}

class _AchatState extends State<Achat> {
  final List<String> products = [
    'Café',
    'Lait',
    'Thé',
    'Eau 0.5L',
    'Eau 1L',
    'Eau 1.5L',
    'Canette Gazeuze',
    'Chocolat Chaud',
    'Cake',
    'Cake Brownie',
    'sucre',
  ];

  String? selectedProduct;
  final TextEditingController quantityController = TextEditingController();

  String? selectedConsumable;
  final List<String> consumables = [
    'Papier Serviette',
    'Agitateurs',
    'Pailles',
    'Savon',
    'Goblet Express',
    'Goblet Cappuccin',
    'Goblet Direct',
    'Sucre',
  ];

  Future<void> saveDataToFirestore() async {
    if (selectedProduct != null && quantityController.text.isNotEmpty) {
      final DateTime now = DateTime.now();
      final String date = DateFormat('yyyy-MM-dd').format(now);

      final String product = selectedProduct!;
      final int quantity = int.tryParse(quantityController.text) ?? 0;

      final Map<String, dynamic> newData = {
        'quantity': quantity,
      };

      final DocumentReference documentRef =
          FirebaseFirestore.instance.collection('achat').doc(date);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final DocumentSnapshot snapshot = await transaction.get(documentRef);

        if (snapshot.exists) {
          // If the document already exists, merge the new data with the existing data
          final Map<String, dynamic> existingData =
              snapshot.data() as Map<String, dynamic>? ?? {};
          final Map<String, dynamic> updatedData = existingData['data'] ?? {};

          updatedData[product] = newData;

          transaction.update(documentRef, {'data': updatedData});
        } else {
          // If the document does not exist, create it with the new data
          transaction.set(documentRef, {
            'date': date,
            'data': {product: newData},
          });
        }
      });

      // Update the stock data
      await updateStockData(product, quantity);

      // Show success alert and refresh the page
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Success'),
              content: const Text('Product added successfully!'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        ).then((_) {
          setState(() {
            selectedProduct = null;
            quantityController.clear();
          });
        });
      }

      print('Data saved to Firestore');
    } else {
      print('Please select a product and enter quantity');
    }
  }

  Future<void> updateStockData(String product, int quantity) async {
    final DocumentReference stockRef = FirebaseFirestore.instance
        .collection('stockadmin')
        .doc('realtimeStock');

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final DocumentSnapshot snapshot = await transaction.get(stockRef);

      if (snapshot.exists) {
        // If the document exists, update only the specific product quantity
        final Map<String, dynamic> stockData =
            snapshot.data() as Map<String, dynamic>? ?? {};
        final Map<String, dynamic> currentData = stockData['data'] ?? {};
        final int currentQuantity = (currentData[product] ?? 0).toInt();

        // Create a new map with updated quantity for the specific product
        final Map<String, dynamic> updatedData = {
          ...currentData, // Keep existing data
          product: currentQuantity + quantity, // Update specific product
        };

        transaction.update(stockRef, {
          'data': updatedData,
        });
      } else {
        // If the document does not exist, create it with initial data
        transaction.set(stockRef, {
          'data': {
            product: quantity,
          },
        });
      }
    });
  }

  Future<void> saveConsumableToFirestore() async {
    if (selectedConsumable != null && quantityController.text.isNotEmpty) {
      try {
        final int quantity = int.tryParse(quantityController.text) ?? 0;

        final DocumentReference consumableRef =
            FirebaseFirestore.instance.collection('consommable').doc('stock');

        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final DocumentSnapshot snapshot =
              await transaction.get(consumableRef);

          if (snapshot.exists) {
            final Map<String, dynamic> stockData =
                snapshot.data() as Map<String, dynamic>? ?? {};
            final Map<String, dynamic> currentData = stockData['data'] ?? {};
            final int currentQuantity =
                (currentData[selectedConsumable] ?? 0).toInt();

            final Map<String, dynamic> updatedData = {
              ...currentData,
              selectedConsumable!: currentQuantity + quantity,
            };

            transaction.update(consumableRef, {'data': updatedData});
          } else {
            transaction.set(consumableRef, {
              'data': {
                selectedConsumable!: quantity,
              },
            });
          }
        });

        // Show success alert and refresh the page
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Success'),
                content: const Text('Consumable added successfully!'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          ).then((_) {
            setState(() {
              selectedConsumable = null;
              quantityController.clear();
            });
          });
        }

        print('Consumable saved to Firestore');
      } catch (e) {
        print('Error saving consumable: $e');
      }
    } else {
      print('Please select a consumable and enter quantity');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Achat Page'),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: saveDataToFirestore,
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButton<String>(
                  value: selectedProduct,
                  hint: const Text('Select a product'),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedProduct = newValue;
                    });
                  },
                  items: products.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16.0),
                if (selectedProduct != null) ...[
                  TextField(
                    controller: quantityController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Enter quantity',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
                const SizedBox(height: 32.0),
                DropdownButton<String>(
                  value: selectedConsumable,
                  hint: const Text('Select a consumable'),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedConsumable = newValue;
                    });
                  },
                  items:
                      consumables.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16.0),
                if (selectedConsumable != null) ...[
                  TextField(
                    controller: quantityController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Enter quantity',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: saveConsumableToFirestore,
                    child: const Text('Save Consumable'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
