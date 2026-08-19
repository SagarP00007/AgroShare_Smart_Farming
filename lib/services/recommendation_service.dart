import 'package:latlong2/latlong.dart';
import '../models/equipment.dart';

/// Represents recommendation criteria submitted by a farmer.
class RecommendationCriteria {
  const RecommendationCriteria({
    this.crop,
    this.task,
    this.landSizeAcres,
    this.maxBudgetPerHour,
    this.userLocation,
    this.searchQuery,
  });

  final String? crop;
  final String? task;
  final double? landSizeAcres;
  final double? maxBudgetPerHour;
  final LatLng? userLocation;
  final String? searchQuery;

  bool get isEmpty =>
      (crop == null || crop!.isEmpty) &&
      (task == null || task!.isEmpty) &&
      (landSizeAcres == null || landSizeAcres == 0) &&
      (maxBudgetPerHour == null || maxBudgetPerHour == 0) &&
      (searchQuery == null || searchQuery!.isEmpty);

  bool get isNotEmpty => !isEmpty;
}

/// Holds a recommended equipment item along with match analytics.
class RecommendedEquipment {
  const RecommendedEquipment({
    required this.equipment,
    required this.matchScore,
    required this.matchReason,
    required this.highlights,
  });

  final Equipment equipment;
  final int matchScore; // Percentage 0 - 100%
  final String matchReason;
  final List<String> highlights;
}

/// Smart Equipment Recommendation Service.
/// Analyzes real Firestore equipment data against farmer constraints.
class RecommendationService {
  RecommendationService._();
  static final RecommendationService instance = RecommendationService._();

  /// Ranks a list of available Firestore equipment based on farmer criteria.
  List<RecommendedEquipment> recommend({
    required List<Equipment> equipmentList,
    required RecommendationCriteria criteria,
  }) {
    if (equipmentList.isEmpty) return [];

    final scored = <RecommendedEquipment>[];

    for (final item in equipmentList) {
      if (!item.isAvailable) continue;

      int score = 50; // Base baseline score for available equipment
      final highlights = <String>[];

      final nameLower = item.name.toLowerCase();
      final descLower = item.description.toLowerCase();
      final taskLower = (criteria.task ?? '').toLowerCase();
      final cropLower = (criteria.crop ?? '').toLowerCase();
      final queryLower = (criteria.searchQuery ?? '').toLowerCase();

      // 1. Task Match Scoring (Weight: 35 pts)
      if (taskLower.isNotEmpty) {
        if (_matchesTask(nameLower, descLower, taskLower)) {
          score += 35;
          highlights.add('Ideal for $taskLower');
        } else {
          score -= 15;
        }
      }

      // 2. Query Text Match Scoring (Weight: 20 pts)
      if (queryLower.isNotEmpty) {
        if (nameLower.contains(queryLower) || descLower.contains(queryLower)) {
          score += 20;
          highlights.add('Matches "$queryLower"');
        }
      }

      // 3. Crop Match Scoring (Weight: 15 pts)
      if (cropLower.isNotEmpty) {
        if (_matchesCrop(nameLower, descLower, cropLower)) {
          score += 15;
          highlights.add('Recommended for $cropLower');
        }
      }

      // 4. Budget Fit Scoring (Weight: 20 pts)
      final maxBudget = criteria.maxBudgetPerHour;
      if (maxBudget != null && maxBudget > 0) {
        if (item.pricePerHour <= maxBudget) {
          score += 20;
          highlights.add('Fits ₹${maxBudget.toInt()}/hr budget');
        } else if (item.pricePerHour <= maxBudget * 1.15) {
          score += 8;
          highlights.add('Slightly above target budget');
        } else {
          score -= 20;
        }
      }

      // 5. Land Size Capacity Scoring (Weight: 10 pts)
      final land = criteria.landSizeAcres;
      if (land != null && land > 0) {
        final (landScore, landTag) = _scoreLandCapacity(nameLower, descLower, land);
        score += landScore;
        if (landTag.isNotEmpty) highlights.add(landTag);
      }

      // 6. Proximity & Rating Bonus
      final dist = item.calculateDistanceKm(
        criteria.userLocation?.latitude,
        criteria.userLocation?.longitude,
      );
      if (dist <= 5.0) {
        score += 5;
        highlights.add('Nearby (${dist.toStringAsFixed(1)} km)');
      }
      if (item.rating >= 4.5) {
        score += 5;
        highlights.add('Top Rated (${item.rating}★)');
      }

      // Clamp score to 60% - 98% for matching entries
      final finalScore = score.clamp(40, 98);

      // Only include items with positive match score
      if (finalScore >= 50 || criteria.isEmpty) {
        final reason = highlights.isNotEmpty
            ? highlights.take(2).join(' • ')
            : 'Available nearby in ${item.locationName}';

        scored.add(RecommendedEquipment(
          equipment: item,
          matchScore: finalScore,
          matchReason: reason,
          highlights: highlights,
        ));
      }
    }

    // Sort descending by match score, then distance
    scored.sort((a, b) {
      final scoreCompare = b.matchScore.compareTo(a.matchScore);
      if (scoreCompare != 0) return scoreCompare;
      final distA = a.equipment.calculateDistanceKm(
        criteria.userLocation?.latitude,
        criteria.userLocation?.longitude,
      );
      final distB = b.equipment.calculateDistanceKm(
        criteria.userLocation?.latitude,
        criteria.userLocation?.longitude,
      );
      return distA.compareTo(distB);
    });

    return scored;
  }

  bool _matchesTask(String name, String desc, String task) {
    switch (task) {
      case 'plowing':
        return name.contains('tractor') ||
            name.contains('rotavator') ||
            name.contains('plow') ||
            name.contains('tiller') ||
            desc.contains('ploughing') ||
            desc.contains('tilling');
      case 'harvesting':
        return name.contains('harvester') ||
            name.contains('thresher') ||
            name.contains('reaper') ||
            desc.contains('harvest');
      case 'irrigation':
        return name.contains('pump') ||
            name.contains('sprinkler') ||
            desc.contains('irrigation') ||
            desc.contains('water');
      case 'seeding':
        return name.contains('seed') ||
            name.contains('drill') ||
            name.contains('planter') ||
            desc.contains('planting') ||
            desc.contains('seeding');
      case 'spraying':
        return name.contains('sprayer') || desc.contains('pesticide');
      default:
        return name.contains(task) || desc.contains(task);
    }
  }

  bool _matchesCrop(String name, String desc, String crop) {
    if (crop == 'rice' || crop == 'paddy') {
      return name.contains('harvester') ||
          name.contains('thresher') ||
          name.contains('pump') ||
          name.contains('rotavator');
    }
    if (crop == 'wheat') {
      return name.contains('harvester') ||
          name.contains('seed drill') ||
          name.contains('tractor');
    }
    if (crop == 'sugarcane' || crop == 'cotton') {
      return name.contains('tractor') ||
          name.contains('rotavator') ||
          name.contains('sprayer');
    }
    if (crop == 'vegetables') {
      return name.contains('mini') ||
          name.contains('tiller') ||
          name.contains('sprayer') ||
          name.contains('pump');
    }
    return true;
  }

  (int, String) _scoreLandCapacity(String name, String desc, double acres) {
    if (acres <= 3.0) {
      if (name.contains('mini') || name.contains('tiller') || name.contains('pump') || name.contains('seed drill')) {
        return (10, 'Optimal for small farms (<3 acres)');
      }
      return (5, 'Suitable for 3 acres');
    } else if (acres <= 10.0) {
      if (name.contains('tractor') || name.contains('rotavator') || name.contains('harvester')) {
        return (10, 'Great capacity for $acres acres');
      }
      return (5, 'Covers $acres acres');
    } else {
      if (name.contains('tractor') || name.contains('harvester')) {
        return (10, 'Heavy-duty for large fields (>10 acres)');
      }
      return (3, 'Large acreage duty');
    }
  }
}
