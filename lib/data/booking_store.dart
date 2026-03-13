import '../models/booking.dart';

/// Simple in-memory booking store.
///
/// Holds all bookings created during the session. This will be
/// consumed by the My Bookings screen in a later brick.
class BookingStore {
  BookingStore._();

  static final BookingStore instance = BookingStore._();

  final List<Booking> _bookings = [];

  List<Booking> get bookings => List.unmodifiable(_bookings);

  void add(Booking booking) => _bookings.add(booking);

  void updateStatus(String id, BookingStatus status) {
    final idx = _bookings.indexWhere((b) => b.id == id);
    if (idx != -1) {
      _bookings[idx].status = status;
    }
  }

  void completeBooking(String id, double rating, String reviewText) {
    final idx = _bookings.indexWhere((b) => b.id == id);
    if (idx != -1) {
      _bookings[idx].status = BookingStatus.completed;
      _bookings[idx].rating = rating;
      _bookings[idx].reviewText = reviewText;
    }
  }

  int get nextId => _bookings.length + 1;
}
