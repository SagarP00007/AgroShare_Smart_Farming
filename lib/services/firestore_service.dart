import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

import '../models/booking.dart';
import '../models/equipment.dart';
import '../models/equipment_request.dart';
import '../models/equipment_request_response.dart';
import '../models/farmer.dart';
import '../models/payment.dart';

/// Central Firestore CRUD service for AgroShare.
class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Sanitize a map for Firestore: valid field names, no nulls, valid types only.
  static Map<String, dynamic> _sanitizeForFirestore(Map<String, dynamic>? data) {
    if (data == null) return {};
    final out = <String, dynamic>{};
    for (final entry in data.entries) {
      final key = entry.key;
      if (key.contains('.') ||
          key.contains('*') ||
          key.contains('~') ||
          key.contains('[') ||
          key.contains(']') ||
          key.contains('/')) {
        continue; // skip invalid field names
      }
      final v = entry.value;
      if (v == null) continue; // do not write null
      if (v is DateTime) {
        out[key] = Timestamp.fromDate(v);
      } else if (v is num) {
        if (v.isNaN || !v.isFinite) {
          out[key] = 0;
        } else {
          out[key] = v;
        }
      } else if (v is Map) {
        out[key] = _sanitizeForFirestore(Map<String, dynamic>.from(v));
      } else if (v is List) {
        out[key] = v.map((e) {
          if (e == null) return '';
          if (e is Map) return _sanitizeForFirestore(Map<String, dynamic>.from(e));
          if (e is DateTime) return Timestamp.fromDate(e);
          if (e is num && (e.isNaN || !e.isFinite)) return 0;
          return e;
        }).toList();
      } else if (v is LatLng) {
        out[key] = <String, double>{
          'lat': v.latitude,
          'lng': v.longitude,
        };
      } else if (v is String || v is bool || v is Timestamp || v is FieldValue) {
        out[key] = v;
      }
      // skip other types (e.g. custom objects)
    }
    return out;
  }

  // Simple connectivity test collection
  CollectionReference get _test => _db.collection('test');

  // ── Collections ────────────────────────────────────────────────
  CollectionReference get _users => _db.collection('users');
  CollectionReference get _equipment => _db.collection('equipment');
  CollectionReference get _bookings => _db.collection('bookings');
  CollectionReference get _groups => _db.collection('community_groups');
  CollectionReference get _reviews => _db.collection('reviews');
  CollectionReference get _chats => _db.collection('chats');
  CollectionReference get _requests => _db.collection('equipment_requests');
  CollectionReference get _requestResponses => _db.collection('equipment_request_responses');
  CollectionReference get _payments => _db.collection('payments');

  /// Write a small test document to confirm Firestore connectivity.
  Future<void> writeConnectionTest() async {
    try {
      await _test.add(_sanitizeForFirestore({
        'message': 'Firebase connected',
        'timestamp': FieldValue.serverTimestamp(),
      }));
    } catch (e) {
      // Best-effort connectivity check; avoid crashing the app on failure.
      // ignore: avoid_print
      print('Firestore connectivity test failed: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════
  // USERS
  // ══════════════════════════════════════════════════════════════

  /// Get user profile document.
  Future<DocumentSnapshot> getUser(String uid) => _users.doc(uid).get();

  /// Stream a user profile.
  Stream<DocumentSnapshot> userStream(String uid) => _users.doc(uid).snapshots();

  /// Update user profile fields.
  Future<void> updateProfile(String uid, Map<String, dynamic> data) {
    try {
      final sanitized = _sanitizeForFirestore(data);
      if (sanitized.isEmpty) return Future.value();
      return _users.doc(uid).update(sanitized);
    } catch (e) {
      // ignore: avoid_print
      print('Firestore updateProfile error: $e');
      rethrow;
    }
  }

  // ══════════════════════════════════════════════════════════════
  // EQUIPMENT
  // ══════════════════════════════════════════════════════════════

  final List<Map<String, dynamic>> _localEquipmentStore = [];

  List<Equipment> getFallbackEquipment() {
    final list = <Equipment>[
      const Equipment(
        id: 'seed_1',
        name: 'Mahindra Tractor 575 DI',
        pricePerHour: 500.0,
        distance: 2.0,
        rating: 4.7,
        reviewCount: 24,
        imageUrl: 'assets/images/tractor.webp',
        ownerName: 'Rajesh Kumar',
        ownerId: 'seed',
        description: 'Powerful 45 HP tractor ideal for ploughing, tilling, and hauling. Well-maintained with AC cabin.',
        locationName: 'Angondhalli',
        latitude: 12.9650,
        longitude: 77.6000,
        isAvailable: true,
        purchasePrice: 250000.0,
        listingType: 'rent',
        contactNumber: '+91 98765 43210',
      ),
      const Equipment(
        id: 'seed_2',
        name: 'Mini Harvester',
        pricePerHour: 800.0,
        distance: 3.0,
        rating: 4.5,
        reviewCount: 12,
        imageUrl: 'assets/images/harvester.webp',
        ownerName: 'Sunil Patil',
        ownerId: 'seed',
        description: 'Compact combine harvester suitable for wheat and rice. High efficiency with low grain loss.',
        locationName: 'Ramapur',
        latitude: 12.9800,
        longitude: 77.5850,
        isAvailable: true,
        purchasePrice: 350000.0,
        listingType: 'buy',
        contactNumber: '+91 98765 43211',
      ),
      const Equipment(
        id: 'seed_3',
        name: 'Irrigation Pump Set',
        pricePerHour: 200.0,
        distance: 1.5,
        rating: 4.2,
        reviewCount: 8,
        imageUrl: 'assets/images/pump.webp',
        ownerName: 'Anita Sharma',
        ownerId: 'seed',
        description: '5 HP diesel pump with 100m pipe set. Perfect for field irrigation during dry spells.',
        locationName: 'Kengeri',
        latitude: 12.9550,
        longitude: 77.5700,
        isAvailable: true,
        purchasePrice: 45000.0,
        listingType: 'rent',
        contactNumber: '+91 98765 43212',
      ),
      const Equipment(
        id: 'seed_4',
        name: 'Rotavator',
        pricePerHour: 600.0,
        distance: 4.0,
        rating: 4.8,
        reviewCount: 36,
        imageUrl: 'assets/images/rotavator.webp',
        ownerName: 'Vikram Singh',
        ownerId: 'seed',
        description: 'Heavy-duty rotavator for soil preparation. 48 blades, 6-foot working width.',
        locationName: 'Yelahanka',
        latitude: 12.9900,
        longitude: 77.6100,
        isAvailable: true,
        purchasePrice: 180000.0,
        listingType: 'buy',
        contactNumber: '+91 98765 43213',
      ),
      const Equipment(
        id: 'seed_5',
        name: 'Seed Drill Machine',
        pricePerHour: 350.0,
        distance: 2.5,
        rating: 4.4,
        reviewCount: 15,
        imageUrl: 'assets/images/seed_drill.webp',
        ownerName: 'Priya Desai',
        ownerId: 'seed',
        description: 'Precision seed drill with 9-row capacity. Ensures even seed spacing and depth.',
        locationName: 'Whitefield',
        latitude: 12.9750,
        longitude: 77.6200,
        isAvailable: true,
        purchasePrice: 120000.0,
        listingType: 'rent',
        contactNumber: '+91 98765 43214',
      ),
      const Equipment(
        id: 'seed_6',
        name: 'Crop Sprayer',
        pricePerHour: 250.0,
        distance: 1.8,
        rating: 4.3,
        reviewCount: 19,
        imageUrl: 'assets/images/sprayer.webp',
        ownerName: 'Mohan Reddy',
        ownerId: 'seed',
        description: 'Boom sprayer with 200L tank capacity. Ideal for pesticide and fertilizer application.',
        locationName: 'Hebbal',
        latitude: 12.9600,
        longitude: 77.5800,
        isAvailable: true,
        purchasePrice: 75000.0,
        listingType: 'buy',
        contactNumber: '+91 98765 43215',
      ),
    ];

    for (var i = 0; i < _localEquipmentStore.length; i++) {
      final data = _localEquipmentStore[i];
      list.insert(0, Equipment.fromMap(data['id'] ?? 'local_$i', data));
    }
    return list;
  }

  List<Booking> getFallbackBookings() {
    return [
      Booking(
        id: 'bk_1',
        userId: 'demo',
        equipmentId: 'seed_1',
        equipmentName: 'Mahindra Tractor 575 DI',
        date: DateTime.now().add(const Duration(days: 1)),
        durationHours: 5,
        totalCost: 2500.0,
        status: BookingStatus.upcoming,
      ),
      Booking(
        id: 'bk_2',
        userId: 'demo',
        equipmentId: 'seed_2',
        equipmentName: 'Mini Harvester',
        date: DateTime.now(),
        durationHours: 8,
        totalCost: 6400.0,
        status: BookingStatus.active,
      ),
      Booking(
        id: 'bk_3',
        userId: 'demo',
        equipmentId: 'seed_3',
        equipmentName: 'Irrigation Pump Set',
        date: DateTime.now().subtract(const Duration(days: 5)),
        durationHours: 4,
        totalCost: 800.0,
        status: BookingStatus.completed,
        rating: 5.0,
        reviewText: 'Excellent pump, started in one crank!',
      ),
    ];
  }

  List<Map<String, dynamic>> getFallbackGroupMaps() {
    return [
      {
        'id': 'grp_1',
        'equipmentType': 'Mahindra 575 DI Tractor',
        'currentMembers': 3,
        'targetMembers': 4,
        'targetPrice': 250000.0,
        'locationName': 'Mandya District',
        'status': 'active',
        'members': ['m1', 'm2', 'm3'],
        'creatorId': 'seed_1',
      },
      {
        'id': 'grp_2',
        'equipmentType': 'Mini Combine Harvester',
        'currentMembers': 2,
        'targetMembers': 3,
        'targetPrice': 360000.0,
        'locationName': 'Kengeri, Bengaluru',
        'status': 'active',
        'members': ['m1', 'm2'],
        'creatorId': 'seed_2',
      },
      {
        'id': 'grp_3',
        'equipmentType': '10 HP Solar Pump Set',
        'currentMembers': 4,
        'targetMembers': 5,
        'targetPrice': 150000.0,
        'locationName': 'Yelahanka',
        'status': 'active',
        'members': ['m1', 'm2', 'm3', 'm4'],
        'creatorId': 'seed_3',
      },
    ];
  }

  Farmer getFallbackFarmer(String? uid) {
    return Farmer(
      uid: uid ?? 'demo_farmer',
      name: 'Ramesh Kumar',
      email: 'ramesh.farmer@agroshare.app',
      location: 'Mandya, Karnataka',
      phone: '+91 9876543210',
      trustScore: 4.8,
      completedRentals: 12,
      groupPurchases: 3,
      profileImage: '',
    );
  }

  /// Add a new equipment listing.
  Future<DocumentReference> addEquipment(Map<String, dynamic> data) async {
    final sanitized = _sanitizeForFirestore(data);
    try {
      return await _equipment.add(sanitized);
    } catch (e) {
      // ignore: avoid_print
      print('Firestore addEquipment notice: $e. Saving to local store.');
      final localId = 'local_${DateTime.now().millisecondsSinceEpoch}';
      sanitized['id'] = localId;
      _localEquipmentStore.add(sanitized);
      return _equipment.doc(localId);
    }
  }

  /// Stream all available equipment.
  Stream<QuerySnapshot> equipmentStream() {
    return _equipment.orderBy('createdAt', descending: true).snapshots();
  }

  /// Stream equipment owned by a specific user.
  Stream<QuerySnapshot> userEquipmentStream(String uid) {
    return _equipment.where('ownerId', isEqualTo: uid).snapshots();
  }

  /// Stream a single equipment document by ID for real-time detail updates.
  Stream<DocumentSnapshot> equipmentByIdStream(String id) {
    return _equipment.doc(id).snapshots();
  }

  /// Delete an equipment listing.
  Future<void> deleteEquipment(String docId) {
    return _equipment.doc(docId).delete();
  }

  /// Update an equipment listing.
  Future<void> updateEquipment(String docId, Map<String, dynamic> data) {
    try {
      final sanitized = _sanitizeForFirestore(data);
      if (sanitized.isEmpty) return Future.value();
      return _equipment.doc(docId).update(sanitized);
    } catch (e) {
      // ignore: avoid_print
      print('Firestore updateEquipment error: $e');
      rethrow;
    }
  }

  // ══════════════════════════════════════════════════════════════
  // BOOKINGS
  // ══════════════════════════════════════════════════════════════

  /// Create a new booking.
  Future<DocumentReference> createBooking(Map<String, dynamic> data) {
    try {
      return _bookings.add(_sanitizeForFirestore(data));
    } catch (e) {
      // ignore: avoid_print
      print('Firestore createBooking error: $e');
      rethrow;
    }
  }

  /// Stream bookings for a user.
  Stream<QuerySnapshot> userBookingsStream(String uid) {
    return _bookings
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Update booking status.
  Future<void> updateBookingStatus(String docId, String status) {
    try {
      final sanitized = _sanitizeForFirestore({'status': status});
      if (sanitized.isEmpty) return Future.value();
      return _bookings.doc(docId).update(sanitized);
    } catch (e) {
      // ignore: avoid_print
      print('Firestore updateBookingStatus error: $e');
      rethrow;
    }
  }

  Future<void> completeBooking(
    String docId,
    double rating,
    String reviewText,
  ) {
    try {
      // 1. Ensure document IDs do not contain spaces.
      final safeDocId = docId.replaceAll(' ', '_');

      // 2. Ensure rating is stored as a double.
      final double ratingValue = rating.isNaN || !rating.isFinite ? 0.0 : rating.clamp(0.0, 5.0);
      final String safeReviewText = reviewText.isEmpty ? '' : reviewText;

      // 3, 4, 5. Replace DateTime.now() with FieldValue.serverTimestamp(), no nulls.
      final payload = <String, dynamic>{
        'status': 'completed',
        'rating': ratingValue.toDouble(),
        'reviewText': safeReviewText,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final sanitized = _sanitizeForFirestore(payload);
      if (sanitized.isEmpty) return Future.value();

      // 6. Add debugging logs before Firestore writes.
      // ignore: avoid_print
      print('--- DEBUG INFO FOR completeBooking ---');
      // ignore: avoid_print
      print('Booking ID: $safeDocId');
      // ignore: avoid_print
      print('Booking Update Data: $sanitized');
      // ignore: avoid_print
      print('--- END DEBUG INFO ---');

      return _bookings.doc(safeDocId).update(sanitized);
    } catch (e) {
      // ignore: avoid_print
      print('Firestore completeBooking error: $e');
      rethrow;
    }
  }

  /// Save Pre-Rental Condition Inspection record to booking.
  Future<void> savePreConditionVerification(String docId, Map<String, dynamic> conditionData) async {
    try {
      final safeDocId = docId.replaceAll(' ', '_');
      final payload = {
        'preCondition': conditionData,
        'isPreVerified': true,
        'status': 'active', // Automatically move to active after pre-condition verification!
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await _bookings.doc(safeDocId).update(_sanitizeForFirestore(payload));
    } catch (e) {
      // ignore: avoid_print
      print('Firestore savePreConditionVerification error: $e');
      rethrow;
    }
  }

  /// Save Post-Rental Condition Inspection record to booking.
  Future<void> savePostConditionVerification(String docId, Map<String, dynamic> conditionData) async {
    try {
      final safeDocId = docId.replaceAll(' ', '_');
      final payload = {
        'postCondition': conditionData,
        'isPostVerified': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await _bookings.doc(safeDocId).update(_sanitizeForFirestore(payload));
    } catch (e) {
      // ignore: avoid_print
      print('Firestore savePostConditionVerification error: $e');
      rethrow;
    }
  }

  /// Complete verified rental return, submit review, record remaining payment, and update trust score.
  Future<void> completeVerifiedRental({
    required String bookingId,
    required String equipmentId,
    required String userId,
    required double rating,
    required String reviewText,
    String? remainingTxnId,
  }) async {
    try {
      await submitEquipmentReview(
        bookingId: bookingId,
        equipmentId: equipmentId,
        userId: userId,
        rating: rating,
        reviewText: reviewText,
      );

      final safeDocId = bookingId.replaceAll(' ', '_');
      final updates = <String, dynamic>{
        'paymentStatus': 'fully_paid',
        'isPostVerified': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (remainingTxnId != null && remainingTxnId.isNotEmpty) {
        updates['finalTxnId'] = remainingTxnId;
      }
      await _bookings.doc(safeDocId).update(_sanitizeForFirestore(updates));

      // Recalculate & update farmer trust score upon verified return!
      await recalculateTrustScore(userId);
    } catch (e) {
      // ignore: avoid_print
      print('Firestore completeVerifiedRental error: $e');
      rethrow;
    }
  }

  /// Recalculate farmer Trust Score dynamically based on completed rentals, ratings & verified returns.
  Future<void> recalculateTrustScore(String uid) async {
    try {
      final userDoc = await _users.doc(uid).get();
      if (!userDoc.exists) return;

      final data = userDoc.data() as Map<String, dynamic>? ?? {};
      final currentCompleted = (data['completedRentals'] ?? 0).toInt() + 1;
      final currentVerified = (data['verifiedReturns'] ?? 0).toInt() + 1;

      // Query reviews for user
      final reviewsSnap = await _reviews.where('revieweeId', isEqualTo: uid).get();
      double avgRating = 4.8;
      if (reviewsSnap.docs.isNotEmpty) {
        double total = 0;
        for (var doc in reviewsSnap.docs) {
          total += ((doc.data() as Map<String, dynamic>)['rating'] ?? 5.0).toDouble();
        }
        avgRating = total / reviewsSnap.docs.length;
      }

      final newTrustScore = Farmer.calculateTrustScore(
        avgRating: avgRating,
        completedRentals: currentCompleted,
        verifiedReturns: currentVerified,
      );

      await _users.doc(uid).update(_sanitizeForFirestore({
        'completedRentals': currentCompleted,
        'verifiedReturns': currentVerified,
        'trustScore': newTrustScore,
        'updatedAt': FieldValue.serverTimestamp(),
      }));
    } catch (e) {
      // ignore: avoid_print
      print('Firestore recalculateTrustScore error: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════
  // PAYMENTS (PROTOTYPE SIMULATION)
  // ══════════════════════════════════════════════════════════════

  /// Save payment transaction record to Firestore.
  Future<DocumentReference> recordPayment(Map<String, dynamic> data) async {
    try {
      return await _payments.add(_sanitizeForFirestore(data));
    } catch (e) {
      // ignore: avoid_print
      print('Firestore recordPayment error: $e');
      rethrow;
    }
  }

  /// Stream user payment transaction history.
  Stream<QuerySnapshot> userPaymentsStream(String uid) {
    return _payments
        .where('userId', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Fallback demo payment transactions for offline testing.
  List<Payment> getFallbackPayments(String uid) {
    final now = DateTime.now();
    return [
      Payment(
        id: 'pay_seed_1',
        transactionId: 'TXN2026081910245892',
        userId: uid,
        equipmentId: 'seed_1',
        equipmentName: 'Mahindra Tractor 575 DI',
        equipmentImage: 'assets/images/tractor.webp',
        amount: 200.0,
        paymentType: 'rental_deposit',
        paymentMethod: 'PhonePe UPI',
        upiId: 'farmer@ybl',
        status: 'successful',
        date: now.subtract(const Duration(hours: 4)),
        bookingId: 'bk_1',
      ),
      Payment(
        id: 'pay_seed_2',
        transactionId: 'TXN2026081514301290',
        userId: uid,
        equipmentId: 'seed_3',
        equipmentName: 'Irrigation Pump Set',
        equipmentImage: 'assets/images/pump.webp',
        amount: 600.0,
        paymentType: 'rental_remaining',
        paymentMethod: 'Google Pay',
        upiId: 'farmer@okicici',
        status: 'successful',
        date: now.subtract(const Duration(days: 5)),
        bookingId: 'bk_3',
      ),
    ];
  }

  // ══════════════════════════════════════════════════════════════
  // COMMUNITY GROUPS
  // ══════════════════════════════════════════════════════════════

  /// Create a new community group.
  Future<DocumentReference> createGroup(Map<String, dynamic> data) {
    try {
      return _groups.add(_sanitizeForFirestore(data));
    } catch (e) {
      // ignore: avoid_print
      print('Firestore createGroup error: $e');
      rethrow;
    }
  }

  /// Stream all groups.
  Stream<QuerySnapshot> groupsStream() {
    return _groups.orderBy('createdAt', descending: true).snapshots();
  }

  /// Stream a single group by ID.
  Stream<DocumentSnapshot> groupStream(String groupId) {
    return _groups.doc(groupId).snapshots();
  }

  /// Join a group — add uid to members array.
  Future<void> joinGroup(String groupId, String uid) {
    try {
      return _groups.doc(groupId).update({
        'members': FieldValue.arrayUnion([uid]),
        'currentMembers': FieldValue.increment(1),
      });
    } catch (e) {
      // ignore: avoid_print
      print('Firestore joinGroup error: $e');
      rethrow;
    }
  }

  // ══════════════════════════════════════════════════════════════
  // REVIEWS
  // ══════════════════════════════════════════════════════════════

  /// Add a review.
  Future<DocumentReference> addReview(Map<String, dynamic> data) {
    try {
      return _reviews.add(_sanitizeForFirestore(data));
    } catch (e) {
      // ignore: avoid_print
      print('Firestore addReview error: $e');
      rethrow;
    }
  }

  /// Stream reviews for a user.
  Stream<QuerySnapshot> userReviewsStream(String uid) {
    return _reviews.where('revieweeId', isEqualTo: uid).snapshots();
  }

  // ══════════════════════════════════════════════════════════════
  // CHAT (real-time messaging between user and owner)
  // ══════════════════════════════════════════════════════════════

  /// Room ID is sorted pair of UIDs so one room per pair.
  static String chatRoomId(String uid1, String uid2) {
    final a = uid1.compareTo(uid2) <= 0 ? uid1 : uid2;
    final b = uid1.compareTo(uid2) <= 0 ? uid2 : uid1;
    return '${a}_$b';
  }

  /// Get or create a chat room between two users. Returns room ID.
  Future<String> getOrCreateChatRoom(String uid1, String uid2) async {
    final roomId = chatRoomId(uid1, uid2);
    final ref = _chats.doc(roomId);
    final snap = await ref.get();
    if (snap.exists) return roomId;
    await ref.set(_sanitizeForFirestore({
      'participantIds': [uid1, uid2],
      'lastMessage': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }));
    return roomId;
  }

  /// Send a message and update room lastMessage.
  Future<void> sendChatMessage({
    required String roomId,
    required String senderId,
    required String text,
  }) async {
    final sanitized = _sanitizeForFirestore({
      'senderId': senderId,
      'text': text.isEmpty ? '' : text,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _chats.doc(roomId).collection('messages').add(sanitized);
    await _chats.doc(roomId).update(_sanitizeForFirestore({
      'lastMessage': text.isEmpty ? '' : text,
      'lastMessageAt': FieldValue.serverTimestamp(),
    }));
  }

  /// Real-time stream of messages in a room.
  Stream<QuerySnapshot> chatMessagesStream(String roomId) {
    return _chats
        .doc(roomId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  /// Submit an equipment review and mark the booking as completed, while
  /// updating the equipment's aggregate rating and review count.
  /// All fields are normalized to valid Firestore types; no nulls or invalid names.
  Future<void> submitEquipmentReview({
    required String bookingId,
    required String equipmentId,
    required String userId,
    required double rating,
    required String reviewText,
  }) async {
    try {
      // 1. Ensure document IDs do not contain spaces.
      final safeBookingId = bookingId.replaceAll(' ', '_');
      final safeEquipmentId = equipmentId.replaceAll(' ', '_');
      final safeUserId = userId.replaceAll(' ', '_');

      // 2. Normalize inputs: ensure rating is a valid double, reviewText is non-null string.
      double ratingValue = rating.isNaN || !rating.isFinite ? 0.0 : rating.clamp(0.0, 5.0);
      String reviewTextValue = reviewText.isEmpty ? '' : reviewText;

      // 3 & 4. Build review document with valid field names and types only (no nulls). Replace DateTime.now() with FieldValue.serverTimestamp().
      final reviewPayload = <String, dynamic>{
        'equipmentId': safeEquipmentId,
        'userId': safeUserId,
        'rating': ratingValue.toDouble(),
        'reviewText': reviewTextValue,
        'date': FieldValue.serverTimestamp(),
        'bookingId': safeBookingId,
      };

      // 5. Sanitize: Ensure no null values and no special characters in field names.
      final reviewData = _sanitizeForFirestore(reviewPayload);
      if (reviewData.isEmpty) {
        // ignore: avoid_print
        print('submitEquipmentReview: sanitized review data is empty, aborting');
        return;
      }

      final bookingRef = _bookings.doc(safeBookingId);
      final equipmentRef = _equipment.doc(safeEquipmentId);
      final reviewRef = _reviews.doc();

      await _db.runTransaction((txn) async {
        final equipmentSnap = await txn.get(equipmentRef);

        // 6. Add debugging logs before Firestore writes to verify data being sent.
        // ignore: avoid_print
        print('--- DEBUG INFO FOR submitEquipmentReview ---');
        // ignore: avoid_print
        print('Review Doc Setup: equipmentId: $safeEquipmentId, userId: $safeUserId, bookingId: $safeBookingId');
        // ignore: avoid_print
        print('Review Data to Write: $reviewData');
        
        txn.set(reviewRef, reviewData);

        final bookingUpdate = _sanitizeForFirestore(<String, dynamic>{
          'status': 'completed',
          'rating': ratingValue.toDouble(),
          'reviewText': reviewTextValue,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        if (bookingUpdate.isNotEmpty) {
          // ignore: avoid_print
          print('Booking Update Request for $safeBookingId: $bookingUpdate');
          txn.update(bookingRef, bookingUpdate);
        }

        // Only update equipment if it still exists
        if (equipmentSnap.exists) {
          final data = equipmentSnap.data() as Map<String, dynamic>? ?? <String, dynamic>{};

          final currentRating = (data['rating'] ?? 0).toDouble();
          final currentCount = (data['reviewCount'] ?? 0).toInt();

          final int newCount = (currentCount + 1).toInt();
          final double sumRating = (currentRating * currentCount) + ratingValue;
          final double newRating = newCount > 0 ? sumRating / newCount : 0.0;
          final double newRatingSafe = newRating.isNaN || !newRating.isFinite ? 0.0 : newRating;

          final equipmentUpdate = _sanitizeForFirestore(<String, dynamic>{
            'rating': newRatingSafe.toDouble(),
            'reviewCount': newCount.toInt(),
            'isAvailable': true,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          
          if (equipmentUpdate.isNotEmpty) {
            // ignore: avoid_print
            print('Equipment Update Request for $safeEquipmentId: $equipmentUpdate');
            txn.update(equipmentRef, equipmentUpdate);
          }
        } else {
          // ignore: avoid_print
          print('Warning: equipment $safeEquipmentId not found, skipping equipment update.');
        }
        // ignore: avoid_print
        print('--- END DEBUG INFO ---');
      });
    } catch (e, stackTrace) {
      // ignore: avoid_print
      print('Firestore submitEquipmentReview error: $e');
      // ignore: avoid_print
      print('Firestore submitEquipmentReview stackTrace: $stackTrace');
      rethrow;
    }
  }

  // ══════════════════════════════════════════════════════════════
  // EQUIPMENT REQUESTS & RESPONSES
  // ══════════════════════════════════════════════════════════════

  /// Post a new equipment request.
  Future<DocumentReference> createEquipmentRequest(Map<String, dynamic> data) async {
    final sanitized = _sanitizeForFirestore(data);
    try {
      return await _requests.add(sanitized);
    } catch (e) {
      // ignore: avoid_print
      print('Firestore createEquipmentRequest notice: $e');
      rethrow;
    }
  }

  /// Stream all equipment requests.
  Stream<QuerySnapshot> equipmentRequestsStream() {
    return _requests.orderBy('createdAt', descending: true).snapshots();
  }

  /// Stream open requests for owners to browse.
  Stream<QuerySnapshot> openRequestsStream() {
    return _requests
        .where('status', isEqualTo: 'open')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Stream requests posted by a specific user.
  Stream<QuerySnapshot> myEquipmentRequestsStream(String uid) {
    return _requests
        .where('requesterId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Stream a single request doc by ID.
  Stream<DocumentSnapshot> equipmentRequestStream(String id) {
    return _requests.doc(id).snapshots();
  }

  /// Update request status.
  Future<void> updateEquipmentRequestStatus(String requestId, String status) {
    return _requests.doc(requestId).update({'status': status});
  }

  /// Submit an owner offer/response to a request.
  Future<DocumentReference> submitRequestResponse(Map<String, dynamic> data) async {
    final sanitized = _sanitizeForFirestore(data);
    final ref = await _requestResponses.add(sanitized);
    final requestId = data['requestId'] as String?;
    if (requestId != null && requestId.isNotEmpty) {
      try {
        await _requests.doc(requestId).update({
          'responseCount': FieldValue.increment(1),
        });
      } catch (_) {}
    }
    return ref;
  }

  /// Stream responses for a specific request.
  Stream<QuerySnapshot> requestResponsesStream(String requestId) {
    return _requestResponses
        .where('requestId', isEqualTo: requestId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Accept an owner offer.
  Future<void> acceptRequestResponse({
    required String requestId,
    required String responseId,
  }) async {
    final batch = _db.batch();
    batch.update(_requestResponses.doc(responseId), {'status': 'accepted'});
    batch.update(_requests.doc(requestId), {'status': 'fulfilled'});
    await batch.commit();
  }

  /// Fallback requests for demo/offline.
  List<EquipmentRequest> getFallbackEquipmentRequests() {
    final now = DateTime.now();
    return [
      EquipmentRequest(
        id: 'req_1',
        requesterId: 'demo_farmer_1',
        requesterName: 'Ramesh Patel',
        equipmentType: 'Mahindra Tractor 575 DI',
        taskCrop: 'Wheat Plowing',
        requiredDate: now.add(const Duration(days: 2)),
        durationHours: 6,
        locationName: 'Angondhalli',
        latitude: 12.9650,
        longitude: 77.6000,
        maxBudgetPerHour: 550.0,
        description: 'Urgently need 45+ HP tractor with rotavator attachment for 5 acres of wheat field plowing.',
        status: 'open',
        createdAt: now.subtract(const Duration(hours: 3)),
        responseCount: 2,
      ),
      EquipmentRequest(
        id: 'req_2',
        requesterId: 'demo_farmer_2',
        requesterName: 'Suresh Gowda',
        equipmentType: 'Mini Harvester',
        taskCrop: 'Paddy Harvesting',
        requiredDate: now.add(const Duration(days: 4)),
        durationHours: 8,
        locationName: 'Ramapur',
        latitude: 12.9800,
        longitude: 77.5850,
        maxBudgetPerHour: 850.0,
        description: 'Need mini combine harvester for harvesting 3 acres of paddy crops before rain expected this weekend.',
        status: 'open',
        createdAt: now.subtract(const Duration(hours: 12)),
        responseCount: 1,
      ),
      EquipmentRequest(
        id: 'req_3',
        requesterId: 'demo_farmer_3',
        requesterName: 'Anita Sharma',
        equipmentType: 'Irrigation Pump Set',
        taskCrop: 'Vegetable Field Watering',
        requiredDate: now.add(const Duration(days: 1)),
        durationHours: 4,
        locationName: 'Kengeri',
        latitude: 12.9550,
        longitude: 77.5700,
        maxBudgetPerHour: 220.0,
        description: 'Need 5 HP diesel pump with 100m pipe set for emergency watering of tomato crop field.',
        status: 'open',
        createdAt: now.subtract(const Duration(days: 1)),
        responseCount: 3,
      ),
    ];
  }

  /// Fallback responses for demo/offline.
  List<EquipmentRequestResponse> getFallbackRequestResponses(String requestId) {
    final now = DateTime.now();
    return [
      EquipmentRequestResponse(
        id: 'resp_1',
        requestId: requestId,
        ownerId: 'seed',
        ownerName: 'Rajesh Kumar',
        equipmentId: 'seed_1',
        equipmentName: 'Mahindra Tractor 575 DI',
        equipmentImage: 'assets/images/tractor.webp',
        offeredPricePerHour: 500.0,
        message: 'Tractor is fully serviced with rotavator attached. Ready for your wheat field plowing on requested date.',
        status: 'pending',
        createdAt: now.subtract(const Duration(minutes: 45)),
      ),
      EquipmentRequestResponse(
        id: 'resp_2',
        requestId: requestId,
        ownerId: 'seed',
        ownerName: 'Vikram Singh',
        equipmentId: 'seed_4',
        equipmentName: 'Rotavator Heavy Duty',
        equipmentImage: 'assets/images/rotavator.webp',
        offeredPricePerHour: 520.0,
        message: 'Includes experienced driver and fuel. Can start early morning.',
        status: 'pending',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
    ];
  }

  // ══════════════════════════════════════════════════════════════
  // SEED DATA
  // ══════════════════════════════════════════════════════════════

  /// Seed dummy equipment data if the collection is empty.
  Future<void> seedDummyEquipment() async {
    try {
      final snapshot = await _equipment.limit(1).get();
      if (snapshot.docs.isNotEmpty) return; // already seeded

    final dummyItems = [
      {
        'name': 'Mahindra Tractor 575 DI',
        'pricePerHour': 500.0,
        'distance': 2.0,
        'rating': 4.7,
        'reviewCount': 24,
        'imageUrl': 'assets/images/tractor.webp',
        'ownerName': 'Rajesh Kumar',
        'ownerId': 'seed',
        'description':
            'Powerful 45 HP tractor ideal for ploughing, tilling, and hauling. Well-maintained with AC cabin.',
        'locationName': 'Angondhalli',
        'latitude': 12.9650,
        'longitude': 77.6000,
        'isAvailable': true,
        'purchasePrice': 250000.0,
        'listingType': 'rent',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Mini Harvester',
        'pricePerHour': 800.0,
        'distance': 3.0,
        'rating': 4.5,
        'reviewCount': 12,
        'imageUrl': 'assets/images/harvester.webp',
        'ownerName': 'Sunil Patil',
        'ownerId': 'seed',
        'description':
            'Compact combine harvester suitable for wheat and rice. High efficiency with low grain loss.',
        'locationName': 'Ramapur',
        'latitude': 12.9800,
        'longitude': 77.5850,
        'isAvailable': true,
        'purchasePrice': 350000.0,
        'listingType': 'sell',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Irrigation Pump Set',
        'pricePerHour': 200.0,
        'distance': 1.5,
        'rating': 4.2,
        'reviewCount': 8,
        'imageUrl': 'assets/images/pump.webp',
        'ownerName': 'Anita Sharma',
        'ownerId': 'seed',
        'description':
            '5 HP diesel pump with 100m pipe set. Perfect for field irrigation during dry spells.',
        'locationName': 'Kengeri',
        'latitude': 12.9550,
        'longitude': 77.5700,
        'isAvailable': true,
        'purchasePrice': 45000.0,
        'listingType': 'rent',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Rotavator',
        'pricePerHour': 600.0,
        'distance': 4.0,
        'rating': 4.8,
        'reviewCount': 36,
        'imageUrl': 'assets/images/rotavator.webp',
        'ownerName': 'Vikram Singh',
        'ownerId': 'seed',
        'description':
            'Heavy-duty rotavator for soil preparation. 48 blades, 6-foot working width.',
        'locationName': 'Yelahanka',
        'latitude': 12.9900,
        'longitude': 77.6100,
        'isAvailable': true,
        'purchasePrice': 180000.0,
        'listingType': 'sell',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Seed Drill Machine',
        'pricePerHour': 350.0,
        'distance': 2.5,
        'rating': 4.4,
        'reviewCount': 15,
        'imageUrl': 'assets/images/seed_drill.webp',
        'ownerName': 'Priya Desai',
        'ownerId': 'seed',
        'description':
            'Precision seed drill with 9-row capacity. Ensures even seed spacing and depth.',
        'locationName': 'Whitefield',
        'latitude': 12.9750,
        'longitude': 77.6200,
        'isAvailable': true,
        'purchasePrice': 120000.0,
        'listingType': 'rent',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Crop Sprayer',
        'pricePerHour': 250.0,
        'distance': 1.8,
        'rating': 4.3,
        'reviewCount': 19,
        'imageUrl': 'assets/images/sprayer.webp',
        'ownerName': 'Mohan Reddy',
        'ownerId': 'seed',
        'description':
            'Boom sprayer with 200L tank capacity. Ideal for pesticide and fertilizer application.',
        'locationName': 'Hebbal',
        'latitude': 12.9600,
        'longitude': 77.5800,
        'isAvailable': true,
        'purchasePrice': 75000.0,
        'listingType': 'sell',
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];

    final batch = _db.batch();
    for (final item in dummyItems) {
      batch.set(_equipment.doc(), _sanitizeForFirestore(Map<String, dynamic>.from(item)));
    }
    await batch.commit();
    } catch (e) {
      // ignore: avoid_print
      print('Firestore seedDummyEquipment error: $e');
      rethrow;
    }
  }
}
