import 'package:flutter/material.dart';
import 'package:saadoun/localStorage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EndShift extends StatefulWidget {
  const EndShift({super.key});

  @override
  _EndShiftState createState() => _EndShiftState();
}

class _EndShiftState extends State<EndShift> {
  List<FactureData> factureDataList = [];
  FactureData? storedData;
  final LStorage? lStorage = LStorage();
  final Map<String, TextEditingController> controllers = {};
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

  @override
  void initState() {
    super.initState();
    loadStockData();
  }

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

        final Map<String, double> processedStock = {};
        stock.forEach((key, value) {
          if (value == null) {
            print('Warning: Null value found for $key, setting to 0.0');
            processedStock[key] = 0.0;
          } else {
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

      final Map<String, dynamic> recetteData = {
        'date': date,
        'time': time,
        'soldStock': soldStock,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('recette')
          .doc(date)
          .set(recetteData);
      debugPrint('Successfully saved to recette collection');

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

      if (mounted) {
        debugPrint('Clearing controllers...');
        controllers.forEach((key, controller) => controller.clear());

        debugPrint('Showing success message...');
        showSnackbar('Data saved successfully!');

        debugPrint('Closing keyboard...');
        FocusScope.of(context).unfocus();

        debugPrint('Refreshing stock data...');
        await loadStockData();

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

      await sendStockReportByEmail(
          newStock.map((key, value) => MapEntry(key, value.toDouble())));
    } catch (e, stackTrace) {
      debugPrint('Error in saveDataToFirestore: $e');
      debugPrint('Error stack trace: $stackTrace');
      if (mounted) {
        showSnackbar('Error saving data: $e');
      }
    }

    debugPrint('Completed saveDataToFirestore process');
  }

  Future<void> sendStockReportByEmail(Map<String, double> stockData) async {
    final emailConfig = getEmailConfig();

    final StringBuffer stockDetails = StringBuffer();
    if (stockData.isNotEmpty) {
      stockData.forEach((key, value) {
        stockDetails.writeln('$key: ${value.toStringAsFixed(2)}');
      });
    } else {
      stockDetails.writeln('Aucune donnée de stock disponible.');
    }

    // Calculate total revenue and profit/loss for the day
    final String date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    double totalRevenue = 0.0;
    double totalVariableCost = 0.0;

    try {
      final DocumentSnapshot caisseSnapshot =
          await FirebaseFirestore.instance.collection('caisse').doc(date).get();

      if (caisseSnapshot.exists) {
        final Map<String, dynamic> caisseData =
            caisseSnapshot.data() as Map<String, dynamic>;

        caisseData.entries
            .where((entry) => entry.key.startsWith('command_'))
            .forEach((entry) {
          final command = entry.value;
          final commandTotal = command['total'];

          // Safely parse the total value
          totalRevenue += commandTotal is num
              ? commandTotal.toDouble()
              : double.tryParse(commandTotal.toString()) ?? 0.0;

          for (var article in command['articles']) {
            final name = article['name'];
            final quantity = article['quantity'] is num
                ? (article['quantity'] as num).toDouble()
                : double.tryParse(article['quantity']?.toString() ?? '0') ??
                    0.0;
            final price = article['price'] is num
                ? (article['price'] as num).toDouble()
                : double.tryParse(article['price']?.toString() ?? '0') ?? 0.0;

            totalVariableCost += _getArticleCost(name, price) * quantity;
          }
        });
      }
    } catch (e) {
      print('Erreur lors de la récupération des données de caisse : $e');
    }

    // Use daily fixed cost from admin.dart
    const double monthlyFixedCost = 1500 + 900 + 150;
    const int workingDaysPerMonth = 20;
    final double dailyFixedCost = monthlyFixedCost / workingDaysPerMonth;

    final double totalCost = totalVariableCost + dailyFixedCost;
    final double profit = totalRevenue - totalCost;
    final String phase = profit >= 0 ? 'Gain ✅' : 'Perte ❌';

    final StringBuffer financialDetails = StringBuffer();
    financialDetails
        .writeln('Recette Totale: ${totalRevenue.toStringAsFixed(2)} DT');
    financialDetails.writeln('Coût Total: ${totalCost.toStringAsFixed(2)} DT');
    financialDetails
        .writeln('Profit: ${profit.toStringAsFixed(2)} DT ($phase)');

    print('Financial Summary:\n${financialDetails.toString()}'); // Debugging

    // Send email
    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
    final response = await http.post(
      url,
      headers: {
        'origin': 'http://localhost',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'service_id': emailConfig['serviceId'],
        'template_id': emailConfig['templateId'],
        'user_id': emailConfig['userId'],
        'template_params': {
          'to_email': emailConfig['toEmail'],
          'date': date,
          'stock': stockDetails.toString(),
          'financial_summary': financialDetails.toString(),
        }
      }),
    );

    if (response.statusCode == 200) {
      print('Email envoyé avec succès');
    } else {
      print('Erreur lors de l\'envoi de l\'email: ${response.body}');
    }
  }

  Map<String, String> getEmailConfig() {
    return {
      'serviceId': 'service_9frimjq',
      'templateId': 'template_cpizged',
      'userId': '045MKDooB2Thc1kTN',
      'toEmail': 'papmalik2013@gmail.com',
    };
  }

  void showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  double _getArticleCost(String articleName, double sellingPrice) {
    const double cafeCostPerUnit = 37.0 / 100;
    const double sucreCostPerSachet = 32.0 / (8000 / 5);
    const double agitateurCost = 3.5 / 500;
    const double laitCostPerL = 1.35;
    const double chocolatCostPerG = 4.0 / 250;
    const double gobeletSmallCost = 2.2 / 50;
    const double gobeletMediumCost = 2.8 / 50;
    const double gobeletLargeCost = 4.5 / 50;

    switch (articleName) {
      case 'Express':
        return cafeCostPerUnit +
            (2 * sucreCostPerSachet) +
            agitateurCost +
            gobeletSmallCost;
      case 'Americain':
        return cafeCostPerUnit +
            (2 * sucreCostPerSachet) +
            agitateurCost +
            gobeletMediumCost;
      case 'Cappucin':
        return cafeCostPerUnit +
            (1.35 / 9) +
            (2 * sucreCostPerSachet) +
            agitateurCost +
            gobeletMediumCost;
      case 'Direct':
        return cafeCostPerUnit +
            (1.35 / 6) +
            (2 * sucreCostPerSachet) +
            agitateurCost +
            gobeletLargeCost;
      case 'Chocolat au Lait':
        return (10 * chocolatCostPerG) +
            (2 * sucreCostPerSachet) +
            agitateurCost +
            gobeletLargeCost;
      case 'Thé Vert':
        return (sellingPrice / 2.7) + gobeletLargeCost;
      case 'Eau 0.5L':
        return 0.416;
      case 'Eau 1L':
        return 0.5;
      case 'Eau 1.5L':
        return 0.666;
      case 'Boisson Gazeuse':
        return 1.4;
      case 'Citronade':
        return (3.0 / 5) + gobeletLargeCost;
      case 'Croissant':
        return 0.9;
      case 'Pathé':
        return 1.2;
      case 'Cake':
        return 1.2;
      case 'Mille Feuilles':
        return 1.2;
      case 'Sablé':
        return 1.2;
      default:
        return 0.0;
    }
  }

  @override
  void dispose() {
    controllers.forEach((key, controller) => controller.dispose());
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
      'Eau 0.5L',
      'Eau 1L',
      'Eau 1.5L',
      'Canette Gazeuze',
      'Chocolat Chaud',
      'Cake',
      'Cake Brownie',
      'sucre',
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Home Page'),
          actions: [
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
      ),
    );
  }
}
