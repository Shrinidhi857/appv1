// File: landmark_bus.dart
// Simple singleton to share LandmarkReceiver across app

import 'bluetooth/landmark_receiver.dart';

final LandmarkReceiver landmarkBus = LandmarkReceiver();
