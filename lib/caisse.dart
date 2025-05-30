import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Caisse extends StatefulWidget {
  const Caisse({super.key});

  @override
  _CaisseState createState() => _CaisseState();
}

class _CaisseState extends State<Caisse> {
  // Liste des articles (avec un nom et un prix)
  final List<Map<String, dynamic>> articles = [
    {'name': 'Express', 'price': 1.500, 'color': Colors.brown[800]},
    {'name': 'Americain', 'price': 1.700, 'color': Colors.brown[700]},

    {'name': 'Cappucin', 'price': 1.700, 'color': Colors.brown[700]},
    {'name': 'Direct', 'price': 2.000, 'color': Colors.brown[600]},
    {'name': 'Chocolat au Lait', 'price': 2.000, 'color': Colors.brown[500]},
    // {'name': 'Chocolat Chaud', 'price': 3.500, 'color': Colors.brown[400]},
    {'name': 'Thé Vert', 'price': 1.200, 'color': Colors.green[600]},
    {'name': 'Eau 0.5L', 'price': 1.000, 'color': Colors.blue[300]},
    {'name': 'Eau 1L', 'price': 1.500, 'color': Colors.blue[300]},
    {'name': 'Eau 1.5L', 'price': 2.000, 'color': Colors.blue[300]},
    {'name': 'Boisson Gazeuse', 'price': 2.500, 'color': Colors.orange[600]},
    {'name': 'Citronade', 'price': 1.800, 'color': Colors.yellow[600]},
    {'name': 'Fraise', 'price': 2.500, 'color': Colors.yellow[600]},

    {'name': 'Croissant', 'price': 2.000, 'color': Colors.amber[600]},
    {'name': 'Pathé', 'price': 2.200, 'color': Colors.yellow[600]},

    {'name': 'Cake', 'price': 1.800, 'color': Colors.pink[300]},
    // {'name': 'Cake Brownie', 'price': 1.900, 'color': Colors.purple[300]},
    {'name': 'Mille Feuilles', 'price': 2.200, 'color': Colors.pink[300]},
    {'name': 'Sablé', 'price': 1.600, 'color': Colors.pink[300]},

    // {'name': 'Pizza', 'price': 3.000, 'color': Colors.red[300]},
    {'name': 'Nestlé', 'price': 1.500, 'color': Colors.blueGrey[300]},
  ];

  List<Map<String, dynamic>> selectedArticles = [];

  // Nouvelle map pour stocker les quantités des articles sélectionnés
  final Map<String, int> articleQuantities = {};

  // Fonction pour ajouter un article au ticket de caisse
  void _addToCart(Map<String, dynamic> article) {
    setState(() {
      final String articleName = article['name'];
      if (articleQuantities.containsKey(articleName)) {
        articleQuantities[articleName] = articleQuantities[articleName]! + 1;
      } else {
        articleQuantities[articleName] = 1;
        selectedArticles.add(article);
      }
    });
  }

  // Fonction pour supprimer un article du ticket de caisse
  void _removeFromCart(int index) {
    setState(() {
      final String articleName = selectedArticles[index]['name'];
      if (articleQuantities[articleName]! > 1) {
        articleQuantities[articleName] = articleQuantities[articleName]! - 1;
      } else {
        articleQuantities.remove(articleName);
        selectedArticles.removeAt(index);
      }
    });
  }

  // Fonction pour enregistrer les données dans la collection caisse
  Future<void> _saveReceipt() async {
    final DateTime now = DateTime.now();
    final String date = DateFormat('yyyy-MM-dd').format(now);
    final String time = DateFormat('HH:mm:ss').format(now);

    // Calculer le total avec 3 chiffres après la virgule
    final double total = double.parse(selectedArticles
        .fold(
            0.0,
            (sum, item) =>
                sum + (item['price'] * articleQuantities[item['name']]!))
        .toStringAsFixed(3));

    // Créer un objet pour la commande actuelle
    final Map<String, dynamic> receiptData = {
      'time': time,
      'articles': selectedArticles
          .map((item) => {
                'name': item['name'],
                'quantity':
                    articleQuantities[item['name']]!, // Ajouter la quantité
                'price': double.parse(item['price'].toStringAsFixed(
                    3)), // Prix avec 3 chiffres après la virgule
              })
          .toList(),
      'total':
          total.toStringAsFixed(3), // Total avec 3 chiffres après la virgule
    };

    try {
      // Référence au document de la date actuelle
      final DocumentReference docRef =
          FirebaseFirestore.instance.collection('caisse').doc(date);

      // Récupérer le document existant
      final DocumentSnapshot docSnapshot = await docRef.get();

      // Si le document existe, ajouter la nouvelle commande
      if (docSnapshot.exists) {
        final Map<String, dynamic> existingData =
            docSnapshot.data() as Map<String, dynamic>;
        final int nextIndex = existingData.length; // Prochain index disponible

        // Ajouter la nouvelle commande avec un index unique
        await docRef.update({
          'command_$nextIndex': receiptData,
        });
      } else {
        // Si le document n'existe pas, créer un nouveau document avec la première commande
        await docRef.set({
          'command_0': receiptData,
        });
      }

      // Réinitialiser le ticket de caisse
      setState(() {
        selectedArticles.clear();
        articleQuantities.clear();
      });

      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Données enregistrées avec succès!')),
      );
    } catch (e) {
      // Gérer les erreurs
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'enregistrement: $e')),
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
        ),
        body: Column(
          children: [
            Expanded(
              flex: 2, // Augmenter la taille de la partie des articles
              child: Column(
                children: [
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        crossAxisSpacing: 8.0,
                        mainAxisSpacing: 8.0,
                        childAspectRatio:
                            2.9, // Réduire la taille des cadres de produit
                      ),
                      itemCount: articles.length,
                      itemBuilder: (context, index) {
                        final article = articles[index];
                        return GestureDetector(
                          onTap: () => _addToCart(article),
                          child: Container(
                            decoration: BoxDecoration(
                              color: article['color'],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      article['name'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${article['price'].toStringAsFixed(3)} DT',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.grey), // Petit trait de séparation
                ],
              ),
            ),
            Expanded(
              flex: 1, // Réduire la taille du bloc du ticket
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: selectedArticles.length,
                      itemBuilder: (context, index) {
                        final article = selectedArticles[index];
                        return ListTile(
                          leading: IconButton(
                            icon: const Icon(Icons.delete,
                                color: Color.fromARGB(255, 175, 76, 76)),
                            onPressed: () => _removeFromCart(index),
                          ),
                          title: Text(
                              '${article['name']} x${articleQuantities[article['name']]}'),
                          trailing: Text(
                              '${(article['price'] * articleQuantities[article['name']]!).toStringAsFixed(3)} DT'),
                        );
                      },
                    ),
                  ),
                  Text(
                    'Total: ${selectedArticles.fold(0.0, (sum, item) => sum + (item['price'] * articleQuantities[item['name']]!)).toStringAsFixed(3)} DT',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.all(5.0), // Padding de 5px
                    child: SizedBox(
                      width: double.infinity, // Prend toute la largeur
                      child: ElevatedButton(
                        onPressed:
                            selectedArticles.isEmpty ? null : _saveReceipt,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 20.0), // Augmenter la taille du bouton
                        ),
                        child: const Text('Enregistrer'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
