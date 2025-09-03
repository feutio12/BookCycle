import 'package:cloud_firestore/cloud_firestore.dart';

class Enchere {
  final String id;
  final String titre;
  final String imageUrl; // Ajoutez ce champ
  final String? description;
  final double prixActuel;
  final double? prixDepart;
  final DateTime dateFin;
  final String? etatLivre;
  final String? gagnant;
  final bool estActive;

  Enchere({
    required this.id,
    required this.titre,
    required this.imageUrl, // Ajoutez ce champ
    this.description,
    required this.prixActuel,
    this.prixDepart,
    required this.dateFin,
    this.etatLivre,
    this.gagnant,
    required this.estActive,
  });

  factory Enchere.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Enchere(
      id: doc.id,
      titre: data['titre'] ?? 'Sans titre',
      imageUrl: data['imageUrl'] ?? '', // Ajoutez ce champ
      description: data['description'],
      prixActuel: (data['prixActuel'] as num?)?.toDouble() ?? 0.0,
      prixDepart: (data['prixDepart'] as num?)?.toDouble(),
      dateFin: (data['dateFin'] as Timestamp).toDate(),
      etatLivre: data['etatLivre'],
      gagnant: data['gagnant'],
      estActive: data['dateFin'] != null
          ? (data['dateFin'] as Timestamp).toDate().isAfter(DateTime.now())
          : false,
    );
  }
}