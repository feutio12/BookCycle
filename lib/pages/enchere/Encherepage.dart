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
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
            },
            child: const Text('Se connecter'),
          ),
        ],
      ),
    );
  }

  Widget _construireOngletEncheres(Stream<QuerySnapshot> streamEncheres, bool estActif) {
    return StreamBuilder<QuerySnapshot>(
      stream: streamEncheres,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator();
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        final encheres = snapshot.data?.docs.map((doc) => Enchere.fromFirestore(doc)).toList() ?? [];

        if (encheres.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  estActif ? Icons.hourglass_empty : Icons.history_toggle_off,
                  size: 60,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(estActif ? 'Aucune enchère en cours' : 'Aucune enchère terminée'),
                if (estActif && !_estConnecte()) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Connectez-vous pour créer la première enchère !',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _chargerEncheres(),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: encheres.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final enchere = encheres[index];
              return AuctionCard(
                enchere: enchere,
                onTap: () => _afficherDetailsEnchere(context, enchere),
                actions: [
                  if (estActif && enchere.estActive)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16)),
                      onPressed: () {
                        if (!_estConnecte()) {
                          _afficherMessageConnexion('placer une offre');
                        } else {
                          _placerOffre(enchere);
                        }
                      },
                      child: const Text('Enchérir'),
                    ),
                  TextButton(
                    onPressed: () => _afficherDetailsEnchere(context, enchere),
                    child: const Text('Détails'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _afficherDetailsEnchere(BuildContext context, Enchere enchere) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _construireDetailsEnchere(ctx, enchere),
    );
  }

  Widget _construireDetailsEnchere(BuildContext context, Enchere enchere) {
    final estConnecte = _estConnecte();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                enchere.imageUrl ?? 'https://picsum.photos/400/300?book',
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, size: 50),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(enchere.titre, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (enchere.description != null) Text(enchere.description!, style: Theme.of(context).textTheme.bodyMedium),
          const Divider(height: 32),
          AuctionDetailItem(
            icon: Icons.attach_money,
            label: 'Prix ${enchere.estActive ? 'actuel' : 'final'}',
            valeur: '${enchere.prixActuel.toStringAsFixed(2)} €', value: '',
          ),
          if (enchere.prixDepart != null)
            AuctionDetailItem(
              icon: Icons.price_change,
              label: 'Prix de départ',
              valeur: '${enchere.prixDepart!.toStringAsFixed(2)} €', value: '',
            ),
          AuctionDetailItem(
            icon: enchere.estActive ? Icons.timer : Icons.history,
            label: enchere.estActive ? 'Temps restant' : 'Statut',
            valeur: enchere.estActive
                ? _formaterTempsRestant(enchere.dateFin)
                : 'Terminée le ${DateFormat('dd/MM/yyyy').format(enchere.dateFin)}', value: '',
          ),
          if (enchere.etatLivre != null)
            AuctionDetailItem(
              icon: Icons.star,
              label: 'État du livre',
              valeur: enchere.etatLivre!, value: '',
            ),
          if (!enchere.estActive && enchere.gagnant != null)
            AuctionDetailItem(
              icon: Icons.emoji_events,
              label: 'Gagnant',
              valeur: enchere.gagnant!, value: '',
            ),
          if (!estConnecte && enchere.estActive) ...[
            const SizedBox(height: 20),
            InfoMessage(
              message: 'Connectez-vous pour placer une offre',
              icon: Icons.info_outline,
              color: Colors.blue,
            ),
          ],
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
              if (enchere.estActive) ...[
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (!estConnecte) {
                      Navigator.pop(context);
                      _afficherMessageConnexion('placer une offre');
                    } else {
                      _placerOffre(enchere);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Faire une offre'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _formaterTempsRestant(DateTime dateFin) {
    final difference = dateFin.difference(DateTime.now());
    if (difference.inDays > 0) return '${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    if (difference.inHours > 0) return '${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    if (difference.inMinutes > 0) return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    return 'Moins d\'une minute';
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
        content: Form(
          key: cleFormulaire,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Livre: ${enchere.titre}'),
              const SizedBox(height: 16),
              Text('Offre actuelle: ${enchere.prixActuel.toStringAsFixed(2)} €', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              FormTextField(
                controller: controleurOffre,
                label: 'Votre offre (€)',
                isNumber: true,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Veuillez entrer un montant';
                  final offre = double.tryParse(value);
                  if (offre == null) return 'Montant invalide';
                  if (offre <= enchere.prixActuel) return 'L\'offre doit être supérieure à ${enchere.prixActuel.toStringAsFixed(2)} €';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (cleFormulaire.currentState!.validate()) {
                final nouvelleOffre = double.parse(controleurOffre.text);
                try {
                  // Mettre à jour l'enchère principale
                  await _firestore.collection('encheres').doc(enchere.id).update({
                    'prixActuel': nouvelleOffre,
                    'nombreEncherisseurs': FieldValue.increment(1),
                    'dernierEncherisseur': _auth.currentUser!.uid,
                    'derniereOffre': FieldValue.serverTimestamp(),
                  });

                  // Ajouter l'offre à la sous-collection
                  await _firestore.collection('encheres').doc(enchere.id)
                      .collection('offres').add({
                    'montant': nouvelleOffre,
                    'userId': _auth.currentUser!.uid,
                    'userName': _auth.currentUser!.displayName ?? 'Utilisateur',
                    'date': FieldValue.serverTimestamp(),
                    'type': 'offre_utilisateur'
                  });

                  Navigator.pop(ctx);
                  AppUtils.showSuccessSnackBar(context, 'Offre soumise avec succès!');
                } catch (e) {
                  Navigator.pop(ctx);
                  AppUtils.showErrorSnackBar(context, 'Erreur: ${e.toString()}');
                }
              }
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Enchères BookCycle'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.timer), text: 'En cours'),
              Tab(icon: Icon(Icons.history), text: 'Terminées'),
            ],
          ),
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _chargerEncheres),
            IconButton(
              icon: const Icon(Icons.add_box_sharp),
              onPressed: () {
                if (!_estConnecte()) {
                  _afficherMessageConnexion('créer une enchère');
                } else {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AddEncherePage(isGuest: false)));
                }
              },
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _construireOngletEncheres(_streamEncheresActives, true),
            _construireOngletEncheres(_streamEncheresTerminees, false),
          ],
        ),
      ),
    );
  }
}