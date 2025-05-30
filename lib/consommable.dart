import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ConsommablePage extends StatefulWidget {
  const ConsommablePage({Key? key}) : super(key: key);

  @override
  _ConsommablePageState createState() => _ConsommablePageState();
}

class _ConsommablePageState extends State<ConsommablePage> {
  final Map<String, bool> _selectedItems = {
    'Papier Serviette': false,
    'Agitateurs': false,
    'Pailles': false,
    'Savon': false,
    'Goblet Express': false,
    'Goblet Cappuccin': false,
    'Goblet Direct': false,
    'Sucre': false,
  };

  final Map<String, int> _stock = {};

  @override
  void initState() {
    super.initState();
    print('[INIT] Initialisation de la page');
    _loadConsommableStock();
  }

  Future<void> _loadConsommableStock() async {
    try {
      print('[LOAD] Chargement du stock...');
      final snapshot = await FirebaseFirestore.instance
          .collection('consommable')
          .doc('stock')
          .get();

      if (snapshot.exists) {
        final data = snapshot.data()?['data'] as Map<String, dynamic>?;
        if (data != null) {
          setState(() {
            _stock.clear();
            _stock
                .addAll(data.map((key, value) => MapEntry(key, value as int)));
          });
          print('[LOAD] Données chargées: $_stock');
        }
      } else {
        print('[LOAD] Document stock non trouvé');
      }
    } catch (e) {
      print('[ERROR] Erreur chargement stock: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors du chargement du stock : $e")),
      );
    }
  }

  Future<void> _consumeSelectedItemsWithContext(BuildContext context) async {
    try {
      print("[SAVE] Début de l'enregistrement...");
      final updatedStock = Map<String, int>.from(_stock);

      _selectedItems.forEach((key, isSelected) {
        if (isSelected && updatedStock.containsKey(key)) {
          updatedStock[key] = updatedStock[key]! - 1;
          print(
              "[SAVE] Consommation de 1 $key => Nouveau stock: ${updatedStock[key]}");
        }
      });

      await FirebaseFirestore.instance
          .collection('consommable')
          .doc('stock')
          .set({'data': updatedStock});

      print('[SAVE] Données enregistrées avec succès : $updatedStock');

      await _loadConsommableStock();

      setState(() {
        _selectedItems.updateAll((key, value) => false);
      });

      // ✅ Afficher une boîte de dialogue de succès
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Succès'),
          content: const Text('Données enregistrées avec succès !'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                print('[ALERT] Fenêtre de confirmation fermée');
              },
              child: const Text('OK'),
            )
          ],
        ),
      );
    } catch (e) {
      print("[ERROR] Erreur lors de l'enregistrement: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de l'enregistrement : $e")),
      );
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
          title: const Text('Consommable'),
          centerTitle: true,
        ),
        body: _stock.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                children: _stock.entries.map((entry) {
                  return CheckboxListTile(
                    title: Text('${entry.key} (Stock: ${entry.value})'),
                    value: _selectedItems[entry.key],
                    onChanged: (bool? value) {
                      setState(() {
                        _selectedItems[entry.key] = value ?? false;
                      });
                    },
                  );
                }).toList(),
              ),
        floatingActionButton: Builder(
          builder: (context) => FloatingActionButton(
            onPressed: () => _consumeSelectedItemsWithContext(context),
            child: const Icon(Icons.check),
          ),
        ),
      ),
    );
  }
}
