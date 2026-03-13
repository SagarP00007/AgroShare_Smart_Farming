/// Represents a booking for a piece of farm equipment.
class Booking {
  Booking({
    required this.id,
    required this.equipmentId,
    required this.equipmentName,
    required this.date,
    required this.durationHours,
    required this.totalCost,
    this.status = BookingStatus.upcoming,
    this.rating,
    this.reviewText,
  });

  final String id;
  final String equipmentId;
  final String equipmentName;
  final DateTime date;
  final int durationHours;
  final double totalCost;
  BookingStatus status;
  double? rating;
  String? reviewText;
}

/// Possible states of a booking.
enum BookingStatus {
  upcoming,
  active,
  completed,
}
