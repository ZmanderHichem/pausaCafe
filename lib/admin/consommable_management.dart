import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ConsommableManagement {
  void showConsommableInitPopup(BuildContext context) {
    final controllers = {
      'Papier Serviette': TextEditingController(),
      'Agitateurs': TextEditingController(),
      'Pailles': TextEditingController(),
      'Savon': TextEditingController(),
      'Goblet Express': TextEditingController(),
      'Goblet Cappuccin': TextEditingController(),
      'Goblet Direct': TextEditingController(),
      'Sucre': TextEditingController(),
    };

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          'Initialiser Consommables',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown),
          textAlign: TextAlign.center,
        ),
        content: SingleChildScrollView(
          child: Column(
            children: controllers.entries.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextField(
                controller: e.value,
                decoration: InputDecoration(
                  labelText: e.key,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.coffee, color: Colors.brown),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.brown, width: 2),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
            )).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final data = {
                for (var e in controllers.entries)
                  e.key: int.tryParse(e.value.text) ?? 0
              };
              try {
                await FirebaseFirestore.instance
                    .collection('consommable')
                    .doc('stock')
                    .set({'data': data});
                    
                // Dispose controllers
                controllers.forEach((key, controller) => controller.dispose());
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Consommables sauvegardés !'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                    ),
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $e'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                    ),
                  );
                }
              }
            },
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
      ),
    );
  }

  Widget buildConsommableStream() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('consommable')
          .doc('stock')
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
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: const Column(
              children: [
                Icon(Icons.info_outline, color: Colors.orange, size: 40),
                SizedBox(height: 8),
                Text(
                  'Aucune donnée disponible pour les consommables.',
                  style: TextStyle(color: Colors.orange),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final consommableData = snapshot.data!.data() as Map<String, dynamic>?;
        final consommableItems =
            consommableData?['data'] as Map<String, dynamic>?;

        if (consommableItems == null || consommableItems.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: const Column(
              children: [
                Icon(Icons.info_outline, color: Colors.orange, size: 40),
                SizedBox(height: 8),
                Text(
                  'Aucun consommable trouvé.',
                  style: TextStyle(color: Colors.orange),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Consommables en temps réel:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown),
            ),
            const SizedBox(height: 8),
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
                itemCount: consommableItems.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final entry = consommableItems.entries.elementAt(index);
                  final stockLevel = entry.value;
                  Color stockColor;
                  
                  if (stockLevel <= 10) {
                    stockColor = Colors.red;
                  } else if (stockLevel <= 30) {
                    stockColor = Colors.orange;
                  } else {
                    stockColor = Colors.green;
                  }
                  
                  return ListTile(
                    leading: Icon(
                      _getConsommableIcon(entry.key),
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
            ),
          ],
        );
      },
    );
  }
  
  IconData _getConsommableIcon(String consommableName) {
    switch (consommableName) {
      case 'Papier Serviette':
        return Icons.cleaning_services;
      case 'Agitateurs':
        return Icons.soup_kitchen;
      case 'Pailles':
        return Icons.water;
      case 'Savon':
        return Icons.soap;
      case 'Goblet Express':
      case 'Goblet Cappuccin':
      case 'Goblet Direct':
        return Icons.coffee;
      case 'Sucre':
        return Icons.grain;
      default:
        return Icons.inventory;
    }
  }
}