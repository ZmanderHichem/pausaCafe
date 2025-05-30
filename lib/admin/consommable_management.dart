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
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.9),
        title: const Text('Initialiser Consommables'),
        content: SingleChildScrollView(
          child: Column(
            children: controllers.entries
                .map((e) => TextField(
                      controller: e.value,
                      decoration: InputDecoration(labelText: e.key),
                      keyboardType: TextInputType.number,
                    ))
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
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
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Consommables sauvegardés !')));
              } catch (e) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Erreur: $e')));
              }
              Navigator.pop(context);
            },
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
          return const CircularProgressIndicator();
        }
        if (snapshot.hasError) {
          return Text('Erreur: ${snapshot.error}');
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text('Aucune donnée disponible pour les consommables.');
        }

        final consommableData = snapshot.data!.data() as Map<String, dynamic>?;
        final consommableItems =
            consommableData?['data'] as Map<String, dynamic>?;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Consommables en temps réel:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ...?consommableItems?.entries.map((entry) => ListTile(
                  title: Text(entry.key),
                  trailing: Text(entry.value.toString()),
                )),
          ],
        );
      },
    );
  }
}
