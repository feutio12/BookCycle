import 'dart:convert';
import 'package:bookcycle/pages/enchere/payment_dialog.dart';
import 'package:bookcycle/pages/enchere/payment_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bookcycle/models/auction.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../composants/auction_components.dart';
import '../../composants/common_components.dart';
import '../../composants/common_utils.dart';
import '../auth/loginpage.dart';
import 'add_enchere.dart';
import 'auction_views.dart';
import 'card_details.dart';

class AuctionPage extends StatefulWidget {
  const AuctionPage({super.key});

  @override
  State<AuctionPage> createState() => _AuctionPageState();
}

class _AuctionPageState extends State<AuctionPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late Stream<QuerySnapshot> _streamEncheresActives;
  late Stream<QuerySnapshot> _streamEncheresTerminees;

  @override
  void initState() {
    super.initState();
    _chargerEncheres();
  }

  void _chargerEncheres() {
    _streamEncheresActives = _firestore
        .collection('encheres')
        .where('dateFin', isGreaterThan: DateTime.now())
        .orderBy('dateFin')
        .snapshots();

    _streamEncheresTerminees = _firestore
        .collection('encheres')
        .where('dateFin', isLessThan: DateTime.now())
        .orderBy('dateFin', descending: true)
        .snapshots();
  }

  bool _estConnecte() => _auth.currentUser != null;

  void _afficherMessageConnexion(String action) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Connexion requise'),
        content: Text('Connectez-vous pour $action'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Se connecter'),
          ),
        ],
      ),
    );
  }

  Future<void> _placerOffre(Enchere enchere) async {
    if (!enchere.estActive) {
      AppUtils.showErrorSnackBar(context, 'Cette enchère est terminée, vous ne pouvez plus faire d\'offres');
      return;
    }

    if (!_estConnecte()) {
      _afficherMessageConnexion('placer une offre');
      return;
    }

    final controleurOffre = TextEditingController();
    final cleFormulaire = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nouvelle offre'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Form(
          key: cleFormulaire,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Livre: ${enchere.titre}', style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface
              )),
              const SizedBox(height: 16),
              Text('Offre actuelle: ${enchere.prixActuel.toStringAsFixed(2)} fcfa',
                  style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.primary)),
              const SizedBox(height: 16),
              FormTextField(
                controller: controleurOffre,
                label: 'Votre offre (fcfa)',
                isNumber: true,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Veuillez entrer un montant';
                  final offre = double.tryParse(value);
                  if (offre == null) return 'Montant invalide';
                  if (offre <= enchere.prixActuel) return 'L\'offre doit être supérieure à ${enchere.prixActuel.toStringAsFixed(2)} fcfa';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')
          ),
          ElevatedButton(
            onPressed: () async {
              if (cleFormulaire.currentState!.validate()) {
                final nouvelleOffre = double.parse(controleurOffre.text);

                // Afficher le dialogue de paiement
                final paymentResult = await _processPayment(nouvelleOffre, enchere);

                if (paymentResult['success'] == true) {
                  try {
                    await _firestore.collection('encheres').doc(enchere.id).update({
                      'prixActuel': nouvelleOffre,
                      'nombreEncherisseurs': FieldValue.increment(1),
                      'dernierEncherisseur': _auth.currentUser!.uid,
                      'derniereOffre': FieldValue.serverTimestamp(),
                    });

                    await _firestore.collection('encheres').doc(enchere.id)
                        .collection('offres').add({
                      'montant': nouvelleOffre,
                      'userId': _auth.currentUser!.uid,
                      'userName': _auth.currentUser!.displayName ?? 'Utilisateur',
                      'date': FieldValue.serverTimestamp(),
                      'type': 'offre_utilisateur',
                      'paymentIntentId': paymentResult['paymentIntentId'],
                      'paymentStatus': 'reserved'
                    });

                    Navigator.pop(ctx);
                    AppUtils.showSuccessSnackBar(context, 'Offre soumise avec succès! Paiement réservé.');
                  } catch (e) {
                    Navigator.pop(ctx);
                    AppUtils.showErrorSnackBar(context, 'Erreur: ${e.toString()}');
                  }
                } else {
                  AppUtils.showErrorSnackBar(context, 'Erreur de paiement: ${paymentResult['error']}');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF1976D2),
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Payer et confirmer'),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _processPayment(double amount, Enchere enchere) async {
    // Créer l'intention de paiement
    final paymentIntent = await PaymentService.createPaymentIntent(
        amount,
        'xof', // XOF pour le Franc CFA
        enchere.id,
        _auth.currentUser!.uid
    );

    // Afficher l'interface de paiement
    final cardDetails = await showDialog<CardDetails>(
      context: context,
      builder: (ctx) => PaymentDialog(
        clientSecret: paymentIntent['client_secret'],
        amount: amount,
      ),
    );

    if (cardDetails != null) {
      // Confirmer le paiement
      return await PaymentService.confirmPayment(paymentIntent['client_secret'], cardDetails);
    }

    return {'success': false, 'error': 'Paiement annulé'};
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        appBar: AppBar(
          title: const Text( 'Enchères BookCycle',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          backgroundColor: const Color(0xFF42A5F5),
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: Colors.blue.shade200,
          bottom: TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3.0,
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.7),
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
            ),
            tabs: const [
              Tab(
                icon: Icon(Icons.timer, size: 20),
                text: 'En cours',
              ),
              Tab(
                icon: Icon(Icons.history, size: 20),
                text: 'Terminées',
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.refresh,
                color: Colors.white,
                size: 24,
              ),
              onPressed: _chargerEncheres,
            ),
          ],
        ),
        body: TabBarView(
          children: [
            AuctionViews.buildOngletEncheres(
                context,
                _streamEncheresActives,
                true,
                _estConnecte(),
                _chargerEncheres,
                _afficherDetailsEnchere,
                _placerOffre,
                _afficherMessageConnexion
            ),
            AuctionViews.buildOngletEncheres(
                context,
                _streamEncheresTerminees,
                false,
                _estConnecte(),
                _chargerEncheres,
                _afficherDetailsEnchere,
                _placerOffre,
                _afficherMessageConnexion
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            if (!_estConnecte()) {
              _afficherMessageConnexion('créer une enchère');
            } else {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AddEncherePage(isGuest: false)));
            }
          },
          backgroundColor: Color(0xFF1976D2),
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.add, size: 28),
        ),
      ),
    );
  }

  void _afficherDetailsEnchere(Enchere enchere) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => AuctionViews.buildDetailsEnchere(
          ctx,
          enchere,
          _estConnecte(),
          _placerOffre,
          _afficherMessageConnexion
      ),
    );
  }
}