import 'package:camera/camera.dart';

class CameraModel {
  final String id;
  final CameraDescription description;
  final String name;
  final CameraLensDirection lensDirection;

  CameraModel({
    required this.id,
    required this.description,
    required this.name,
    required this.lensDirection,
  });

  factory CameraModel.fromDescription(CameraDescription description) {
    return CameraModel(
      id: description.sensorOrientation.toString(),
      description: description,
      name: description.name,
      lensDirection: description.lensDirection,
    );
  }
}

class CameraStatus {
  final bool isInitialized;
  final bool isRecording;
  final String? errorMessage;
  final DateTime? lastFrameTime;

  CameraStatus({
    this.isInitialized = false,
    this.isRecording = false,
    this.errorMessage,
    this.lastFrameTime,
  });

  CameraStatus copyWith({
    bool? isInitialized,
    bool? isRecording,
    String? errorMessage,
    DateTime? lastFrameTime,
  }) {
    return CameraStatus(
      isInitialized: isInitialized ?? this.isInitialized,
      isRecording: isRecording ?? this.isRecording,
      errorMessage: errorMessage ?? this.errorMessage,
      lastFrameTime: lastFrameTime ?? this.lastFrameTime,
    );
  }
}

