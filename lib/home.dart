import 'package:flutter/material.dart';
import 'package:saadoun/localStorage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<FactureData> factureDataList = [];
  FactureData? storedData;
  final LStorage? lStorage = LStorage();
  final Map<String, TextEditingController> controllers = {};
  final TextEditingController recetteController = TextEditingController();
  final TextEditingController caisseController = TextEditingController();
  Map<String, double> stockData = {}; // Map to store stock data

  void reloadWidget() {
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        loadData();
      });
    });
  }

  void loadData() async {
    List<Map<String, dynamic>>? data = await lStorage?.loadFromLocalStorage();
    print(data);
  }

  // Méthode pour charger les données du stock depuis Firestore
  @override
  void initState() {
    super.initState();
    loadStockData();
  }

  // Fonction pour charger les données depuis Firestore
  Future<void> loadStockData() async {
    try {
      print('Fetching stock data from Firestore...');
      final stockSnapshot = await FirebaseFirestore.instance
          .collection('stockadmin')
          .doc('realtimeStock')
          .get();
      print('hettttt stockkk: ${stockSnapshot.data()}');

      if (stockSnapshot.exists) {
        print('Stock document found');
        final Map<String, dynamic>? stock = stockSnapshot.data()?['data'];

        if (stock == null) {
          print('Error: Document exists but data is null');
          showSnackbar('Error: Stock data is null in Firestore');
          return;
        }

        print('Raw stock data: $stock');

        // Convertir les valeurs en double et gérer les valeurs nulles
        final Map<String, double> processedStock = {};
        stock.forEach((key, value) {
          if (value == null) {
            print('Warning: Null value found for $key, setting to 0.0');
            processedStock[key] = 0.0;
          } else {
            // Convertir en double
            processedStock[key] = value is double
                ? value
                : double.tryParse(value.toString()) ?? 0.0;
          }
        });

        print('Processed stock data: $processedStock');

        setState(() {
          stockData = processedStock;
        });
      } else {
        print('Stock document does not exist');
        showSnackbar('Error: Stock document not found');
      }
    } catch (e) {
      print('Erreur lors du chargement des stocks : $e');
      showSnackbar('Erreur lors du chargement des stocks : $e');
    }
  }

  Future<void> saveDataToFirestore() async {
    debugPrint('Starting saveDataToFirestore process...');

    final DateTime now = DateTime.now();
    final String date = DateFormat('yyyy-MM-dd').format(now);
    final String time = DateFormat('HH:mm').format(now);
    debugPrint('Generated date: $date, time: $time');

    try {
      debugPrint('Fetching current stock data...');
      final stockSnapshot = await FirebaseFirestore.instance
          .collection('stockadmin')
          .doc('realtimeStock')
          .get();

      if (!stockSnapshot.exists) {
        debugPrint('Error: realtimeStock document does not exist');
        if (mounted) {
          showSnackbar('Error: realtimeStock document does not exist');
        }
        return;
      }

      final Map<String, dynamic> currentStock = stockSnapshot.data()!['data'];
      debugPrint('Current stock data: $currentStock');

      // 2. Calculer la différence entre l'ancien stock et le nouveau stock
      debugPrint('Calculating sold stock...');
      Map<String, dynamic> soldStock = {};
      controllers.forEach((title, controller) {
        final double oldStock = currentStock[title]?.toDouble() ?? 0;
        final double newStock = controller.text.isNotEmpty
            ? double.tryParse(controller.text) ?? oldStock
            : oldStock;
        soldStock[title] = oldStock - newStock;
        debugPrint('Processing $title - old: $oldStock, new: $newStock');
      });
      debugPrint('Calculated sold stock: $soldStock');

      // 3. Enregistrer dans la collection recette
      debugPrint('Saving to recette collection...');
      final Map<String, dynamic> recetteData = {
        'date': date,
        'time': time,
        'recette': recetteController.text,
        'caisse': caisseController.text,
        'soldStock': soldStock,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('recette')
          .doc(date)
          .set(recetteData);
      debugPrint('Successfully saved to recette collection');

      // 4. Mettre à jour le realtimeStock avec le nouveau stock restant
      debugPrint('Updating realtimeStock...');
      final Map<String, dynamic> newStock = {};
      controllers.forEach((title, controller) {
        newStock[title] = controller.text.isNotEmpty
            ? double.tryParse(controller.text) ??
                currentStock[title]?.toDouble() ??
                0
            : currentStock[title]?.toDouble() ?? 0;
      });
      debugPrint('New stock to be saved: $newStock');

      await FirebaseFirestore.instance
          .collection('stockadmin')
          .doc('realtimeStock')
          .update({'data': newStock});
      debugPrint('Successfully updated realtimeStock');

      // 5. Gestion UI sécurisée
      if (mounted) {
        debugPrint('Clearing controllers...');
        controllers.forEach((key, controller) => controller.clear());
        recetteController.clear();
        caisseController.clear();

        debugPrint('Showing success message...');
        showSnackbar('Data saved successfully!');

        debugPrint('Closing keyboard...');
        FocusScope.of(context).unfocus();

        debugPrint('Refreshing stock data...');
        await loadStockData(); // Recharger les données du stock

        debugPrint('Waiting before navigation...');
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          try {
            debugPrint('Attempting to pop navigation...');
            await Navigator.of(context).maybePop();
            debugPrint('Navigation pop successful');
          } catch (e, stackTrace) {
            debugPrint('Navigation error: $e');
            debugPrint('Navigation stack trace: $stackTrace');
            if (mounted) {
              showSnackbar('Error during navigation: $e');
            }
          }
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error in saveDataToFirestore: $e');
      debugPrint('Error stack trace: $stackTrace');
      if (mounted) {
        showSnackbar('Error saving data: $e');
      }
    }

    debugPrint('Completed saveDataToFirestore process');
  }

  Future<void> saveRecetteData() async {
    final DateTime now = DateTime.now();
    final String date = DateFormat('yyyy-MM-dd').format(now);
    final String time = DateFormat('HH:mm').format(now);

    final Map<String, dynamic> recetteData = {
      'date': date,
      'time': time,
      'recette': recetteController.text,
      'caisse': caisseController.text,
    };

    try {
      await FirebaseFirestore.instance
          .collection('recette')
          .doc()
          .set(recetteData);
      showSnackbar('Recette data saved successfully!');
      recetteController.clear();
      caisseController.clear();
      Navigator.of(context).pop(); // Close the popup
    } catch (e) {
      showSnackbar('Error saving recette data: $e');
    }
  }

  void showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void showRecetteDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Fin de Service'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: recetteController,
                decoration: const InputDecoration(
                  labelText: 'Recette du Service',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: caisseController,
                decoration: const InputDecoration(
                  labelText: 'Fond Restant dans la Caisse',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: saveRecetteData,
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    controllers.forEach((key, controller) => controller.dispose());
    recetteController.dispose();
    caisseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (stockData.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    print('Current stock data in UI: $stockData');
    final List<String> titles = [
      'Café',
      'Lait',
      'Thé',
      'Eau 1.5L',
      'Eau 1L',
      'Eau Garci',
      'Eau 0.5L',
      'Boisson Gazeuse',
      'Canette Gazeuze',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
        actions: [
          IconButton(
            icon: const Icon(Icons.assignment_turned_in),
            onPressed: showRecetteDialog,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: saveDataToFirestore,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: titles.map((title) {
              // Assurez-vous que chaque contrôleur existe
              if (!controllers.containsKey(title)) {
                controllers[title] = TextEditingController();
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text(
                        title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'Stock: ${stockData[title]?.toStringAsFixed(0) ?? 'N/A'}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: controllers[title],
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          hintText:
                              '${controllers[title]?.text.isEmpty ?? true ? "Saisir quantité" : controllers[title]?.text}',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
