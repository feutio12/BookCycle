class Auction {
  final String id;
  final String title;
  final String? description;
  final double currentBid;
  final double? startingPrice;
  final DateTime endTime;
  final String? imageUrl;
  final int? bidderCount;
  final String? winner;
  final bool isActive;
  final String? bookCondition;
  final String? sellerId;

  Auction({
    required this.id,
    required this.title,
    this.description,
    required this.currentBid,
    this.startingPrice,
    required this.endTime,
    this.imageUrl,
    this.bidderCount,
    this.winner,
    required this.isActive,
    this.bookCondition,
    this.sellerId,
  });

  factory Auction.fromMap(Map<String, dynamic> map) {
    return Auction(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      currentBid: map['currentBid']?.toDouble() ?? 0.0,
      startingPrice: map['startingPrice']?.toDouble(),
      endTime: DateTime.parse(map['endTime']),
      imageUrl: map['imageUrl'],
      bidderCount: map['bidderCount'],
      winner: map['winner'],
      isActive: map['isActive'] ?? false,
      bookCondition: map['bookCondition'],
      sellerId: map['sellerId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'currentBid': currentBid,
      'startingPrice': startingPrice,
      'endTime': endTime.toIso8601String(),
      'imageUrl': imageUrl,
      'bidderCount': bidderCount,
      'winner': winner,
      'isActive': isActive,
      'bookCondition': bookCondition,
      'sellerId': sellerId,
    };
  }

  String get timeLeft {
    final now = DateTime.now();
    if (endTime.isBefore(now)) return 'Terminée';

    final difference = endTime.difference(now);
    return '${difference.inHours}h ${difference.inMinutes.remainder(60)}m';
  }
}