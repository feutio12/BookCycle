class AdminStats {
  final int totalUsers;
  final int activeUsers;
  final int totalBooks;
  final int availableBooks;
  final int totalAuctions;
  final int activeAuctions;
  final int totalTransactions;
  final double totalRevenue;

  AdminStats({
    required this.totalUsers,
    required this.activeUsers,
    required this.totalBooks,
    required this.availableBooks,
    required this.totalAuctions,
    required this.activeAuctions,
    required this.totalTransactions,
    required this.totalRevenue,
  });

  factory AdminStats.fromMap(Map<String, dynamic> data) {
    return AdminStats(
      totalUsers: data['totalUsers'] ?? 0,
      activeUsers: data['activeUsers'] ?? 0,
      totalBooks: data['totalBooks'] ?? 0,
      availableBooks: data['availableBooks'] ?? 0,
      totalAuctions: data['totalAuctions'] ?? 0,
      activeAuctions: data['activeAuctions'] ?? 0,
      totalTransactions: data['totalTransactions'] ?? 0,
      totalRevenue: data['totalRevenue']?.toDouble() ?? 0.0,
    );
  }
}