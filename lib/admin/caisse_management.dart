import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'utils.dart';

class CaisseManagement {
  List<Map<String, dynamic>> caisseData = [];
  bool _showCaisseData = false;

  Future<void> loadCaisseData() async {
    try {
      final caisseSnapshot =
          await FirebaseFirestore.instance.collection('caisse').get();
      caisseData = caisseSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final sortedEntries = data.entries.toList()
          ..sort((a, b) => a.value['time'].compareTo(b.value['time']));
        return {'date': doc.id, 'data': Map.fromEntries(sortedEntries)};
      }).toList();
      
      // Sort by date (newest first)
      caisseData.sort((a, b) => b['date'].compareTo(a['date']));
    } catch (e) {
      throw Exception('Erreur de chargement des données de caisse: $e');
    }
  }

  void toggleCaisseData() {
    _showCaisseData = !_showCaisseData;
  }

  bool get showCaisseData => _showCaisseData;

  void showCaisseDetails(
      BuildContext context, String date, Map<String, dynamic> data) {
    double totalRevenue = 0.0;
    double totalVariableCost = 0.0;
    Map<String, int> productTotals = {};

    data.entries.where((e) => e.key.startsWith('command_')).forEach((entry) {
      final command = entry.value;
      totalRevenue += (command['total'] as num).toDouble();

      for (var article in command['articles']) {
        final name = article['name'];
        final quantity = article['quantity'];
        final price = (article['price'] as num).toDouble();
        totalVariableCost += AdminUtils.getArticleCost(name, price) * quantity;
        productTotals.update(name, (v) => (v + quantity) as int,
            ifAbsent: () => quantity);
      }
    });

    final totalFixedCost = AdminUtils.dailyFixedCost;
    final totalCost = totalVariableCost + totalFixedCost;
    final profit = totalRevenue - totalCost;
    final phase = profit >= 0 ? 'Positive ✅' : 'Negative ❌';

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          'Détails Caisse - $date',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.brown),
          textAlign: TextAlign.center,
        ),
        content: SingleChildScrollView(
          child: Column(
            children: [
              AdminUtils.buildAnalysisSection(
                title: 'Analyse Financière',
                items: [
                  AdminUtils.buildAnalysisItem('Revenue Total', totalRevenue),
                  AdminUtils.buildAnalysisItem(
                      'Coûts Variables', totalVariableCost),
                  AdminUtils.buildAnalysisItem('Coûts Fixes', totalFixedCost),
                  AdminUtils.buildAnalysisItem('Coût Total', totalCost,
                      isTotal: true),
                  AdminUtils.buildAnalysisItem('Profit', profit,
                      isProfit: true),
                  AdminUtils.buildAnalysisItem('Profit', profit,
                      isProfit: true, difference: profit),
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: profit >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: profit >= 0 ? Colors.green.shade300 : Colors.red.shade300,
                        ),
                      ),
                      child: Text(
                        'Phase: $phase',
                        style: TextStyle(
                          color: profit >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(thickness: 1),
              AdminUtils.buildAnalysisSection(
                title: 'Quantités Vendues',
                items: productTotals.entries
                    .map((e) => AdminUtils.buildAnalysisItem(
                        e.key, e.value.toDouble(),
                        isCount: true))
                    .toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer', style: TextStyle(color: Colors.brown)),
          ),
        ],
      ),
    );
  }

  String calculateDailyPhase(Map<String, dynamic> data) {
    double revenue = 0.0;
    double costs = AdminUtils.dailyFixedCost;

    data.entries.where((e) => e.key.startsWith('command_')).forEach((entry) {
      final commandTotal = entry.value['total'];
      if (commandTotal is num) {
        revenue += commandTotal.toDouble();
      } else if (commandTotal is String) {
        revenue += double.tryParse(commandTotal) ?? 0.0;
      }

      if (entry.value['articles'] is List) {
        for (var article in entry.value['articles']) {
          if (article is Map) {
            final name = article['name']?.toString() ?? '';
            final quantity = article['quantity'] is num
                ? (article['quantity'] as num).toDouble()
                : double.tryParse(article['quantity']?.toString() ?? '0') ??
                    0.0;
            final price = article['price'] is num
                ? (article['price'] as num).toDouble()
                : double.tryParse(article['price']?.toString() ?? '0') ?? 0.0;

            costs += AdminUtils.getArticleCost(name, price) * quantity;
          }
        }
      }
    });

    final difference = revenue - costs;

    if (difference >= 0) {
      return '✅ Positive (+${difference.toStringAsFixed(3)} DT)';
    } else {
      return '❌ Negative (${difference.toStringAsFixed(3)} DT)';
    }
  }

  double calculateDailyTotal(Map<String, dynamic> data) {
    return data.entries.fold<double>(0.0, (sum, entry) {
      if (entry.key.startsWith('command_')) {
        final total = entry.value['total'];
        if (total is num) {
          return sum + total.toDouble();
        } else if (total is String) {
          return sum + (double.tryParse(total) ?? 0.0);
        }
      }
      return sum;
    });
  }

  Widget buildCaisseList(BuildContext context) {
    if (caisseData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.symmetric(vertical: 20),
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
              'Aucune donnée de caisse disponible',
              style: TextStyle(color: Colors.blue),
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
          'Historique des Caisses',
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
            itemCount: caisseData.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final caisse = caisseData[index];
              final dailyPhase = calculateDailyPhase(caisse['data']);
              final dailyTotal = calculateDailyTotal(caisse['data']);
              final isPositive = dailyPhase.contains('Positive');
              
              // Format date from YYYY-MM-DD to DD/MM/YYYY
              final dateStr = caisse['date'] as String;
              final dateParts = dateStr.split('-');
              final formattedDate = '${dateParts[2]}/${dateParts[1]}/${dateParts[0]}';
              
              return ListTile(
                leading: Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  color: isPositive ? Colors.green : Colors.red,
                ),
                title: Text(
                  formattedDate,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(dailyPhase),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    '${dailyTotal.toStringAsFixed(3)} DT',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
                onTap: () => showCaisseDetails(context, caisse['date'], caisse['data']),
              );
            },
          ),
        ),
      ],
    );
  }
}