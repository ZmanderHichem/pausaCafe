import 'package:flutter/material.dart';

class AdminUtils {
  static double get dailyFixedCost {
    const double monthlyFixedCost = 1500 + 900 + 150;
    const int workingDaysPerMonth = 20;
    return monthlyFixedCost / workingDaysPerMonth;
  }

  static double getArticleCost(String articleName, double sellingPrice) {
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

  static Widget buildAnalysisSection(
      {required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ...items,
        const SizedBox(height: 20),
      ],
    );
  }

  static Widget buildAnalysisItem(
    String label,
    double value, {
    bool isTotal = false,
    bool isProfit = false,
    bool isCount = false,
    double? difference,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontWeight:
                    isTotal || isProfit ? FontWeight.bold : FontWeight.normal,
                color: isProfit
                    ? (value >= 0 ? Colors.green : Colors.red)
                    : Colors.black,
              )),
          Text(
            isCount
                ? 'x${value.toInt()}'
                : '${value.toStringAsFixed(3)} DT' +
                    (difference != null
                        ? ' (${difference >= 0 ? '+' : ''}${difference.toStringAsFixed(3)})'
                        : ''),
            style: TextStyle(
              fontWeight:
                  isTotal || isProfit ? FontWeight.bold : FontWeight.normal,
              color: isProfit
                  ? (value >= 0 ? Colors.green : Colors.red)
                  : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
