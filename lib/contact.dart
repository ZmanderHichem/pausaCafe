import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool _isAuthenticated = false;
  String? _errorMessage;
  final TextEditingController _passwordController = TextEditingController();
  final String adminPassword = '1996';
  List<Widget> _stockDataWidgets = [];
  final Map<String, TextEditingController> _stockControllers = {
    'Café': TextEditingController(),
    'Lait': TextEditingController(),
    'Thé': TextEditingController(),
    'Eau 1.5L': TextEditingController(),
    'Eau 1L': TextEditingController(),
    'Eau Garci': TextEditingController(),
    'Eau 0.5L': TextEditingController(),
    'Boisson Gazeuze': TextEditingController(),
    'Canette Gazeuze': TextEditingController(),
    'Sucre': TextEditingController(),
    'Chocolat': TextEditingController(),
    'Citronade': TextEditingController(),
  };
  bool _isLoading = true;

  // Nouvelle liste pour stocker les données de caisse
  List<Map<String, dynamic>> caisseData = [];

  // Nouvelle variable pour gérer l'affichage des données de caisse
  bool _showCaisseData = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showPasswordPopup();
    });
    _loadStockData();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _stockControllers.forEach((key, controller) {
      controller.dispose();
    });
    super.dispose();
  }

  void _checkPassword() {
    if (_passwordController.text == adminPassword) {
      setState(() {
        _isAuthenticated = true;
        _errorMessage = null;
      });
      Navigator.of(context).pop();
      _loadStockData();
    } else {
      setState(() {
        _errorMessage = 'Incorrect password. Please try again.';
      });
    }
  }

  Future<void> _loadStockData() async {
    try {
      // Récupération des données de realtimeStock
      final stockSnapshot = await FirebaseFirestore.instance
          .collection('stockadmin')
          .doc('realtimeStock')
          .get();

      if (stockSnapshot.exists) {
        final stockData =
            stockSnapshot.data()?['data'] as Map<String, dynamic>?;

        if (stockData != null) {
          // Initialisation des contrôleurs avec les données existantes
          stockData.forEach((key, value) {
            if (_stockControllers.containsKey(key)) {
              _stockControllers[key]!.text = value.toString();
            }
          });
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur de chargement : $e';
      });
    }
  }

  void _showStockInitPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
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
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _submitStockData,
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  void _submitStockData() async {
    Map<String, dynamic> stockData = {};
    _stockControllers.forEach((key, controller) {
      stockData[key] =
          controller.text.isNotEmpty ? int.parse(controller.text) : 0;
    });

    final date =
        DateTime.now().toIso8601String().split('T')[0]; // Format: YYYY-MM-DD

    try {
      // Enregistrement dans Firestore - collection stock
      await FirebaseFirestore.instance
          .collection('stock')
          .doc(date)
          .set(stockData);

      // Mise à jour du stock en temps réel dans stockadmin/realtimeStock
      await FirebaseFirestore.instance
          .collection('stockadmin')
          .doc('realtimeStock')
          .set({'data': stockData, 'lastUpdated': FieldValue.serverTimestamp()},
              SetOptions(merge: true));

      // Mise à jour de l'UI
      setState(() {
        _stockDataWidgets = [
          ListTile(
            title: Text('Date: $date'),
            subtitle: Text('Stock: $stockData'),
          ),
          ..._stockDataWidgets,
        ];
      });

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

  void _showPasswordPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Admin Login'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Enter Admin Password',
                  errorText: _errorMessage,
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _checkPassword,
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  // Fonction pour charger les données de caisse
  Future<void> _loadCaisseData() async {
    try {
      final QuerySnapshot caisseSnapshot =
          await FirebaseFirestore.instance.collection('caisse').get();

      setState(() {
        caisseData = caisseSnapshot.docs.map((doc) {
          return {
            'date': doc.id,
            'data': doc.data(),
          };
        }).toList();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de chargement des données de caisse: $e';
      });
    }
  }

  // Fonction pour afficher les détails de caisse d'une journée spécifique
  void _showCaisseDetails(String date, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Détails de caisse pour le $date'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var entry in data.entries)
                  if (entry.key.startsWith('command_'))
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Commande ${entry.key.split('_')[1]}:',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('Heure: ${entry.value['time']}'),
                        const Text('Articles:'),
                        for (var article in entry.value['articles'])
                          Text(
                              '  - ${article['name']} x${article['quantity']} (${article['price']} DT)'),
                        Text('Total: ${entry.value['total']} DT'),
                        const Divider(),
                      ],
                    ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  // Fonction pour basculer l'affichage des données de caisse
  void _toggleCaisseData() {
    setState(() {
      _showCaisseData = !_showCaisseData;
      if (_showCaisseData) {
        _loadCaisseData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        centerTitle: true,
      ),
      body: _isAuthenticated
          ? Column(
              children: [
                ElevatedButton(
                  onPressed: _showStockInitPopup,
                  child: const Text('Initialize Stock'),
                ),
                ElevatedButton(
                  onPressed: _toggleCaisseData,
                  child: const Text('Caisse'),
                ),
                if (_showCaisseData) // Afficher les données de caisse uniquement si _showCaisseData est vrai
                  Expanded(
                    child: ListView(
                      children: [
                        ..._stockDataWidgets,
                        ...caisseData.map((caisseEntry) {
                          // Calculer le total de la journée
                          final double totalJournee = caisseEntry['data']
                              .entries
                              .fold(0.0, (sum, entry) {
                            if (entry.key.startsWith('command_')) {
                              return sum +
                                  double.parse(entry.value['total'].toString());
                            }
                            return sum;
                          });

                          return ListTile(
                            title: Text(
                                'Caisse du ${caisseEntry['date']} - Total: ${totalJournee.toStringAsFixed(3)} DT'),
                            subtitle:
                                Text('${caisseEntry['data'].length} commandes'),
                            onTap: () => _showCaisseDetails(
                                caisseEntry['date'], caisseEntry['data']),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}
