class AdminReport {
  final DateTime startDate;
  final DateTime endDate;
  final int newUsers;
  final int booksAdded;
  final int auctionsCreated;
  final int transactionsCompleted;
  final double revenue;

  AdminReport({
    required this.startDate,
    required this.endDate,
    required this.newUsers,
    required this.booksAdded,
    required this.auctionsCreated,
    required this.transactionsCompleted,
    required this.revenue,
  });

  Map<String, dynamic> toMap() {
    return {
      'startDate': startDate,
      'endDate': endDate,
      'newUsers': newUsers,
      'booksAdded': booksAdded,
      'auctionsCreated': auctionsCreated,
      'transactionsCompleted': transactionsCompleted,
      'revenue': revenue,
    };
  }
}