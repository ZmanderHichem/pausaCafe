import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'stock_management.dart';
import 'caisse_management.dart';
import 'consommable_management.dart';

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
  bool _isLoading = true;

  final StockManagement _stockManagement = StockManagement();
  final CaisseManagement _caisseManagement = CaisseManagement();
  final ConsommableManagement _consommableManagement = ConsommableManagement();

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
    _stockManagement.dispose();
    super.dispose();
  }

  void _showPasswordPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white.withOpacity(0.9),
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
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
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
      await _stockManagement.loadStockData();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur de chargement : $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) return Center(child: Text(_errorMessage!));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        centerTitle: true,
        backgroundColor: Colors.white.withOpacity(0.9),
      ),
      body: Container(
        color: Colors.white.withOpacity(0.9),
        child: _isAuthenticated
            ? SingleChildScrollView(
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () =>
                          _stockManagement.showStockInitPopup(context),
                      child: const Text('Initialiser Stock'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _caisseManagement.toggleCaisseData();
                          if (_caisseManagement.showCaisseData) {
                            _caisseManagement.loadCaisseData();
                          }
                        });
                      },
                      child: const Text('Caisse'),
                    ),
                    ElevatedButton(
                      onPressed: () => _consommableManagement
                          .showConsommableInitPopup(context),
                      child: const Text('Consommables'),
                    ),
                    if (_caisseManagement.showCaisseData)
                      _caisseManagement.buildCaisseList(context),
                    _stockManagement.buildStockStream(),
                    const SizedBox(height: 20),
                    _consommableManagement.buildConsommableStream(),
                  ],
                ),
              )
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
