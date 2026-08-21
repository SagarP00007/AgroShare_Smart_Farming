/// Local in-memory store for user reports (demo purposes).
class ReportStore {
  ReportStore._();

  static final List<UserReport> _reports = [];

  /// All submitted reports.
  static List<UserReport> get reports => List.unmodifiable(_reports);

  /// Submit a new report.
  static void submit(UserReport report) => _reports.add(report);
}

/// A single user report entry.
class UserReport {
  const UserReport({
    required this.reportedUser,
    required this.reason,
    required this.timestamp,
  });

  final String reportedUser;

  /// One of: 'Fraud', 'Fake listing', 'Misbehavior'.
  final String reason;

  final DateTime timestamp;

  @override
  String toString() => 'Report($reportedUser, $reason, $timestamp)';
}
