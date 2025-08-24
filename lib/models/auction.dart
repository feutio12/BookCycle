import 'package:cloud_firestore/cloud_firestore.dart';

class Enchere {
  final String id;
  final String titre;
  final String description;
  final double prixDepart;
  late final double prixActuel;
  final DateTime dateFin;
  final String imageUrl;
  late final int nombreEncherisseurs;
  final bool estActive;
  final String etatLivre;
  final String? gagnant;
  late final String? dernierEncherisseur;
  late final DateTime? derniereOffre;

  Enchere({
    required this.id,
    required this.titre,
    required this.description,
    required this.prixDepart,
    required this.prixActuel,
    required this.dateFin,
    required this.imageUrl,
    this.nombreEncherisseurs = 0,
    this.estActive = true,
    required this.etatLivre,
    this.gagnant,
    this.dernierEncherisseur,
    this.derniereOffre,
  });

  factory Enchere.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Enchere(
      id: doc.id,
      titre: data['titre'] ?? 'Sans titre',
      description: data['description'] ?? '',
      prixDepart: (data['prixDepart'] as num).toDouble(),
      prixActuel: (data['prixActuel'] as num).toDouble(),
      dateFin: (data['dateFin'] as Timestamp).toDate(),
      imageUrl: data['imageUrl'] ?? '',
      nombreEncherisseurs: data['nombreEncherisseurs'] ?? 0,
      estActive: data['estActive'] ?? true,
      etatLivre: data['etatLivre'] ?? 'Non spécifié',
      gagnant: data['gagnant'],
      dernierEncherisseur: data['dernierEncherisseur'],
      derniereOffre: data['derniereOffre']?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'titre': titre,
      'description': description,
      'prixDepart': prixDepart,
      'prixActuel': prixActuel,
      'dateFin': dateFin,
      'imageUrl': imageUrl,
      'nombreEncherisseurs': nombreEncherisseurs,
      'estActive': estActive,
      'etatLivre': etatLivre,
      'gagnant': gagnant,
      'dernierEncherisseur': dernierEncherisseur,
      'derniereOffre': derniereOffre,
    };
  }

  String get tempsRestant {
    final maintenant = DateTime.now();
    if (dateFin.isBefore(maintenant)) return 'Terminée';

    final difference = dateFin.difference(maintenant);

    if (difference.inDays > 0) {
      return '${difference.inDays}j ${difference.inHours.remainder(24)}h';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ${difference.inMinutes.remainder(60)}m';
    } else {
      return '${difference.inMinutes}m';
    }
  }

  bool get estTerminee => dateFin.isBefore(DateTime.now());

  get createurNom => null;

  get nombrePages => null;

  get categorie => null;

  void mettreAJourOffre(double nouveauPrix, String encherisseurId) {
    prixActuel = nouveauPrix;
    nombreEncherisseurs++;
    dernierEncherisseur = encherisseurId;
    derniereOffre = DateTime.now();
  }
}