import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:saadoun/auth.dart';
import 'package:saadoun/admin/admin_dashboard.dart';
import 'consommable.dart';
import 'package:saadoun/caisse.dart';
import 'package:saadoun/achat.dart';
import 'package:saadoun/EndShift.dart';
import 'package:saadoun/localStorage.dart';
import 'package:saadoun/signin.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BottomNavigation extends StatefulWidget {
  const BottomNavigation({super.key});

  @override
  _BottomNavigationState createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  int _currentIndex = 0;

  LStorage lStorage = LStorage();
  UserData? storedData;

  Future<void> fetchData() async {
    try {
      print('UserrrrrrrrrrIMATTTT: ${storedData?.Plate}');
      if (storedData?.Plate != null) {
        // Reference to the user's document in the 'users' collection

        QuerySnapshot<Map<String, dynamic>> querySnapshot =
            await FirebaseFirestore.instance
                .collection('FACT')
                .doc(storedData?.Plate)
                .collection('facture')
                .get();
        print('UIMATTTT: ${storedData?.Plate}');
        if (querySnapshot.docs.isEmpty) {
          print('No documents found.');
        } else {
          print('Documents found:');
          // Convert Firestore document data to JSON
          List<Map<String, dynamic>> jsonDataList = [];
          List<Map<String, dynamic>>? jsonUniqueDataList = [];
          Map<String, dynamic> uniqueDataMap = {}; // Map to store unique data

          for (QueryDocumentSnapshot<Map<String, dynamic>> doc
              in querySnapshot.docs) {
            print('Documents fffffff');
            Map<String, dynamic> data = doc.data();
            String libelleArticle = data['LIBELLEARTICLE'];

            // Convert Timestamp to DateTime
            //String dateFact = (data['Datefact'] as Timestamp).toDate().toIso8601String();
            //String dateFact = (data['Datefact'] as Timestamp).toDate().toIso8601String();
            String dateFact = data['DATEFACT'].substring(0, 10);
            //DateTime dateFact = DateTime.parse(dateFacture);

            print(dateFact);
            print("DATEFACT");
            // Replace Timestamp with DateTime
            data['DATEFACT'] = dateFact;

            jsonDataList.add(data);
            print("data");
            print(data);
            if (uniqueDataMap.containsKey(libelleArticle)) {
              continue;
            } else {
              jsonUniqueDataList.add(data);
              uniqueDataMap[libelleArticle] = data;
            }
          }
          jsonUniqueDataList =
              uniqueDataMap.values.cast<Map<String, dynamic>>().toList();
          jsonUniqueDataList
              .sort((b, a) => a['DATEFACT'].compareTo(b['DATEFACT']));

          jsonDataList.sort((b, a) => a['DATEFACT'].compareTo(b['DATEFACT']));
          print('sorttttttttt');
          print(jsonUniqueDataList);
          // Save JSON data to local storage
          SharedPreferences prefs = await SharedPreferences.getInstance();
          String jsonString = jsonEncode(jsonDataList);
          String jsonUniqueString = jsonEncode(jsonUniqueDataList);
          await prefs.setString('factureData', jsonString);
          await prefs.setString('factureUniqueData', jsonUniqueString);
          print('Data saved to local storage.');
          print('Data 3adeya$jsonString');
          print('Data Unique$jsonUniqueString');
        }
        print('5rjt');
        // Check if the document exists
      } else {
        print('User is not signed indaaaaata');
// or throw an exception, depending on your error handling strategy
      }
    } catch (e) {
      print('Error retrieving data: $e');
    }
  }

  Map<String, dynamic>? mapData;
  Future<void> loadData() async {
    mapData = await lStorage.getStoredData('userData');
    if (mapData != null) {
      storedData = UserMapper.mapToUserData(mapData!);
      print('Stored Map Data: $storedData');
      // You can use storedData as needed in your widget
      setState(() {}); // Trigger a rebuild to update the UI
    }
    print('Stored Map Data: $storedData');
    // You can use storedData as needed in your widget
  }

  @override
  void initState() {
    super.initState();
    // Suppression de la vérification d'authentification
  }

  // Add ConsommablePage to the list of pages
  final List<Widget> _pages = [
    const EndShift(),
    const Achat(),
    const Caisse(),
    const ConsommablePage(),
  ];

  // Add "Consommable" to the list of page titles
  final List<String> _pagesTitle = [
    "EndShift",
    "Achat",
    "Caisse",
    "Consommable",
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void sendMail({
    required String recipientEmail,
    required String mailMessage,
  }) async {
    // change your email here
    String username = 'youssef.zmander@gmail.com';
    // change your password here
    String password = 'bilnwrnkybqfptmf';
    final smtpServer = gmail(username, password);
    final message = Message()
      ..from = Address(username, 'probleme Bosh Car')
      ..recipients.add(recipientEmail)
      ..subject = 'Issue With Boch Car service Sliti auto '
      ..text =
          'Message from ${storedData?.Email} Immat num ${storedData?.Plate}: $mailMessage';

    try {
      if (mailMessage != "") {
        await send(message, smtpServer).then(
          (value) => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Padding(
                padding: EdgeInsets.only(bottom: 10), // Add bottom margin here
                child: Text(
                  "Message envoyé ",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ), // Change font size here
                ),
              ),
              backgroundColor: const Color.fromARGB(
                  255, 0, 184, 3), // Change background color here
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30), // Change shape here
              ),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Padding(
            padding: EdgeInsets.only(bottom: 10), // Add bottom margin here
            child: Text(
              "Message vide non envoyée ",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ), // Change font size here
            ),
          ),
          backgroundColor: const Color.fromARGB(
              255, 242, 22, 22), // Change background color here
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30), // Change shape here
          ),
        ));
      }
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _pagesTitle[_currentIndex],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: const Icon(
            Icons.report,
            color: Color.fromARGB(255, 34, 21, 20),
            size: 30,
          ), // You can use any icon you want
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                String textValue = ''; // Variable to hold text field value
                return AlertDialog(
                  title: const Text(
                    'Signaler un problem',
                    style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
                  ),
                  content: TextField(
                    onChanged: (value) {
                      textValue =
                          value; // Update textValue when text field changes
                    },
                    decoration: const InputDecoration(hintText: 'Entrer text'),
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close dialog
                      },
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        // Do something with textValue, e.g., print it
                        print('Text entered: $textValue');
                        sendMail(
                            recipientEmail: 'hafedh.zd@gmail.com',
                            mailMessage: textValue);
                        Navigator.of(context).pop(); // Close dialog
                      },
                      child: const Text('OK'),
                    ),
                  ],
                );
              },
            );
          },
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminDashboard()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Deconection'),
                    content: const Text('Confirmer la deconection'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Auth().signOut();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const SignIn()),
                          );
                        },
                        child: const Text('OK'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.exit_to_app),
            label: 'EndShift',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Achat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: 'Caisse',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Consommable',
          ),
        ],
      ),
    );
  }
}
