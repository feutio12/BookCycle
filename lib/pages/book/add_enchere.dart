import 'dart:async';
import 'dart:io';
import 'package:bookcycle/pages/homepage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../composants/common_components.dart';
import '../../composants/common_utils.dart';

class AddEncherePage extends StatefulWidget {
  final bool isGuest;
  const AddEncherePage({super.key, required this.isGuest});

  @override
  State<AddEncherePage> createState() => _AddEncherePageState();
}

class _AddEncherePageState extends State<AddEncherePage> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = {
    'titre': TextEditingController(),
    'description': TextEditingController(),
    'prixDepart': TextEditingController(),
    'etat': TextEditingController(),
  };

  File? _imageFile;
  DateTime _dateFin = DateTime.now().add(const Duration(days: 7));
  bool _isLoading = false;
  String? _uploadError;
  bool _hasPostedAsGuest = false;

  @override
  void initState() {
    super.initState();
    _checkGuestPostingStatus();
  }

  Future<void> _checkGuestPostingStatus() async {
    final hasPosted = await AppUtils.checkGuestPostingStatus();
    setState(() => _hasPostedAsGuest = hasPosted);
  }

  @override
  void dispose() {
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final file = await AppUtils.pickImage();
      if (file != null) {
        setState(() {
          _imageFile = file;
          _uploadError = null;
        });
      }
    } catch (e) {
      AppUtils.showErrorSnackBar(context, e.toString());
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateFin,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _dateFin) {
      setState(() => _dateFin = picked);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageFile == null) {
      AppUtils.showErrorSnackBar(context, 'Veuillez ajouter une image');
      return;
    }

    if (widget.isGuest && _hasPostedAsGuest) {
      AppUtils.showErrorSnackBar(context, 'Connectez-vous pour créer plus d\'enchères');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final imageBase64 = await AppUtils.convertImageToBase64(_imageFile);
      if (imageBase64 == null) return;

      final enchereData = await _prepareEnchereData(imageBase64);
      await _saveEnchereToFirestore(enchereData);

      if (widget.isGuest) {
        await AppUtils.setGuestPostingStatus(true);
      }

      AppUtils.showSuccessSnackBar(context, 'Enchère créée avec succès');
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    } catch (e) {
      _showErrorMessage(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>> _prepareEnchereData(String imageBase64) async {
    final user = FirebaseAuth.instance.currentUser;

    return {
      'titre': _controllers['titre']!.text.trim(),
      'description': _controllers['description']!.text.trim(),
      'prixDepart': double.parse(_controllers['prixDepart']!.text),
      'prixActuel': double.parse(_controllers['prixDepart']!.text),
      'dateFin': Timestamp.fromDate(_dateFin),
      'dateCreation': FieldValue.serverTimestamp(),
      'etatLivre': _controllers['etat']!.text.trim(),
      'imageUrl': imageBase64,
      'statut': 'active',
      'nombreEncherisseurs': 0,
      'createurId': user?.uid ?? 'guest',
      'createurNom': user?.displayName ?? 'Anonyme',
      'createurEmail': user?.email,
      'dernierEncherisseur': null,
      'derniereOffre': null,
    };
  }

  Future<void> _saveEnchereToFirestore(Map<String, dynamic> enchereData) async {
    final docRef = await FirebaseFirestore.instance.collection('encheres')
        .add(enchereData)
        .timeout(const Duration(seconds: 10));

    await docRef.collection('offres').add({
      'montant': enchereData['prixDepart'],
      'userId': enchereData['createurId'],
      'userName': enchereData['createurNom'],
      'date': FieldValue.serverTimestamp(),
      'type': 'offre_initiale',
    });
  }

  void _showErrorMessage(dynamic error) {
    String message = 'Erreur inconnue';
    if (error is FirebaseException) {
      message = 'Erreur Firestore: ${error.message}';
    } else if (error is TimeoutException) {
      message = 'Timeout - Vérifiez votre connexion';
    } else {
      message = 'Erreur: ${error.toString()}';
    }
    AppUtils.showErrorSnackBar(context, message);
  }

  Widget _buildFormField(String label, String key, {bool isNumber = false}) {
    return FormTextField(
      controller: _controllers[key]!,
      label: label,
      isNumber: isNumber,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Ce champ est requis';
        if (isNumber) {
          final amount = double.tryParse(value);
          if (amount == null) return 'Entrez un montant valide';
          if (amount <= 0) return 'Le montant doit être positif';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const LoadingIndicator(message: 'Création de l\'enchère...');

    return Scaffold(
      appBar: AppBar(title: const Text('Créer une enchère')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              ImagePickerWidget(
                imageFile: _imageFile,
                onTap: _pickImage,
                errorMessage: _uploadError,
              ),
              const SizedBox(height: 20),
              _buildFormField('Titre du livre*', 'titre'),
              const SizedBox(height: 16),
              _buildFormField('Description', 'description'),
              const SizedBox(height: 16),
              _buildFormField('Prix de départ*', 'prixDepart', isNumber: true),
              const SizedBox(height: 16),
              _buildFormField('État du livre', 'etat'),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date de fin*',
                    border: OutlineInputBorder(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('dd/MM/yyyy').format(_dateFin)),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: 'PUBLIER L\'ENCHÈRE',
                onPressed: _submitForm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}