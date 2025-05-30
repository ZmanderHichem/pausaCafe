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
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white.withOpacity(0.95),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text(
            'Initialiser Stock',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown),
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: Column(
              children: _stockControllers.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextField(
                    controller: entry.value,
                    decoration: InputDecoration(
                      labelText: entry.key,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: const Icon(Icons.inventory, color: Colors.brown),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.brown, width: 2),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => _submitStockData(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text('Enregistrer'),
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
        const SnackBar(
          content: Text('Stock initialisé avec succès !'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur d'enregistrement: $e"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
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
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.brown),
            ),
          );
        }
        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Column(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 40),
                const SizedBox(height: 8),
                Text(
                  'Erreur: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: const Column(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 40),
                SizedBox(height: 8),
                Text(
                  'Aucune donnée disponible pour le stock.',
                  style: TextStyle(color: Colors.blue),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final stockData = snapshot.data!.data() as Map<String, dynamic>?;
        final stockItems = stockData?['data'] as Map<String, dynamic>?;
        final lastUpdated = stockData?['lastUpdated'] as Timestamp?;
        final lastUpdatedText = lastUpdated != null 
            ? '${lastUpdated.toDate().day}/${lastUpdated.toDate().month}/${lastUpdated.toDate().year} à ${lastUpdated.toDate().hour}:${lastUpdated.toDate().minute}'
            : 'Non disponible';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.brown.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.update, color: Colors.brown),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Dernière mise à jour: $lastUpdatedText',
                      style: TextStyle(color: Colors.brown.shade700, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Stock en temps réel:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown),
            ),
            const SizedBox(height: 8),
            if (stockItems != null && stockItems.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: stockItems.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final entry = stockItems.entries.elementAt(index);
                    final stockLevel = entry.value;
                    Color stockColor;
                    
                    if (stockLevel <= 5) {
                      stockColor = Colors.red;
                    } else if (stockLevel <= 15) {
                      stockColor = Colors.orange;
                    } else {
                      stockColor = Colors.green;
                    }
                    
                    return ListTile(
                      leading: Icon(
                        Icons.inventory,
                        color: stockColor,
                      ),
                      title: Text(
                        entry.key,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: stockColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: stockColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          entry.value.toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: stockColor,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              const Center(
                child: Text('Aucun élément en stock'),
              ),
          ],
        );
      },
    );
  }
}