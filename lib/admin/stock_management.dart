import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StockManagement {
  final Map<String, TextEditingController> _stockControllers = {
    'Café': TextEditingController(),
    'Lait': TextEditingController(),
    'Thé': TextEditingController(),
    'Eau 1L': TextEditingController(),
    'Eau 0.5L': TextEditingController(),
    'Eau 1.5L': TextEditingController(),
    'Canette Gazeuze': TextEditingController(),
    'Chocolat Chaud': TextEditingController(),
    'Cake': TextEditingController(),
    'Cake Brownie': TextEditingController(),
    'sucre': TextEditingController(),
  };

  void dispose() {
    _stockControllers.forEach((key, controller) => controller.dispose());
  }

  Future<void> loadStockData() async {
    try {
      final stockSnapshot = await FirebaseFirestore.instance
          .collection('stockadmin')
          .doc('realtimeStock')
          .get();

      if (stockSnapshot.exists) {
        final stockData =
            stockSnapshot.data()?['data'] as Map<String, dynamic>?;
        stockData?.forEach((key, value) {
          if (_stockControllers.containsKey(key)) {
            _stockControllers[key]!.text = value.toString();
          }
        });
      }
    } catch (e) {
      throw Exception('Erreur de chargement : $e');
    }
  }

  void showStockInitPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white.withOpacity(0.9),
          title: const Text('Initialize Stock'),
          content: SingleChildScrollView(
            child: Column(
              children: _stockControllers.entries.map((entry) {
                return TextField(
                  controller: entry.value,
                  decoration: InputDecoration(labelText: entry.key),
                  keyboardType: TextInputType.number,
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _submitStockData(context),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitStockData(BuildContext context) async {
    Map<String, dynamic> stockData = {};
    _stockControllers.forEach((key, controller) {
      stockData[key] =
          controller.text.isNotEmpty ? int.parse(controller.text) : 0;
    });

    final date = DateTime.now().toIso8601String().split('T')[0];

    try {
      await FirebaseFirestore.instance
          .collection('stock')
          .doc(date)
          .set(stockData);
      await FirebaseFirestore.instance
          .collection('stockadmin')
          .doc('realtimeStock')
          .set(
        {'data': stockData, 'lastUpdated': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stock initialisé avec succès !')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur d'enregistrement: $e")),
      );
    }
    Navigator.of(context).pop();
  }

  Widget buildStockStream() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('stockadmin')
          .doc('realtimeStock')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (snapshot.hasError) {
          return Text('Erreur: ${snapshot.error}');
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text('Aucune donnée disponible pour le stock.');
        }

        final stockData = snapshot.data!.data() as Map<String, dynamic>?;
        final stockItems = stockData?['data'] as Map<String, dynamic>?;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Stock en temps réel:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ...?stockItems?.entries.map((entry) => ListTile(
                  title: Text(entry.key),
                  trailing: Text(entry.value.toString()),
                )),
          ],
        );
      },
    );
  }
}
