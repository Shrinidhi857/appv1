// File: landmark_receiver.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';

/// Models for hand landmark data (kept from original)
class HandLandmark {
  final double x, y, z;
  HandLandmark({required this.x, required this.y, required this.z});

  factory HandLandmark.fromJson(Map<String, dynamic> json) {
    return HandLandmark(
      x: (json['x'] ?? 0).toDouble(),
      y: (json['y'] ?? 0).toDouble(),
      z: (json['z'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {'x': x, 'y': y, 'z': z};
}

class HandFeatures {
  final double thumbDistance;
  final double indexDistance;
  final double handSize;

  HandFeatures({
    required this.thumbDistance,
    required this.indexDistance,
    required this.handSize,
  });

  factory HandFeatures.fromJson(Map<String, dynamic> json) {
    return HandFeatures(
      thumbDistance: (json['thumb_distance'] ?? 0).toDouble(),
      indexDistance: (json['index_distance'] ?? 0).toDouble(),
      handSize: (json['hand_size'] ?? 0).toDouble(),
    );
  }
}

class HandData {
  final int handIndex;
  final String label;
  final double confidence;
  final List<HandLandmark> landmarks;
  final HandFeatures? features;

  HandData({
    required this.handIndex,
    required this.label,
    required this.confidence,
    required this.landmarks,
    this.features,
  });

  factory HandData.fromJson(Map<String, dynamic> json) {
    var landmarksList = (json['landmarks'] as List?) ?? [];
    List<HandLandmark> landmarksData = landmarksList
        .map((landmark) {
          if (landmark is List && landmark.length >= 3) {
            // sometimes landmarks can be arrays [x,y,z]
            return HandLandmark(
                x: (landmark[0] ?? 0).toDouble(),
                y: (landmark[1] ?? 0).toDouble(),
                z: (landmark[2] ?? 0).toDouble());
          } else if (landmark is Map) {
            return HandLandmark.fromJson(Map<String, dynamic>.from(landmark));
          } else {
            return HandLandmark(x: 0, y: 0, z: 0);
          }
        })
        .cast<HandLandmark>()
        .toList();

    HandFeatures? features;
    if (json.containsKey('features') && json['features'] is Map) {
      features = HandFeatures.fromJson(Map<String, dynamic>.from(json['features']));
    }

    return HandData(
      handIndex: (json['hand_index'] ?? 0) is int ? json['hand_index'] : int.tryParse((json['hand_index'] ?? '0').toString()) ?? 0,
      label: (json['label'] ?? '').toString(),
      confidence: (json['confidence'] ?? 0).toDouble(),
      landmarks: landmarksData,
      features: features,
    );
  }

  Map<String, dynamic> toJson() => {
        'hand_index': handIndex,
        'label': label,
        'confidence': confidence,
        'landmarks': landmarks.map((e) => e.toJson()).toList(),
        'features': features == null
            ? null
            : {
                'thumb_distance': features!.thumbDistance,
                'index_distance': features!.indexDistance,
                'hand_size': features!.handSize,
              },
      };
}

class LandmarkDataPacket {
  final double timestamp;
  final int handsCount;
  final List<HandData> hands;

  LandmarkDataPacket({
    required this.timestamp,
    required this.handsCount,
    required this.hands,
  });

  factory LandmarkDataPacket.fromJson(Map<String, dynamic> json) {
    var handsList = (json['hands'] as List?) ?? [];
    List<HandData> hands = handsList
        .map((hand) => HandData.fromJson(Map<String, dynamic>.from(hand)))
        .toList();

    return LandmarkDataPacket(
      timestamp: (json['timestamp'] ?? 0).toDouble(),
      handsCount: (json['hands_count'] ?? hands.length) is int ? (json['hands_count'] ?? hands.length) : int.tryParse((json['hands_count'] ?? hands.length).toString()) ?? hands.length,
      hands: hands,
    );
  }

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp,
        'hands_count': handsCount,
        'hands': hands.map((h) => h.toJson()).toList(),
      };
}

/// LandmarkReceiver: accepts payloads (Map) and emits a broadcast stream
class LandmarkReceiver {
  final StreamController<LandmarkDataPacket> _ctrl = StreamController<LandmarkDataPacket>.broadcast();

  Stream<LandmarkDataPacket> get stream => _ctrl.stream;

  void dispose() {
    if (!_ctrl.isClosed) _ctrl.close();
  }

  void clear() {
    if (!_ctrl.isClosed) {
      _ctrl.add(LandmarkDataPacket(timestamp: 0.0, handsCount: 0, hands: []));
    }
  }

  /// Accepts a payload map (from server) - flexible parsing
  /// payload should be like: {"timestamp":..., "hands_count":..., "hands":[...] }
  void processPayload(Map<String, dynamic> payload) {
    try {
      final packet = LandmarkDataPacket.fromJson(payload);
      if (!_ctrl.isClosed) _ctrl.add(packet);
    } catch (e) {
      debugPrint('LandmarkReceiver.processPayload error: $e');
    }
  }
}
