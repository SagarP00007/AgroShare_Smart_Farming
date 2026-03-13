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

  int get nextId => _bookings.length + 1;
}
